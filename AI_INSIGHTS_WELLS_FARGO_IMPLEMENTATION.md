# AI Insights - Wells Fargo Fargo-Inspired Implementation

## Overview

This document describes the comprehensive AI Insights feature inspired by Wells Fargo's "Fargo" virtual assistant. The implementation includes conversational AI, 30-day balance forecasting, and proactive financial guidance.

---

## Features Implemented

### 1. 30-Day Balance Forecasting (Wells Fargo Cash Flow Monitor)

**Predictive Balance Projection:**
- Projects daily balance for the next 30 days
- Formula: `Current Balance + Scheduled Income - Scheduled Expenses - Average Daily Spending`
- Color-coded status indicators:
  - 🟢 **Healthy**: Balance ≥ $500
  - 🟡 **Warning**: Balance between $100-$500
  - 🔴 **Critical**: Balance < $100

**Key Components:**
- Visual timeline chart with balance trends
- Daily breakdown showing scheduled transactions
- Low-balance warnings (e.g., "Your balance may go negative on March 15")
- "Safe to spend" calculator
- Takes into account:
  - Current account balances
  - Recurring transactions (bills, subscriptions, income)
  - Future one-time transactions
  - Historical spending patterns (90-day average)

**File:** `lib/features/ai_insights/data/services/balance_forecast_service.dart`

---

### 2. Conversational AI Chat Interface

**Natural Language Query Processing:**
The system can understand and respond to various financial queries:

**Balance Queries:**
- "What's my current balance?"
- "How much money do I have?"
- "Show my account balances"

**Bill Queries:**
- "What bills are due soon?"
- "When is my next bill?"
- "Show upcoming payments"

**Spending Queries:**
- "How much did I spend this month?"
- "How much did I spend on groceries?"
- "Show my dining spending"
- "What did I spend last week?"

**Affordability Queries:**
- "Can I afford a $500 purchase?"
- "Can I buy something for $200?"

**Forecast Queries:**
- "What's my balance next week?"
- "Show my balance forecast"
- "What will my balance be tomorrow?"

**Income Queries:**
- "How much did I earn this month?"
- "Show my income"

**Category Queries:**
- "Show spending by category"
- "Break down my expenses"

**Chat Features:**
- Message bubbles (user vs AI)
- User avatar (person icon) and AI avatar (sparkle icon)
- Timestamp on each message
- Suggested prompt chips for common queries
- Chat history stored securely (last 50 messages)
- Clear chat history option

**Files:**
- `lib/features/ai_insights/data/services/query_processor_service.dart`
- `lib/features/ai_insights/presentation/widgets/chat_message_bubble.dart`
- `lib/features/ai_insights/presentation/widgets/chat_input_field.dart`
- `lib/features/ai_insights/presentation/widgets/suggested_prompts.dart`

---

### 3. Enhanced Spending Insights

**Proactive Insights:**
1. **Top Spending Category**
   - Identifies highest spending category
   - Shows amount and category name

2. **Spending Trend Analysis**
   - Detects if spending is increasing, decreasing, or stable
   - Compares recent 30 days vs previous 30 days
   - Shows average daily spending

3. **Unusual Spending Detection**
   - Flags categories with spending > 30% of total
   - Alerts user to potential budget issues

4. **Savings Opportunity Calculator**
   - Analyzes non-essential categories (Entertainment, Shopping, Dining, Other)
   - Calculates potential savings (20% reduction)

5. **Subscription Monitoring**
   - Detects price changes in recurring transactions
   - Alerts to subscription increases/decreases

**Files:**
- `lib/features/ai_insights/data/services/insights_service.dart` (enhanced)

---

### 4. Three-Tab Interface

#### Tab 1: Chat
- Conversational AI interface
- Message history
- Suggested prompts
- Real-time query processing

#### Tab 2: Insights
- Personalized insight cards
- Spending by category (top 5)
- 3-month cashflow forecast
- Traditional dashboard view

#### Tab 3: Forecast
- 30-day balance projection card
- Balance timeline chart
- Next 7 days detailed breakdown
- Warning alerts

**Files:**
- `lib/features/ai_insights/presentation/pages/ai_insights_page.dart`
- `lib/features/ai_insights/presentation/pages/insights_tab.dart`

---

## Architecture

### Data Layer

**Services:**
```
data/
└── services/
    ├── balance_forecast_service.dart    # 30-day forecasting logic
    ├── insights_service.dart            # Spending analysis
    └── query_processor_service.dart     # NLP query handling
```

### Domain Layer

**Entities:**
```
domain/
└── entities/
    ├── balance_forecast.dart            # Balance projection data models
    ├── chat_message.dart                # Chat message model
    └── spending_alert.dart              # Alert/notification models
```

### Presentation Layer

**Pages:**
```
presentation/
├── pages/
│   ├── ai_insights_page.dart           # Main tabbed interface
│   └── insights_tab.dart               # Traditional insights view
```

