# Technical Improvements Plan - Supabase Edition

**Goal:** Enhance code quality, monitoring, and reliability before launch
**Timeline:** 2-3 weeks
**Stack:** Supabase + Sentry (for error tracking)

---

## **Week 1: Critical Infrastructure** 🔴

### **Day 1-2: Error Tracking with Sentry**

#### 1. **Sentry Setup for Error Tracking** ✅ PRIORITY
**Why:** Catch crashes and errors in production (Sentry works great with Flutter + Supabase)

**Tasks:**
- [ ] Create Sentry account (free tier available)
- [ ] Add sentry_flutter package to pubspec.yaml
- [ ] Configure Sentry DSN in environment variables
- [ ] Add Sentry initialization to main.dart
- [ ] Test error reporting in debug mode
- [ ] Set up custom error contexts (user ID, screen name)
- [ ] Configure source maps for better stack traces

**Code Changes:**
```yaml
# pubspec.yaml
dependencies:
  sentry_flutter: ^7.0.0
```

```dart
// main.dart
import 'package:sentry_flutter/sentry_flutter.dart';

Future<void> main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn = const String.fromEnvironment('SENTRY_DSN');
      options.tracesSampleRate = 1.0;
      options.environment = const String.fromEnvironment('ENV', defaultValue: 'development');
    },
    appRunner: () => runApp(
      ProviderScope(
        child: const MyApp(),
      ),
    ),
  );
}

// In error handling
try {
  // Your code
} catch (error, stackTrace) {
  await Sentry.captureException(
    error,
    stackTrace: stackTrace,
    hint: Hint.withMap({
      'userId': currentUserId,
      'screen': 'TransactionsPage',
    }),
  );
}
```

**Sentry Features:**
- Real-time error alerts
- Error grouping and deduplication
- User impact tracking
- Performance monitoring
- Release tracking
- Breadcrumb tracking (user actions before error)

**Estimated time:** 4-6 hours

---

#### 2. **Supabase Analytics & Monitoring** ✅ PRIORITY
**Why:** Leverage Supabase's built-in analytics and monitoring

**Supabase Built-in Tools:**

**A. Database Activity Monitoring**
- [ ] Set up Supabase Dashboard monitoring
- [ ] Monitor query performance in Supabase Dashboard
- [ ] Set up slow query alerts
- [ ] Review connection pool usage
- [ ] Monitor storage usage

**B. Custom Analytics with Supabase**
Create analytics tracking table:

```sql
-- Migration: 16_create_analytics_events.sql
CREATE TABLE analytics_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  event_name TEXT NOT NULL,
  event_properties JSONB DEFAULT '{}'::jsonb,
  screen_name TEXT,
  session_id TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add indexes for performance
CREATE INDEX idx_analytics_user_id ON analytics_events(user_id);
CREATE INDEX idx_analytics_event_name ON analytics_events(event_name);
CREATE INDEX idx_analytics_created_at ON analytics_events(created_at DESC);

-- RLS policies
ALTER TABLE analytics_events ENABLE ROW LEVEL SECURITY;

CREATE POLICY analytics_insert_own
  ON analytics_events FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY analytics_select_admin
  ON analytics_events FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role = 'admin'
    )
  );
```

**C. Create Analytics Service**
```dart
// lib/core/services/analytics_service.dart
class AnalyticsService {
  final SupabaseClient _supabase;

  AnalyticsService(this._supabase);

  Future<void> logEvent(
    String eventName, {
    Map<String, dynamic>? properties,
    String? screenName,
  }) async {
    try {
      await _supabase.from('analytics_events').insert({
        'user_id': _supabase.auth.currentUser?.id,
        'event_name': eventName,
        'event_properties': properties ?? {},
        'screen_name': screenName,
        'session_id': _getSessionId(),
      });
    } catch (e) {
      // Don't let analytics failures break the app
      print('Analytics error: $e');
    }
  }

  String _getSessionId() {
    // Generate or retrieve session ID
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}

// Provider
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService(supabase);
});
```

