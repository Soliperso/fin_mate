# Check if Migration Was Run Successfully

## Quick Test in Supabase

Go to: https://supabase.com/dashboard/project/sfgazuuopgrnkhvciawm/sql/new

Run this query to test if the functions exist:

```sql
-- Test 1: Check if admin functions exist
SELECT routine_name
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name IN ('get_all_users_with_stats', 'get_system_stats', 'get_user_details_admin', 'is_admin');
```

**Expected result:** You should see 4 rows with these function names.

---

## If Functions Don't Exist

Run the migration again:

1. Copy **ALL** contents of `supabase/migrations/11_add_admin_functions.sql`
2. Paste in SQL Editor
3. Click RUN

---

## Test the Admin Function Directly

After running migration, test if it works:

```sql
-- This should return your user info with stats
SELECT * FROM get_all_users_with_stats(10, 0, NULL);
```

**Expected result:** You should see your user info with transaction counts and net worth.

---

## Test System Stats

```sql
SELECT * FROM get_system_stats();
```

**Expected result:** One row with system-wide statistics.

---

## Common Issues

### Issue 1: "Function does not exist"
- Migration wasn't run
- Solution: Run the migration SQL

### Issue 2: "Access denied. Admin privileges required"
- Your role is not 'admin' in database
- Solution: Run this:
```sql
UPDATE public.user_profiles SET role = 'admin' WHERE email = 'chah762002@yahoo.fr';
```

### Issue 3: "is_admin function does not exist"
- Migration 10 wasn't run first
- Solution: Run `supabase/migrations/10_add_admin_role.sql` first, then run migration 11

---

## Verify Your Admin Role

```sql
SELECT id, email, full_name, role, created_at
FROM public.user_profiles
WHERE email = 'chah762002@yahoo.fr';
```

**Expected result:** role = 'admin'

---

After confirming these work in SQL, the app should work properly!
