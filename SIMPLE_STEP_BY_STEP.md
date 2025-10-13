# Step-by-Step Migration Guide

## The Problem
Your app shows: "Could not find the table public.bill_groups"

This means the database tables don't exist yet.

## Solution - Do This Exactly:

### Step 1: Open Supabase SQL Editor
1. Go to: https://supabase.com/dashboard/project/sfgazuuopgrnkhvciawm/sql/new
2. You should see a blank SQL editor

### Step 2: Check What Already Exists (Optional)
Paste this and click RUN to see if tables already exist:
```sql
SELECT tablename FROM pg_tables
WHERE schemaname = 'public'
AND tablename LIKE '%group%' OR tablename LIKE '%goal%';
```

If you see tables already, we need to delete them first (see troubleshooting below).

### Step 3: Run the Migration
1. Open the file: `supabase/migrations/FIXED_MIGRATION.sql`
2. Select ALL (Cmd+A)
3. Copy (Cmd+C)
4. Go back to Supabase SQL Editor
5. Paste (Cmd+V)
6. Click the **RUN** button (or press Cmd+Enter)
7. Wait 3-5 seconds

### Step 4: Verify Success
You should see one of these messages:
- ✅ "Success. No rows returned" - **THIS IS GOOD!**
- ✅ "Success" with some output - **THIS IS GOOD!**
- ❌ Any error message - **TELL ME THE ERROR**

### Step 5: Restart Your App
1. In your terminal running Flutter, press `R` (capital R for full restart)
2. Or stop and run `flutter run` again

---

## Troubleshooting

### If you see "relation already exists" error:

This means tables were partially created. Run this FIRST to clean up:

```sql
-- Drop all bill splitting tables
DROP TABLE IF EXISTS public.expense_splits CASCADE;
DROP TABLE IF EXISTS public.group_expenses CASCADE;
DROP TABLE IF EXISTS public.settlements CASCADE;
DROP TABLE IF EXISTS public.group_members CASCADE;
DROP TABLE IF EXISTS public.bill_groups CASCADE;

-- Drop all savings goals tables
DROP TABLE IF EXISTS public.goal_contributions CASCADE;
DROP TABLE IF EXISTS public.savings_goals CASCADE;

-- Drop functions
DROP FUNCTION IF EXISTS add_creator_as_admin() CASCADE;
DROP FUNCTION IF EXISTS create_equal_splits() CASCADE;
DROP FUNCTION IF EXISTS get_group_balances(UUID) CASCADE;
DROP FUNCTION IF EXISTS update_goal_amount_on_contribution() CASCADE;
DROP FUNCTION IF EXISTS get_goal_progress(UUID) CASCADE;
DROP FUNCTION IF EXISTS get_goals_summary() CASCADE;
```

After running the cleanup above, go back to Step 3 and run the FIXED_MIGRATION.sql again.

### If you see "permission denied" error:

You might not be logged in properly. Make sure you're logged into Supabase with the account that owns this project.

### If you see "syntax error" at specific line:

Copy only a small portion at a time:
1. First copy just the table creation (lines 1-135)
2. Then copy the RLS policies (lines 137-340)
3. Then copy the functions (lines 342-545)

---

## What Tables Should Exist After Success

Run this to verify:
```sql
SELECT tablename FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;
```

You should see:
- bill_groups
- group_members
- group_expenses
- expense_splits
- settlements
- savings_goals
- goal_contributions

Plus your existing tables (accounts, budgets, transactions, etc.)
