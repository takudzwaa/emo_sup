# Store privacy questionnaire mapping

Maps what the app actually collects (verified against `firestore.rules`,
`functions/src/index.ts`, `lib/services/analytics_service.dart`, and
`docs/firestore_schema.md`) to Apple's App Privacy ("nutrition label") and
Google Play's Data Safety form, so filling out the consoles is copy-paste
instead of re-deriving it from the code each time.

**Not legal advice** — both forms ask you to self-certify; use this as a
starting draft and re-check against the current console wording before you
submit, since both platforms revise these categories periodically.

## General answers

- **Do we track users across apps/websites for advertising (Apple "tracking" /
  IDFA)?** No. No ad SDK, no cross-app identifiers, `firebase_analytics` only,
  no third-party ad network.
- **Do we sell data or share it with data brokers?** No.
- **Is data shared with third parties?** Firebase/Google Cloud (Firestore,
  Auth, Crashlytics, Analytics, Cloud Functions, FCM, App Check) processes
  data on our behalf as a service provider — under both platforms' current
  definitions this is *not* "third-party sharing" for the purposes of the
  questionnaire, but confirm current wording before submitting.
- **Can a user request deletion?** Yes — Safety & Privacy → Delete my data,
  backed by the `deleteMyData` Cloud Function (`functions/src/index.ts`),
  which deletes the Firebase Auth account, scrubs message text, removes FCM
  tokens/quota docs, and unlinks past sessions.
- **Encrypted in transit?** Yes, all traffic goes over Firebase SDKs (TLS).
  **Encrypted at rest?** Yes, Firestore/Cloud Storage default at-rest
  encryption. **Not** end-to-end encrypted — see `docs/firestore_schema.md` §3
  for the honesty gap this implies in current UI copy.

## Data type reference

| Data | Where it lives | Linked to identity? | Sensitive category? |
|---|---|---|---|
| Phone number / email | Firebase Auth only — never mirrored to Firestore (`firestore.rules` blocks `email`/`phone` on `users/{uid}`) | Yes (account) | Contact info |
| Anonymous display name | `users/{uid}.anonymousName` | Yes, but not real-world identity | Identifiers / User ID |
| Age (18+ attestation) | `users/{uid}.ageConfirmed`, `ageConfirmedAt` | Yes (account) | — |
| Chat messages | `chats/{id}/messages/{id}.text` | Yes (sender/participants only) | User content |
| Mood check-ins | `users/{uid}/mood_entries/{id}.value` | Yes (self only) | **Health/mental health** — treat as sensitive |
| Device push token | `users/{uid}/fcm_tokens/{id}` | Yes | Device identifiers |
| Crash reports | Firebase Crashlytics (device model, OS version, stack trace) | Pseudonymous (crash instance, not directly your name) | Diagnostics |
| Product analytics events | Firebase Analytics — explicit allowlist in `analytics_service.dart`; message/crisis content is stripped before an event is ever sent | Pseudonymous (app-instance ID) | Usage data |
| Safety reports | `reports/{id}` (reporter-only create, admin-only read) | Yes (reporter + target) | User content / potentially sensitive (safety incident description) |
| Blocks | `blocks/{id}` | Yes | User content |
| Booking/payment status | `bookings/{id}` — payments disabled at launch, no real payment method data collected yet | Yes | Financial info (N/A until payments enabled) |
| App Check attestation | Ephemeral token (Play Integrity / App Attest), not stored as user data | No | Not applicable |

## Apple App Privacy ("nutrition label")

| Apple category | Collected? | Linked to user? | Used to track? | Notes |
|---|---|---|---|---|
| Contact Info (Email, Phone) | Yes | Yes | No | Auth only, not shown to other users |
| Identifiers (User ID, Device ID) | Yes | Yes | No | Anonymous display name + FCM device token |
| User Content (Messages, Other User Content) | Yes | Yes | No | Chat text, reports, block reasons |
| Health & Fitness (Health) | Yes | Yes | No | Mood check-in values — declare under Health, not Usage Data |
| Diagnostics (Crash Data) | Yes | No (pseudonymous) | No | Crashlytics |
| Usage Data (Product Interaction) | Yes | No (pseudonymous) | No | Allow-listed analytics events only |
| Financial Info | Not yet | — | — | Revisit before flipping `config/payments.enabled` |
| Location, Contacts, Browsing/Search History, Photos, Sensitive Info (beyond above) | No | — | — | Not collected |

## Google Play Data Safety

| Play category | Collected? | Shared? | Optional? | Purpose |
|---|---|---|---|---|
| Personal info (Email, Phone, User IDs) | Yes | No | No (required for account) | Account management |
| Personal info (Age) | Yes | No | No (required for account) | Account management, compliance |
| Messages (In-app messages) | Yes | No | No (core feature) | App functionality |
| Health and fitness (Health info) | Yes | No | Yes (mood check-in is optional) | App functionality |
| App activity (App interactions) | Yes | No | No | Analytics |
| App info and performance (Crash logs) | Yes | No | No | Analytics, fraud prevention |
| Device or other IDs | Yes | No | No | App functionality (push notifications) |
| Financial info | Not yet | — | — | Revisit before enabling payments |
| Location, Photos/videos, Audio, Files/docs, Calendar, Contacts, Web browsing | No | — | — | Not collected |

## Before submitting

1. Fill in the Privacy Policy URL (see `docs/legal-hosting.md`) in both
   consoles — both forms link to it.
2. Re-verify the Health/mental-health mood-check-in classification with
   current Play/Apple guidance — this is the one category most likely to
   trigger extra review for a mental-health-adjacent app.
3. Once age gating ships (`ageConfirmed`/`ageConfirmedAt` on `users/{uid}`),
   confirm the age-rating questionnaire matches (13+/17+/18+ depending on
   platform categories) — the app currently self-attests 18+ at signup.
4. If/when payments are enabled, add the Financial Info / Payments rows back
   in with the real gateway's data flow.
