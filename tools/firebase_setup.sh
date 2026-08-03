#!/usr/bin/env bash
# Phase 0 — create/link Firebase project for emo_sup.
# Requires interactive Google login (cannot run fully headless).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PROJECT_ID="${FIREBASE_PROJECT_ID:-emo-sup-staging}"
DISPLAY_NAME="${FIREBASE_PROJECT_NAME:-Emo Sup Staging}"

echo "==> Firebase CLI + FlutterFire"
command -v firebase >/dev/null || { echo "Install: npm i -g firebase-tools"; exit 1; }
command -v flutterfire >/dev/null || dart pub global activate flutterfire_cli

echo "==> Login (browser)"
firebase login

echo "==> Create project if missing: $PROJECT_ID"
if ! firebase projects:list 2>/dev/null | grep -q "$PROJECT_ID"; then
  # Display names cannot contain underscores (GCP INVALID_ARGUMENT).
  firebase projects:create "$PROJECT_ID" --display-name "$DISPLAY_NAME" || true
fi
firebase use "$PROJECT_ID"

echo "==> Enable APIs (Auth, Firestore, Functions, FCM) in Console if prompted."
echo "    https://console.firebase.google.com/project/$PROJECT_ID"
echo "    Blaze billing required for Cloud Functions."

echo "==> FlutterFire configure (android + ios)"
flutterfire configure \
  --project="$PROJECT_ID" \
  --platforms=android,ios \
  --android-package-name=com.emosup.emo_sup \
  --ios-bundle-id=com.emosup.emoSup \
  --yes || flutterfire configure --project="$PROJECT_ID"

echo "==> Deploy rules + indexes"
firebase deploy --only firestore:rules,firestore:indexes

echo "==> Seed config + demo listeners (Admin SDK script)"
(
  cd functions
  npm install
  npm run build
  node scripts/seed_pilot.js
) || echo "Run: cd functions && node scripts/seed_pilot.js after linking a service account"

echo "==> flutterfire wrote android/app/src/staging/google-services.json"
echo "    (also copy it to android/app/src/prototype/ so that flavor still builds)"
cp android/app/src/staging/google-services.json android/app/src/prototype/google-services.json 2>/dev/null || true

echo "==> Done. Run:"
echo "    flutter run --flavor staging --dart-define=FLAVOR=staging   (Android)"
echo "    flutter run --dart-define=FLAVOR=staging                     (iOS)"
echo "    Phone Auth: add Android SHA-1 / iOS APNs, or use email until then."
