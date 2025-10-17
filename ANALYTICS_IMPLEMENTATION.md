# Supabase Analytics Implementation

## Overview

FinMate now includes a comprehensive analytics system built on Supabase. This system tracks user behavior, app usage, and feature adoption to help you understand how users interact with your app.

## Architecture

### Database Layer

**Table: `analytics_events`**
- Stores all user events with JSONB properties for flexibility
- Includes session tracking, platform detection, and app version
- Protected by Row Level Security (RLS) policies

**Key Columns:**
- `user_id` - Links to authenticated user
- `event_name` - Name of the event (e.g., 'transaction_created')
- `event_properties` - JSONB field for custom event data
- `screen_name` - Screen where event occurred
- `session_id` - Groups events within a user session
- `platform` - ios/android/web
- `app_version` - App version for debugging
- `created_at` - Timestamp

**Indexes for Performance:**
- `idx_analytics_user_id` - Query by user
- `idx_analytics_event_name` - Query by event type
- `idx_analytics_created_at` - Time-series queries
- `idx_analytics_user_date` - Composite for user activity
- `idx_analytics_screen` - Screen analytics
- `idx_analytics_properties` - JSONB GIN index for property queries

### Analytics Functions

Six SQL functions provide pre-built analytics queries:

1. **`get_event_summary(start_date, end_date)`**
   - Returns event counts, unique users, first/last occurrence
   - Useful for: Understanding most popular actions

2. **`get_daily_active_users(start_date, end_date)`**
   - Returns DAU over time
   - Useful for: Growth tracking, retention analysis

3. **`get_popular_screens(start_date, end_date, limit)`**
   - Returns most viewed screens
   - Useful for: Navigation optimization

4. **`get_user_funnel(start_date, end_date)`**
   - Returns conversion rates for key steps
   - Useful for: Identifying drop-off points

5. **`get_retention_cohort(cohort_date)`**
   - Returns retention rates by days since signup
   - Useful for: Understanding user engagement over time

6. **`get_feature_adoption(start_date, end_date)`**
   - Returns adoption rates for major features
   - Useful for: Feature prioritization

### Service Layer

**File: `lib/core/services/analytics_service.dart`**

The `AnalyticsService` class provides a clean API for tracking events:

```dart
// Initialize with app info
await analytics.initialize();

// Track screen views
await analytics.trackScreen('TransactionsPage');

// Track specific events
await analytics.trackTransactionCreated(
  transactionId: 'abc123',
  amount: 50.00,
  type: 'expense',
  category: 'Food',
);
```

**Key Features:**
- Automatic session management
- Platform and app version detection
- Silent failure (analytics errors don't break UX)
- Automatic user context from Supabase auth

### Provider Layer

**File: `lib/core/providers/analytics_provider.dart`**

Riverpod providers for dependency injection:

```dart
// Access analytics service anywhere
final analytics = ref.read(analyticsServiceProvider);
await analytics.trackFeatureUsed('BillSplitting');
```

## Security & Privacy

### Row Level Security (RLS)

**Insert Policy:** Users can only insert their own events
```sql
CREATE POLICY analytics_insert_own
  ON analytics_events FOR INSERT
  WITH CHECK (auth.uid() = user_id);
```

**Select Policy:** Only admins can view analytics
```sql
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

### Privacy Considerations

- Events only logged for authenticated users
- No PII stored in event_properties
- 90-day data retention (configurable via cleanup function)
- Silent failures prevent analytics from impacting UX

## Event Tracking

### Currently Tracked Events

**Authentication:**
- `user_signed_up` - User creates account
- `user_signed_in` - User logs in
- `user_signed_out` - User logs out

**Transactions:**
- `transaction_created`
- `transaction_updated`
- `transaction_deleted`

**Budgets:**
- `budget_created`
- `budget_updated`
- `budget_deleted`

**Bill Splitting:**
- `group_created`
- `expense_created`
- `settlement_recorded`

**Savings Goals:**
- `goal_created`
- `contribution_added`

**AI Insights:**
- `ai_query`

**Documents:**
- `document_uploaded`

**General:**
- `screen_view` - Screen navigation
- `feature_used` - Generic feature usage
- `user_error` - User-facing errors
- `app_opened/closed/backgrounded/foregrounded` - Lifecycle

### Adding New Events

1. **Add tracking method to AnalyticsService:**

```dart
Future<void> trackCustomEvent({
  required String param1,
  int? param2,
}) async {
  await logEvent(
    eventName: 'custom_event',
    properties: {
      'param1': param1,
      'param2': param2,
    },
  );
}
```

2. **Call from feature code:**

```dart
final analytics = ref.read(analyticsServiceProvider);
await analytics.trackCustomEvent(
  param1: 'value',
  param2: 123,
);
```

## Usage Examples

### Track Screen Views

```dart
// In your page widget
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ref.read(analyticsServiceProvider).trackScreen('DashboardPage');
  });
}
```

### Track Feature Usage

```dart
// When user uses a feature
onPressed: () async {
  await ref.read(analyticsServiceProvider).trackFeatureUsed('ExportData');
  // ... rest of feature code
}
```

### Track Custom Events

```dart
await ref.read(analyticsServiceProvider).logEvent(
  eventName: 'custom_action',
  screenName: 'SettingsPage',
  properties: {
    'setting_changed': 'theme',
    'new_value': 'dark',
  },
);
```

## Querying Analytics

### From SQL Editor (Supabase Dashboard)

```sql
-- Get last 30 days event summary
SELECT * FROM get_event_summary(
  NOW() - INTERVAL '30 days',
  NOW()
);

