# Migration 31 - Manual Application via Supabase Web UI

Due to database authentication issues with the Supabase CLI, apply this migration manually:

## Steps:

1. **Open Supabase SQL Editor**:
   - Go to: https://supabase.com/dashboard/project/sfgazuuopgrnkhvciawm/sql/new
   - Or: Dashboard → SQL Editor → New Query

2. **Copy and paste the entire SQL migration**:
   - File location: `supabase/migrations/31_add_subscription_tier_and_enable_documents.sql`
   - Copy ALL content (lines 1-77)

3. **Run the query**:
   - Click the "Run" button (or Cmd+Enter)
   - Wait for success message

## Verification Queries (to confirm migration applied):

Run these in the SQL editor to verify:

```sql
-- Check subscription_tier column exists
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'user_profiles'
AND column_name = 'subscription_tier';

-- Check documents bucket exists
SELECT id, name, public, file_size_limit
FROM storage.buckets
WHERE id = 'documents';

-- Check helper function exists
SELECT proname FROM pg_proc WHERE proname = 'is_user_premium';
```

## After Migration is Applied:

1. Set test users to premium (optional):
   ```sql
   UPDATE user_profiles
   SET subscription_tier = 'premium'
   WHERE email = 'your-test-email@example.com';
   ```

2. Return to terminal and verify by building/running:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

3. Test the receipt scanning feature:
   - Premium users should see "Scan Receipt" button in Add Transaction page
   - Click button → Camera/Gallery selection
   - Take/select receipt photo
   - Review extracted data (amount, merchant, date, items)
   - Confirm to auto-fill transaction form

## Troubleshooting:

- If you get "relation already exists" error: The migration has already been applied (safe to ignore)
- If permissions error: Make sure you're logged in as the project owner
- If bucket creation fails: Check that documents bucket doesn't already exist in Storage section

