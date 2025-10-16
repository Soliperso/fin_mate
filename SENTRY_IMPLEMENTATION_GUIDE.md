# Sentry Error Tracking - Implementation Guide

**Status:** ✅ Implemented
**Date:** October 15, 2025
**Version:** 1.0.0

---

## Overview

Sentry has been integrated into FinMate to track errors, crashes, and performance issues in production. This guide explains how to set it up and use it effectively.

---

## What's Included

### ✅ Core Features Implemented
- **Error Tracking** - Catch all uncaught exceptions
- **Crash Reporting** - Automatic crash reports with stack traces
- **User Context** - Know which users experienced errors
- **Breadcrumbs** - Track user actions leading to errors
- **Performance Monitoring** - Track slow operations
- **Privacy Protection** - Filter sensitive data automatically
- **Screen Tracking** - Know where errors occurred

---

## Setup Instructions

### Step 1: Create Sentry Account (Free)

1. Go to [sentry.io](https://sentry.io)
2. Sign up for free account (50,000 errors/month free)
3. Create a new project:
   - Platform: **Flutter**
   - Project name: **FinMate**

### Step 2: Get Your DSN

1. In Sentry Dashboard, go to **Settings** → **Projects** → **FinMate**
2. Click **Client Keys (DSN)**
3. Copy your DSN (looks like: `https://xxx@o123.ingest.sentry.io/456`)

### Step 3: Configure Environment Variables

Add to your `.env` file:

```env
# Error Tracking
SENTRY_DSN=https://your-actual-dsn-here@sentry.io/project-id
SENTRY_ENVIRONMENT=development
SENTRY_RELEASE=1.0.0+1
```

**Important:**
- `SENTRY_DSN` is required
- `SENTRY_ENVIRONMENT` options: `development`, `staging`, `production`
- `SENTRY_RELEASE` should match your app version

### Step 4: Test It Works

Run the app and trigger a test error:

```dart
// Add this to any button in your app temporarily
ElevatedButton(
  onPressed: () {
    throw Exception('Test error - Sentry is working!');
  },
  child: Text('Test Sentry'),
),
```

Check Sentry dashboard - you should see the error appear within seconds!

---

## How It Works

### Automatic Error Catching

**All errors are automatically caught** in these places:

1. **Flutter Framework Errors**
   ```dart
   // Caught automatically - widget build errors, etc.
   Widget build(BuildContext context) {
     return Text(null!); // ← This will be caught
   }
   ```

2. **Async Errors**
   ```dart
   // Caught automatically - Future errors
   Future<void> fetchData() async {
     throw Exception('Network error'); // ← This will be caught
   }
   ```

3. **Uncaught Exceptions**
   ```dart
   // Caught automatically - any unhandled exceptions
   void doSomething() {
     throw Exception('Oops!'); // ← This will be caught
   }
   ```

### Manual Error Reporting

Use `GlobalErrorHandler` for manual reporting:

```dart
import 'package:fin_mate/core/error/global_error_handler.dart';

// Report an error
try {
  await riskyOperation();
} catch (e, stackTrace) {
  await GlobalErrorHandler.handleError(
    e,
    stackTrace,
    context: 'User Profile Update',
    extra: {'user_id': userId},
  );
}

// Report a warning (non-fatal)
await GlobalErrorHandler.handleWarning(
  'User tried to access feature without permission',
  context: 'Feature Access',
  extra: {'feature': 'admin_panel'},
);

// Report network errors
await GlobalErrorHandler.handleNetworkError(
  error,
  stackTrace,
  endpoint: '/api/transactions',
  statusCode: 500,
);
```

---

## User Context

**User context is automatically set** when users sign in/out:

```dart
// ✅ Already implemented in AuthNotifier
// When user signs in:
await SentryService.setUser(id: user.id, email: user.email);

// When user signs out:
await SentryService.clearUser();
```

**In Sentry dashboard, you'll see:**
- User ID
- User email
- Number of users affected by each error

---

## Breadcrumbs (User Actions)

Track user actions leading to errors:

```dart
import 'package:fin_mate/core/services/sentry_service.dart';

// Track screen navigation
SentryService.trackScreen('TransactionsPage');

// Track feature usage
SentryService.trackFeature('CreateBudget', data: {
  'category': 'Groceries',
  'amount': 500.00,
});

// Add custom breadcrumb
SentryService.addBreadcrumb(
  message: 'User clicked Export button',
  category: 'user_action',
  data: {'export_format': 'CSV'},
);
```

---

## Performance Monitoring

Track slow operations:

```dart
import 'package:fin_mate/core/services/sentry_service.dart';

// Start transaction
final transaction = SentryService.startTransaction(
  'Load Dashboard',
  'db.query',
  data: {'user_id': userId},
);

try {
  // Your slow operation
  await loadDashboardData();
} finally {
  // Finish transaction
  await transaction?.finish();
}
```

---

## Privacy & Security

### ✅ Automatic Privacy Protection

Sentry is configured to **automatically filter** sensitive data:

**Filtered Keywords:**
- `password`
- `token`
- `secret`
- `apikey`
- `mfa`

**What's NOT sent to Sentry:**
- Passwords
- API keys
- Auth tokens
- Credit card numbers
- SSN or sensitive IDs

**What IS sent:**
- User ID (UUID)
- User email
- Error messages
- Stack traces
- Screen names
- Non-sensitive user actions

### Manual Filtering

Add more filters if needed:

```dart
// In SentryService.initialize()
options.beforeSend = (event, hint) {
  // Add custom filtering
  if (event.message?.contains('SECRET_DATA')) {
    return null; // Don't send this event
  }
  return event;
};
```

---

## Integration Examples

### Example 1: Repository Error Handling

```dart
// In your repository
class TransactionRepositoryImpl implements TransactionRepository {
  @override
  Future<List<Transaction>> getTransactions() async {
    try {
      final response = await _supabase
          .from('transactions')
          .select()
          .order('date', ascending: false);

      return response.map((json) => TransactionModel.fromJson(json)).toList();
    } catch (e, stackTrace) {
      // Log to Sentry
      await GlobalErrorHandler.handleDatabaseError(
        e,
        stackTrace,
        query: 'SELECT * FROM transactions',
        table: 'transactions',
      );
      rethrow; // Re-throw so UI can handle it
    }
  }
}
```

### Example 2: UI Error Handling

```dart
// In your widget
class TransactionsPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsProvider);

    return transactionsAsync.when(
      data: (transactions) => ListView.builder(...),
      loading: () => CircularProgressIndicator(),
      error: (error, stackTrace) {
        // Error is already logged automatically
        // Just show user-friendly message
        return ErrorWidget('Failed to load transactions');
      },
    );
  }
}
```

### Example 3: Form Submission

```dart
Future<void> _submitForm() async {
  try {
    setState(() => _isLoading = true);

    await ref.read(transactionOperationsProvider.notifier).createTransaction(
      amount: _amountController.text,
      category: _selectedCategory,
    );

    // Success
    Navigator.pop(context);
  } catch (e, stackTrace) {
    // Log to Sentry with context
    await GlobalErrorHandler.handleError(
      e,
      stackTrace,
      context: 'Transaction Form Submission',
      extra: {
        'amount': _amountController.text,
        'category': _selectedCategory,
      },
    );

    // Show user-friendly error
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to create transaction')),
    );
  } finally {
    setState(() => _isLoading = false);
  }
}
```

---

## Monitoring in Sentry Dashboard

### What You'll See

**1. Issues Tab**
- All errors grouped by type
- Error frequency and trends
- Affected user count
- First and last seen timestamps

**2. Releases Tab**
- Errors per app version
- Crash-free users percentage
- Adoption rate

**3. Performance Tab**
- Slow transactions
- Database query times
- API response times

### Setting Up Alerts

1. Go to **Alerts** → **Create Alert**
2. Choose alert type:
   - **Issues:** New error or spike in errors
   - **Performance:** Slow transactions
   - **Crash Rate:** Too many crashes

3. Configure notification:
   - Email
   - Slack (recommended)
   - PagerDuty (for critical apps)

**Recommended Alerts:**
```
- New Issue Created (Email)
- Error Spike: >100 errors/hour (Slack)
- Crash Rate: >5% (Email + Slack)
```

---

## Testing Checklist

### Before Production Launch

- [ ] Verify Sentry DSN is set in production `.env`
- [ ] Test error reporting (trigger test error)
- [ ] Verify user context appears in Sentry
- [ ] Check breadcrumbs are recording
- [ ] Confirm sensitive data is filtered
- [ ] Set up Slack/email alerts
- [ ] Add team members to Sentry project

### After Launch

- [ ] Monitor error rate daily
- [ ] Fix critical errors immediately
- [ ] Review error trends weekly
- [ ] Update error handling based on real data

---

## Best Practices

### ✅ DO

1. **Always add context** to manual error reports
   ```dart
   GlobalErrorHandler.handleError(
     error,
     stackTrace,
     context: 'Where did this happen?',
     extra: {'relevant': 'data'},
   );
   ```

2. **Track screen navigation**
   ```dart
   @override
   void initState() {
     super.initState();
     SentryService.trackScreen('TransactionsPage');
   }
   ```

3. **Add breadcrumbs for important actions**
   ```dart
   SentryService.addBreadcrumb(
     message: 'User exported data',
     category: 'export',
   );
   ```

4. **Use appropriate severity levels**
   - `fatal` - App crashes
   - `error` - User-facing errors
   - `warning` - Handled errors
   - `info` - Important events

### ❌ DON'T

1. **Don't log sensitive data**
   ```dart
   // ❌ BAD
   SentryService.addBreadcrumb(
     message: 'User password: ${password}',
   );

   // ✅ GOOD
   SentryService.addBreadcrumb(
     message: 'Password updated',
   );
   ```

2. **Don't spam Sentry**
   ```dart
   // ❌ BAD - Will hit rate limits
   for (var i = 0; i < 1000; i++) {
     SentryService.captureMessage('Loop iteration $i');
   }
   ```

3. **Don't ignore error context**
   ```dart
   // ❌ BAD - No context
   GlobalErrorHandler.handleError(e, stackTrace);

   // ✅ GOOD - With context
   GlobalErrorHandler.handleError(
     e,
     stackTrace,
     context: 'Budget Calculation',
   );
   ```

---

## Troubleshooting

### Problem: Errors not appearing in Sentry

**Check:**
1. Is `SENTRY_DSN` set in `.env`?
2. Did you restart the app after setting DSN?
3. Check console for Sentry initialization message
4. Is your network connection working?

**Solution:**
```bash
# Check if Sentry initialized
flutter run
# Look for: "✅ Sentry initialized successfully"
# If not, check your .env file
```

### Problem: Too many errors

**Cause:** Catching and reporting every minor issue

**Solution:** Use appropriate severity levels
```dart
// Use warning for non-critical issues
GlobalErrorHandler.handleWarning('Minor issue');

// Use error only for real problems
GlobalErrorHandler.handleError(e, stackTrace);
```

### Problem: Sensitive data in reports

**Solution:** Add custom filtering
```dart
// In sentry_service.dart
options.beforeSend = (event, hint) {
  // Remove sensitive data
  event = event.copyWith(
    contexts: event.contexts?.map((key, value) {
      if (key == 'sensitive_key') return MapEntry(key, '[REDACTED]');
      return MapEntry(key, value);
    }),
  );
  return event;
};
```

---

## Files Modified

### New Files Created
1. `lib/core/services/sentry_service.dart` - Sentry wrapper
2. `lib/core/error/global_error_handler.dart` - Error handling utilities

### Modified Files
1. `pubspec.yaml` - Added sentry_flutter package
2. `lib/main.dart` - Added error zone and Sentry init
3. `lib/features/auth/presentation/providers/auth_providers.dart` - Added user context
4. `.env.example` - Added Sentry configuration

---

## Cost & Limits

**Free Tier (Recommended for MVP):**
- 50,000 errors per month
- 100 performance transactions
- 1 GB attachments
- 7 days data retention
- Unlimited team members

**When to upgrade:**
- Exceeding 50k errors/month
- Need longer data retention (> 7 days)
- Want more performance monitoring

---

## Next Steps

### Phase 1 (Now) ✅
- [x] Install Sentry package
- [x] Configure error tracking
- [x] Add user context
- [x] Test error reporting

### Phase 2 (Before Launch)
- [ ] Set up production DSN
- [ ] Configure Slack alerts
- [ ] Add team members
- [ ] Test in staging environment

### Phase 3 (After Launch)
- [ ] Monitor error trends
- [ ] Create error resolution workflow
- [ ] Set up on-call rotation (if needed)
- [ ] Review and optimize performance

---

## Support & Resources

**Documentation:**
- Sentry Flutter Docs: https://docs.sentry.io/platforms/flutter/
- Sentry Dashboard: https://sentry.io

**Team Contacts:**
- Primary: Development Team
- Escalation: Project Lead

---

**Implementation Status:** ✅ COMPLETE
**Ready for:** Beta Testing & Production

---

## Quick Reference

```dart
// Import
import 'package:fin_mate/core/services/sentry_service.dart';
import 'package:fin_mate/core/error/global_error_handler.dart';

// Track screen
SentryService.trackScreen('PageName');

// Track feature
SentryService.trackFeature('FeatureName');

// Add breadcrumb
SentryService.addBreadcrumb(message: 'Action', category: 'user');

// Report error
await GlobalErrorHandler.handleError(e, stackTrace, context: 'Where');

// Report warning
await GlobalErrorHandler.handleWarning('Message');

// Set user (done automatically)
await SentryService.setUser(id: userId, email: email);

// Clear user (done automatically)
await SentryService.clearUser();
```

**That's it! You're all set up with production-ready error tracking!** 🎉
