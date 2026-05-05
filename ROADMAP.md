# Finmate — Implementation Roadmap
> Goal: $3k–10k/mo MRR within 12 months. iOS-first, bootstrapped.
> Rule: Check off each item before moving to the next sprint.

---

## SPRINT 1 — Fix the Product ✅ COMPLETE
> Unlock the differentiators. No user who downloads today should hit a dead end.

### 1.1 Enable AI Insights ✅
- [x] Uncomment `/insights` route import in `lib/core/config/router.dart`
- [x] Uncomment the `/insights` GoRoute block in `router.dart`
- [x] Added `_AiInsightsCard` to dashboard (below Money Health Score) — navigates to `/insights`
- [x] 10 free query gate already live in `lib/core/providers/ai_query_limit_provider.dart`

### 1.2 Kill the Ads ✅
- [x] Commented out `AdBannerWidget` in `lib/features/dashboard/presentation/pages/dashboard_page.dart`
- [x] Commented out interstitial call + preload in `lib/core/config/router.dart`
- [x] RE-ENABLE comments in place for when DAU > 1,000 and 30-day retention > 20%

### 1.3 Fix "Coming Soon" CTAs ✅
- [x] `lib/shared/widgets/premium_feature_dialog.dart` — button now says "Upgrade to Premium", wired to `onUpgradePressed` callback
- [x] `lib/features/ai_insights/presentation/pages/ai_insights_page.dart` — "coming soon" snackbar replaced with `TODO Sprint 2` RevenueCat hook

---

## SPRINT 2 — Activate the Paywall (RevenueCat)
> Money must be able to change hands. Nothing else matters until this works.
> **Time estimate: 3–5 days**

### 2.1 App Store Connect Setup ✅
- [x] Created Subscription Group: "Finmate Premium"
- [x] Created product: `finmate_premium_monthly` — $9.99/month, 7-day free trial
- [x] Created product: `finmate_premium_annual` — $49.99/year, 7-day free trial
- [x] Annual set as featured/default product in the group

### 2.2 RevenueCat Dashboard Setup
- [ ] Create account at revenuecat.com
- [ ] Create new App → iOS → paste App Store Connect Shared Secret
- [ ] Create Offering: `default` with both monthly + annual packages
- [ ] Create Entitlement: `premium` → attach both products to it
- [ ] Copy the RevenueCat public SDK key (needed in code)

### 2.3 Flutter Integration
- [ ] Add `purchases_flutter: ^6.x.x` to `pubspec.yaml`
- [ ] Run `flutter pub get`
- [ ] Initialize RevenueCat in `lib/main.dart` (after Supabase init):
  ```dart
  await Purchases.configure(PurchasesConfiguration('<RC_PUBLIC_KEY>'));
  ```
- [ ] On login in `lib/features/auth/presentation/providers/auth_providers.dart`, call:
  ```dart
  await Purchases.logIn(supabase.auth.currentUser!.id);
  ```
- [ ] On logout, call `await Purchases.logOut()`

### 2.4 Replace `isPremiumProvider`
- [ ] Open `lib/core/providers/subscription_provider.dart`
- [ ] Replace Stripe stub with RevenueCat call:
  ```dart
  final isPremiumProvider = FutureProvider<bool>((ref) async {
    final info = await Purchases.getCustomerInfo();
    return info.entitlements.active.containsKey('premium');
  });
  ```

### 2.5 Wire the Upgrade Flow
- [ ] Open `lib/shared/widgets/premium_feature_dialog.dart`
- [ ] Connect "Upgrade" CTA to RevenueCat purchase:
  ```dart
  final offerings = await Purchases.getOfferings();
  final package = offerings.current?.annual ?? offerings.current?.monthly;
  await Purchases.purchasePackage(package!);
  ref.invalidate(isPremiumProvider);
  ```
- [ ] On successful purchase: update `user_profiles.subscription_tier = 'premium'` in Supabase
- [ ] Test full flow: free user → hits AI limit → taps upgrade → completes purchase (sandbox) → AI unlocks

