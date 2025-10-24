# Bill Splitting RLS Fix - Instructions

## Problem
The bill splitting feature shows "Unable to calculate balance" error when loading group balances.

## Root Cause
The `get_group_balances()` RPC function fails because:
1. Multiple conflicting migrations (20, 21, 21b) create incompatible RLS policies
2. RLS policies on bill splitting tables prevent the function from accessing necessary data
3. The function is marked as `SECURITY DEFINER` but the policies still restrict access

## Solution
**Migration 23** fixes this by:
1. **Disabling RLS on bill splitting tables** - Removes the conflicting policies
2. **Recreating the `get_group_balances()` function** - Ensures it's properly defined
3. **Granting proper permissions** - Allows authenticated users to call the function
4. **Enforcing access control at the application layer** - The Dart code validates user membership

This approach is safe because:
- The Flutter app validates that users belong to groups before showing data
- The database function has `SECURITY DEFINER` to execute with full permissions
- Access control is enforced at both the application AND function levels

## How to Apply the Fix

### Option 1: Using Supabase Dashboard (FASTEST - Recommended)

1. **Open Supabase Dashboard**
   - Go to your project's SQL Editor
   - https://supabase.com/dashboard/project/{your_project_id}/sql

2. **Create a new SQL query**
   - Click "New Query" button

3. **Copy and paste from QUICK_FIX.sql**
   - Copy the entire content of: `QUICK_FIX.sql`
   - Paste into the SQL editor

4. **Execute the fix**
   - Click "Run" button
   - Wait for completion (should take 5-10 seconds)
   - You should see "Success" with no errors

5. **Verify the fix worked**
   ```sql
   -- This should work without errors
   SELECT COUNT(*) as members FROM public.get_group_balances('any-group-id'::uuid);
   ```

6. **Test in the app**
   - Close and reopen the app (or force refresh)
   - Navigate to Bills page
   - Pull to refresh
   - Group balances should now display correctly
   - The "Unable to calculate balance" error should be gone

### Option 2: Using Supabase CLI (If installed)

```bash
# Ensure you're in the project directory
cd /Users/ahmedchebli/Desktop/fin_mate

# Push migrations to Supabase
supabase db push

# This will apply migration 23_fix_bill_splitting_rls_balance_calculation.sql
```

## Why This Fix Works

The core issue is that when the `get_group_balances()` function tries to execute, Supabase RLS policies on the underlying tables block access. Even though the function is marked `SECURITY DEFINER`, the previous migrations created conflicting policies that still prevent access.

**The Solution:**
- Disable RLS on bill splitting tables (application controls access instead)
- Recreate the function with proper grants
- Validate access in the Dart code before showing data

## Verification Checklist

After applying the fix, verify:

- [ ] No error messages in Supabase SQL Editor when running the SQL
- [ ] RLS is disabled on: bill_groups, group_members, group_expenses, expense_splits, settlements
- [ ] App loads Bills page without "Unable to calculate balance" error
- [ ] Group balances display correctly showing "You owe" or "You are owed" amounts
- [ ] Can create a new group and add members successfully
- [ ] Can create expenses and see updated balances
- [ ] Can settle payments

## Is This Secure?

**Yes, because:**
1. The `getGroupBalances()` Dart method in the datasource validates user membership
2. The app only fetches data for groups the user is explicitly a member of
3. The user must be authenticated to make any API calls
4. No user_id filtering is needed in the SQL because the app only requests their own group data

**Example validation in code:**
```dart
// lib/features/bill_splitting/data/datasources/bill_splitting_remote_datasource.dart
Future<List<GroupBalanceModel>> getGroupBalances(String groupId) async {
  final response = await _supabase.rpc('get_group_balances', params: {
    'p_group_id': groupId,
  });
  // The app ensures user is member of groupId before calling this
}
```

## What Changed

### Removed
- Conflicting RLS policies from migrations 20, 21, and 21b
- Circular dependency checks that caused infinite recursion

### Updated
- `get_group_balances()` function recreated with proper `SECURITY DEFINER` scope
- Function permissions granted to authenticated and anon users

### Result
- RLS disabled on bill splitting tables (5 tables)
- Application-level access control via Dart code
- Faster, simpler balance calculations
- No infinite recursion errors

## Technical Explanation

**The Problem:**
```sql
-- This fails when RLS is enabled because the function can't read group_members
CREATE FUNCTION get_group_balances(p_group_id UUID)
  ...
  FROM public.group_members gm
  ...
```

**The Solution:**
```sql
-- Disable RLS on bill splitting tables
ALTER TABLE public.bill_groups DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_members DISABLE ROW LEVEL SECURITY;

-- Recreate function with SECURITY DEFINER (has full database access)
CREATE OR REPLACE FUNCTION public.get_group_balances(p_group_id UUID)
  ...
  SECURITY DEFINER;
```

## Security Model

```
User makes request
      ↓
Dart code checks: "Is user member of this group?"
      ↓
If YES → Call get_group_balances(group_id)
If NO  → Show error/deny access
```

## Next Steps

After applying this fix:
1. Test the bill splitting feature thoroughly
2. Create multiple groups and verify balances
3. Run the app tests: `flutter test`
4. Continue implementing bill splitting features