-- Get DAU for last week
SELECT * FROM get_daily_active_users(
  CURRENT_DATE - INTERVAL '7 days',
  CURRENT_DATE
);

-- Get most popular screens
SELECT * FROM get_popular_screens(
  NOW() - INTERVAL '7 days',
  NOW(),
  10
);

-- Get user funnel
SELECT * FROM get_user_funnel(
  NOW() - INTERVAL '30 days',
  NOW()
);

-- Get retention for users who signed up 30 days ago
SELECT * FROM get_retention_cohort(
  CURRENT_DATE - INTERVAL '30 days'
);

-- Get feature adoption
SELECT * FROM get_feature_adoption(
  NOW() - INTERVAL '30 days',
  NOW()
);
```

### From Dart (Future Enhancement)

You can create repository methods to call these functions:

```dart
class AnalyticsRepository {
  Future<List<EventSummary>> getEventSummary({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final response = await supabase
        .rpc('get_event_summary', params: {
          'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
        });
    // Parse and return
  }
}
```

## Data Cleanup

Analytics data is automatically cleaned after 90 days using the `cleanup_old_analytics()` function.

**Manual cleanup:**
```sql
SELECT cleanup_old_analytics();
```

**Automatic cleanup with pg_cron (optional):**
```sql
SELECT cron.schedule(
  'cleanup-analytics',
  '0 0 * * 0', -- Every Sunday at midnight
  'SELECT cleanup_old_analytics();'
);
```

## Migration Instructions

The analytics system is ready to deploy:

1. **Apply the migration:**
   ```bash
   supabase db push
   ```

   Or manually in SQL Editor:
   - Copy contents of `supabase/migrations/16_create_analytics_events.sql`
   - Paste in SQL Editor and run

2. **Verify installation:**
   ```sql
   -- Check table exists
   SELECT * FROM analytics_events LIMIT 1;

   -- Check functions exist
   SELECT routine_name
   FROM information_schema.routines
   WHERE routine_name LIKE 'get_%';
   ```

3. **Test tracking:**
   - Run the app
   - Sign in
   - Check events: `SELECT * FROM analytics_events ORDER BY created_at DESC LIMIT 10;`

## Future Enhancements

### Admin Dashboard (TODO)

Create a dashboard page for admins to view analytics:

- Event timeline chart
- DAU/WAU/MAU graphs
- Feature adoption funnel
- User retention cohorts
- Real-time event stream

### Export Features (TODO)

- CSV export for analysis in Excel/Google Sheets
- Integration with external analytics tools (Amplitude, Mixpanel)

### Advanced Tracking (TODO)

- Session duration calculation
- User journey mapping
- A/B test tracking
- Performance metrics

## Testing

### Unit Tests

Test analytics methods don't throw errors:

```dart
test('trackSignIn should not throw', () async {
  final analytics = AnalyticsService(mockSupabase);
  await analytics.initialize();

  await expectLater(
    analytics.trackSignIn(method: 'email'),
    completes,
  );
});
```

### Integration Tests

Verify events are stored:

```dart
testWidgets('signin creates analytics event', (tester) async {
  // ... sign in flow

  final events = await supabase
      .from('analytics_events')
      .select()
      .eq('event_name', 'user_signed_in')
      .limit(1);

  expect(events, isNotEmpty);
});
```

## Troubleshooting

### Events Not Appearing

1. **Check user is authenticated:**
   ```dart
   print(Supabase.instance.client.auth.currentUser);
   ```

2. **Check RLS policies:**
   - Verify insert policy allows current user
   - Test with service role key (bypasses RLS)

3. **Check for errors:**
   - Analytics errors are caught silently
   - Check Sentry for analytics-related errors

### Query Performance Issues

1. **Verify indexes exist:**
   ```sql
   SELECT indexname FROM pg_indexes
   WHERE tablename = 'analytics_events';
   ```

2. **Add indexes for custom queries:**
   ```sql
   CREATE INDEX idx_custom ON analytics_events(custom_field);
   ```

3. **Limit date ranges:**
   - Don't query all-time data
   - Use 7/30/90 day windows

## Cost Considerations

**Storage:**
- ~500 bytes per event
- 1M events ≈ 500 MB storage
- Supabase Free Tier: 500 MB included

**Database Operations:**
- Inserts count toward daily quota
- Functions use compute time
- Free Tier: 2 GB database size

**Recommendations:**
- Keep 90-day retention (configurable)
- Archive old data if needed
- Monitor Supabase usage dashboard

## Support

For questions or issues:
1. Check this documentation
2. Review migration file: `supabase/migrations/16_create_analytics_events.sql`
3. Check service code: `lib/core/services/analytics_service.dart`
4. Consult Supabase docs: https://supabase.com/docs

---

**Created:** 2025-10-15
**Last Updated:** 2025-10-15
**Status:** ✅ Implemented & Ready for Use
