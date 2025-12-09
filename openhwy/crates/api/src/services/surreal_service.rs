use std::env;

use anyhow::{anyhow, Context, Result};
use base64::{engine::general_purpose, Engine as _};
use chrono::Utc;
use once_cell::sync::OnceCell;
use reqwest::header::{HeaderMap, HeaderValue, AUTHORIZATION};
use reqwest::Client;
use serde_json::{json, Value};
use uuid::Uuid;

use crate::models::{CreateUserRequest, User, UserRole};

static SURREAL_SERVICE: OnceCell<SurrealService> = OnceCell::new();

pub struct SurrealService {
    client: Client,
    base_url: String,
    namespace: String,
    database: String,
    credentials: Option<(String, String)>,
}

impl SurrealService {
    pub async fn initialize() -> Result<()> {
        let namespace = env::var("SURREALDB_NAMESPACE").unwrap_or_else(|_| "hwy_tms".to_string());
        let database = env::var("SURREALDB_DATABASE").unwrap_or_else(|_| "local".to_string());
        let base_url =
            env::var("SURREALDB_URL").unwrap_or_else(|_| "http://127.0.0.1:8000".to_string());

        let credentials = match (
            env::var("SURREALDB_USER").ok(),
            env::var("SURREALDB_PASSWORD").ok(),
        ) {
            (Some(user), Some(password)) => Some((user, password)),
            _ => None,
        };

        let mut client_builder = Client::builder();
        let mut default_headers = HeaderMap::new();
        default_headers.insert("Accept", HeaderValue::from_static("application/json"));
        default_headers.insert("Content-Type", HeaderValue::from_static("text/plain"));

        if let Some((ref user, ref password)) = credentials {
            let pair = format!("{user}:{password}");
            let encoded = general_purpose::STANDARD.encode(pair.as_bytes());
            let header_value = HeaderValue::from_str(&format!("Basic {encoded}"))?;
            default_headers.insert(AUTHORIZATION, header_value);
        }

        client_builder = client_builder.default_headers(default_headers);
        let client = client_builder.build()?;

        let use_stmt = format!("USE {namespace} {database};");
        let service = SurrealService {
            client,
            base_url,
            namespace: namespace.clone(),
            database: database.clone(),
            credentials,
        };

        service
            .execute(&use_stmt)
            .await
            .context("failed to select SurrealDB namespace")?;

        SURREAL_SERVICE
            .set(service)
            .map_err(|_| anyhow!("SurrealService already initialized"))?;

        Ok(())
    }

    pub fn get() -> &'static Self {
        SURREAL_SERVICE
            .get()
            .expect("SurrealService not initialized")
    }

    pub async fn register_user(&self, payload: &CreateUserRequest) -> Result<User> {
        if self.find_user_by_email(&payload.email).await?.is_some() {
            return Err(anyhow!("Email already registered"));
        }

        let password_hash = bcrypt::hash(&payload.password, bcrypt::DEFAULT_COST)?;
        let role: UserRole = UserRole::Dispatcher;
        let now = Utc::now();

        let mut record = json!({
            "first_name": payload.first_name,
            "last_name": payload.last_name,
            "email": payload.email,
            "password_hash": password_hash,
            "role": serde_json::to_value(&role)?,
            "is_active": true,
            "created_at": now,
            "updated_at": now,
        });

        if let Some(phone) = &payload.phone {
            if let Value::Object(map) = &mut record {
                map.insert("phone".to_string(), Value::String(phone.clone()));
            }
        }

        let payload_str = record.to_string();
        let query = format!("CREATE user CONTENT {payload_str};");
        let mut results = self.execute(&query).await?;
        let raw_record = results
            .pop()
            .ok_or_else(|| anyhow!("SurrealDB did not return a user record"))?;
        self.record_to_user(raw_record)
    }

    pub async fn find_user_by_email(&self, email: &str) -> Result<Option<User>> {
        let sanitized_email = Self::sanitize(email);
        let query = format!("SELECT * FROM user WHERE email = '{sanitized_email}' LIMIT 1;");
        let mut results = self.execute(&query).await?;
        if let Some(record) = results.pop() {
            Ok(Some(self.record_to_user(record)?))
        } else {
            Ok(None)
        }
    }

    pub async fn find_user_by_id(&self, id: &Uuid) -> Result<Option<User>> {
        let query = format!("SELECT * FROM user WHERE id = 'user:{id}' LIMIT 1;");
        let mut results = self.execute(&query).await?;
        if let Some(record) = results.pop() {
            Ok(Some(self.record_to_user(record)?))
        } else {
            Ok(None)
        }
    }

    pub async fn create_payment(
        &self,
        user_id: Uuid,
        amount: f64,
        status: Option<String>,
        method: Option<String>,
        metadata: Option<Value>,
    ) -> Result<Value> {
        let now = Utc::now();
        let payload = json!({
            "user_id": format!("user:{user_id}"),
            "amount": amount,
            "status": status.unwrap_or_else(|| "pending".to_string()),
            "method": method.unwrap_or_else(|| "card".to_string()),
            "metadata": metadata,
            "created_at": now,
            "updated_at": now,
        });

        let query = format!("CREATE payment CONTENT {payload};");
        let mut results = self.execute(&query).await?;
        let mut record = results
            .pop()
            .ok_or_else(|| anyhow!("SurrealDB did not return a payment record"))?;
        Self::strip_record_id(&mut record);
        Ok(record)
    }

    pub(crate) async fn execute(&self, query: &str) -> Result<Vec<Value>> {
        let mut request = self
            .client
            .post(format!("{}/sql", self.base_url))
            .header("NS", &self.namespace)
            .header("DB", &self.database)
            .body(query.to_string());

        if let Some((user, password)) = &self.credentials {
            request = request.basic_auth(user, Some(password));
        }

        let response = request
            .send()
            .await
            .context("failed to send SurrealDB request")?
            .error_for_status()
            .context("SurrealDB returned an error")?;

        let payload = response
            .json::<Vec<Value>>()
            .await
            .context("failed to parse SurrealDB response")?;

        let mut records = Vec::new();
        for entry in payload.into_iter() {
            if let Some(array) = entry.get("result").and_then(Value::as_array) {
                records.extend(array.clone());
            }
        }

        Ok(records)
    }

    fn record_to_user(&self, mut record: Value) -> Result<User> {
        Self::strip_record_id(&mut record);
        if let Some(obj) = record.as_object_mut() {
            if let Some(role_value) = obj.get("role").and_then(Value::as_str) {
                obj.insert("role".to_string(), Value::String(role_value.to_lowercase()));
            }
        }
        let user: User = serde_json::from_value(record)?;
        Ok(user)
    }

    pub(crate) fn strip_record_id(record: &mut Value) {
        if let Some(obj) = record.as_object_mut() {
            if let Some(Value::String(id)) = obj.get("id") {
                if let Some(pos) = id.rfind(':') {
                    if let Ok(uuid) = Uuid::parse_str(&id[pos + 1..]) {
                        obj.insert("id".to_string(), Value::String(uuid.to_string()));
                    }
                }
            }
        }
    }

    fn sanitize(value: &str) -> String {
        value.replace('\'', "\\'")
    }
}