**Key Events to Track:**
```dart
// User events
analytics.logEvent('user_signed_up');
analytics.logEvent('user_logged_in');
analytics.logEvent('user_logged_out');

// Transaction events
analytics.logEvent('transaction_created', properties: {
  'amount': transaction.amount,
  'category': transaction.category,
  'type': transaction.type,
});

// Budget events
analytics.logEvent('budget_created', properties: {
  'category': budget.category,
  'amount': budget.amount,
});

// Bill splitting events
analytics.logEvent('group_created');
analytics.logEvent('settlement_recorded', properties: {
  'amount': settlement.amount,
});

// AI events
analytics.logEvent('ai_query', properties: {
  'query_type': queryType,
  'response_time_ms': responseTime,
});
```

**D. Analytics Dashboard Queries**
Create database functions for admin analytics:

```sql
-- Get event counts by type
CREATE OR REPLACE FUNCTION get_event_summary(
  start_date TIMESTAMPTZ,
  end_date TIMESTAMPTZ
)
RETURNS TABLE (
  event_name TEXT,
  event_count BIGINT,
  unique_users BIGINT
) AS $$
BEGIN
  RETURN QUERY
  SELECT
    ae.event_name,
    COUNT(*) as event_count,
    COUNT(DISTINCT ae.user_id) as unique_users
  FROM analytics_events ae
  WHERE ae.created_at BETWEEN start_date AND end_date
  GROUP BY ae.event_name
  ORDER BY event_count DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
```

**Estimated time:** 6-8 hours

---

### **Day 3-4: Performance Optimizations**

#### 3. **Supabase Query Optimization** 🟡 MEDIUM
**Tasks:**
- [ ] Review all Supabase queries for efficiency
- [ ] Add database indexes for frequently queried columns
- [ ] Use Supabase's built-in query analyzer
- [ ] Implement pagination for large datasets
- [ ] Cache frequently accessed data with Riverpod

**Indexes to Add:**
```sql
-- Migration: 17_add_performance_indexes.sql

-- Transactions - frequently queried by user and date
CREATE INDEX IF NOT EXISTS idx_transactions_user_date
  ON transactions(user_id, date DESC);

-- Transactions - for category filtering
CREATE INDEX IF NOT EXISTS idx_transactions_user_category
  ON transactions(user_id, category_id);

-- Budgets - for period queries
CREATE INDEX IF NOT EXISTS idx_budgets_user_period
  ON budgets(user_id, period_start, period_end);

-- Group expenses - for bill splitting
CREATE INDEX IF NOT EXISTS idx_group_expenses_group_date
  ON group_expenses(group_id, date DESC);

-- Settlements - for history queries
CREATE INDEX IF NOT EXISTS idx_settlements_group_date
  ON settlements(group_id, settled_at DESC);

-- Savings goals - for user queries
CREATE INDEX IF NOT EXISTS idx_savings_goals_user_status
  ON savings_goals(user_id, is_completed);

-- Analytics events - for reporting
CREATE INDEX IF NOT EXISTS idx_analytics_user_date
  ON analytics_events(user_id, created_at DESC);
```

**Query Optimization Patterns:**
```dart
// BAD: Fetch all then filter in app
final allTransactions = await supabase.from('transactions').select();
final filtered = allTransactions.where((t) => t.userId == userId);

// GOOD: Filter in database
final transactions = await supabase
  .from('transactions')
  .select()
  .eq('user_id', userId)
  .order('date', ascending: false)
  .limit(50); // Limit results
```

**Enable Supabase Realtime (for live updates):**
```dart
// Listen to real-time changes
final subscription = supabase
  .from('transactions')
  .stream(primaryKey: ['id'])
  .eq('user_id', userId)
  .listen((data) {
    // Update UI with new data
    ref.invalidate(transactionsProvider);
  });
```

**Estimated time:** 6-8 hours

---

