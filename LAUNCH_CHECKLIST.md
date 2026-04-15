# Finmate Launch Checklist

**App Version:** 1.0.0+1
**Target:** Beta Launch
**Timeline:** 3-5 days from now

---

## 🔴 CRITICAL (Must Complete Today)

### 0. Drop TOTP plain-text column ⚠️ **SECURITY — YOUR ACTION REQUIRED**

**Time:** 5 minutes
**Complexity:** Easy (copy-paste SQL)

Migration `51_encrypt_totp_secrets.sql` added an encrypted column and copied secrets, but the `DROP COLUMN` was left commented out. Plain-text TOTP secrets may still exist in production.

**Steps:**
1. Open Supabase SQL editor for your project
2. Run the verification query first:
```sql
SELECT COUNT(*)
FROM user_profiles
WHERE totp_secret IS NOT NULL;
```
3. If count > 0, encrypted migration hasn't finished — do NOT drop yet, re-run migration 51 fully.
4. If count = 0, all secrets are encrypted. Safe to drop:
```sql
ALTER TABLE user_profiles DROP COLUMN IF EXISTS totp_secret;
```

**Why critical:** Plain-text TOTP secrets in the database is a security breach exposure.

**Status:** ⚠️ PENDING — run verification query now

---

### 1. Apply Database Migration 31 ⚠️ **YOUR ACTION REQUIRED**

**Time:** 15 minutes
**Complexity:** Easy (copy-paste SQL)

**Steps:**
1. Open: https://supabase.com/dashboard/project/YOUR_PROJECT_ID/sql/new
2. Copy SQL from: `supabase/migrations/31_add_subscription_tier_and_enable_documents.sql`
3. Paste and click "Run"
4. Verify with test queries (provided in CRITICAL_BLOCKERS_STATUS.md)

**Why critical:** Without this, premium subscriptions won't work properly.

**Status:** ⚠️ PENDING

---


<!-- I'VE GOTTEN TO THIS POINT AND I NEED COMPLETE THE ITEMS BELOW -->

### 2. Configure Sentry DSN (Optional but Highly Recommended)

**Time:** 5 minutes
**Complexity:** Easy

**Steps:**
1. Sign up: https://sentry.io/signup/
2. Create Flutter project
3. Copy DSN (format: `https://xxxxx@oXXXXX.ingest.sentry.io/XXXXXXX`)
4. Update `.env` file: `SENTRY_DSN=your-dsn-here`

**Why important:** Production error tracking and crash monitoring.

**Status:** ℹ️ OPTIONAL (but strongly recommended for launch)

---

## 🟢 COMPLETED ✅

- ✅ **Stripe Secret Key Configuration** - All 9 edge functions deployed and active
- ✅ **Code Quality** - `flutter analyze` shows zero issues
- ✅ **Security Audit** - No hardcoded secrets, .env properly gitignored
- ✅ **Environment Configuration** - .env and .env.example in sync

---

## 🟡 HIGH PRIORITY (This Week - Before Beta Launch)

### 3. End-to-End Payment Testing (After Migration 31)

**Time:** 30-60 minutes
**Complexity:** Medium

**Test Flow:**
```bash
flutter clean
flutter pub get
flutter run
```

**Steps:**
1. Create new test user account
2. Navigate: Profile → Upgrade to Premium
3. Click "Start Free Trial" or "Subscribe Monthly"
4. Should redirect to Stripe checkout page
5. Use test card: `4242 4242 4242 4242`
   - Expiry: Any future date (e.g., 12/25)
   - CVC: Any 3 digits (e.g., 123)
   - ZIP: Any 5 digits (e.g., 12345)
6. Complete checkout
7. Return to app
8. Verify subscription status shows "Premium"
9. Check Supabase: `user_profiles` table should show `subscription_tier = 'premium'`

**Expected Result:** ✅ Subscription activates, user is premium

**If it fails:**
- Check Supabase Edge Function logs
- Verify Stripe webhook is receiving events
- Check `STRIPE_SECRET_KEY` is set correctly

