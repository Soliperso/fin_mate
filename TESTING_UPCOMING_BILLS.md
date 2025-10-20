# Testing Upcoming Bills Feature

## Problem Overview

The **"Upcoming Bills"** section in the dashboard displays recurring transactions that are due within the next 30 days. Currently, this section appears empty because there are no recurring transactions in the database.

## Why It's Empty

The dashboard queries the `recurring_transactions` table looking for:
- Active recurring transactions (`is_active = true`)
- With due dates between today and 30 days from now
- Sorted by `next_occurrence` date

**The section is empty because the app currently has no UI to create recurring transactions**, even though the database infrastructure exists.

## How to Test

### Option 1: Quick Test with Sample Data (Recommended)

This is the fastest way to verify the feature works correctly.

#### Steps:

1. **Open Supabase SQL Editor**
   - Go to: `https://supabase.com/dashboard/project/YOUR_PROJECT_ID/sql/new`
   - Make sure you're viewing the correct project

2. **Run the Test Data Script**
   - Open the file: [`test_data/insert_recurring_transactions_easy.sql`](test_data/insert_recurring_transactions_easy.sql)
   - Copy the entire contents
   - Paste into the Supabase SQL Editor
   - Click **"RUN"**

3. **Verify in Database**
   - After running, you should see success messages in the Results panel
   - The script automatically uses your authenticated user ID and first active account
   - It inserts 6 sample recurring transactions:
     - Electric Bill (due tomorrow)
     - Netflix Subscription (due in 5 days)
     - Monthly Rent (due in 10 days)
     - Internet Service (due in 15 days)
     - Gym Membership (due in 20 days)
     - Spotify Premium (due in 25 days)

4. **Test in the App**
   - Open the FinMate app
   - Navigate to the Dashboard
   - Pull down to refresh
   - You should now see the **"Upcoming Bills"** section populated with the top 3 upcoming bills

5. **Expected Behavior**
   - Bills appear sorted by due date (soonest first)
   - Only the first 3 bills are shown (dashboard only shows top 3)
   - Bills due within 3 days or less show in red text
   - Each bill shows:
     - Icon with warning color
     - Description (e.g., "Electric Bill")
     - Days until due (e.g., "Due tomorrow", "Due in 5 days")
     - Amount formatted as currency

### Option 2: Manual Database Insert

If you prefer more control, you can manually insert records:

```sql
-- Replace YOUR_USER_ID and YOUR_ACCOUNT_ID with actual values
INSERT INTO public.recurring_transactions (
  user_id,
  account_id,
  category_id,
  type,
  amount,
  description,
  frequency,
  start_date,
  next_occurrence,
  is_active
) VALUES (
  'YOUR_USER_ID',
  'YOUR_ACCOUNT_ID',
  NULL,  -- Optional category
  'expense',
  50.00,
  'Test Recurring Bill',
  'monthly',
  CURRENT_DATE,
  CURRENT_DATE + INTERVAL '7 days',  -- Due in 7 days
  true
);
```

**To get your IDs:**
```sql
-- Get your user ID
SELECT id, email FROM auth.users WHERE email = 'your-email@example.com';

-- Get your account ID
SELECT id, name FROM accounts WHERE user_id = 'YOUR_USER_ID';
```

### Option 3: Test Edge Cases

After inserting sample data, test these scenarios:

1. **No Bills Due**
   - Delete all recurring transactions or set `next_occurrence` to more than 30 days in the future
   - Dashboard should show "No upcoming bills" message with a green checkmark icon

2. **Bills Due Today**
   - Set `next_occurrence` to `CURRENT_DATE`
   - Bill should display "Due today" in the subtitle

3. **Urgent Bills (≤3 days)**
   - Bills due within 3 days should show with red text
   - Test with bills due in 1, 2, and 3 days

4. **Many Bills**
   - Insert more than 3 bills
   - Dashboard should only show the first 3 (sorted by due date)
   - "View All" button should navigate to `/bills` page

## Implementation Status

### ✅ What's Working
- Database table `recurring_transactions` exists and is properly configured
- Dashboard query logic correctly fetches upcoming bills
- UI widget properly displays bills with proper formatting
- Empty state with friendly message
- Proper date formatting and urgency indicators

### ❌ What's Missing
- **No UI to create recurring transactions** - Users can't add bills through the app
- **No UI to edit recurring transactions** - Users can't modify existing bills
- **No UI to delete recurring transactions** - Users can't remove bills
- **No recurring transactions page** - The "View All" button goes to the bills (bill splitting) page, not recurring transactions

## Code References

