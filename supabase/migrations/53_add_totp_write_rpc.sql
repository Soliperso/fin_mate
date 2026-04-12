-- Migration 53: Add RPC for writing encrypted TOTP secrets
-- Pairs with migration 51 (encrypted column) and the read RPC get_totp_secret_for_user.

-- Create a secure RPC to write a TOTP secret without storing it as plain text.
-- The caller passes the plain-text secret; the function encrypts it server-side.
-- Key is read from Supabase Vault (vault.decrypted_secrets).
CREATE OR REPLACE FUNCTION set_totp_secret_for_user(p_secret TEXT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_key TEXT;
BEGIN
  SELECT decrypted_secret INTO v_key
  FROM vault.decrypted_secrets
  WHERE name = 'totp_encryption_key'
  LIMIT 1;

  IF v_key IS NULL THEN
    RAISE EXCEPTION 'Encryption key not configured';
  END IF;

  UPDATE user_profiles
  SET
    totp_secret = NULL,                          -- clear any plain-text remnant
    totp_secret_encrypted = extensions.pgp_sym_encrypt(p_secret, v_key)
  WHERE id = auth.uid();
END;
$$;

-- Restrict execute to authenticated users only
REVOKE ALL ON FUNCTION set_totp_secret_for_user(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION set_totp_secret_for_user(TEXT) TO authenticated;
