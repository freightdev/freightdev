use acme_lib::{create_p384_key, persist::FilePersist, Directory, DirectoryUrl};
use anyhow::{anyhow, Result};
use rcgen::{Certificate, CertificateParams, DistinguishedName};
use std::path::{Path, PathBuf};
use tokio::fs;
use tracing::{error, info};

pub struct AcmeManager {
    email: String,
    cert_dir: PathBuf,
}

impl AcmeManager {
    pub fn new(email: String, cert_dir: impl AsRef<Path>) -> Self {
        Self {
            email,
            cert_dir: cert_dir.as_ref().to_path_buf(),
        }
    }

    pub async fn get_or_create_certificate(&self, domain: &str) -> Result<(Vec<u8>, Vec<u8>)> {
        let cert_path = self.cert_dir.join(format!("{}.crt", domain));
        let key_path = self.cert_dir.join(format!("{}.key", domain));

        if cert_path.exists() && key_path.exists() {
            info!("Loading existing certificate for {}", domain);
            let cert = fs::read(&cert_path).await?;
            let key = fs::read(&key_path).await?;
            return Ok((cert, key));
        }

        info!("Requesting new certificate from Let's Encrypt for {}", domain);
        self.request_certificate(domain).await
    }

    async fn request_certificate(&self, domain: &str) -> Result<(Vec<u8>, Vec<u8>)> {
        fs::create_dir_all(&self.cert_dir).await?;

        let persist = FilePersist::new(&self.cert_dir);
        let dir = Directory::from_url(persist, DirectoryUrl::LetsEncrypt)?;

        let acc = dir.account(&self.email)?;

        let mut ord_new = acc.new_order(domain, &[])?;

        let ord_csr = loop {
            if let Some(ord_csr) = ord_new.confirm_validations() {
                break ord_csr;
            }

            let auths = ord_new.authorizations()?;
            for auth in auths {
                let challenge = auth.http_challenge();

                let token = challenge.http_token();
                let proof = challenge.http_proof();

                let challenge_path = self
                    .cert_dir
                    .join(".well-known")
                    .join("acme-challenge")
                    .join(&token);

                fs::create_dir_all(challenge_path.parent().unwrap()).await?;
                fs::write(&challenge_path, proof.as_bytes()).await?;

                info!(
                    "ACME challenge file created at {:?} for {}",
                    challenge_path, domain
                );

                challenge.validate(5000)?;

                fs::remove_file(&challenge_path).await.ok();
            }

            ord_new.refresh()?;
        };

        let pkey = create_p384_key();
        let ord_cert = ord_csr.finalize_pkey(pkey, 5000)?;
        let cert_pem = ord_cert.download_and_save_cert()?;

        info!("Certificate for {} acquired from Let's Encrypt", domain);

        let cert_path = self.cert_dir.join(format!("{}.crt", domain));
        let key_path = self.cert_dir.join(format!("{}.key", domain));

        let cert_bytes = fs::read(&cert_path).await?;
        let key_bytes = fs::read(&key_path).await?;

        Ok((cert_bytes, key_bytes))
    }

    pub async fn renew_certificate(&self, domain: &str) -> Result<()> {
        info!("Renewing certificate for {}", domain);
        let (cert, key) = self.request_certificate(domain).await?;

        let cert_path = self.cert_dir.join(format!("{}.crt", domain));
        let key_path = self.cert_dir.join(format!("{}.key", domain));

        fs::write(&cert_path, cert).await?;
        fs::write(&key_path, key).await?;

        Ok(())
    }

    pub fn generate_self_signed(domain: &str) -> Result<(Vec<u8>, Vec<u8>)> {
        let mut params = CertificateParams::new(vec![domain.to_string()])?;
        params.distinguished_name.push(rcgen::DnType::CommonName, rcgen::DnValue::Utf8String(domain.to_string()));

        let key_pair = rcgen::KeyPair::generate()?;
        let cert = params.self_signed(&key_pair)?;
        let cert_pem = cert.pem();
        let key_pem = key_pair.serialize_pem();

        Ok((cert_pem.into_bytes(), key_pem.into_bytes()))
    }
}
