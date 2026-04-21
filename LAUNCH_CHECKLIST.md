# Finmate Launch Checklist

**App Version:** 1.0.0+1  
**Target:** Beta → Public App Store Launch  
**Last updated:** 2026-04-15

---

## ✅ COMPLETED

| Item | Detail |
|---|---|
| `flutter analyze` — zero issues | All code changes clean |
| Security: email validation | RFC regex via `Validators.email()` |
| Security: password cleared post-login | In success + catch |
| Security: login rate limiting | 5 failures → 15-min lockout |
| Security: login error feedback fix | `onChanged` vs `addListener` bug fixed |
| Security: Sentry in dashboard catch blocks | Silent errors now reported |
| Android build hardening | ProGuard + minification + shrinkResources |
| Font system | DM Sans via GoogleFonts, single source of truth |
| Dashboard performance | `getMonthlyFlowData` parallelised (~6× faster) |
| Emergency fund removal | All traces deleted |
| Debt payoff gamification | Streak, badges, milestone progress bars |
| Recurring transactions auto-gen | `processOverdue()` inserts real transactions, idempotent |
| Accessibility — Semantics labels | Login + Signup key fields/buttons wrapped |
| Customizable insights frequency | `aiInsightsFrequency` in settings entity, model, and UI |
| Community benchmarks | `CommunityBenchmarkCard` with stacked bars + color-coded status |
| "What if you paid extra?" bug fix | `hitMaxMonths` flag → two-panel display |
| TOTP column dropped | Verification count = 0, column dropped |
| Migration 31 applied | Subscription tier column live in `user_profiles` |
| Sentry DSN configured | DSN confirmed in `.env` |
| Payment flow | Deferred to V1.1 — no premium features in V1.0 |
| Signup errors fixed | Proper messages for duplicate account, rate limit, etc. |
| Cross-user data isolation | `userSessionProvider` pattern — all 10 repository providers updated |
| Admin route links fixed | Router re-evaluates after profile loads; optimistic allow while loading |

---

## ✅ READY TO SUBMIT WHEN:

- [x] `flutter analyze` — zero issues
- [x] All V1.0 features implemented
- [x] Critical bugs fixed
- [x] TOTP column dropped
- [x] Migration 31 applied
- [x] Sentry DSN configured
- [x] Apple Developer account active ✅
- [x] App ID + provisioning profile created ✅ com.chebli.finmate
- [x] Xcode signing configured ✅ Apple Distribution: Ahmed Chebli (LHVP55DRTQ)
- [ ] App icon — 1024×1024 no alpha ⏳ **→ Step 6**
- [x] Screenshots — 6.9" captured ✅ (5.5" skipped — App Store Connect uses 6.9" for all sizes)
- [x] App record created in App Store Connect ✅ "Finmate: Budget & Debt Tracker"
- [x] Privacy Policy URL live ✅ https://www.notion.so/Finmate-Privacy-Policy-348cdac35b0c80429096fac24972c5f8
- [x] App Store listing complete ✅ Description, keywords, subtitle, URLs, App Privacy declaration published
- [x] IPA built + uploaded to TestFlight ✅
- [ ] Physical iOS device testing passed ⏳ **→ Step 12**
- [ ] TestFlight external beta approved (optional) ⏳ **→ Step 13**
- [ ] Zero critical bugs from beta testing ⏳
- [ ] App Store submission submitted ⏳ **→ Step 14**

---

## SEQUENCE OVERVIEW

```
Step 1  → Apple Developer account ($99)
Step 2  → Register App ID in developer portal
Step 3  → Create Distribution Certificate
Step 4  → Create Provisioning Profile
Step 5  → Configure Xcode signing
Step 6  → Generate app icon (1024×1024, no alpha)
Step 7  → Take screenshots in Simulator
Step 8  → Create app record in App Store Connect
Step 9  → Write + publish Privacy Policy
Step 10 → Complete App Store listing (description, keywords, screenshots, privacy)
Step 11 → Build IPA + upload to TestFlight
Step 12 → Install on physical device + test all flows
Step 13 → External beta (optional, 1–2 weeks)
Step 14 → Submit for App Review
```

Steps 1–5 must be done in order. Steps 6–10 can be done in parallel once Step 1 is active. Steps 11–14 are sequential.

---

## STEP 1 — Apple Developer Account

**Blocker: everything below depends on this.**

