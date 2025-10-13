# 🚨 IMPORTANT: Run Database Migration NOW

## You haven't run the migration yet!

The `role` column doesn't exist in your database yet. That's why you don't see the admin badge.

---

## Step-by-Step Guide (Takes 2 minutes)

### Step 1: Open Supabase SQL Editor

Click this link: **https://supabase.com/dashboard/project/sfgazuuopgrnkhvciawm/sql/new**

### Step 2: Copy the Migration SQL

Open this file: `supabase/migrations/10_add_admin_role.sql`

Copy **ALL** the contents (lines 1-51)

### Step 3: Paste and Run

1. Paste the SQL into the Supabase SQL Editor
2. Click the green **RUN** button (bottom right)
3. You should see: "Success. No rows returned"

### Step 4: Set Yourself as Admin

In the same SQL editor, run this query (replace with YOUR email):

```sql
UPDATE public.user_profiles
SET role = 'admin'
WHERE email = 'your-actual-email@example.com';
```

Click **RUN** again.

You should see: "Success. 1 row affected"

### Step 5: Verify It Worked

Run this query to check:

```sql
SELECT email, role, full_name
FROM public.user_profiles
WHERE role = 'admin';
```

You should see your email with role = 'admin'

---

## Step 6: Refresh the App

1. Pull down to refresh on the Profile page, OR
2. Log out and log back in
3. Navigate to Profile page
4. You should now see:
   - ✨ Admin badge under your email
   - ✨ Admin section in settings

---

## Need Help?

If you see any errors in the SQL editor, paste them and I'll help you fix them.

The most common issue is the column already existing (which is fine - the migration handles that).