**Widgets:**
```
presentation/
├── widgets/
│   ├── balance_forecast_card.dart      # Balance overview card
│   ├── balance_timeline_chart.dart     # 30-day chart
│   ├── chat_input_field.dart           # Chat input
│   ├── chat_message_bubble.dart        # Message bubbles
│   └── suggested_prompts.dart          # Quick action chips
```

**Providers:**
```
presentation/
├── providers/
│   ├── balance_forecast_provider.dart  # Forecast state
│   ├── chat_provider.dart              # Chat state
│   └── insights_providers.dart         # Insights state
```

---

## State Management

### Riverpod Providers

**Balance Forecasting:**
```dart
// Generate 30-day forecast
final balanceForecastProvider = FutureProvider<BalanceForecast>

// Current balance extracted from forecast
final currentBalanceProvider = Provider<double>

// Safe to spend amount
final safeToSpendProvider = Provider<double>
```

**Chat:**
```dart
// Chat messages and operations
final chatProvider = StateNotifierProvider<ChatNotifier, AsyncValue<List<ChatMessage>>>

// Query processor service
final queryProcessorProvider = Provider<QueryProcessorService>

// Suggested prompts
final suggestedPromptsProvider = Provider<List<String>>
```

**Insights:**
```dart
// Spending patterns analysis
final spendingPatternsProvider = FutureProvider<Map<String, dynamic>>

// Personalized insights
final spendingInsightsProvider = FutureProvider<List<Map<String, dynamic>>>

// Category breakdown (parameterized by days)
final categoryBreakdownProvider = FutureProvider.family<List<Map<String, dynamic>>, int>

// Cashflow forecast (parameterized by months)
final cashflowForecastProvider = FutureProvider.family<List<Map<String, dynamic>>, int>

// Proactive alerts
final proactiveAlertsProvider = FutureProvider<List<Map<String, dynamic>>>

// Subscription change detection
final subscriptionChangesProvider = FutureProvider<List<Map<String, dynamic>>>
```

---

## Data Sources

### Supabase Tables Used

**Primary Tables:**
- `transactions` - All financial transactions
- `accounts` - Account balances
- `categories` - Transaction categories
- `user_profiles` - User information

**Queries:**
- Recurring transactions filtering (`is_recurring = true`)
- Date range filtering for analysis
- User-specific data (`user_id` filter)
- Category joins for spending breakdown

---

## Algorithm Details

### Balance Forecasting Algorithm

```
For each day D in next 30 days:
  1. Start with: running_balance
  2. Calculate scheduled_income for day D
     - Check recurring transactions (next occurrence on D)
     - Check future one-time transactions (date = D)
  3. Calculate scheduled_expenses for day D
     - Check recurring bills (next occurrence on D)
     - Check future one-time expenses (date = D)
  4. Add average_daily_spending (from historical data)
  5. Update: running_balance = running_balance + scheduled_income - scheduled_expenses - avg_daily_spending
  6. Determine status based on running_balance
  7. Record forecast for day D
```

**Recurring Transaction Projection:**
```
Calculate next occurrence based on interval:
- daily: +1 day
- weekly: +7 days
- biweekly: +14 days
- monthly: +1 month (same day)
- quarterly: +3 months
- yearly: +1 year
```

**Safe to Spend Calculation:**
```
min_balance = min(projected_balance over next 30 days)
buffer = $100
safe_to_spend = current_balance - (current_balance - min_balance) - buffer
```

---

### Query Processing Algorithm

**Intent Detection:**
Uses keyword matching to determine query type:

```
Query Type              Keywords
─────────────────────  ──────────────────────────────────
Balance                balance, how much, account
Bills                  bill, due, payment, pay
Spending               spend, spent, spending
Affordability          afford, can i buy, purchase
Forecast               forecast, predict, next week/month
Income                 income, earn, salary
Category               category, categories
Savings                save, saving, savings
Help                   help, what can, how do
```

**Response Generation:**
1. Parse query for intent and parameters
2. Extract time period (today, week, month, last month)
3. Extract category if mentioned
4. Extract amount if present (e.g., "$500")
5. Query Supabase for relevant data
6. Format response with currency formatting
7. Return natural language response

---

## UI/UX Design

### Color Coding

