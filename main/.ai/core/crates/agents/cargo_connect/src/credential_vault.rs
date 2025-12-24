// Credential Vault - Your passwords, encrypted and safe
// Never stored in plaintext. Ever.

use anyhow::Result;
use aes_gcm::{
    aead::{Aead, KeyInit},
    Aes256Gcm, Nonce,
};
use sha2::{Sha256, Digest};

pub struct CredentialVault {
    cipher: Aes256Gcm,
}

impl CredentialVault {
    pub fn new() -> Result<Self> {
        // In production, load key from secure storage
        let vault_key = std::env::var("VAULT_KEY")
            .unwrap_or_else(|_| "development-key-change-in-production-32bytes!!".to_string());
        
        let key = Self::derive_key(&vault_key);
        let cipher = Aes256Gcm::new(&key.into());
        
        Ok(Self { cipher })
    }
    
    pub fn encrypt(&self, plaintext: &str) -> Result<Vec<u8>> {
        let nonce = Nonce::from_slice(b"unique nonce"); // In production: random nonce per encryption
        
        let ciphertext = self.cipher
            .encrypt(nonce, plaintext.as_bytes())
            .map_err(|e| anyhow::anyhow!("Encryption failed: {}", e))?;
        
        Ok(ciphertext)
    }
    
    pub fn decrypt(&self, ciphertext: &[u8]) -> Result<String> {
        let nonce = Nonce::from_slice(b"unique nonce");
        
        let plaintext = self.cipher
            .decrypt(nonce, ciphertext)
            .map_err(|e| anyhow::anyhow!("Decryption failed: {}", e))?;
        
        Ok(String::from_utf8(plaintext)?)
    }
    
    fn derive_key(password: &str) -> [u8; 32] {
        let mut hasher = Sha256::new();
        hasher.update(password.as_bytes());
        let result = hasher.finalize();
        
        let mut key = [0u8; 32];
        key.copy_from_slice(&result);
        key
    }
}