**Status:** ⏳ PENDING (blocked by Migration 31)

---

### 4. Receipt Scanning Feature Testing (Premium Only)

**Time:** 15 minutes
**Complexity:** Easy

**Prerequisites:**
- Migration 31 applied ✅
- User has premium subscription ✅

**Steps:**
1. Login as premium user
2. Go to: Transactions → Add Transaction
3. Look for "Scan Receipt" button
4. Tap → Choose camera or photo library
5. Take/select a receipt photo
6. Review extracted data:
   - Amount
   - Merchant name
   - Date
   - Line items
7. Confirm → Should auto-fill transaction form

**Expected Result:** ✅ Receipt data extracted and transaction created

**Status:** ⏳ PENDING (blocked by Migration 31)

---

### 5. Physical Device Testing (iOS Priority)

**Time:** 2-3 hours
**Complexity:** Medium

**Device Requirements:**
- iPhone with iOS 15+ (for Face ID/Touch ID testing)
- Physical device (not simulator)

**Test Checklist:**

**Authentication & Security:**
- [ ] Sign up new user → Email verification works
- [ ] Login with email/password
- [ ] Enable Face ID/Touch ID
- [ ] Logout → Login with biometric auth
- [ ] Enable MFA (TOTP) → Scan QR code with authenticator app
- [ ] Logout → Login with MFA code
- [ ] Test "Forgot Password" flow

**Core Features:**
- [ ] Create income transaction → Appears in dashboard
- [ ] Create expense transaction → Budget updates
- [ ] Create transfer between accounts
- [ ] Filter transactions by date, category, amount
- [ ] Search transactions
- [ ] Create monthly budget → Track spending
- [ ] Get over-budget alert when exceeding limit

**Premium Features:**
- [ ] Upgrade to premium subscription
- [ ] Scan receipt with camera
- [ ] Upload document to Documents page
- [ ] Export all transactions to CSV