**Status Colors:**
- 🟢 Success/Healthy: `AppColors.success` (#20808D)
- 🟡 Warning: `AppColors.warning` (#F39C12)
- 🔴 Error/Critical: `AppColors.error` (#E74C3C)
- 🔵 Info: `AppColors.info` (#3498DB)

**Chat Bubbles:**
- User messages: `AppColors.primaryTeal` background, white text
- AI messages: `AppColors.lightGray` background, dark text

**Avatars:**
- User: Person icon in teal circle
- AI: Sparkle icon in light teal circle

### Design Principles

1. **Material 3 Design System**
   - Consistent with existing app theme
   - Rounded corners (AppSizes.radius*)
   - Elevated cards with shadows

2. **Wells Fargo Inspiration**
   - Clean, professional aesthetic
   - Card-based layout
   - Conversational interface
   - Proactive insights

3. **User Experience**
   - Pull-to-refresh on all tabs
   - Loading skeletons during data fetch
   - Error states with retry button
   - Empty states with helpful messages
   - Smooth tab transitions

---

## Security & Privacy

### Data Storage

**Chat History:**
- Stored locally using `flutter_secure_storage`
- Encrypted at rest
- User-specific
- Limited to last 50 messages
- Can be cleared by user

**Financial Data:**
- All queries access Supabase with RLS policies
- No external AI API (queries processed locally)
- No sensitive data logged
- User authentication required

---

## Performance Optimizations

1. **Caching:**
   - Chat history cached locally
   - Provider results cached by Riverpod

2. **Efficient Queries:**
   - Date range filtering at database level
   - Limited result sets (e.g., top 5 categories)
   - Indexes on frequently queried columns

3. **Lazy Loading:**
   - Forecast generated on-demand
   - Chat messages paginated (50 limit)

4. **Chart Rendering:**
   - CustomPainter for efficient drawing
   - Show every 3rd data point to avoid clutter

---

## Future Enhancements

### Phase 2 (Recommended)

1. **Real AI Integration**
   - OpenAI GPT-4 or Google Gemini API
   - More sophisticated query understanding
   - Contextual conversation memory

2. **Voice Input**
   - Speech-to-text integration
   - Voice activation ("Hey FinMate")

3. **Advanced Forecasting**
   - Machine learning models for better predictions
   - Seasonal spending pattern detection
   - Income variability handling

4. **Multi-Account Support**
   - Consolidated balance forecasting
   - Account-specific insights

5. **Actionable Recommendations**
   - One-tap bill payments
   - Automatic savings transfers
   - Budget adjustments

6. **Push Notifications**
   - Low balance alerts
   - Bill reminders
   - Savings milestones

---

## Testing

### Manual Testing Checklist

**Chat Tab:**
- [ ] Send a message and receive response
- [ ] Tap suggested prompt
- [ ] View message history
- [ ] Clear chat history
- [ ] Test various query types

**Insights Tab:**
- [ ] View personalized insights
- [ ] Check category breakdown
- [ ] Review 3-month forecast
- [ ] Pull to refresh

**Forecast Tab:**
- [ ] View balance forecast card
- [ ] Interact with timeline chart
- [ ] Check 7-day details
- [ ] Verify warnings display

### Edge Cases Handled

1. Empty states (no transactions)
2. No recurring transactions
3. Negative balance projections
4. Large amounts (number formatting)
5. Multiple accounts
6. Authentication errors
7. Network failures

---

## Code Quality

### Metrics

- **Zero analysis errors** ✅
- **Zero analysis warnings** ✅
- **Clean architecture** ✅
- **Type safety** ✅
- **Null safety** ✅

### Best Practices

- ✅ Separation of concerns (data/domain/presentation)
- ✅ Provider-based state management
- ✅ Reusable widgets
- ✅ Error handling
- ✅ Loading states
- ✅ Responsive design
- ✅ Accessibility considerations

---

## Integration Points

### Existing Features Used

1. **Transactions Feature**
   - Transaction data
   - Categories
   - Recurring transaction detection

2. **Accounts Feature**
   - Balance information
   - Account types

3. **Auth Feature**
   - User authentication
   - User ID for data filtering

4. **Shared Widgets**
   - LoadingSkeleton
   - EmptyState
   - ErrorRetryWidget

---

## Deployment Notes

### Requirements

- Flutter 3.37+
- Dart 3.10.0+
- Supabase account
- Existing FinMate database schema

### Configuration

No additional configuration needed! The feature:
- Uses existing Supabase connection
- Works with current database schema
- Requires no external API keys (for basic functionality)
- Integrates seamlessly with existing routing

### Router Update

The router has been updated to use the new `AiInsightsPage`:

```dart
GoRoute(
  path: '/insights',
  name: 'insights',
  builder: (context, state) => const AiInsightsPage(),
),
```

---

## Usage Examples

### Example Conversations

**User:** "What's my balance?"
**AI:** "Your current balances:
• Checking Account: $2,450.00
• Savings Account: $5,320.00

Total: $7,770.00"

---

**User:** "Can I afford a $500 purchase?"
**AI:** "Yes! You can afford $500.00. You'll still have $1,850.50 safe to spend after this purchase."

---

**User:** "What bills are due soon?"
**AI:** "Here are your upcoming bills:

• Netflix: $15.99 (in 3 days)
• Electric Bill: $120.00 (in 5 days)
• Rent: $1,500.00 (in 12 days)"

---

**User:** "How much did I spend on groceries this month?"
**AI:** "You spent $450.25 on groceries this month (12 transactions)."

---

## Credits

**Inspired by:** Wells Fargo's Fargo virtual assistant
**Design System:** Material 3
**State Management:** Riverpod
**Backend:** Supabase
**Developer:** Claude Code AI Assistant

---

## Changelog

### v1.0.0 (2025-10-13)
- Initial implementation
- 30-day balance forecasting
- Conversational AI chat interface
- Enhanced spending insights
- Three-tab interface
- Pattern-based query processing
- Local chat history storage
- Wells Fargo-inspired UI/UX
