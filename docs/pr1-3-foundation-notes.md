# PR 1–3 foundation notes

Implements the first three PRs from
[`production-scale-vulnerable-communities.md`](./production-scale-vulnerable-communities.md).

## PR 1 — Minimal Firebase foundation

| Item | Location |
|------|----------|
| Packages | `cloud_firestore`, `cloud_functions`, `firebase_crashlytics` (+ existing auth/core) |
| Flavor | `lib/config/app_flavor.dart` — `--dart-define=FLAVOR=prototype\|staging\|prod` (default **prototype**) |
| DI | `createAppServices()` in `lib/firebase_bootstrap.dart` → `AppServices` |
| Entry | `lib/main.dart` uses `EmoSupApp.fromServices(services)` |

**Not initialized yet (later PRs):** FCM, App Check, Remote Config, Crashlytics runtime hookup.

### Run flavors

```bash
# Default prototype (no Firebase project required)
flutter run

# Staging / prod (requires flutterfire configure)
flutter run --dart-define=FLAVOR=staging
flutter run --dart-define=FLAVOR=prod
```

## PR 2 — Emulator + rules unit tests

| Item | Location |
|------|----------|
| Emulator ports | `firebase.json` → Auth 9099, Firestore 8080, UI 4000 |
| Rules tests | `rules_tests/` (Node + `@firebase/rules-unit-testing`) |
| CI | `.github/workflows/ci.yml` (Flutter + rules jobs) |

```bash
cd rules_tests
npm install
npm test   # starts Firestore emulator via firebase-tools
```

**Local requirement:** Java 17+ on `PATH` (Firestore emulator). GitHub Actions
installs Temurin 17 in CI. Without Java, `npm test` fails at emulator startup;
Flutter tests still run independently.

Baseline asserts current rules behavior (including open listener list and
client chat/booking create). Later lockdown PRs must update tests first.

## PR 3 — Domain repositories + memory adapters

| Interface | Memory impl | Store façade |
|-----------|-------------|--------------|
| `ChatRepository` | `MemoryChatRepository` | `ChatStore` |
| `BookingRepository` | `MemoryBookingRepository` | `BookingStore` |
| `ListenerDirectoryRepository` | `MemoryListenerDirectoryRepository` | `BookingStore` |
| `MoodRepository` | `MemoryMoodRepository` | `MoodStore` |
| `MembershipRepository` | `MemoryMembershipRepository` | `MembershipStore` |
| `UserProfileRepository` | `MemoryUserProfileRepository` | (AuthController next PR) |
| `ListenerOpsRepository` | `MemoryListenerOpsRepository` | `ListenerDashboardStore` |
| `SafetyRepository` | `MemorySafetyRepository` | (Safety screen next PRs) |

Screens keep the same constructors; inject repos via optional store params
or `EmoSupApp.fromServices`.

---

# PR 4–6 notes (next phase)

## PR 4 — Honest privacy copy

- Chat app bar + Safety “How your messages are protected”: **“Private conversation”**
- Explicitly **not** marketing E2E until crypto ships
- Tests updated (`chat_test`, `safety_privacy_test`, `widget_test`, `listener_dashboard_test`)

## PR 5 — Pre-auth Safety

- `lib/widgets/pre_auth_safety_button.dart` — shield + crisis link
- Welcome, Auth credential, Display name, Consent all expose Safety without profile
- Tests: `test/pre_auth_safety_test.dart`

## PR 6 — i18n skeleton

- `flutter_localizations` + `intl`, `l10n.yaml`, `lib/l10n/app_{en,sn,nd}.arb`
- Generated: `lib/l10n/app_localizations*.dart`
- Welcome uses l10n; MaterialApp supports `en` / `sn` / `nd`
- Listener seeds: English / Shona / Ndebele (ZW pilot)
- **Crisis packs not localized here** (partner gate in PR 18+)

---

# PR 7–10 notes (backend authority)

## PR 7 — Phone-first auth + profile persistence
- Auth default mode **phone**, prefills **+263**
- `AuthController` uses `UserProfileRepository`; restore + returning-user skip
- Rules: user field ACL, `fcm_tokens` RW self, `match_quota` read-only client, no client profile delete

## PR 8 — listener_public
- `listener_public/{id}` list/get for signed-in; **writes deny**
- Private `listeners` list denied; self get for claim `role: listener`

## PR 9 — Bookings lockdown
- Client **create/update/delete denied** on bookings
- Model: `pending_payment`, `expired`, hold/sponsor fields

## PR 10 — requestMatch + chat create deny + quota
- Client chat **create denied**
- `MemoryMatchRepository` (2 free async/week) + Home empty-states
- CF scaffold: `functions/src/index.ts` → `requestMatch` (EU region)

---

# PR 11–15 notes

## PR 11 — Chat ids / retry / block soft-reject
- Client-generated `msg_*` ids; `retryMessage` reuses id
- Failed bubble shows “Tap to retry”
- Soft block list on `ChatStore`; mock replies prototype-only

## PR 12 — Notifications (private by default)
- `NotificationService` + `MemoryNotificationService`
- Default: **no notification body** (shared-phone safety)

## PR 13 — Booking checkout
- `BookingCheckoutRepository` / memory dual-entry (free/plan/sponsored vs pending_payment)
- Hold TTL 12m; CF scaffolds `createBookingCheckout`, `setListenerAvailability`

## PR 14 — Payments Phase A
- `PaymentGateway` + `PaymentService` ledger (FakePaymentGateway)
- Checkout: hold → fake charge → confirm

## PR 15 — Sponsor free slots
- `TimeSlot.sponsored`; morning community free chips; confirm free path
