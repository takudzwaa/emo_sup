# App Check / Play Integrity (PR 25)

## Policy
- **Prototype:** not enforced (`MemoryAppCheckService`).
- **Staging:** debug provider tokens registered in Firebase Console.
- **Production / open enrollment:** enforce App Check on callable Functions +
  Firestore (Play Integrity on Android, App Attest on iOS).

## Activation steps (when project linked)
1. Add `firebase_app_check` to the Flutter app.
2. Android: enable Play Integrity API; register SHA-256.
3. iOS: App Attest capability.
4. Staging: print debug token once, add to Firebase App Check debug tokens.
5. Cloud Functions: `enforceAppCheck: true` on callables after staging soak.
6. Kill switch: Remote Config / feature flag to relax only in emergency.

## Code
- Interface: `lib/services/app_check_service.dart`
- Bootstrap calls `activate()` after Firebase init for staging/prod flavors.

## Do not
- Ship open enrollment without enforcement.
- Log debug tokens in production builds.