#### 4. **Caching Strategy with Riverpod** 🟡 MEDIUM
**Tasks:**
- [ ] Implement provider caching (already partially done ✅)
- [ ] Add cache invalidation strategy
- [ ] Use `keepAlive()` for important data
- [ ] Implement local storage caching for offline support
- [ ] Add cache expiration logic

**Example:**
```dart
// Cache for 5 minutes
final transactionsProvider = FutureProvider.autoDispose((ref) async {
  final cacheTime = ref.keepAlive();
  Timer(const Duration(minutes: 5), cacheTime.close);

  return await ref.watch(transactionRepositoryProvider).getTransactions();
});

// Or use family providers with caching
final transactionProvider = FutureProvider.family<Transaction, String>((ref, id) async {
  return await ref.watch(transactionRepositoryProvider).getById(id);
});
```

**Estimated time:** 4-6 hours

---

### **Day 5: Error Boundaries & Resilience**

#### 5. **Comprehensive Error Handling** ✅ PRIORITY

**A. Global Error Handler**
```dart
// lib/core/error/error_handler.dart
class GlobalErrorHandler {
  static Future<void> handleError(
    Object error,
    StackTrace stackTrace, {
    bool fatal = false,
  }) async {
    // Log to Sentry
    await Sentry.captureException(error, stackTrace: stackTrace);

    // Log to Supabase for internal tracking
    try {
      await supabase.from('error_logs').insert({
        'user_id': supabase.auth.currentUser?.id,
        'error_message': error.toString(),
        'stack_trace': stackTrace.toString(),
        'is_fatal': fatal,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Silently fail - don't break app due to error logging
    }

    // Show user-friendly message
    if (fatal) {
      // Navigate to error screen
    }
  }
}
```

**B. Supabase Error Logging Table**
```sql
-- Migration: 18_create_error_logs.sql
CREATE TABLE error_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  error_message TEXT NOT NULL,
  stack_trace TEXT,
  is_fatal BOOLEAN DEFAULT false,
  device_info JSONB,
  app_version TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_error_logs_user ON error_logs(user_id);
CREATE INDEX idx_error_logs_date ON error_logs(created_at DESC);
CREATE INDEX idx_error_logs_fatal ON error_logs(is_fatal) WHERE is_fatal = true;

-- RLS
ALTER TABLE error_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY error_logs_insert
  ON error_logs FOR INSERT
  WITH CHECK (true); -- Anyone can log errors

CREATE POLICY error_logs_select_admin
  ON error_logs FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM user_profiles
      WHERE user_profiles.id = auth.uid()
      AND user_profiles.role = 'admin'
    )
  );
```

**C. Error Boundary Widget**
```dart
// lib/core/widgets/error_boundary.dart
class ErrorBoundary extends ConsumerWidget {
  final Widget child;
  final String? screenName;

  const ErrorBoundary({
    required this.child,
    this.screenName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ErrorWidget.builder = (FlutterErrorDetails details) {
      GlobalErrorHandler.handleError(
        details.exception,
        details.stack ?? StackTrace.empty,
        fatal: true,
      );

      return ErrorScreen(
        error: details.exception,
        onRetry: () {
          // Retry logic
        },
      );
    };

    return child;
  }
}
```

**Wrap app with error boundary:**
```dart
void main() async {
  runZonedGuarded(() async {
    await SentryFlutter.init(/*...*/);
    runApp(
      ErrorBoundary(
        child: ProviderScope(child: MyApp()),
      ),
    );
  }, (error, stack) {
    GlobalErrorHandler.handleError(error, stack, fatal: true);
  });
}
```

**Estimated time:** 6-8 hours

---

## **Week 2: Testing & Quality** 🟡

### **Day 6-8: Unit Tests**

#### 6. **Unit Tests for Critical Business Logic**
(Same as before - not affected by Supabase vs Firebase)

**Target Tests:**
- Emergency Fund Service
- Balance Forecast Service
- Query Processor Service
- Budget calculations
- Bill splitting calculations

