#!/usr/bin/env bash
# Provision / link emo-sup-prod and merge FlutterFire options into
# lib/firebase_options.dart (prod* constants). Interactive Google login required.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PROJECT_ID="${FIREBASE_PROJECT_ID:-emo-sup-prod}"
DISPLAY_NAME="${FIREBASE_PROJECT_NAME:-Emo Sup}"

echo "==> Firebase CLI + FlutterFire"
command -v firebase >/dev/null || { echo "Install: npm i -g firebase-tools"; exit 1; }
command -v flutterfire >/dev/null || dart pub global activate flutterfire_cli

echo "==> Login (browser)"
firebase login

echo "==> Create project if missing: $PROJECT_ID"
if ! firebase projects:list 2>/dev/null | grep -q "$PROJECT_ID"; then
  firebase projects:create "$PROJECT_ID" --display-name "$DISPLAY_NAME" || true
fi
firebase use "$PROJECT_ID"

echo "==> Enable in Console (Blaze required for Functions):"
echo "    https://console.firebase.google.com/project/$PROJECT_ID"
echo "    Auth (Phone + Email/Password), Firestore, Functions, FCM, App Check"
echo "    App Check: Play Integrity (Android SHA-256) + App Attest (iOS)"

TMP_OPTS="$(mktemp -d)/firebase_options_prod.dart"
echo "==> FlutterFire configure → temp file (merge into prod* constants manually if needed)"
flutterfire configure \
  --project="$PROJECT_ID" \
  --platforms=android,ios \
  --android-package-name=com.emosup.emo_sup \
  --ios-bundle-id=com.emosup.emoSup \
  --out="$TMP_OPTS" \
  --yes || flutterfire configure --project="$PROJECT_ID" --out="$TMP_OPTS"

echo ""
echo "==> Generated options at: $TMP_OPTS"
echo "    Copy android/ios values into lib/firebase_options.dart prodAndroid / prodIos"
echo "    (keep staging constants untouched)."
echo ""
echo "==> This run also overwrote android/app/src/staging/google-services.json"
echo "    (flutterfire always targets the 'default' android config in firebase.json)."
echo "    Back that file up BEFORE running this script if you need it, then:"
echo "    mv android/app/src/staging/google-services.json android/app/src/prod/google-services.json"
echo "    Re-run ./tools/firebase_setup.sh afterwards to regenerate staging's copy."
echo "    Copy GoogleService-Info.plist similarly to ios/Runner/GoogleService-Info-Prod.plist."
echo ""

echo "==> Deploy rules + indexes + functions to prod"
firebase deploy --only firestore:rules,firestore:indexes,functions

echo "==> Seed config (free_match + payments disabled)"
(
  cd functions
  npm install
  npm run build
  GCLOUD_PROJECT="$PROJECT_ID" node scripts/seed_pilot.js
)

echo "==> Done. Run prod builds with:"
echo "    flutter run --dart-define=FLAVOR=prod"
echo "    Confirm App Check enforcement: functions/.env.emo-sup-prod has ENFORCE_APP_CHECK=true"
