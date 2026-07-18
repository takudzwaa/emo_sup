# Listener custom claims (PR 20)

## Production
```js
// Admin SDK (Node)
await admin.auth().setCustomUserClaims(uid, { role: 'listener' });
// Optional admin:
await admin.auth().setCustomUserClaims(adminUid, { role: 'admin' });
```

Listeners must **sign out and back in** (or force token refresh) after claim set.

## Firestore
Rules use `request.auth.token.role == 'listener'` for private `listeners/{id}` get/update.

## App gate
- Entry: `lib/main_listener.dart`
- Without claim: “Not a listener” screen (no dashboard data).
- Pilot: volunteer listeners; **demo earnings UI is hidden**.

## Local prototype
```bash
flutter run -t lib/main_listener.dart --dart-define=LISTENER_CLAIM=true
```