**Estimated time:** 12-16 hours

---

### **Day 9-10: Widget Tests**

#### 7. **Widget Tests for Key Flows**
(Same as before)

**Estimated time:** 12-16 hours

---

## **Week 3: Security & Monitoring** 🟢

### **Day 11-12: Supabase Security Hardening**

#### 8. **Supabase Security Review** ✅ PRIORITY

**A. RLS Policy Audit**
```sql
-- Review script: Check all tables have RLS enabled
SELECT tablename
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename NOT IN (
    SELECT tablename
    FROM pg_policies
  );

-- This should return empty - all tables should have policies
```

**B. Review Each Table's Policies**
- [ ] user_profiles - Can only read/update own profile
- [ ] accounts - User can only access their own accounts
- [ ] transactions - User can only access their own transactions
- [ ] budgets - User can only access their own budgets
- [ ] group_members - Members can only see their groups
- [ ] settlements - Members can only see group settlements
- [ ] documents - Users can only access their own documents

**C. Test RLS Policies**
```sql
-- Test as specific user
SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claims.sub TO 'user-uuid-here';

-- Try to access another user's data
SELECT * FROM transactions WHERE user_id != 'user-uuid-here';
-- Should return empty

-- Reset
RESET ROLE;
```

**D. Enable Supabase Audit Logs**
- [ ] Enable audit logging in Supabase Dashboard
- [ ] Monitor for suspicious queries
- [ ] Set up alerts for failed RLS checks

**Estimated time:** 8-10 hours

---

#### 9. **Supabase Performance Monitoring**

**A. Enable Supabase Monitoring**
- [ ] Set up alerts in Supabase Dashboard
- [ ] Monitor database size
- [ ] Monitor connection count
- [ ] Monitor slow queries
- [ ] Set up usage alerts (approaching limits)

**B. Query Performance Dashboard**
Create admin view for query performance:

```sql
-- Migration: 19_create_performance_views.sql
CREATE OR REPLACE VIEW admin_query_performance AS
SELECT
  query,
  calls,
  total_time,
  mean_time,
  max_time
FROM pg_stat_statements
WHERE userid = (SELECT usesysid FROM pg_user WHERE usename = 'postgres')
ORDER BY total_time DESC
LIMIT 50;

-- Grant to admin role
GRANT SELECT ON admin_query_performance TO authenticated;
```

**Estimated time:** 4-6 hours

---

## **Supabase-Specific Improvements Summary**

### **Must-Have (Week 1)** 🔴
1. ✅ Sentry for error tracking
2. ✅ Supabase analytics with custom events table
3. ✅ Database query optimization (indexes)
4. ✅ Error boundaries and logging
5. 🟡 Caching strategy with Riverpod

**Total Time:** ~35-45 hours

---

### **Should-Have (Week 2)** 🟡
6. Unit tests for business logic
7. Widget tests for critical flows
8. Performance profiling

**Total Time:** ~30-40 hours

---

### **Nice-to-Have (Week 3)** 🟢
9. RLS security audit
10. Supabase monitoring setup
11. Code documentation
12. Query performance optimization

**Total Time:** ~25-35 hours

---

## **Recommended Approach: 2-Week Balanced Plan**

### **Week 1: Infrastructure**
- Days 1-2: Sentry setup + Supabase analytics
- Days 3-4: Database optimization + caching
- Day 5: Error handling + boundaries

### **Week 2: Testing + Security**
- Days 6-8: Unit tests (60% coverage goal)
- Days 9-10: Widget tests (critical flows)
- Days 11-12: Security audit + monitoring

**Then proceed to Phase A: Launch Preparation**

---

## **Which option do you prefer?**

1. **Quick (1 week)** - Infrastructure + Error handling only
2. **Balanced (2 weeks)** - Infrastructure + Tests ⭐ RECOMMENDED
3. **Complete (3 weeks)** - Everything including full security audit

**Ready to start? Let me know which option and I'll begin implementation!** 🚀
