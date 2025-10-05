# Product Requirements Document (PRD)

## Product Name  
**FinMate** (placeholder – to be branded later)

---

## 1. Vision & Goals

### Vision  
Build a **professional, visually appealing, and secure financial app** that empowers individuals, families, and groups to:  
1. Manage personal finances with clarity.  
2. Split and settle bills easily.  
3. Gain actionable insights from AI forecasts.  

### Goals  
- Deliver a **cross-platform app** (iOS, Android, Web) using **Flutter**.  
- Combine **personal finance, bill splitting, and AI predictions** in one seamless app.  
- Establish trust through **secure, compliant, and privacy-first design**.  
- Provide a **stunning UI** that reflects growth, confidence, and simplicity.  

---

## 2. Target Users
- **Young professionals & students** → manage expenses, split bills with roommates/friends.  
- **Families & couples** → shared household budgets and goals.  
- **Freelancers & gig workers** → irregular income forecasting.  
- **Tech-savvy users** → early adopters seeking AI-powered financial insights.  

---

## 3. Core Features (MVP)

### 3.1 Authentication & Security
- Supabase Auth (JWT).  
- Multi-factor Authentication (MFA): SMS/email OTP + TOTP.  
- Biometric login (FaceID/TouchID via `local_auth`).  
- Role-Based Access Control (RBAC) for shared wallets.  

### 3.2 Personal Finance Management
- **Dashboard**:  
  - Net worth overview.  
  - Monthly cash flow (income vs. expenses).  
  - Upcoming bills timeline.  
  - “Money Health” score (visual gauge).  
- **Budgets**:  
  - Category-based spending.  
  - Alerts for overspending.  
- **Savings Goals**:  
  - Individual + shared.  
  - Progress visualization.  
- **Transactions**:  
  - Auto-import via Plaid/TrueLayer.  
  - Manual entry fallback.  
  - Smart categorization with manual overrides.  

### 3.3 Bill Splitting
- Create groups for roommates, trips, or families.  
- Add expenses with equal, percentage, or custom splits.  
- Track balances and who owes who.  
- Settlement flows:  
  - Manual records (MVP).  
  - Stripe/PayPal settlement (Phase 2).  
- Notifications and reminders.  

### 3.4 AI Insights & Forecasting
- Weekly digest: “Where your money went.”  
- 3–6 month cashflow forecast.  
- Scenario planning (baseline, optimistic, conservative).  
- Personalized recommendations (e.g., “Cut dining out 20% to save $250 in 3 months”).  
- Explainable insights with assumptions displayed.  

---

## 4. Extended Features (Phase 2+)
- Shared wallets & joint accounts.  
- Subscription manager (detect recurring charges).  
- Multi-currency support (with real-time FX).  
- Conversational AI assistant (chat-style).  
- Smart notifications (overspending, bill reminders, forecast alerts).  

---

## 5. Visual Design Guidelines

### Principles
- Trustworthy → professional & clean.  
- Clarity → minimal clutter, high readability.  
- Confidence → strong visuals for financial growth.  
- Delight → subtle gradients & animations.  

### Color Palette
- **Primary**:  
  - Deep Navy (#1A2B4C) – trust, security.  
  - Emerald Green (#2ECC71) – growth, success.  
- **Secondary**:  
  - Royal Purple (#6C5CE7) – premium fintech.  
  - Teal Blue (#00CEC9) – balance & freshness.  
- **Neutral**: Light Gray (#F5F7FA), White (#FFFFFF), Charcoal (#2D3436).  
- **Status**:  
  - Success Green (#27AE60).  
  - Warning Orange (#F39C12).  
  - Error Red (#E74C3C).  

### Typography
- Inter or Poppins (Google Fonts).  
- Bold, high-contrast numbers for balances.  

### Components
- Rounded cards, soft shadows.  
- Charts with green for gains, red for losses.  
- Light + dark mode support.  

---

## 6. Tech Stack

### Frontend (Flutter)
- Framework: Flutter (Material 3, Cupertino).  
- State Management: Riverpod or Bloc.  
- Routing: GoRouter.  
- Charts: `fl_chart`, `syncfusion_flutter_charts`.  
- Animations: `rive`, `lottie`.  

### Backend
- Supabase (auth, Postgres, storage).  
- Plaid/TrueLayer (bank data).  
- Stripe/PayPal (settlements).  
- OpenAI (AI insights).  
- PostHog or Amplitude (analytics).  

### Local
- Hive/Isar (encrypted offline storage).  
- Intl (currency formatting & localization).  

---

## 7. Security & Compliance

### Authentication
- MFA + biometrics.  
- Passkey/WebAuthn readiness.  

### Data Security
- AES-256 encryption at rest.  
- TLS 1.3 encryption in transit.  
- Encrypted local storage (Hive/Isar).  
- Key rotation with KMS.  

### Backend & API Security
- OAuth2 with Plaid/TrueLayer (no credential storage).  
- Rate limiting, input validation, audit logging.  

### Fraud Prevention
- Anomaly detection for suspicious logins.  
- Transaction verification for high-value splits.  

### Privacy & Compliance
- GDPR/CCPA compliance.  
- PCI-DSS (Stripe/PayPal handles cards).  
- SOC2 readiness.  
- User data deletion requests honored.  

### Secure Development Lifecycle
- Code reviews for security.  
- Static & dependency analysis.  
- Annual penetration testing.  

---

## 8. Metrics for Success (KPIs)

### MVP KPIs
- Daily Active Users (DAU).  
- Retention rates (Day 7, Day 30).  
- # of transactions categorized per user.  
- # of bills split per group.  
- Engagement with AI insights.  

### Growth KPIs
- Net Promoter Score (NPS).  
- % of settlements completed in-app.  
- Premium conversion rate.  

---

## 9. Release Plan

### Phase 1 (0–3 months)
- Auth + onboarding.  
- Dashboard (balances, budgets, bills).  
- Bill splitting (manual settlement).  
- Weekly AI digest.  

### Phase 2 (3–6 months)
- Stripe/PayPal settlements.  
- Shared goals & wallets.  
- Advanced AI forecasting.  
- Subscription manager.  

### Phase 3 (6–12 months)
- Multi-currency support.  
- Conversational AI assistant.  
- Smart notifications.  
- Web app release.  

---

## 10. Risks & Mitigations
- **Banking API limits/costs** → support manual entry & offline mode.  
- **User trust in AI** → explain assumptions & show confidence levels.  
- **Privacy concerns** → transparent consent + zero-knowledge option.  
- **Complex UX** → keep core flows ≤3 steps.  

---

## 11. Open Questions
- Monetization: freemium vs. subscription?  
- Region focus: US first (Plaid) or EU/UK (TrueLayer)?  
- AI compute: cloud-based or on-device for privacy?  


