-- ============================================================================
-- FIX SECURITY WARNINGS
-- ============================================================================

-- Fix search_path for all functions to prevent injection attacks
ALTER FUNCTION update_account_balance() SET search_path = public, pg_temp;
ALTER FUNCTION initialize_user_financial_data() SET search_path = public, pg_temp;
ALTER FUNCTION get_total_by_type(DATE, DATE, TEXT) SET search_path = public, pg_temp;
ALTER FUNCTION calculate_money_health_score() SET search_path = public, pg_temp;

-- Enable password protection (Leaked Password Protection)
-- This needs to be done in Supabase Dashboard:
-- Go to Authentication > Settings > Enable "Leaked Password Protection"

-- The "Insufficient MFA Options" warning is already addressed since we have:
-- 1. Email OTP (via Supabase Auth)
-- 2. TOTP (implemented in the app with mfa_enabled and totp_secret columns)
