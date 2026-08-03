# emo_sup

Confidential emotional support app (Flutter + Firebase). Connects people with
trained human listeners for private 1:1 text chat and scheduled sessions.
**Not therapy, not medical care, not an emergency service.**

## Flavors

Android has real Gradle product flavors (`android/app/build.gradle.kts`), each
bundling its own `google-services.json` from `android/app/src/<flavor>/` — no
manual file-copying, so a prod build can't silently end up pointed at
staging. iOS doesn't have per-flavor Xcode targets yet (still one scheme), so
**omit `--flavor` on iOS** — `--dart-define=FLAVOR=...` alone selects the Dart
side, and `GoogleService-Info.plist` is swapped at release time by
`tools/build_release.sh` (see the production runbook below).

| Flavor | Android command | iOS command | Data |
|--------|------------------|-------------|------|
| **prototype** (default) | `flutter run --flavor prototype` | `flutter run` | In-memory repos + demo seeds |
| **staging** | `flutter run --flavor staging --dart-define=FLAVOR=staging` | `flutter run --dart-define=FLAVOR=staging` | Firebase `emo-sup-staging` |
| **prod** | `flutter run --flavor prod --dart-define=FLAVOR=prod` | `flutter run --dart-define=FLAVOR=prod` (after running the release script to swap the plist) | Firebase `emo-sup-prod` (fails closed if unconfigured) |

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
`android/app/src/prod/google-services.json` (picked up automatically by the
`prod` Gradle flavor) and `ios/Runner/GoogleService-Info-Prod.plist` (staging
remains the day-to-day default for both platforms).

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

3. **For a store release build**, set `DEVELOPMENT_TEAM` in
   `ios/Flutter/Team.xcconfig` (your Apple Developer Team ID — see comments
   in that file) so unattended/CI `flutter build ipa` can archive; interactive
   Xcode builds don't need this if a team is already picked in Signing &
   Capabilities. Then generate the Android upload keystore once:

   ```bash
   keytool -genkey -v -keystore android/upload-keystore.jks \
     -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   cp android/key.properties.example android/key.properties
   # Fill passwords / alias / storeFile
   ```

   Then build via the release script, which verifies the right Firebase
   project is wired up (Android via its Gradle flavor, iOS via a
   copy-and-verify of `GoogleService-Info-Prod.plist`) *before* handing off to
   `flutter build`, instead of trusting a manual copy step:

   ```bash
   chmod +x tools/build_release.sh
   ./tools/build_release.sh prod appbundle
   ./tools/build_release.sh prod ipa
   ```

4. **Listener accounts:** grant `role: listener` via
   `functions/scripts/grant_listener_claim.js` on the **prod** project only for
   vetted listeners. Claims come from Auth (no `LISTENER_CLAIM` dart-define).

To re-run provisioning from scratch: `./tools/firebase_setup_prod.sh`.

## Listener app

```bash
# Staging / local: dart-define still works for demos without a claim
# (add --flavor staging before -t on Android; omit --flavor on iOS)
flutter run -t lib/main_listener.dart \
  --dart-define=FLAVOR=staging \
  --dart-define=LISTENER_CLAIM=true

# Prod: sign in as a user that already has role=listener
# (add --flavor prod before -t on Android; omit --flavor on iOS)
flutter run -t lib/main_listener.dart --dart-define=FLAVOR=prod
```

## CI

GitHub Actions (`.github/workflows/ci.yml`): `flutter analyze` + `flutter test`,
plus Firestore rules unit tests against the emulator.

## Safety

Safety & Privacy (crisis pack, report/block, delete-my-data) is always reachable
and never gated by paywalls or feature flags.