### 2.6 Paywall UI (upgrade dialog)
- [ ] Show annual price FIRST with "Most Popular" badge
- [ ] Headline: "Unlock Finmate Premium"
- [ ] CTA: "Start 7-Day Free Trial"
- [ ] Fine print: "Cancel anytime. Billed through the App Store."
- [ ] 3 benefit bullets: Unlimited AI · Receipt scanning · Document storage

### 2.7 Restore Purchases
- [ ] Add "Restore Purchase" link in `lib/features/profile/presentation/pages/profile_page.dart`
- [ ] Wire to `await Purchases.restorePurchases()` then `ref.invalidate(isPremiumProvider)`
- [ ] **Required by App Store guidelines — will cause rejection if missing**

### 2.8 Enable Receipt Scanning for Premium
- [ ] Remove the "Coming Soon" gate from receipt scanning
- [ ] Wrap behind `isPremiumProvider` — premium users go straight to scanner, free users see upgrade dialog
- [ ] Test: free user → taps scan → upgrade dialog. Premium user → taps scan → camera opens.

---

## WEBSITE — Marketing Page Updated ✅ COMPLETE
> `landing/index.html` deployed at https://get-finmate.netlify.app/

- [x] Meta description updated to reflect iOS-only, AI-powered positioning
- [x] Schema.org: removed Android from `operatingSystem`, updated pricing offers
- [x] Hero: "Free on iOS · AI-Powered" kicker, Google Play button removed
- [x] Stat strip: updated free tier messaging to reflect premium upsell
- [x] AI Insights card: "Coming to V1.1" → "✓ Available now — 10 free questions/month"
- [x] AI mockup status: "Beta Preview" → "Live"; blur overlays removed
- [x] FAQ: "Is it free?" updated with $9.99/mo · $49.99/yr · 7-day trial pricing
- [x] FAQ: "When is AI Insights coming?" → "How does AI Insights work?" (live description)
- [x] FAQ: Android answer updated to iOS-only with Android on roadmap
- [x] FAQ: Security answer — removed technical jargon (Supabase, row-level security)
- [x] CTA section: Google Play button removed, iOS-only messaging
- [x] Footer: Google Play button removed, "AI Insights (soon)" → "AI Insights"
- [x] JSON-LD FAQ schema updated to match all FAQ changes

---

## SPRINT 3 — App Store Optimization
> Passive organic discovery. One-time effort, permanent return.
> **Time estimate: 1 day**

- [ ] Update app **Name**: `Finmate: Budget & Debt Tracker` (30 char limit)
- [ ] Update **Subtitle**: `AI Finance & Expense Planner` (30 char limit)
- [ ] Update **Keywords** (100 chars): `budget tracker,expense tracker,debt payoff,money manager,personal finance,spending tracker,YNAB`
- [ ] Update **Description** opening lines (shown before "more"): *"Track your money, pay off debt, and get AI-powered financial insights — without linking your bank account."*
- [ ] Redo **Screenshots** in this order:
  1. Money Health Score
  2. AI Insights chat
  3. Debt Payoff timeline
  4. Dashboard net worth
  5. Receipt scanner
- [ ] Each screenshot: bold 3–5 word caption at the top (tool: Previewed.app)
- [ ] Submit updated listing with next app version

---

## SPRINT 4 — Email Onboarding Sequence
> Get users to day 21. That's when habit forms and churn drops.
> **Time estimate: 1–2 days**

- [ ] Create account on Brevo (free up to 300 emails/day)
- [ ] Set up automation trigger: new user signup → enters sequence
- [ ] Write and schedule 5 emails:

| # | Send day | Subject | Goal |
|---|---|---|---|
| 1 | Day 1 | "Welcome to Finmate — start here" | First transaction |
| 2 | Day 3 | "You added transactions — here's what that reveals" | Show value |
| 3 | Day 7 | "Your Money Health Score is ready" | Drive back to app |
| 4 | Day 14 | "Two weeks in — your spending pattern" | Show category insight |
| 5 | Day 30 | "One month of financial clarity" | Soft premium upsell |