1. Go to [developer.apple.com/enroll](https://developer.apple.com/enroll)
2. Sign in with your Apple ID → choose **Individual** ($99/year)
3. Pay the fee — approval is usually instant for individuals
4. Confirm you can log into [appstoreconnect.apple.com](https://appstoreconnect.apple.com)

- [ ] Account active and accessible

---

## STEP 2 — Register Your App ID

1. [developer.apple.com](https://developer.apple.com) → **Certificates, Identifiers & Profiles** → **Identifiers** → **+**
2. Select **App IDs** → **App** → Continue
3. Open your project: check `ios/Runner.xcodeproj` for `PRODUCT_BUNDLE_IDENTIFIER` (e.g. `com.yourname.finmate`)
4. Paste that exact value as the Bundle ID
5. Enable capabilities: **Push Notifications** (nothing else required for V1.0)
6. Register

- [ ] App ID registered with correct Bundle ID

---

## STEP 3 — Distribution Certificate

1. **Certificates** → **+** → **Apple Distribution**
2. On your Mac: open **Keychain Access** → menu **Keychain Access → Certificate Assistant → Request a Certificate from a Certificate Authority**
3. Enter your email, select **Saved to disk**, save the `.certSigningRequest` file
4. Upload that file on developer.apple.com → Download the resulting `.cer` file
5. Double-click the `.cer` to install it in Keychain

- [ ] Distribution certificate installed in Keychain

---

## STEP 4 — Provisioning Profile

1. **Profiles** → **+** → **App Store Connect**
2. Select your App ID → select your Distribution Certificate
3. Name it: `Finmate AppStore Distribution`
4. Download → double-click to install
5. Confirm it appears in Xcode → **Settings** → **Accounts** → your team

- [ ] Provisioning profile installed

---

## STEP 5 — Configure Xcode Signing

1. Open `ios/Runner.xcworkspace` in Xcode (not `.xcodeproj`)
2. Select **Runner** target → **Signing & Capabilities**
3. Set **Team** to your Apple Developer account
4. Set **Signing** to **Manual** → select `Finmate AppStore Distribution`
5. Verify Bundle Identifier matches what you registered
6. Build (`Cmd+B`) — confirm no signing errors

- [ ] Xcode builds with no signing errors

---

## STEP 6 — App Icon

Requirements: **1024×1024 px PNG, no alpha channel, no rounded corners** (iOS applies corners automatically).

**To check for alpha:** Open the PNG in Preview → Tools → Adjust Color — if there's an Alpha slider, re-export with alpha unchecked.

Once you have the image:

1. Place it at `assets/icon/app_icon.png`
2. Add to `pubspec.yaml` under the `flutter` section:
   ```yaml
   flutter_launcher_icons:
     android: true
     ios: true
     image_path: "assets/icon/app_icon.png"
   ```
3. Run:
   ```bash
   dart run flutter_launcher_icons
   ```
4. Confirm `ios/Runner/Assets.xcassets/AppIcon.appiconset/` has all sizes generated

- [ ] App icon generated, all sizes present, no alpha

---

## STEP 7 — Screenshots

Apple requires screenshots for every device size you support. **Minimum required:**

| Device | Resolution |
|---|---|
| 6.9" — iPhone 16 Pro Max | 1320×2868 px |
| 5.5" — iPhone 8 Plus | 1242×2208 px |

**How to take them (Simulator, not physical device):**

1. In Xcode → open Simulator → File → Open Simulator → select the device size
2. Run: `flutter run`
3. Navigate to each screen → **Cmd+S** in Simulator → screenshot saves to Desktop
4. Repeat for the other device size

**Screens to capture (5–8 per device size):**

- [ ] Dashboard — net worth card + cash flow chart
- [ ] Transactions list — populated with data
- [ ] Add Transaction screen
- [ ] Budgets — with progress bars
- [ ] Debt Payoff — milestone card + extra payment slider
- [ ] AI Insights — community benchmarks card
- [ ] Dark mode version of Dashboard
- [ ] Login screen (optional)

**Optional but recommended:** Add text overlays in Canva or Figma (e.g. "Track every dollar", "Crush your debt faster") — improves App Store conversion significantly.

- [x] Screenshots taken for 6.9" device
- [x] Screenshots taken for 5.5" device (skipped — 6.9" covers all sizes)

---

## STEP 8 — Create App Record in App Store Connect

1. [appstoreconnect.apple.com](https://appstoreconnect.apple.com) → **My Apps** → **+** → **New App**
2. Fill in:
   - **Platform:** iOS
   - **Name:** Finmate (max 30 chars — this is the public App Store name)
   - **Primary Language:** English
   - **Bundle ID:** select the one you registered
   - **SKU:** `finmate-ios-v1` (internal only, never shown publicly)
3. **App Information** → Category: **Finance** (Primary), **Productivity** (Secondary)
4. **Age Rating:** complete the questionnaire → should land at **4+**
5. **Pricing:** Free

- [ ] App record created in App Store Connect

---

## STEP 9 — Privacy Policy

Apple rejects apps without a publicly accessible Privacy Policy URL.

**Quickest option — Notion:**

1. Create a new Notion page and paste:
   ```
   Privacy Policy for Finmate
   Last updated: [date]

   We collect: email address (for account login), financial transaction data
   (entered manually by you), crash reports (via Sentry).

   We do not sell your data. We do not share your data with third parties
   except Sentry (crash reporting).

   Your data is stored securely via Supabase (cloud database).

   To request data deletion, email: [your@email.com]
   ```
2. Click **Share** → **Publish to web** → copy the public URL

**Alternative:** [termsfeed.com](https://www.termsfeed.com/privacy-policy-generator/) — free generator, 2 minutes.

- [x] Privacy Policy published and URL accessible

---

## STEP 10 — Complete the App Store Listing

In App Store Connect → your app → **App Store** tab:

### Description
```
Take control of your finances with Finmate — the personal finance app that helps you track spending, crush debt, and hit your savings goals.

TRACK EVERYTHING
• Log income, expenses, and transfers across multiple accounts
• Categorize transactions and search your full history

BUDGET SMARTER
• Set monthly budgets by category
• Get alerted before you overspend
• See exactly where your money goes

DEBT PAYOFF
• Avalanche or Snowball strategy — you choose
• See exactly how much interest you save with extra payments
• Track your streak and milestones as you pay down debt

INSIGHTS
• Spending breakdown by category
• Community benchmarks — see how you compare

YOUR DATA, YOUR PRIVACY
• All data stored securely in the cloud
• Biometric login (Face ID / Touch ID)
• Two-factor authentication (TOTP + email OTP)
• No bank account linking required — full manual control
```

### Keywords (100 chars max, no spaces after commas)
```
budget,finance,money,expense,debt,savings,tracker,spending,income,cashflow,payoff
```

### Subtitle (max 30 chars)
```
Personal Finance & Budgeting
```

### Remaining fields
- **Support URL:** your privacy policy URL (or a simple landing page)
- **Privacy Policy URL:** from Step 9
- **Screenshots:** upload from Step 7 — match each screenshot set to the correct device size slot

### App Privacy Declaration
App Store Connect → your app → **App Privacy** → **Get Started**

| Data type | Collected | Used for tracking |
|---|---|---|
| Email address | Yes — account login | No |
| Financial info (transaction amounts) | Yes — user-entered | No |
| Crash data | Yes — Sentry | No |
| Everything else | No | No |

- [x] Description pasted
- [x] Keywords filled in
- [x] Support URL + Privacy Policy URL entered
- [x] Screenshots uploaded for all required device sizes
- [x] App Privacy declaration completed
- [x] Age rating completed (4+)
- [x] Pricing set to Free

---

## STEP 11 — Build IPA + Upload to TestFlight

### Build
```bash
flutter clean
flutter pub get
flutter build ipa --release
```

Output: `build/ios/ipa/finmate.ipa`

**Increment build number before each upload** (`pubspec.yaml`):
```yaml
version: 1.0.0+1   # increment the +N each upload, e.g. +2, +3
```

### Upload (pick one method)

**Option A — Transporter (easiest):**
1. Download [Transporter](https://apps.apple.com/app/transporter/id1450874784) (free, Mac App Store)
2. Drag and drop the `.ipa` file
3. Click Deliver

**Option B — Xcode Organizer:**
1. Open `ios/Runner.xcworkspace`
2. Select **Any iOS Device** as the target (not a simulator)
3. **Product → Archive**
4. **Organizer → Distribute App → App Store Connect → Upload**

Wait 5–15 minutes for Apple to process. Build appears under the **TestFlight** tab.

- [x] IPA built successfully
- [x] Build uploaded and visible in TestFlight

---

## STEP 12 — Physical Device Testing

Install via TestFlight on a physical iPhone (iOS 15+).

### Internal TestFlight Setup
1. App Store Connect → **TestFlight** → **Internal Testing** → **+**
2. Add yourself by Apple ID (must be in your developer team)
3. Select the build → Save
4. You get an email → install via the TestFlight app

### Full Test Checklist

**Auth flows:**
- [ ] Sign up with new email → confirmation email received → OTP verified → lands on dashboard
- [ ] Login with correct credentials
- [ ] Login with wrong password → error shown, field not cleared
- [ ] 5 wrong passwords → rate limit message → 15-min lockout enforced
- [ ] Forgot Password → email received → can reset
- [ ] Face ID / Touch ID login
- [ ] MFA with TOTP (if configured)
- [ ] Sign out → data cleared → login as different user → sees only their own data

**Transactions:**
- [ ] Add income transaction
- [ ] Add expense transaction with category
- [ ] Add transfer between accounts
- [ ] Edit existing transaction
- [ ] Delete transaction
- [ ] Search + filter transactions
- [ ] Pull-to-refresh updates the list

**Budgets:**
- [ ] Create budget for a category
- [ ] Add expense in that category → budget progress updates
- [ ] Over-budget alert appears when spending exceeds budget

**Debt Payoff:**
- [ ] Add a debt
- [ ] View Avalanche / Snowball strategy switch
- [ ] Extra payment slider → recalculates correctly
- [ ] Log a payment → milestone card updates
- [ ] Streak counter increments

**Recurring Transactions:**
- [ ] Navigate to Recurring Transactions page → overdue ones auto-generate
- [ ] No duplicates on second visit

**Settings & Profile:**
- [ ] Edit profile — name, currency saves
- [ ] Change password in Security Settings
- [ ] Dark mode toggle applies immediately across all screens
- [ ] Language preference saves
- [ ] AI Insights frequency dropdown saves

**Admin (if applicable):**
- [ ] Admin section visible in Profile for admin accounts
- [ ] User Management, System Analytics, System Settings links navigate correctly

**General:**
- [ ] Dark mode renders correctly on all main screens
- [ ] Keyboard does not overlap input fields on any screen
- [ ] Pull-to-refresh works on Dashboard, Transactions, Budgets
- [ ] Airplane mode → offline indicator shown → back online → data syncs
- [ ] App does not crash after 10+ minutes of use

- [ ] All test flows passed on physical device

---

## STEP 13 — External Beta (Optional)

Recommended if you want feedback before public launch. Adds 1–2 weeks but catches real-world issues.

1. TestFlight → **External Groups** → **+** → create group "Beta Testers"
2. Add the build → **Submit for Beta App Review**
3. First review takes 1–2 days; subsequent builds same day
4. Share the public TestFlight link with testers
5. Collect and address critical feedback before Step 14

- [ ] Beta review approved
- [ ] At least 5–10 testers installed and tested
- [ ] Zero critical bugs reported

---

## STEP 14 — Submit for App Review

Once testing passes:

1. App Store Connect → your app → **iOS App** → **Build** → **+** → select the TestFlight build that passed testing
2. Fill in **Review Notes:**
   ```
   Test account credentials:
   Email: testuser@finmate.app
   Password: TestPass123!

   Note: This app does not connect to bank accounts.
   All financial data is entered manually by the user.
   No real financial transactions are processed in this version.
   ```
3. Click **Add for Review** → **Submit to App Review**
4. Export compliance: **Yes, standard encryption** (HTTPS only)
5. Advertising identifier: **No**
6. Status changes to "Waiting for Review"

### Review Timeline
- First submission: **1–3 days**
- Updates: usually **24 hours**, often same day
- Expedited review: available at developer.apple.com/contact/app-store for critical fixes

### Common Rejection Reasons for Finance Apps
| Rejection reason | Fix |
|---|---|
| Missing privacy policy | Add URL, resubmit |
| Placeholder content or broken flows | Fix and resubmit |
| Misleading screenshots | Update screenshots |
| Missing functionality description | Clarify in Review Notes |

- [ ] Build attached to submission
- [ ] Review Notes filled in
- [ ] Submitted for App Review
- [ ] Approved and live on App Store

---

## PHASE 8 — Post-Launch

### Monitor Crash Reports
- Sentry dashboard: check within first 24 hours
- Focus on: auth flow, transaction creation, database errors

### Monitor App Store Reviews
- App Store Connect → **Ratings and Reviews**
- Respond to every review in the first week — Apple factors response rate into ranking

### Watch Key Metrics (First 7 Days)
- Crash-free rate: target 99%+
- Avg session length
- Transactions created per user
- Day-1 and Day-7 retention

---

## DEFERRED TO V1.1

| Feature | Status |
|---|---|
| Premium subscription + payment flow | Deferred — no premium features in V1.0 |
| AI Insights frequency enforcement | UI saves, enforcement logic pending |
| Adaptive onboarding (persona-driven) | Not started |
| TOTP MFA backup codes | Not in MVP scope |
| CSV import for transactions | Not started |
| Data export (CSV/PDF) | Not started |
| Expanded Semantics coverage | Auth screens done, rest pending |
| Test coverage (target 60%) | Currently ~20% |
| CI/CD pipeline | Not started |
| Bank integration (Plaid/TrueLayer) | Phase 2 |
| Multi-currency | Phase 2 |
| Android public release | After iOS beta is stable |
