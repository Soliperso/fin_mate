-- Migration 51: Encrypt existing TOTP secrets using pgcrypto
-- Requires the pgcrypto extension (enabled by default on Supabase).
-- TOTP secrets are encrypted with a symmetric key stored in Supabase Vault.
-- If Vault is not configured, set the TOTP_ENCRYPTION_KEY env var instead.

-- Enable pgcrypto if not already enabled
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Add encrypted column alongside existing plain-text column
ALTER TABLE user_profiles
  ADD COLUMN IF NOT EXISTS totp_secret_encrypted TEXT;

-- Encrypt all existing plain-text TOTP secrets.
-- Replace 'your-encryption-key' with the value from your Supabase Vault secret
-- named 'totp_encryption_key', or set it via supabase secrets set TOTP_ENCRYPTION_KEY=...
UPDATE user_profiles
SET totp_secret_encrypted = extensions.pgp_sym_encrypt(
      totp_secret,
      (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'totp_encryption_key' LIMIT 1)
    )
WHERE totp_secret IS NOT NULL
  AND totp_secret_encrypted IS NULL;

-- Once all rows are migrated, drop the plain-text column
-- NOTE: Only run this after verifying the encrypted column is populated correctly.
-- ALTER TABLE user_profiles DROP COLUMN totp_secret;
-- ALTER TABLE user_profiles RENAME COLUMN totp_secret_encrypted TO totp_secret;

-- Create a secure RPC to retrieve a decrypted TOTP secret for the calling user.
-- Key is read from Supabase Vault (vault.decrypted_secrets).
CREATE OR REPLACE FUNCTION get_totp_secret_for_user(p_user_id UUID)
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_encrypted TEXT;
  v_key TEXT;
BEGIN
  -- Only the owning user can retrieve their own secret
  IF auth.uid() != p_user_id THEN
    RAISE EXCEPTION 'Access denied';
  END IF;

  SELECT totp_secret_encrypted INTO v_encrypted
  FROM user_profiles
  WHERE id = p_user_id;

  IF v_encrypted IS NULL THEN
    RETURN NULL;
  END IF;

  SELECT decrypted_secret INTO v_key
  FROM vault.decrypted_secrets
  WHERE name = 'totp_encryption_key'
  LIMIT 1;

  IF v_key IS NULL THEN
    RAISE EXCEPTION 'Encryption key not configured';
  END IF;

  RETURN extensions.pgp_sym_decrypt(v_encrypted::bytea, v_key);
END;
$$;