### Key Files
- **Dashboard Repository**: [lib/features/dashboard/data/repositories/dashboard_repository_impl.dart:163-198](lib/features/dashboard/data/repositories/dashboard_repository_impl.dart#L163-L198)
  - `_getUpcomingBills()` method queries the database

- **Dashboard Stats Entity**: [lib/features/dashboard/domain/entities/dashboard_stats.dart:91-114](lib/features/dashboard/domain/entities/dashboard_stats.dart#L91-L114)
  - `UpcomingBill` entity definition

- **Upcoming Bills Card Widget**: [lib/features/dashboard/presentation/widgets/upcoming_bills_card.dart](lib/features/dashboard/presentation/widgets/upcoming_bills_card.dart)
  - UI component that displays the bills

- **Database Schema**: [supabase/migrations/00_create_core_schema.sql:197-238](supabase/migrations/00_create_core_schema.sql#L197-L238)
  - `recurring_transactions` table definition

### Query Logic
The dashboard fetches bills using this query:
```dart
final response = await _supabase
    .from('recurring_transactions')
    .select('''
      id,
      description,
      amount,
      next_occurrence,
      category_id,
      categories(name)
    ''')
    .eq('is_active', true)
    .gte('next_occurrence', now.toIso8601String().split('T')[0])
    .lte('next_occurrence', thirtyDaysFromNow.toIso8601String().split('T')[0])
    .order('next_occurrence')
    .limit(limit);
```

## Next Steps: Full Implementation

To fully implement recurring transactions management, you would need to:

### 1. Create Recurring Transactions Feature Module
```
lib/features/recurring_transactions/
├── data/
│   ├── datasources/
│   │   └── recurring_transactions_remote_datasource.dart
│   ├── models/
│   │   └── recurring_transaction_model.dart
│   └── repositories/
│       └── recurring_transactions_repository_impl.dart
├── domain/
│   ├── entities/
│   │   └── recurring_transaction_entity.dart
│   └── repositories/
│       └── recurring_transactions_repository.dart
└── presentation/
    ├── pages/
    │   └── recurring_transactions_page.dart
    ├── widgets/
    │   ├── add_recurring_transaction_bottom_sheet.dart
    │   └── edit_recurring_transaction_bottom_sheet.dart
    └── providers/
        └── recurring_transactions_providers.dart
```

### 2. Add Navigation Routes
Update [lib/core/config/router.dart](lib/core/config/router.dart):
```dart
GoRoute(
  path: '/recurring-transactions',
  builder: (context, state) => const RecurringTransactionsPage(),
),
GoRoute(
  path: '/recurring-transactions/add',
  builder: (context, state) => const AddRecurringTransactionPage(),
),
```

### 3. Update "View All" Button
In [upcoming_bills_card.dart:34](lib/features/dashboard/presentation/widgets/upcoming_bills_card.dart#L34):
```dart
TextButton(
  onPressed: () {
    context.go('/recurring-transactions');  // Instead of '/bills'
  },
  child: const Text('View All'),
),
```

### 4. Add Quick Action (Optional)
Add a quick action button on the dashboard for creating recurring bills.

### 5. Implement Automatic Transaction Creation
Create a background service or scheduled function that:
- Checks for recurring transactions where `next_occurrence` is today or past
- Creates actual transactions in the `transactions` table
- Updates `next_occurrence` based on frequency (daily, weekly, monthly, yearly)

## Cleanup

After testing, you can remove the test data:

```sql
-- Delete all test recurring transactions
DELETE FROM recurring_transactions
WHERE user_id = auth.uid()
  AND description IN (
    'Netflix Subscription',
    'Monthly Rent',
    'Electric Bill',
    'Internet Service',
    'Gym Membership',
    'Spotify Premium'
  );
```

## Troubleshooting

### "No upcoming bills" still showing
- Verify the data was inserted: Run the verification query in the SQL script
- Check that `is_active = true` on the records
- Ensure `next_occurrence` is between today and 30 days from now
- Try pulling down to refresh the dashboard
- Check Supabase logs for any RLS policy errors

### Query returns data but UI is empty
- Check browser/app console for errors
- Verify the user is authenticated
- Check Row Level Security policies on the `recurring_transactions` table

### Categories not found
- The script tries to use default categories (Entertainment, Housing, etc.)
- If these don't exist, the `category_id` will be NULL (which is fine for testing)
- You can manually add categories or use NULL for testing

## Summary

The "Upcoming Bills" feature is **fully functional** at the database and dashboard display level, but there's **no way for users to create recurring transactions** through the app UI.

Use the provided SQL scripts in the `test_data/` directory to quickly test the feature with sample data.
