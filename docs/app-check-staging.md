# App Check (PR 25 / Phase 4)

## Staging
- `MemoryAppCheckService` activates with debug-provider notes when
  `FLAVOR=staging`.
- After `flutterfire configure`, add `firebase_app_check` and register the
  debug token printed in logcat / Xcode in Firebase Console → App Check.

## Production
- Enforce Play Integrity (Android) + App Attest (iOS).
- `FLAVOR=prod` sets `enforcementEnabled` on the service interface; wire the
  real SDK providers when the Firebase project is linked.

## Never
- Do not disable Safety hub, crisis, report, block, or delete behind App Check
  failures — fail soft for those paths if attestation is unavailable.
