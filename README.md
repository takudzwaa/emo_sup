# emo_sup

Confidential emotional support app (Flutter + Firebase). Connects people with
trained human listeners for private 1:1 text chat and scheduled sessions.
**Not therapy, not medical care, not an emergency service.**

## Flavors

| Flavor | Command | Data |
|--------|---------|------|
| **prototype** (default) | `flutter run` | In-memory repos + demo seeds |
| **staging** | `flutter run --dart-define=FLAVOR=staging` | Firebase `emo-sup-staging` |
| **prod** | `flutter run --dart-define=FLAVOR=prod` | Firebase `emo-sup-prod` (fails closed if unconfigured) |

## One-time Firebase setup (staging)

Firebase login is interactive (Google account). From the repo root:

```bash
chmod +x tools/firebase_setup.sh
./tools/firebase_setup.sh
```

This will:

1. `firebase login` + create/use `emo-sup-staging`
2. `flutterfire configure` → `lib/firebase_options.dart` + native configs
3. Deploy Firestore rules/indexes
4. Seed `config/free_match`, `config/payments` (disabled), + listener directory

**Required in Console:** Auth (Phone + Email/Password), Firestore, Cloud Functions
(Blaze), Cloud Messaging, App Check. Enable Blaze for Functions.

**Phone Auth:** add Android SHA-1 and iOS APNs; until then use email on staging.

Grant a listener claim:

```bash
cd functions && node scripts/grant_listener_claim.js <firebase_auth_uid>
```

Deploy functions (staging):

```bash
firebase use staging
cd functions && npm i && npm run build && firebase deploy --only functions
```

## Production deploy runbook

Payments are **disabled** at launch (free / sponsored / plan-covered slots only).
Do not set `config/payments.enabled = true` until a real gateway + webhook
verification ships.

**Already done for `emo-sup-prod`:** project + Android/iOS apps created, Dart
`prod*` options filled, Firestore rules/indexes deployed, `config/free_match` +
`config/payments` (enabled: false) seeded. Native prod configs live at
`android/app/google-services-prod.json` and
`ios/Runner/GoogleService-Info-Prod.plist` (staging remains the day-to-day default).

**You still need to finish in Console:**

1. **Upgrade to Blaze** (required for Cloud Functions):
   https://console.firebase.google.com/project/emo-sup-prod/usage/details
   Then deploy functions:

   ```bash
   firebase use prod
   cd functions && npm i && npm run build && firebase deploy --only functions
   ```

2. **Enable Auth** (Email/Password + Phone), FCM / APNs, App Check
   (Play Integrity with Android SHA-256 + App Attest). Confirm
   `functions/.env.emo-sup-prod` has `ENFORCE_APP_CHECK=true`.

3. **For a store release build**, point native configs at prod (or add product
   flavors), then sign Android:

   ```bash
   cp android/app/google-services-prod.json android/app/google-services.json
   cp ios/Runner/GoogleService-Info-Prod.plist ios/Runner/GoogleService-Info.plist
   keytool -genkey -v -keystore android/upload-keystore.jks \
     -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   cp android/key.properties.example android/key.properties
   # Fill passwords / alias / storeFile
   flutter build appbundle --dart-define=FLAVOR=prod
   flutter build ipa --dart-define=FLAVOR=prod
   ```

4. **Listener accounts:** grant `role: listener` via
   `functions/scripts/grant_listener_claim.js` on the **prod** project only for
   vetted listeners. Claims come from Auth (no `LISTENER_CLAIM` dart-define).

To re-run provisioning from scratch: `./tools/firebase_setup_prod.sh`.

## Listener app

```bash
# Staging / local: dart-define still works for demos without a claim
flutter run -t lib/main_listener.dart \
  --dart-define=FLAVOR=staging \
  --dart-define=LISTENER_CLAIM=true

# Prod: sign in as a user that already has role=listener
flutter run -t lib/main_listener.dart --dart-define=FLAVOR=prod
```

## CI

GitHub Actions (`.github/workflows/ci.yml`): `flutter analyze` + `flutter test`,
plus Firestore rules unit tests against the emulator.

## Safety

Safety & Privacy (crisis pack, report/block, delete-my-data) is always reachable
and never gated by paywalls or feature flags.
