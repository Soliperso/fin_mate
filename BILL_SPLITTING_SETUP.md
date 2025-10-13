# Bill Splitting Database Setup

## The Bill Splitting feature requires database tables to be created

If you see an error like "Database Setup Required" when accessing the Bill Splitting screen, you need to run the database migration.

---

## Quick Setup (2 minutes)

### Step 1: Open Supabase SQL Editor

Go to: https://supabase.com/dashboard/project/sfgazuuopgrnkhvciawm/sql/new

### Step 2: Copy the Migration SQL

1. Open the file: `supabase/migrations/09_create_bill_splitting_and_savings_goals.sql`
2. Copy **ALL** the contents (lines 1-545)

### Step 3: Run the Migration

1. Paste the SQL into the Supabase SQL Editor
2. Click the green **RUN** button (bottom right)
3. Wait for it to complete (should take 10-20 seconds)
4. You should see: "Success. No rows returned"

### Step 4: Verify It Worked

Run this query in the SQL editor:

```sql
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name IN (
  'bill_groups',
  'group_members',
  'group_expenses',
  'expense_splits',
  'settlements'
)
ORDER BY table_name;
```

You should see all 5 tables listed.

### Step 5: Test the Feature

1. Refresh your app (pull down on the Bills page, or hot reload)
2. You should now see the "No Groups Yet" empty state instead of an error
3. Try creating a new group!

---

## What This Migration Creates

### Tables:
- **bill_groups** - Group information and settings
- **group_members** - Members in each group with roles (admin/member)
- **group_expenses** - Expenses to be split among group members
- **expense_splits** - Individual split amounts for each member
- **settlements** - Payment records between members
- **savings_goals** - Personal savings goals (bonus feature)
- **goal_contributions** - Contributions to savings goals (bonus feature)

### Functions:
- **get_group_balances()** - Calculates who owes what in each group
- **add_creator_as_admin()** - Automatically adds group creator as admin
- **create_equal_splits()** - Automatically splits expenses equally

### Security:
- Row Level Security (RLS) enabled on all tables
- Users can only see groups they're members of
- Only group admins can add/remove members
- Only expense creators can edit/delete their expenses

---

## Troubleshooting

### Error: "relation already exists"
This means some tables are already created. The migration uses `CREATE TABLE IF NOT EXISTS`, so it's safe to run again.

### Error: "permission denied"
Make sure you're logged into the correct Supabase project and have admin access.

### Error: "function does not exist"
The migration creates all functions. Make sure you ran the complete migration file, not just part of it.

### Still seeing errors after migration?
1. Try refreshing the app (pull down on Bills page)
2. Log out and log back in
3. Hot reload the Flutter app: Press 'r' in the terminal

---

## Need Help?

If you encounter any errors, please share:
1. The exact error message from Supabase SQL editor
2. Which step you're on
3. A screenshot if possible
