# App Store Connect - App Privacy Details

**Document Version:** 1.0
**Last Updated:** October 21, 2025
**App Name:** FinMate
**Bundle ID:** com.finmate.app
**Platform:** iOS

---

## Overview

This document provides the comprehensive privacy details required for App Store Connect submission and compliance with Apple's App Privacy Policy requirements.

---

## 1. Privacy Policy Link

**Privacy Policy URL:** https://finmate.app/privacy-policy

**Privacy Policy Availability:**
- Published on official website
- Linked in-app (Settings → Privacy Policy)
- Available during onboarding

---

## 2. Data & Privacy - Nutrition Label

### 2.1 Data Collection Summary

| Data Type | Collected | Shared with Third Parties | Linked to User | Tracking |
|-----------|-----------|--------------------------|-----------------|----------|
| Email Address | Yes | Yes (Backend) | Yes | No |
| Name | Yes | Yes (Backend) | Yes | No |
| User ID | Yes | Yes (Backend) | Yes | No |
| Financial Information | Yes | No | Yes | No |
| Device Information | Yes | Yes (Analytics) | No | No |
| Usage Data | Yes | Yes (Analytics) | No | No |
| Precise Location | No | No | N/A | No |
| Approximate Location | No | No | N/A | No |
| Photos/Videos | Optional | No | Yes | No |
| Contact Information | Optional | No | Yes | No |
| Search History | No | No | N/A | No |
| Browsing History | No | No | N/A | No |
| Product Interaction | Yes | No | No | No |
| Health/Fitness | No | No | N/A | No |
| Payment Information | No | No | N/A | No |
| Credentials | Yes | Yes (Backend) | Yes | No |
| Other Sensitive Info | Yes | No | Yes | No |

---

## 3. Data Types Collected

### 3.1 Contact Information

**Email Address**
- Purpose: Account creation, authentication, notifications
- Required: Yes
- Linked to User ID: Yes
- Tracking: No
- Third-Party Sharing: Yes (Supabase backend)
- Optional/Required: Required

**Name**
- Purpose: User profile, personalization
- Required: Yes
- Linked to User ID: Yes
- Tracking: No
- Third-Party Sharing: Yes (Supabase backend)
- Optional/Required: Required

**Phone Number**
- Purpose: Optional MFA, notifications
- Required: No
- Linked to User ID: Yes
- Tracking: No
- Third-Party Sharing: Yes (Supabase backend)
- Optional/Required: Optional

**Photo**
- Purpose: User avatar/profile picture
- Required: No
- Linked to User ID: Yes
- Tracking: No
- Third-Party Sharing: Yes (Supabase backend)
- Optional/Required: Optional

### 3.2 User IDs

**Unique Identifier (Account UUID)**
- Purpose: Account identification, data association
- Required: Yes
- Linked to User ID: Yes
- Tracking: No
- Third-Party Sharing: Yes (Backend)
- Optional/Required: Required (automatic)

**Device Identifier (UDID)**
- Purpose: Device tracking, security, analytics
- Required: No
- Linked to User ID: No (anonymized)
- Tracking: No
- Third-Party Sharing: Yes (Analytics)
- Optional/Required: Required (automatic)

### 3.3 Financial Information

**Account Details**
- Purpose: Financial tracking, account management
- Data: Account names, types, balances (not account numbers)
- Required: Yes (for functionality)
- Linked to User ID: Yes
- Tracking: No
- Third-Party Sharing: No
- Optional/Required: Required (user-provided)

**Transaction Data**
- Purpose: Expense tracking, budget management, analysis
- Data: Amounts, descriptions, dates, categories, merchants
- Required: Yes (for functionality)
- Linked to User ID: Yes
- Tracking: No
- Third-Party Sharing: No
- Optional/Required: Required (user-provided)

**Budget Information**
- Purpose: Budget tracking and alerts
- Data: Budget amounts, categories, limits
- Required: No
- Linked to User ID: Yes
- Tracking: No
- Third-Party Sharing: No
- Optional/Required: Optional (user-provided)

**Savings Goals**
- Purpose: Goal tracking and progress
- Data: Goal amounts, targets, progress
- Required: No
- Linked to User ID: Yes
- Tracking: No
- Third-Party Sharing: No
- Optional/Required: Optional (user-provided)

**Net Worth Data**
- Purpose: Financial overview, net worth calculation
- Data: Historical snapshots, asset/liability values
- Required: No
- Linked to User ID: Yes
- Tracking: No
- Third-Party Sharing: No
- Optional/Required: Generated from user data

### 3.4 Credentials

