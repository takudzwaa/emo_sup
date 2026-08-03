#!/usr/bin/env bash
# Verified release build — replaces the old manual
# `cp google-services-prod.json google-services.json` step, which had no
# safeguard against a forgotten copy silently shipping a "prod" binary
# pointed at the staging Firebase project.
#
# Android needs no copy anymore (real Gradle product flavors read
# android/app/src/<env>/google-services.json directly) — this script just
# verifies that file is present and matches the requested project. iOS still
# has one Xcode target, so this script copies the right
# GoogleService-Info-Prod.plist into place and verifies it before building.
#
# Usage: tools/build_release.sh <staging|prod> <appbundle|ipa>
set -euo pipefail

ENV="${1:-}"
TARGET="${2:-}"
if [[ "$ENV" != "staging" && "$ENV" != "prod" ]] || [[ "$TARGET" != "appbundle" && "$TARGET" != "ipa" ]]; then
  echo "Usage: tools/build_release.sh <staging|prod> <appbundle|ipa>" >&2
  exit 1
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

EXPECTED_PROJECT_ID="emo-sup-$ENV"

project_id_of() {
  python3 - "$1" <<'PY'
import json, sys
try:
    print(json.load(open(sys.argv[1]))["project_info"]["project_id"])
except Exception:
    print("")
PY
}

ios_project_id_of() {
  python3 - "$1" <<'PY'
import plistlib, sys
try:
    with open(sys.argv[1], "rb") as f:
        print(plistlib.load(f).get("PROJECT_ID", ""))
except Exception:
    print("")
PY
}

echo "==> Verifying Android config for '$ENV'"
ANDROID_CONFIG="android/app/src/$ENV/google-services.json"
if [[ ! -f "$ANDROID_CONFIG" ]]; then
  echo "error: missing $ANDROID_CONFIG — see README 'Flavors' / run tools/firebase_setup*.sh first." >&2
  exit 1
fi
ANDROID_PROJECT_ID="$(project_id_of "$ANDROID_CONFIG")"
if [[ "$ANDROID_PROJECT_ID" != "$EXPECTED_PROJECT_ID" ]]; then
  echo "error: $ANDROID_CONFIG is for project '$ANDROID_PROJECT_ID', expected '$EXPECTED_PROJECT_ID'." >&2
  exit 1
fi
echo "    OK: $ANDROID_CONFIG -> $ANDROID_PROJECT_ID"

if [[ "$TARGET" == "ipa" ]]; then
  TEAM_LINE="$(grep '^DEVELOPMENT_TEAM' ios/Flutter/Team.xcconfig 2>/dev/null || true)"
  if [[ -z "${TEAM_LINE#DEVELOPMENT_TEAM =}" ]] || [[ "$TEAM_LINE" == "DEVELOPMENT_TEAM =" ]]; then
    echo "error: ios/Flutter/Team.xcconfig has no DEVELOPMENT_TEAM set — unattended archiving will fail." >&2
    echo "       Fill it in (see comments in that file) before building an ipa." >&2
    exit 1
  fi

  echo "==> Wiring up iOS config for '$ENV'"
  if [[ "$ENV" == "prod" ]]; then
    IOS_SOURCE="ios/Runner/GoogleService-Info-Prod.plist"
    if [[ ! -f "$IOS_SOURCE" ]]; then
      echo "error: missing $IOS_SOURCE." >&2
      exit 1
    fi
    cp "$IOS_SOURCE" "ios/Runner/GoogleService-Info.plist"
  fi
  IOS_PROJECT_ID="$(ios_project_id_of "ios/Runner/GoogleService-Info.plist")"
  if [[ "$IOS_PROJECT_ID" != "$EXPECTED_PROJECT_ID" ]]; then
    echo "error: ios/Runner/GoogleService-Info.plist is for project '$IOS_PROJECT_ID', expected '$EXPECTED_PROJECT_ID'." >&2
    exit 1
  fi
  echo "    OK: ios/Runner/GoogleService-Info.plist -> $IOS_PROJECT_ID"
fi

echo "==> Verified. Building $TARGET for '$ENV'."
case "$TARGET" in
  appbundle)
    flutter build appbundle --flavor "$ENV" --dart-define=FLAVOR="$ENV"
    ;;
  ipa)
    flutter build ipa --dart-define=FLAVOR="$ENV"
    ;;
esac
