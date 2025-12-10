use anyhow::Result;
use hmac::{Hmac, Mac};
use sha2::Sha256;

type HmacSha256 = Hmac<Sha256>;

/// Verify Stripe webhook signature
/// Implements: https://stripe.com/docs/webhooks/signatures
pub fn verify_signature(payload: &str, signature: &str, secret: &str) -> Result<bool> {
    // Parse signature header
    // Format: t=timestamp,v1=signature
    let mut timestamp: Option<&str> = None;
    let mut signature_value: Option<&str> = None;

    for part in signature.split(',') {
        let mut kv = part.split('=');
        let key = kv.next().unwrap_or("");
        let value = kv.next().unwrap_or("");

        match key {
            "t" => timestamp = Some(value),
            "v1" => signature_value = Some(value),
            _ => {}
        }
    }

    let timestamp = timestamp.ok_or_else(|| anyhow::anyhow!("Missing timestamp in signature"))?;
    let expected_sig = signature_value.ok_or_else(|| anyhow::anyhow!("Missing v1 in signature"))?;

    // Construct signed payload
    let signed_payload = format!("{}.{}", timestamp, payload);

    // Compute HMAC
    let mut mac = HmacSha256::new_from_slice(secret.as_bytes())?;
    mac.update(signed_payload.as_bytes());
    let result = mac.finalize();
    let computed_sig = hex::encode(result.into_bytes());

    // Compare signatures (constant time comparison)
    Ok(computed_sig == expected_sig)
}
