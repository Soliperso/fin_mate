# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**FinMate** is a cross-platform financial management app built with Flutter, combining personal finance tracking, bill splitting, and AI-powered forecasting. This is currently a greenfield project in its initial setup phase.

## Key Commands

### Development
```bash
# Run the app in development mode
flutter run

# Run on specific device
flutter run -d <device_id>

# Hot reload: Press 'r' in the terminal
# Hot restart: Press 'R' in the terminal

# Run with specific build flavor (when implemented)
flutter run --flavor dev
```

### Testing
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Run tests with coverage
flutter test --coverage
```

### Code Quality
```bash
# Analyze code for issues
flutter analyze

# Format code
dart format .

# Check for outdated dependencies
flutter pub outdated
```

### Building
```bash
# Build for Android
flutter build apk
flutter build appbundle

# Build for iOS
flutter build ios
flutter build ipa

# Build for web
flutter build web
```

### Dependencies
```bash
# Get dependencies
flutter pub get

# Upgrade dependencies
flutter pub upgrade
```

## Architecture & Design

### Tech Stack (Planned)
- **Framework**: Flutter with Material 3 design system
- **State Management**: Riverpod or Bloc (TBD)
- **Routing**: GoRouter
- **Backend**: Supabase (Auth, Postgres, Storage)
- **Local Storage**: Hive/Isar with AES-256 encryption
- **External APIs**:
  - Plaid/TrueLayer for bank integration
  - OpenAI for AI insights
  - Stripe/PayPal for settlements

### Planned Module Structure
The codebase will follow a feature-first architecture:

```
lib/
├── core/           # Shared utilities, constants, themes
├── features/       # Feature modules (auth, dashboard, bills, etc.)
│   ├── auth/
│   ├── dashboard/
│   ├── bill_splitting/
│   ├── budgets/
│   └── ai_insights/
├── shared/         # Shared widgets and services
└── main.dart
```

### Color System
The app uses a professional fintech color palette:
- **Primary**: Deep Navy (#1A2B4C), Emerald Green (#2ECC71)
- **Secondary**: Royal Purple (#6C5CE7), Teal Blue (#00CEC9)
- **Neutral**: Light Gray (#F5F7FA), White (#FFFFFF), Charcoal (#2D3436)
- **Status**: Success (#27AE60), Warning (#F39C12), Error (#E74C3C)

### Typography
- Primary font: Inter or Poppins
- Bold, high-contrast numbers for financial displays

## Security Requirements

This is a financial app with strict security requirements:

### Authentication & Authorization
- Implement MFA (SMS/email OTP + TOTP)
- Support biometric login via `local_auth` package
- Use Supabase Auth with JWT tokens
- Implement RBAC for shared wallets

### Data Protection
- **Local Storage**: All sensitive data must be encrypted using Hive/Isar encryption
- **Network**: All API calls must use TLS 1.3
- **Sensitive Data**: Never log API keys, tokens, or financial data
- **PII Handling**: Follow GDPR/CCPA guidelines

### Banking Integration
- Use OAuth2 with Plaid/TrueLayer (never store credentials)
- Implement rate limiting for API calls
- Add input validation for all financial transactions

## Development Guidelines

### Code Organization
- Use feature-first folder structure once features are implemented
- Keep business logic separate from UI code
- Use dependency injection for testability

### State Management
- When implementing state management, use either Riverpod or Bloc consistently
- Keep state immutable
- Handle loading, error, and success states explicitly

### UI/UX Standards
- Follow Material 3 design guidelines
- Support both light and dark themes
- Ensure accessibility (screen readers, color contrast)
- Keep critical financial flows to ≤3 steps
- Use rounded cards with soft shadows for visual consistency

### Testing Requirements
- Write widget tests for all UI components
- Write unit tests for business logic
- Integration tests for critical flows (auth, transactions)
- Mock external API calls in tests

## MVP Phase Features (0-3 months)

1. **Authentication & Onboarding**
   - Supabase auth integration
   - MFA and biometric login
   - User onboarding flow

2. **Dashboard**
   - Net worth overview
   - Monthly cash flow visualization
   - Upcoming bills timeline
   - "Money Health" score

3. **Bill Splitting**
   - Group creation for roommates/trips
   - Expense entry with multiple split methods
   - Balance tracking
   - Manual settlement records

4. **AI Insights**
   - Weekly spending digest
   - Basic categorization
   - Simple recommendations

## Important Context

- **Project Status**: Early stage - currently has only Flutter boilerplate code
- **Target SDK**: Dart 3.10.0-162.1.beta or higher
- **Platforms**: iOS, Android, Web (in order of priority)
- **Monetization**: TBD (freemium vs subscription)
- **Primary Market**: US initially (Plaid integration), then EU/UK

## Dependencies Management

Current dependencies are minimal. When adding new packages:
- Verify compatibility with Flutter 3.x
- Check package maintenance status and popularity
- Ensure packages support all target platforms
- Review security advisories for financial-related packages

## Performance Considerations

- Optimize for 60fps animations
- Implement pagination for transaction lists
- Use lazy loading for charts and visualizations
- Cache API responses appropriately
- Implement offline-first architecture for core features