**Password**
- Purpose: Account authentication
- Required: Yes
- Linked to User ID: Yes
- Tracking: No
- Third-Party Sharing: Yes (Supabase Auth)
- Encryption: bcrypt hashing + salting
- Optional/Required: Required

**TOTP Secret**
- Purpose: Multi-factor authentication
- Required: No (if MFA enabled)
- Linked to User ID: Yes
- Tracking: No
- Third-Party Sharing: No
- Encryption: AES-256 encrypted
- Optional/Required: Optional (if MFA enabled)

**Biometric Data**
- Purpose: Device unlock, app authentication
- Required: No
- Linked to User ID: Yes
- Tracking: No
- Third-Party Sharing: No
- Storage: Device keychain (not sent to servers)
- Optional/Required: Optional

### 3.5 Sensitive Information

**Bill Splitting Data**
- Purpose: Group expense tracking and settlements
- Data: Group names, member information, expense details
- Required: No
- Linked to User ID: Yes
- Tracking: No
- Third-Party Sharing: Yes (to other group members)
- Optional/Required: Optional (user-provided)

**MFA Configuration**
- Purpose: Account security
- Data: MFA method, backup codes, phone number
- Required: No
- Linked to User ID: Yes
- Tracking: No
- Third-Party Sharing: No (except phone for SMS OTP)
- Optional/Required: Optional

### 3.6 Device Information

**IP Address**
- Purpose: Security, analytics
- Required: Yes
- Linked to User ID: No (anonymized)
- Tracking: No
- Third-Party Sharing: Yes (Analytics)
- Optional/Required: Automatic

**Device Model**
- Purpose: Analytics, optimization
- Required: No
- Linked to User ID: No (anonymized)
- Tracking: No
- Third-Party Sharing: Yes (Analytics)
- Optional/Required: Automatic

**Operating System Version**
- Purpose: Analytics, optimization
- Required: No
- Linked to User ID: No (anonymized)
- Tracking: No
- Third-Party Sharing: Yes (Analytics)
- Optional/Required: Automatic

**Mobile Network Information**
- Purpose: Analytics, performance
- Required: No
- Linked to User ID: No (anonymized)
- Tracking: No
- Third-Party Sharing: Yes (Analytics)
- Optional/Required: Automatic

### 3.7 Usage Data

**Feature Usage**
- Purpose: Analytics, improvement
- Data: Features accessed, frequency, duration
- Required: No
- Linked to User ID: No (anonymized)
- Tracking: No
- Third-Party Sharing: Yes (Analytics)
- Optional/Required: Automatic

**Performance Metrics**
- Purpose: App optimization, error detection
- Data: Crash reports, error logs, performance data
- Required: No
- Linked to User ID: No (anonymized)
- Tracking: No
- Third-Party Sharing: Yes (Crash reporting)
- Optional/Required: Automatic

---

## 4. Third-Party Services & Data Sharing

### 4.1 Backend & Data Infrastructure

**Service: Supabase**
- Type: Cloud database and authentication
- Data Shared: Email, password (hashed), user profile, financial data, encrypted MFA secrets
- Purpose: User authentication, data storage, account management
- Privacy Policy: https://supabase.com/privacy
- Data Location: EU-based servers (configurable)
- Data Sharing Necessity: Required for core functionality

### 4.2 Analytics & Monitoring

**Service: [Analytics Provider - if implemented]**
- Type: Usage analytics
- Data Shared: Device info, usage patterns, anonymous performance metrics
- Purpose: Analytics, app improvement
- Privacy Policy: [Provider URL]
- Data Sharing Necessity: Optional (can be disabled in settings)
- Tracking: No user identification

### 4.3 Crash Reporting

**Service: [Crash Reporter - if implemented]**
- Type: Error and crash reporting
- Data Shared: Crash logs, error traces, device info
- Purpose: Bug detection and fixing
- Privacy Policy: [Provider URL]
- Data Sharing Necessity: Recommended
- Tracking: No personal information

---

## 5. Data Security & Encryption

### 5.1 Data in Transit

- **Protocol:** TLS 1.3 / HTTPS
- **Encryption:** AES-256 (if applicable)
- **Certificate Pinning:** Yes (where applicable)

### 5.2 Data at Rest

- **Database Encryption:** Encrypted by Supabase
- **Sensitive Fields:** AES-256 encryption (TOTP secrets, etc.)
- **Credentials:** Bcrypt hashing with salt
- **Secure Storage:** flutter_secure_storage for device credentials

### 5.3 Authentication