- [ ] Connect Supabase auth (new user created) → Brevo contact via webhook or Edge Function
- [ ] Test the full sequence end-to-end with a test account

---

## SPRINT 5 — Distribution
> Get strangers to find and download the app.

### 5A: Reddit (Week 3)
- [ ] Choose angle (pick one for first post):
  - "After Mint shut down I built the privacy-respecting replacement — here's what I learned"
  - "Avalanche vs Snowball on $X of debt — the interest difference will surprise you"
  - "I tracked every expense manually for 30 days — here's my honest breakdown"
- [ ] Write post (genuine story, Finmate screenshots as evidence, app mention once at end)
- [ ] Post in r/personalfinance or r/YNAB — Tuesday–Thursday 8–10am US Eastern
- [ ] Reply to every comment within 24 hours

### 5B: Product Hunt (Week 3–4)
- [ ] Find a hunter with 500+ PH followers to post on your behalf
- [ ] Write tagline: *"The personal finance app that doesn't need your bank password"*
- [ ] Prepare: 5 screenshots, 30-sec GIF demo, maker comment
- [ ] Set up PH-exclusive offer: "3 months premium for $9.99"
- [ ] Brief 20+ supporters to upvote + comment in the first 2 hours
- [ ] Launch: Tuesday or Wednesday at 12:01am US Pacific Time

### 5C: Micro-Influencer Outreach (Month 2)
- [ ] Find 20 personal finance creators on TikTok/Instagram (10k–150k followers, >3% engagement)
  - Search: "budget with me," "debt free journey," "cash stuffing," "no buy month"
- [ ] Send personalized DM to each (template in the strategy doc)
- [ ] Track responses — follow up once after 5 days if no reply
- [ ] Goal: 3–5 creators try the app and post organically

### 5D: TikTok / Instagram Reels (Month 2 — ongoing)
- [ ] Set up TikTok and Instagram accounts: @finmateapp (or similar)
- [ ] Record first video: founder story — "why I built this" (phone camera, natural light, CapCut)
- [ ] Post 3x/week minimum — no exceptions for 90 days
- [ ] Cross-post every video to TikTok + Instagram Reels + YouTube Shorts
- [ ] **Do not evaluate results before day 90**

### 5E: Apple Search Ads (Month 3)
- [ ] Only start after RevenueCat shows first paying users
- [ ] Set up Apple Search Ads account (searchads.apple.com)
- [ ] Basic campaign: bid on `YNAB`, `Copilot`, `Monarch`, `Mint`, `PocketGuard`
- [ ] Keyword campaign: `budget tracker`, `expense tracker`, `debt payoff app`, `AI finance app`
- [ ] Budget: $5/day. Scale what converts.

---

## Success Metrics

| Metric | Week 4 | Month 3 | Month 12 |
|---|---|---|---|
| Downloads | 100 | 500 | 5,000 |
| 30-day retention | — | >15% | >25% |
| Free → Premium conversion | — | >3% | >5% |
| Paying users | 1 | 15 | 700 |
| MRR | $10 | $150 | $5,000+ |
| App Store rating | 4.5+ | 4.7+ | 4.7+ |

---

## Competitive Positioning — Own This Line

> **"The AI-powered personal finance app built for people who don't trust banks with their passwords."**

Use it in: App Store description · Reddit posts · Product Hunt · TikTok hooks · influencer briefs.

---

## Pricing

| Plan | Price | Trial |
|---|---|---|
| Free | $0 | — |
| Premium Monthly | $9.99/mo | 7 days |
| Premium Annual | $49.99/yr | 7 days |

**Always show annual first.** Annual users churn at 3x lower rate.
**Founding member offer:** "Lock in $49.99/yr forever — offer ends [today + 30 days]"
