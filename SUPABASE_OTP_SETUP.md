# Supabase OTP Email Verification Setup

To enable OTP (One-Time Password) email verification instead of email confirmation links, you need to configure your Supabase project settings.

## Steps to Enable OTP in Supabase Dashboard

1. **Go to Supabase Dashboard**
   - Navigate to https://supabase.com/dashboard
   - Select your project

2. **Navigate to Authentication Settings**
   - Click on "Authentication" in the left sidebar
   - Click on "Email Templates"

3. **Configure Email OTP Settings**
   - Go to "Authentication" → "Providers"
   - Find "Email" provider
   - Make sure "Enable Email provider" is toggled ON
   - Under "Email Settings":
     - **Confirm email**: You can toggle this OFF if you want users to verify via OTP only
     - **Secure email change**: Keep this ON for security

4. **Email Template Configuration** (Optional)
   - Go to "Authentication" → "Email Templates"
   - Customize the "Confirm signup" template if needed
   - The OTP code is available as `{{ .Token }}` in the template

## Alternative: Use Magic Link OTP

If the above doesn't work, Supabase also supports "Magic Link" which is similar to OTP:

1. In your Supabase dashboard:
   - Go to "Authentication" → "Settings"
   - Enable "Email OTP"

## Testing OTP

After configuration:

1. Try signing up with a new email
2. You should receive an email with a 6-digit code
3. Enter the code in the FinMate verification screen
4. User should be verified and logged in

## Troubleshooting

If you're still getting errors:

1. **Check Email Service**: Make sure Supabase email service is working
   - Test by sending a password reset email

2. **Check SMTP Configuration**:
   - By default, Supabase uses their SMTP
   - For production, you may want to configure custom SMTP

3. **Check Error Logs**:
   - In Supabase Dashboard → Logs → Auth Logs
   - Look for signup/OTP errors

4. **Verify Database Trigger**:
   - Make sure the `user_profiles` trigger is working
   - Check if profiles are being created on signup

## Current Implementation

The app is configured to:
- Send OTP on signup
- Force email verification before login
- Allow resending OTP if not received
- Auto-verify when all 6 digits are entered

## If OTP is Not Available in Your Supabase Plan

If your Supabase plan doesn't support OTP, you can:

1. Use the email confirmation link (we can add a custom redirect URL)
2. Upgrade to a plan that supports OTP
3. Implement a custom OTP system with your own email service