- **Method:** JWT tokens
- **Session Management:** Secure token expiration
- **Multi-Factor Authentication:** TOTP + Email OTP support
- **Biometric:** Device keychain storage

---

## 6. Tracking & Identifier Usage

### 6.1 Tracking Definition

FinMate **does NOT engage in tracking** as defined by Apple's privacy standards. We:
- Do NOT track users across other apps or websites
- Do NOT share device identifiers with data brokers
- Do NOT use device identifiers for targeted advertising
- Do NOT correlate user behavior across services

### 6.2 Identifiers Used

| Identifier | Purpose | Linked to User | Shared |
|-----------|---------|-----------------|--------|
| User Account UUID | Account identification | Yes | Backend only |
| Device UDID | App analytics, error tracking | No | Analytics (anonymized) |
| Session Token (JWT) | Authentication | Yes | Backend only |

---

## 7. Data Retention Policies

### 7.1 Active Account

- **Financial Data:** Retained for life of account
- **Transaction History:** Retained for life of account
- **Account Settings:** Retained for life of account
- **Usage Analytics:** Retained for 12 months

### 7.2 Deleted Account

- **Personal Data:** Deleted within 30 days of account deletion
- **Transaction History:** Retained for 7 years (legal/tax compliance)
- **Backup Data:** Deleted within 90 days
- **Analytics Data:** Anonymized immediately

### 7.3 Specific Data Types

| Data Type | Retention Period | Purpose |
|-----------|-----------------|---------|
| Authentication Logs | 90 days | Security |
| Transaction Records | 7 years | Tax/legal compliance |
| User Profile | Account lifetime | Service provision |
| MFA Configuration | Account lifetime | Security |
| Usage Analytics | 12 months | Improvement |
| Error Logs | 30 days | Debugging |
| Session Tokens | Session lifetime | Authentication |

---

## 8. User Controls & Privacy Options

### 8.1 In-App Privacy Settings

Users can access privacy controls via:
- **Settings → Privacy & Security**
  - Disable analytics (where applicable)
  - Manage MFA settings
  - Clear local cache
  - Review connected accounts

- **Settings → Data & Privacy**
  - Download personal data
  - Request account deletion
  - View data retention policies

### 8.2 Device-Level Controls

Users can:
- Disable location services (iOS Settings → Privacy → Location)
- Disable camera access (iOS Settings → Privacy → Camera)
- Disable photo library access (iOS Settings → Privacy → Photos)
- Disable notification access (iOS Settings → Privacy → Notifications)
- Disable biometric authentication (iOS Settings → Face ID/Touch ID)
- Reset advertising identifier (iOS Settings → Privacy → Apple Advertising)

### 8.3 Opt-Out Options

**Analytics:** Users can disable analytics collection in app settings
**Notifications:** Users can disable push notifications in settings or iOS settings
**Marketing:** Users can opt out of marketing emails via email preferences
**Crash Reporting:** Users can disable crash reports in privacy settings

---

## 9. Children's Privacy (COPPA Compliance)

### 9.1 Age Restrictions

- **Minimum Age:** 18 years old
- **Requirement:** Users must be 18+ to create an account
- **Enforcement:** Age verification during signup

### 9.2 Children's Data

FinMate **does NOT intentionally collect data from children under 18**:
- Age verification during registration
- Terms require user to be 18+ years old
- Parental consent NOT available (app not designed for minors)
- If minor data is discovered, account will be deleted immediately

### 9.3 COPPA Compliance Statement

FinMate is not subject to COPPA because:
- App is not directed to children
- App is not intended for users under 18
- Active age restriction enforcement in place
- No features designed for minors

---

## 10. Transparency & User Consent

### 10.1 Consent Mechanism

Users provide consent by:
1. **During Signup:** Agreeing to Privacy Policy and Terms of Service
2. **In-App:** Confirmation when enabling optional features (MFA, biometric)
3. **Implicit:** Continued use after updates to policies

### 10.2 Permission Requests

The app requests permissions for:
- **Camera:** Optional (profile photo upload)
- **Photo Library:** Optional (profile photo upload)
- **Biometric:** Optional (biometric authentication)
- **Notifications:** Optional (budget alerts, bill reminders)
- **Location:** Not required (no location tracking)

### 10.3 Privacy Policy Accessibility

Users can access the privacy policy:
- **In-App:** Settings → Legal → Privacy Policy
- **Website:** https://finmate.app/privacy-policy
- **During Signup:** Link presented before account creation
- **Onboarding:** Privacy information displayed

---

## 11. Changes & Updates to Privacy Policy

### 11.1 Update Procedure

