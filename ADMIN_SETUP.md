# Admin Role Setup Guide

## Overview
The admin role system allows certain users to have elevated privileges in FinMate. For security reasons, admin roles can **ONLY be assigned via direct database access**, not through the app UI.

## Migration Setup

### Step 1: Run the Migration
The migration file has been created at: `supabase/migrations/10_add_admin_role.sql`

Run it in one of two ways:

#### Option A: Via Supabase CLI (if linked)
```bash
supabase db push
```

#### Option B: Via Supabase SQL Editor (recommended)
1. Go to: https://supabase.com/dashboard/project/sfgazuuopgrnkhvciawm/sql/new
2. Open `supabase/migrations/10_add_admin_role.sql`
3. Copy the entire contents
4. Paste into the SQL Editor
5. Click **RUN**

## Assigning Admin Role

### Set Yourself as Admin

After running the migration, execute this SQL query in the Supabase SQL Editor:

```sql
-- Replace 'your-email@example.com' with your actual email
UPDATE public.user_profiles
SET role = 'admin'
WHERE email = 'your-email@example.com';
```

### Verify Admin Assignment

Check if the role was assigned correctly:

```sql
-- View all admin users
SELECT id, email, full_name, role, created_at
FROM public.user_profiles
WHERE role = 'admin';
```

## Using Admin Role in the App

### In Code

#### Check if current user is admin:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fin_mate/core/guards/admin_guard.dart';

// Using the provider
final isAdmin = ref.watch(isAdminProvider);

// Using the guard utility
final isAdmin = AdminGuard.isAdmin(ref);
```

#### Get admin profile:
```dart
final adminProfile = AdminGuard.getAdminProfile(ref);
if (adminProfile != null) {
  // User is admin, show admin features
}
```

#### Protect routes (in router.dart):
```dart
redirect: (context, state) {
  final isAdmin = ref.read(isAdminProvider);

  if (state.matchedLocation.startsWith('/admin') && !isAdmin) {
    return '/dashboard'; // Redirect non-admins
  }

  return null;
}
```

#### Show/hide UI elements:
```dart
Consumer(
  builder: (context, ref, child) {
    final isAdmin = ref.watch(isAdminProvider);

    if (!isAdmin) return const SizedBox.shrink();

    return ElevatedButton(
      onPressed: () => context.push('/admin/users'),
      child: const Text('Admin Panel'),
    );
  },
)
```

### Profile Entity

The `ProfileEntity` now includes:
- `role` field (String: 'user' or 'admin')
- `isAdmin` getter (bool)

```dart
final profile = ref.watch(profileProvider);
profile.when(
  data: (profile) {
    if (profile.isAdmin) {
      // Show admin features
    }
  },
  loading: () => const CircularProgressIndicator(),
  error: (e, _) => Text('Error: $e'),
);
```

## Security Notes

⚠️ **IMPORTANT SECURITY PRACTICES:**

1. **Never expose role modification in the UI** - No dropdowns, switches, or forms should allow role changes
2. **RLS policies remain unchanged** - Standard users cannot modify the role field
3. **Only database admins** can assign admin roles via SQL queries
4. **Audit admin actions** - Consider adding logging for admin-specific operations
5. **Keep admin emails private** - Don't expose admin status in public APIs

## Database Helper Function

A helper function is available in the database:

```sql
-- Check if current authenticated user is admin
SELECT is_admin();
```

Use this in RLS policies if you need admin-only access to certain tables:

```sql
CREATE POLICY "Admins can view all data" ON some_table
  FOR SELECT USING (is_admin() = TRUE);
```

## Troubleshooting

### Role not updating in app after SQL change
- Log out and log back in
- The profile is cached, so you need to refresh the session

### Cannot find profile provider
- Make sure you've imported: `import 'package:fin_mate/features/profile/presentation/providers/profile_providers.dart';`

### Migration fails
- Check if the `role` column already exists: `SELECT column_name FROM information_schema.columns WHERE table_name = 'user_profiles';`
- If it exists, the migration will skip creating it due to `IF NOT EXISTS`

## Future Admin Features (Ideas)

Once admin role is set up, you could add:
- User management dashboard (view all users, analytics)
- System-wide notifications
- Feature flags or A/B testing
- Support ticket system
- Manual transaction approval/review
- Bulk data operations
- Export user data for GDPR compliance

---

**Remember:** Admin privileges should be granted sparingly and only to trusted individuals with legitimate need for elevated access.