**UI/UX:**
- [ ] Toggle dark mode → Check all screens look correct
- [ ] Test on different screen sizes
- [ ] Check keyboard behavior (doesn't overlap inputs)
- [ ] Verify all buttons are tappable
- [ ] Test scrolling on long lists (transactions, budgets)

**Offline Behavior:**
- [ ] Turn on Airplane mode
- [ ] Try to add transaction → Should show offline indicator
- [ ] Turn off Airplane mode → Data syncs

**Performance:**
- [ ] Create 100+ transactions → List scrolls smoothly
- [ ] Charts render without lag
- [ ] App startup time < 3 seconds

**Status:** ⏳ PENDING

---

### 6. Android Testing (After iOS)

**Time:** 2-3 hours
**Complexity:** Medium

**Prerequisites:**
- Fix Java environment: `export JAVA_HOME=/path/to/jdk`
- Android device or emulator

**Test Same Checklist as iOS Above**

**Android-Specific Tests:**
- [ ] Fingerprint authentication (instead of Face ID)
- [ ] Back button behavior (doesn't crash app)
- [ ] Material design components render correctly
- [ ] Permissions (camera, storage) requested properly

**Status:** ⏳ PENDING (Java environment needs fix first)

---

## 🟢 NICE TO HAVE (Can Do Post-Launch)

### 7. Improve Test Coverage

**Current:** 20% (~8 test files)
**Target:** 60%+
**Time:** 2-3 days

**Priority Tests to Add:**
- Integration tests for auth flow
- Transaction CRUD tests
- Budget calculation tests
- Payment flow integration test

**Status:** 📅 DEFERRED TO V1.1

---

### 8. Performance Optimization

**Time:** 1 day
**Focus Areas:**
- Large data sets (1000+ transactions)
- Chart rendering optimization
- Memory leak detection
- App startup time improvement

**Status:** 📅 DEFERRED TO V1.1

---

### 9. Accessibility Audit

**Time:** 4 hours
**Check:**
- VoiceOver/TalkBack compatibility
- Color contrast ratios (WCAG AA)
- Dynamic text sizing
- Keyboard navigation

**Status:** 📅 DEFERRED TO V1.1

---

### 10. Set Up CI/CD Pipeline

**Time:** 1 day
**Setup:**
- GitHub Actions or GitLab CI
- Automated builds for iOS/Android
- Automated tests on PRs
- Automated deployment to TestFlight/Play Console

**Status:** 📅 DEFERRED TO V1.1

---

## 📊 FEATURE SCOPE FOR V1.0 BETA

### ✅ INCLUDED (Core Features)

**Authentication:**
- ✅ Email/password signup & login
- ✅ Email verification
- ✅ Biometric authentication (Face ID/Touch ID/Fingerprint)
- ✅ MFA (TOTP & Email OTP)
- ✅ Password reset

**Personal Finance:**
- ✅ Transactions (income, expense, transfer)
- ✅ Multiple accounts (checking, savings, cash, credit cards)
- ✅ Categories & categorization
- ✅ Transaction search & filtering
- ✅ Budgets by category
- ✅ Budget tracking & alerts

**Dashboard & Analytics:**
- ✅ Net worth tracking
- ✅ Cash flow visualization
- ✅ Money health score
- ✅ Recent transactions feed
- ✅ Category spending breakdown

**Premium Subscription:**
- ✅ Freemium tier (unlimited transactions & budgets)
- ✅ Premium tier ($4.99/mo or $49.99/yr)
- ✅ Stripe checkout integration
- ✅ Subscription management
- ✅ Receipt scanning (Premium only)
- ✅ Document storage (Premium only)
- ✅ Unlimited transaction history (Premium only)

**Profile & Settings:**
- ✅ Profile editing with avatar upload
- ✅ Security settings (MFA, biometric)
- ✅ Theme switching (light/dark/system)
- ✅ Notification preferences
- ✅ Data export (CSV, JSON, PDF)
- ✅ Privacy controls

---

### ❌ DEFERRED TO V1.1 (Optional Features)

**AI Insights:**
- ❌ Conversational AI assistant (needs Gemini API key)
- ❌ Spending pattern analysis
- ❌ Cash flow forecasting
- ❌ Personalized recommendations
- **Status:** 60% complete, needs backend API integration
- **Decision:** DEFER - Can launch without it

**Bill Splitting:**
- ❌ Group expense tracking
- ❌ Split bills (equal, custom, percentage)
- ❌ Settlement tracking
- **Status:** 70% complete, just needs routes uncommented
- **Decision:** DEFER - Niche audience, add after beta feedback

**Savings Goals:**
- ❌ Goal creation & tracking
- ❌ Progress visualization
- ❌ AI goal recommendations
- **Status:** 75% complete, just needs routes uncommented
- **Decision:** DEFER - Can add quickly if beta users request it

**Recurring Transactions:**
- ❌ Auto-generation of recurring transactions
- ❌ Reminder system
- **Status:** 65% complete, auto-generation not implemented
- **Decision:** DEFER - Complex feature, needs more testing

---

### ❌ NOT IN SCOPE (Phase 2+)

**Bank Integration:**
- ❌ Plaid/TrueLayer connection
- ❌ Automatic transaction import
- **Timeline:** Phase 2 (3-6 months)

**Multi-Currency:**
- ❌ Currency conversion
- ❌ FX rate tracking
- **Timeline:** Phase 2 (3-6 months)

**Advanced Features:**
- ❌ Shared/joint wallets
- ❌ Subscription manager (detect recurring charges)
- ❌ API & plugin system
- ❌ Community features
- **Timeline:** Phase 3 (6-12 months)

---

## 🎯 BETA LAUNCH PLAN

### **Week 1: Critical Fixes & Core Testing**

**Monday (Today):**
- [ ] Apply Migration 31 (15 min)
- [ ] Configure Sentry DSN (5 min)
- [ ] Test payment flow (30 min)
- [ ] Test receipt scanning (15 min)

**Tuesday-Wednesday:**
- [ ] Physical device testing - iOS (2-3 hours)
- [ ] Fix any critical bugs found
- [ ] Create TestFlight build

**Thursday:**
- [ ] Invite 20-50 beta testers (friends, family, colleagues)
- [ ] Send beta testing guide
- [ ] Monitor Sentry for crash reports

**Friday:**
- [ ] Collect beta feedback
- [ ] Triage bugs (critical vs nice-to-have)
- [ ] Plan V1.1 features based on user requests

---

### **Week 2: Iterate & Expand**

**Monday-Tuesday:**
- [ ] Fix critical bugs from beta
- [ ] Improve based on feedback
- [ ] Test on Android (if Java environment fixed)

**Wednesday:**
- [ ] Expand to 100-200 beta users
- [ ] A/B test onboarding flow (if time permits)

**Thursday-Friday:**
- [ ] Monitor analytics & crash reports
- [ ] Decide on V1.1 feature priority
- [ ] Prepare for public launch (if beta stable)

---

### **Week 3-4: Public Launch Prep**

**Tasks:**
- [ ] App Store submission (iOS)
- [ ] Play Store submission (Android - if ready)
- [ ] Marketing materials (screenshots, description)
- [ ] Launch announcement (social media, email list)
- [ ] Support system setup (email, in-app chat)

---

## 📈 SUCCESS METRICS

### **Beta Launch (Week 1-2):**
- **Target:** 50 beta users
- **Key Metrics:**
  - Signup completion rate
  - Daily active users (DAU)
  - Transactions created per user
  - Budgets created per user
  - Premium upgrade rate
  - Crash-free rate (target: 99%+)

### **Public Launch (Week 3+):**
- **Target:** 500-1000 users (Month 1)
- **Key Metrics:**
  - 7-day retention rate (target: 40%+)
  - 30-day retention rate (target: 20%+)
  - Premium conversion rate (target: 3-5%)
  - NPS score (target: 50+)

---

## 🚨 LAUNCH BLOCKERS

### **CANNOT LAUNCH WITHOUT:**

1. ⚠️ **Migration 31 applied** - Subscription system won't work
2. ⚠️ **Payment flow tested** - Can't charge users if broken
3. ⚠️ **Physical device testing** - Simulator doesn't catch all bugs

### **CAN LAUNCH WITHOUT (But Not Recommended):**

1. ℹ️ Sentry DSN - Won't have error tracking (risky)
2. ℹ️ Android build - Can do iOS-only beta first
3. ℹ️ AI Insights - Core app works without it
4. ℹ️ Bill Splitting - Can add in V1.1

---

## ✅ READY TO LAUNCH WHEN:

- [x] Flutter analyze shows zero issues ✅
- [ ] Migration 31 applied ⚠️ **DO THIS TODAY**
- [ ] Sentry DSN configured ℹ️ **Strongly recommended**
- [ ] Payment flow tested end-to-end ⏳
- [ ] Tested on physical iOS device ⏳
- [ ] Zero critical bugs ⏳
- [ ] TestFlight build created ⏳

---

## 📞 NEED HELP?

**Resources:**
- Supabase Dashboard: https://supabase.com/dashboard/project/YOUR_PROJECT_ID
- Stripe Dashboard: https://dashboard.stripe.com/test/dashboard
- Sentry Dashboard: https://sentry.io (after signup)

**Common Issues:**
- Edge function errors → Check Supabase function logs
- Payment issues → Check Stripe webhook events
- Database issues → Check Supabase table editor & RLS policies

---

**Current Status:** 🟡 **2 of 4 critical tasks complete**
**Next Action:** 🎯 **Apply Migration 31** (your manual action required)
**Timeline:** 🚀 **3-5 days to beta launch** (after Migration 31)

---

*Last updated: November 28, 2025*
*Review after: Migration 31 applied + payment testing complete*
