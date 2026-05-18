# Finmate — Android Release Roadmap

**Target:** Google Play Store  
**Package:** `com.chebli.finmate`  
**Min SDK:** 24 (Android 7.0) · **Target SDK:** 35 · **compileSdk:** 36  
**Build config:** Gradle 8.11.1 · AGP 8.9.1 · Kotlin 2.1.0

---

## Phase 1 — Pre-Release Fixes

- [x] Add `CAMERA` permission to `AndroidManifest.xml`
- [x] Simplify `MainActivity.kt` (remove native ad factory)
- [x] Delete `FinmateNativeAdFactory.kt`
- [x] Delete `android/app/src/main/res/layout/finmate_native_ad.xml`
- [x] Remove dead `_testNativeAndroid` / `_testNativeIos` constants from `lib/core/services/ad_service.dart`
- [x] Fix adaptive app icon — remove 16% inset, add `ic_launcher_round.xml`
- [x] Fix launch screen — teal background (`#3A8080`) with centered icon (matches iOS)
- [x] Bump `compileSdk` to 36 (required by `androidx.core:core-ktx:1.17.0`)
- [x] Enable core library desugaring (required by `flutter_local_notifications`)
- [x] Remove `id("kotlin-android")` — migrated to Flutter built-in Kotlin

---

## Phase 2 — Emulator UI Audit (Pixel 8 Pro · Android 15)

Run the app:
```bash
flutter emulators --launch Pixel_8_Pro
flutter run -d emulator-5554
```

- [ ] Launch screen: teal background + centered icon
- [ ] Login / signup flow
- [ ] Biometric auth prompt appears correctly
- [ ] Dashboard — all cards render, carousel pages smoothly
- [ ] Transactions list — scroll, filter, add/edit/delete
- [ ] Receipt scanner — camera opens, OCR works
- [ ] CSV import — file picker opens
- [ ] Budgets page
- [ ] Debt payoff page
- [ ] Savings goals page
- [ ] Recurring transactions page
- [ ] Profile — edit photo (camera + gallery)
- [ ] Settings — notifications, display, data privacy
- [ ] AdMob banner renders without error
- [ ] Notifications page
- [ ] Bottom nav not cut off by gesture bar
- [ ] Keyboard doesn't obscure input fields
- [ ] Arabic locale — RTL layout correct
- [ ] Dark mode — all screens correct

---

## Phase 3 — Build & Sign

**3.1 — Verify keystore is in place**

File: `android/key.properties` (gitignored)
```
storePassword=<password>
keyPassword=<password>
keyAlias=finmate
storeFile=<path>/finmate-release.jks
```

**3.2 — Analyze**
```bash
flutter analyze
```
Must return zero errors.

**3.3 — Build signed AAB**
```bash
flutter build appbundle
```
Output: `build/app/outputs/bundle/release/app-release.aab`

**3.4 — Test release build on emulator**
```bash
flutter run --release -d emulator-5554
```

---

## Phase 4 — Play Console Submission

**4.1 — Create the app**
- [Play Console](https://play.google.com/console) → Create app
- Package: `com.chebli.finmate` · Type: App · Category: Finance · Free

**4.2 — Upload AAB**
- Internal Testing track → upload `app-release.aab`

**4.3 — Store listing**
- [ ] App name: `Finmate`
- [ ] Short description (≤ 80 chars)
- [ ] Full description (≤ 4000 chars)
- [ ] Phone screenshots — min 2 at 1080×1920
- [ ] Feature graphic — 1024×500 PNG
- [ ] App icon — 512×512 PNG (use `assets/images/money_icon.png`)

**4.4 — Content rating**
- [ ] Complete questionnaire: Finance · no UGC · no mature content → **Everyone**

**4.5 — Data safety**
- [ ] Financial data (transactions, budgets, goals) — collected, not shared
- [ ] Account info (email) — collected, used for auth only
- [ ] App activity (analytics via Supabase) — collected, not shared

**4.6 — Privacy policy**
- [ ] Live, publicly accessible URL

**4.7 — App access**
- [ ] Provide test credentials for Google reviewers

**4.8 — Release track progression**
```
Internal Testing → Closed Testing → Open Testing → Production
```

---

## Phase 5 — Post-Launch

- [ ] Monitor Sentry for crash reports
- [ ] Monitor Play Console ANRs / crashes tab
- [ ] Respond to user reviews
- [ ] V1.1: Enable AI Insights route (currently dormant in `router.dart`)

---

## Known Warnings (non-blocking for now)

| Item | Current | Min Required |
|------|---------|-------------|
| Gradle | 8.11.1 | 8.14.0 (future) |
| AGP | 8.9.1 | 8.11.1 (future) |
| Kotlin | 2.1.0 | 2.2.20 (future) |

> These are deprecation warnings from Flutter beta. They are not currently breaking and will be resolved once the relevant third-party plugins (sentry_flutter, etc.) support Kotlin 2.2.20.