When privacy practices change:
1. New policy drafted and reviewed
2. Implemented in app with new version
3. "Last Updated" date changed
4. Users notified via in-app notification
5. Explicit consent requested for material changes (if required)

### 11.2 Notification Timeline

- **Material Changes:** Notify users before implementation
- **Minor Updates:** Notify users via in-app notification
- **Policy Download:** Users can download policies from settings

---

## 12. Data Breach Notification

### 12.1 Breach Response Procedure

In the event of a data breach:
1. Immediate investigation and containment
2. Notify affected users within 30 days
3. Provide credit monitoring (if applicable)
4. File required notifications with authorities
5. Post-incident review and improvements

### 12.2 Notification Content

Breach notifications will include:
- Nature of the breach
- Data compromised
- Steps taken to secure data
- User protection steps
- Contact information for questions

### 12.3 Legal Compliance

Breach notifications comply with:
- GDPR (Article 33-34)
- CCPA (Cal. Civ. Code § 1798.150)
- State breach notification laws
- Platform-specific requirements

---

## 13. Developer Information

### 13.1 Developer Details

**Developer Name:** Ahmed Chebli / FinMate Team

**Developer Website:** https://finmate.app

**Support Email:** support@finmate.app

**Privacy Contact:** privacy@finmate.app

---

## 14. Regulatory Compliance

### 14.1 GDPR Compliance (EU Users)

- Privacy Policy published and accessible
- Legal basis for processing documented
- Data subject rights provided
- Data protection impact assessment available
- Supabase DPA complies with GDPR

### 14.2 CCPA Compliance (California Users)

- Privacy policy discloses data practices
- User rights to access, delete, opt-out provided
- Service provider disclosures included
- No sale of personal information (current version)

### 14.3 COPPA Compliance

- App not directed to children under 13
- Age restriction enforced (18+)
- No collection of children's data
- Compliant with children's privacy standards

### 14.4 Apple App Store Requirements

- Privacy nutrition label completed accurately
- Privacy policy available and compliant
- Developer account verified
- Terms of Service on file

---

## 15. International Data Transfers

### 15.1 Data Transfer Mechanisms

For EU/UK users, data transfers use:
- **Standard Contractual Clauses (SCCs)**
- **Adequacy Decisions** (where applicable)
- **Supplementary Measures** (as required)

### 15.2 Supabase Data Location

- **Default Region:** EU (Ireland)
- **Configurable:** Per-project basis
- **Encryption:** Data encrypted in transit and at rest

---

## 16. Right to Privacy & User Rights

### 16.1 Access Rights

Users can request and access:
- All personal data collected
- Purpose of processing
- Data sharing details
- Data retention periods

**Access Request Process:**
- Submit request via support@finmate.app
- Provide verification of identity
- Receive response within 30 days

### 16.2 Deletion Rights (Right to Be Forgotten)

Users can request deletion of:
- All personal data (except legally required records)
- Account information
- Financial records (except tax records)

**Deletion Process:**
- Use in-app account deletion
- Or submit request to privacy@finmate.app
- Data deleted within 30 days
- Tax records retained for 7 years

### 16.3 Correction Rights

Users can correct:
- Personal information (name, email, phone)
- Account settings
- Linked accounts

**Correction Process:**
- Edit directly in app settings
- Or request assistance from support

### 16.4 Data Portability

Users can request:
- Export of all personal data
- Data in machine-readable format (JSON/CSV)

**Export Process:**
- Request via settings → Export Data
- Or email privacy@finmate.app
- Response within 30 days

---

## 17. Contact & Support

For privacy questions or requests:

**Email:** privacy@finmate.app

**Support Email:** support@finmate.app

**Privacy Officer:** Ahmed Chebli

**Website:** https://finmate.app

**Response Time:** 30 days (or as required by law)

---

## 18. App Store Submission Checklist

- [x] Privacy Policy created and published
- [x] Privacy Nutrition Label completed
- [x] Data types and purposes documented
- [x] Third-party sharing disclosed
- [x] Security measures documented
- [x] User controls described
- [x] Children's privacy compliance verified
- [x] GDPR/CCPA compliance addressed
- [x] Developer contact information provided
- [x] Data retention policies documented
- [x] Breach notification procedures established

---

**Document Version History:**

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | Oct 21, 2025 | Initial creation for App Store submission |

---

**Disclaimer:** This document is provided for App Store Connect submission and regulatory compliance. It accurately reflects the current data practices of FinMate as of the date specified. The Privacy Policy and these details should be reviewed and updated as the application evolves or features are added.