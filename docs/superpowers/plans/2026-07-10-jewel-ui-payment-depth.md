# Jewel Calm UI + Hybrid Payment + MVP Depth — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the Flutter prototype feel jewel-calm and elegant (light-first), add multi-method simulated payments (Card, EcoCash, NetOne, InnBucks) for hybrid free/premium + plan, and deepen all six MVP surfaces without leaving product guardrails.

**Architecture:** Keep existing ChangeNotifier stores + Material navigation. Add `MembershipStore` + `PaymentService` (demo rules only). Extend `Booking` / `ListenerProfile` with payment metadata. Wire Confirm → Checkout → Success for premium; free path unchanged in spirit. Theme tokens in `AppTheme` drive jewel indigo/teal/gold. No new packages.

**Tech Stack:** Flutter 3 / Dart 3, Material 3, existing Firebase Auth bootstrap (unchanged for this pass), `flutter_test`.

**Spec:** `docs/superpowers/specs/2026-07-10-jewel-ui-payment-depth-design.md`

**Note on git:** This workspace may not be a git repository. Skip commit steps if `git status` fails; otherwise commit after each task.

---

## File map

| Path | Responsibility |
|------|----------------|
| `lib/theme/app_theme.dart` | Jewel color tokens, gradients, shadows |
| `lib/theme/listener_theme.dart` | Align listener shell with jewel accents |
| `lib/theme/safety_theme.dart` | Quiet safety shell on jewel surfaces |
| `lib/models/payment_method.dart` | Enum: card, ecocash, netone, innbucks |
| `lib/models/payment_result.dart` | success / declined / cancelled + message |
| `lib/models/membership.dart` | free \| planActive + renewsAt |
| `lib/models/booking.dart` | + price, payment fields |
| `lib/models/listener_profile.dart` | + `ListenerTier` |
| `lib/services/payment_service.dart` | Simulated charge + subscribe |
| `lib/data/membership_store.dart` | Plan state ChangeNotifier |
| `lib/data/booking_store.dart` | confirm with payment meta; reschedule; premium listeners |
| `lib/screens/payment/checkout_screen.dart` | Method picker + pay / plan CTAs |
| `lib/screens/payment/booking_success_screen.dart` | Success after free or paid book |
| `lib/screens/booking_confirm_screen.dart` | Free vs pay vs plan-included |
| `lib/screens/bookings_screen.dart` | Filters, reschedule entry |
| `lib/screens/slot_picker_screen.dart` | Premium labels / price hints |
| `lib/screens/home_screen.dart` | Greeting, mood strip, plan chip, upcoming |
| `lib/screens/chat_screen.dart` | Banner, ticks, end session |
| `lib/screens/safety_privacy_screen.dart` | Richer cards, report wizard, delete confirm |
| `lib/screens/auth/*` | Welcome + name reveal polish |
| `lib/screens/listener/listener_dashboard_screen.dart` | Availability, queue, earnings stub |
| `lib/widgets/premium_badge.dart` | Gold premium chip |
| `lib/widgets/plan_status_chip.dart` | Free / Plan chip |
| `lib/widgets/language_filter_chips.dart` | Booking list filter |
| `lib/widgets/soft_surface.dart` | Glassier SoftCard, jewel CTA glow |
| `lib/widgets/message_bubble.dart` | Status ticks |
| `lib/widgets/mood_check_in.dart` | Optional history strip host |
| `lib/main.dart` | Provide MembershipStore if needed for Home |
| `test/payment_service_test.dart` | Method success/fail rules |
| `test/membership_payment_flow_test.dart` | Plan + premium booking rules |
| `test/bookings_test.dart` | Update free path; premium path |
| Other existing tests | String/UI updates as needed |

---

### Task 1: Jewel theme tokens

**Files:**
- Modify: `lib/theme/app_theme.dart`
- Modify: `lib/widgets/soft_surface.dart` (shadow tint only if needed)
- Test: `test/widget_test.dart` (smoke still pumps app)

- [ ] **Step 1: Update `AppTheme` light/dark seeds and gradients**

Replace seed and explicit ColorScheme colors in `lib/theme/app_theme.dart`:

```dart
// Soft indigo seed (jewel calm)
static const _seed = Color(0xFF6B7FD7);

// light():
primary: const Color(0xFF6B7FD7),
onPrimary: Colors.white,
secondary: const Color(0xFF5BB8B0),
onSecondary: Colors.white,
tertiary: const Color(0xFFC9A87C), // premium gold
surface: const Color(0xFFF5F2FB),
onSurface: const Color(0xFF25233A),
surfaceContainerHighest: const Color(0xFFE8E4F4),
outline: const Color(0xFFB8B0C8),
error: const Color(0xFFB07080),
onError: Colors.white,

// dark(): warm charcoal-plum
primary: const Color(0xFF9AA8F0),
onPrimary: const Color(0xFF1A1B2E),
secondary: const Color(0xFF7ED4CC),
onSecondary: const Color(0xFF0F2A28),
tertiary: const Color(0xFFD4B896),
surface: const Color(0xFF1A1625),
onSurface: const Color(0xFFEDE8F5),
surfaceContainerHighest: const Color(0xFF2A2438),
outline: const Color(0xFF5A5268),
error: const Color(0xFFD0A0A8),
onError: const Color(0xFF2A1818),
```

Update `scaffoldGradient` light stops to lilac → mint → ivory:

```dart
colors: [
  const Color(0xFFF5F2FB),
  const Color(0xFFEEF7F5),
  const Color(0xFFFBF6F0),
],
stops: const [0.0, 0.5, 1.0],
```

Update `primaryGradient` to indigo → teal:

```dart
static LinearGradient primaryGradient(ColorScheme scheme) {
  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [scheme.primary, scheme.secondary],
  );
}
```

Add helper for premium gold:

```dart
static Color premiumAccent(ColorScheme scheme) =>
    scheme.brightness == Brightness.dark
        ? const Color(0xFFD4B896)
        : const Color(0xFFC9A87C);
```

- [ ] **Step 2: Soften SoftCard glass tint toward violet**

In `lib/widgets/soft_surface.dart`, keep structure; ensure light card bg uses white ~0.82 and soft shadow uses `AppTheme.softShadow` (already). Optionally tint shadow base toward `Color(0xFF504678)` for light mode in `AppTheme.softShadow`.

- [ ] **Step 3: Run smoke tests**

```bash
cd /Users/admin/workspace/emo_sup && flutter test test/widget_test.dart
```

Expected: PASS

- [ ] **Step 4: Commit (if git available)**

```bash
git add lib/theme/app_theme.dart lib/widgets/soft_surface.dart
git commit -m "style: jewel calm theme tokens (light-first indigo/teal/gold)"
```

---

### Task 2: Payment models + PaymentService + MembershipStore

**Files:**
- Create: `lib/models/payment_method.dart`
- Create: `lib/models/payment_result.dart`
- Create: `lib/models/membership.dart`
- Create: `lib/services/payment_service.dart`
- Create: `lib/data/membership_store.dart`
- Create: `test/payment_service_test.dart`
- Create: `test/membership_store_test.dart`

- [ ] **Step 1: Write failing payment service tests**

Create `test/payment_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:emo_sup/models/payment_method.dart';
import 'package:emo_sup/models/payment_result.dart';
import 'package:emo_sup/services/payment_service.dart';

void main() {
  final service = PaymentService(delay: Duration.zero);

  test('card 4242 succeeds', () async {
    final r = await service.charge(
      method: PaymentMethod.card,
      amountCents: 1200,
      cardNumber: '4242424242424242',
      exp: '12/30',
      cvc: '123',
    );
    expect(r.status, PaymentStatus.success);
  });

  test('card 4000 declines', () async {
    final r = await service.charge(
      method: PaymentMethod.card,
      amountCents: 1200,
      cardNumber: '4000000000000000',
      exp: '12/30',
      cvc: '123',
    );
    expect(r.status, PaymentStatus.declined);
  });

  test('ecocash PIN 0000 succeeds', () async {
    final r = await service.charge(
      method: PaymentMethod.ecocash,
      amountCents: 1200,
      phone: '0772123456',
      pin: '0000',
    );
    expect(r.status, PaymentStatus.success);
  });

  test('ecocash PIN 9999 declines', () async {
    final r = await service.charge(
      method: PaymentMethod.ecocash,
      amountCents: 1200,
      phone: '0772123456',
      pin: '9999',
    );
    expect(r.status, PaymentStatus.declined);
  });

  test('subscribe success activates result message', () async {
    final r = await service.subscribe(
      method: PaymentMethod.innbucks,
      amountCents: 2900,
      phone: '0772000000',
      pin: '0000',
    );
    expect(r.status, PaymentStatus.success);
  });
}
```

- [ ] **Step 2: Run tests — expect FAIL (missing libraries)**

```bash
flutter test test/payment_service_test.dart
```

Expected: FAIL (file not found / undefined classes)

- [ ] **Step 3: Implement models**

`lib/models/payment_method.dart`:

```dart
enum PaymentMethod {
  card,
  ecocash,
  netone,
  innbucks;

  String get displayName {
    switch (this) {
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.ecocash:
        return 'EcoCash';
      case PaymentMethod.netone:
        return 'NetOne (OneMoney)';
      case PaymentMethod.innbucks:
        return 'InnBucks';
    }
  }
}
```

`lib/models/payment_result.dart`:

```dart
enum PaymentStatus { success, declined, cancelled }

class PaymentResult {
  const PaymentResult({
    required this.status,
    this.message = '',
    this.method,
  });

  final PaymentStatus status;
  final String message;
  final PaymentMethod? method;

  bool get isSuccess => status == PaymentStatus.success;
}
```

(Import `payment_method.dart` in this file.)

`lib/models/membership.dart`:

```dart
enum MembershipTier { free, planActive }

class Membership {
  const Membership({
    this.tier = MembershipTier.free,
    this.planId,
    this.renewsAt,
  });

  final MembershipTier tier;
  final String? planId;
  final DateTime? renewsAt;

  bool get hasActivePlan => tier == MembershipTier.planActive;

  Membership copyWith({
    MembershipTier? tier,
    String? planId,
    DateTime? renewsAt,
  }) {
    return Membership(
      tier: tier ?? this.tier,
      planId: planId ?? this.planId,
      renewsAt: renewsAt ?? this.renewsAt,
    );
  }
}
```

- [ ] **Step 4: Implement `PaymentService`**

`lib/services/payment_service.dart`:

```dart
import '../models/payment_method.dart';
import '../models/payment_result.dart';

/// Demo-only payment gateway. No network. No real charges.
class PaymentService {
  PaymentService({this.delay = const Duration(milliseconds: 1400)});

  final Duration delay;

  static const sessionPriceCents = 1200; // $12
  static const planPriceCents = 2900; // $29

  Future<PaymentResult> charge({
    required PaymentMethod method,
    required int amountCents,
    String? cardNumber,
    String? exp,
    String? cvc,
    String? phone,
    String? pin,
  }) async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    return _evaluate(
      method: method,
      cardNumber: cardNumber,
      phone: phone,
      pin: pin,
      successMessage: 'Paid \$${(amountCents / 100).toStringAsFixed(0)} via ${method.displayName}',
    );
  }

  Future<PaymentResult> subscribe({
    required PaymentMethod method,
    required int amountCents,
    String? cardNumber,
    String? exp,
    String? cvc,
    String? phone,
    String? pin,
  }) async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    return _evaluate(
      method: method,
      cardNumber: cardNumber,
      phone: phone,
      pin: pin,
      successMessage: 'Plan activated via ${method.displayName}',
    );
  }

  PaymentResult _evaluate({
    required PaymentMethod method,
    String? cardNumber,
    String? phone,
    String? pin,
    required String successMessage,
  }) {
    final ok = switch (method) {
      PaymentMethod.card => (cardNumber ?? '').replaceAll(' ', '').startsWith('4242'),
      PaymentMethod.ecocash ||
      PaymentMethod.netone ||
      PaymentMethod.innbucks =>
        (pin != null && pin == '0000') ||
            ((phone ?? '').isNotEmpty &&
                pin != '9999' &&
                _lastDigitEven(phone!)),
    };

    // Explicit fail pins / cards
    if (method == PaymentMethod.card &&
        (cardNumber ?? '').replaceAll(' ', '').startsWith('4000')) {
      return PaymentResult(
        status: PaymentStatus.declined,
        message: 'Card declined (demo). Try 4242…',
        method: method,
      );
    }
    if (pin == '9999') {
      return PaymentResult(
        status: PaymentStatus.declined,
        message: 'Payment declined (demo). Use PIN 0000 to succeed.',
        method: method,
      );
    }

    if (ok) {
      return PaymentResult(
        status: PaymentStatus.success,
        message: successMessage,
        method: method,
      );
    }
    return PaymentResult(
      status: PaymentStatus.declined,
      message: 'Payment declined (demo). Check details and try again.',
      method: method,
    );
  }

  bool _lastDigitEven(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return false;
    final d = int.tryParse(digits[digits.length - 1]) ?? 1;
    return d.isEven;
  }
}
```

Clarify mobile money: success if `pin == '0000'` OR (phone last digit even AND pin != `9999`). Prefer PIN rules in UI helper text.

- [ ] **Step 5: Implement `MembershipStore`**

`lib/data/membership_store.dart`:

```dart
import 'package:flutter/foundation.dart';
import '../models/membership.dart';

class MembershipStore extends ChangeNotifier {
  MembershipStore({Membership? initial})
      : _membership = initial ?? const Membership();

  Membership _membership;

  Membership get membership => _membership;
  bool get hasActivePlan => _membership.hasActivePlan;

  void activatePlan({String planId = 'plan_monthly_29'}) {
    _membership = Membership(
      tier: MembershipTier.planActive,
      planId: planId,
      renewsAt: DateTime.now().add(const Duration(days: 30)),
    );
    notifyListeners();
  }

  void clearPlanForTesting() {
    _membership = const Membership();
    notifyListeners();
  }
}
```

Create `test/membership_store_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:emo_sup/data/membership_store.dart';

void main() {
  test('activatePlan sets hasActivePlan', () {
    final store = MembershipStore();
    expect(store.hasActivePlan, isFalse);
    store.activatePlan();
    expect(store.hasActivePlan, isTrue);
    expect(store.membership.planId, 'plan_monthly_29');
  });
}
```

- [ ] **Step 6: Run tests**

```bash
flutter test test/payment_service_test.dart test/membership_store_test.dart
```

Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add lib/models/payment_method.dart lib/models/payment_result.dart lib/models/membership.dart \
  lib/services/payment_service.dart lib/data/membership_store.dart \
  test/payment_service_test.dart test/membership_store_test.dart
git commit -m "feat: simulated payment service and membership store"
```

---

### Task 3: Extend Booking + ListenerProfile + BookingStore

**Files:**
- Modify: `lib/models/booking.dart`
- Modify: `lib/models/listener_profile.dart`
- Modify: `lib/data/booking_store.dart`
- Create: `test/booking_payment_fields_test.dart`

- [ ] **Step 1: Extend `ListenerProfile` with tier**

```dart
enum ListenerTier { standard, premium }

// On ListenerProfile:
final ListenerTier tier; // default ListenerTier.standard

bool get isPremium => tier == ListenerTier.premium;
```

Update constructors, `copyWith` if any, `toMap`/`fromMap`, and `defaultListeners()`: make **Listener — Lantern** premium; others standard.

- [ ] **Step 2: Extend `Booking`**

Add fields (all optional with defaults for seed compatibility):

```dart
final int priceCents; // 0 for free
final String currency; // 'USD'
final bool planApplied;
final PaymentMethod? paymentMethod;
final String paymentStatus; // 'none' | 'paid' | 'plan' | 'free'

// confirmBooking should accept named optional payment fields
```

Import `payment_method.dart`. Update `copyWith`, `toMap`, `fromMap`, `==`, `hashCode`.

- [ ] **Step 3: Extend `BookingStore.confirmBooking`**

```dart
Booking confirmBooking({
  required String listenerId,
  required DateTime slotStart,
  int priceCents = 0,
  String currency = 'USD',
  bool planApplied = false,
  PaymentMethod? paymentMethod,
  String paymentStatus = 'free',
}) {
  final booking = Booking(
    id: 'booking_${++_idCounter}',
    userId: currentUserId,
    listenerId: listenerId,
    slotStart: slotStart,
    status: BookingStatus.confirmed,
    priceCents: priceCents,
    currency: currency,
    planApplied: planApplied,
    paymentMethod: paymentMethod,
    paymentStatus: paymentStatus,
  );
  _bookings.add(booking);
  notifyListeners();
  return booking;
}
```

Add:

```dart
bool isPremiumAccess({required String listenerId, required TimeSlot slot}) {
  final listener = listenerById(listenerId);
  return slot.requiresPremium || (listener?.isPremium ?? false);
}

void rescheduleBooking({
  required String bookingId,
  required DateTime newSlotStart,
}) {
  final index = _bookings.indexWhere((b) => b.id == bookingId);
  if (index == -1) return;
  _bookings[index] = _bookings[index].copyWith(slotStart: newSlotStart);
  notifyListeners();
}
```

- [ ] **Step 4: Unit test booking fields**

```dart
// test/booking_payment_fields_test.dart
test('confirmBooking stores payment metadata', () {
  final store = BookingStore(seedBookings: []);
  final b = store.confirmBooking(
    listenerId: 'listener_harbor',
    slotStart: DateTime.utc(2026, 8, 1, 10),
    priceCents: 1200,
    paymentMethod: PaymentMethod.ecocash,
    paymentStatus: 'paid',
  );
  expect(b.priceCents, 1200);
  expect(b.paymentMethod, PaymentMethod.ecocash);
});
```

- [ ] **Step 5: Run tests**

```bash
flutter test test/booking_payment_fields_test.dart test/bookings_test.dart
```

Expected: PASS (fix compile breaks in other tests if constructor args missing — add defaults)

- [ ] **Step 6: Commit**

```bash
git commit -am "feat: booking payment fields, premium listeners, reschedule"
```

---

### Task 4: Checkout + Success screens + wire Confirm

**Files:**
- Create: `lib/screens/payment/checkout_screen.dart`
- Create: `lib/screens/payment/booking_success_screen.dart`
- Modify: `lib/screens/booking_confirm_screen.dart`
- Modify: `lib/screens/slot_picker_screen.dart` (if navigation args needed)
- Create: `test/payment_checkout_flow_test.dart`
- Modify: `test/bookings_test.dart`

**Constants:** session $12 (`PaymentService.sessionPriceCents`), plan $29.

- [ ] **Step 1: Build `CheckoutScreen`**

Constructor:

```dart
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    super.key,
    required this.store,
    required this.membershipStore,
    required this.listener,
    required this.slot,
    this.paymentService,
    this.mode = CheckoutMode.session, // session | planThenBook
  });
  // ...
}
```

UI structure:

1. AppBar title: `Checkout`
2. SoftGradientBackground + demo banner: `Demo payment only — you will not be charged.`
3. Amount summary SoftCard
4. Method list (4 tiles); selected border uses primary
5. Fields:
   - Card: number, exp, cvc TextFields
   - EcoCash / NetOne / InnBucks: phone + pin (label pin as “Demo PIN”)
6. Primary: `Pay $12` → call `paymentService.charge` → on success `confirmBooking` with paid meta → push success (replace stack)
7. Secondary outlined: `Get Plan · $29/mo` → `subscribe` → `membershipStore.activatePlan` → `confirmBooking` with `planApplied: true`, `paymentStatus: 'plan'` → success
8. While processing: disable buttons, show `CircularProgressIndicator` overlay
9. On decline: `SnackBar` with result.message
10. Bottom: `SafetyQuickAccessBar`

Return type: pop with `Booking` on success only when using imperative nav from confirm; prefer:

```dart
// After success:
Navigator.of(context).pushAndRemoveUntil(
  MaterialPageRoute(builder: (_) => BookingSuccessScreen(booking: booking, listener: listener, store: store)),
  (route) => route.isFirst || route.settings.name == '/',
);
```

Simpler prototype approach: pop results up:

From Confirm: `final booking = await Navigator.push<Booking>(Checkout...)`  
Checkout pops `booking` on success. BookingsScreen already handles booking result.

Success screen can be pushed from Confirm after checkout returns, or from Checkout before pop. Prefer **Checkout confirms booking then pushes Success**, and Success has “Done” that pops to Bookings (pop until Bookings).

Implementation detail for navigator:

```dart
// In Checkout after confirmBooking:
await Navigator.of(context).push<void>(
  MaterialPageRoute(
    builder: (_) => BookingSuccessScreen(
      booking: booking,
      listener: widget.listener,
      receiptLine: result.message,
    ),
  ),
);
if (context.mounted) {
  Navigator.of(context).pop(booking); // to slot picker
}
// Slot picker already pops booking to Bookings — ensure chain still works.
```

Match existing confirm flow: currently Confirm pops twice with booking. Keep that contract: Confirm (or Checkout) must still result in Bookings receiving `Booking`.

**Recommended flow:**

1. Confirm free → `confirmBooking` → pop booking (existing)
2. Confirm premium + no plan → push Checkout → on success Checkout calls `confirmBooking`, then `pop(booking)` once; Confirm should not double-confirm — Confirm only navigates to Checkout and returns its result:

```dart
// booking_confirm_screen.dart
Future<void> _onPrimary() async {
  final needsPay = widget.store.isPremiumAccess(
        listenerId: widget.listener.id,
        slot: widget.slot,
      ) &&
      !widget.membershipStore.hasActivePlan;

  if (!needsPay) {
    final booking = widget.store.confirmBooking(
      listenerId: widget.listener.id,
      slotStart: widget.slot.start,
      priceCents: 0,
      planApplied: widget.membershipStore.hasActivePlan &&
          widget.store.isPremiumAccess(
            listenerId: widget.listener.id,
            slot: widget.slot,
          ),
      paymentStatus: widget.membershipStore.hasActivePlan ? 'plan' : 'free',
    );
    // optional: push success then pop chain
    _finishWith(booking);
    return;
  }

  final booking = await Navigator.of(context).push<Booking>(
    MaterialPageRoute(
      builder: (_) => CheckoutScreen(
        store: widget.store,
        membershipStore: widget.membershipStore,
        listener: widget.listener,
        slot: widget.slot,
      ),
    ),
  );
  if (booking != null && mounted) _finishWith(booking);
}

void _finishWith(Booking booking) {
  Navigator.of(context).pop(); // confirm
  Navigator.of(context).pop(booking); // picker
}
```

Pass `MembershipStore` into SlotPicker → Confirm (add params like `BookingStore`).

- [ ] **Step 2: `BookingSuccessScreen`**

Show listener name, date/time, receipt line, SoftPrimaryButton `View upcoming` that `Navigator.popUntil` first route or pops 2–3 times. Include Safety bar. TrustChip.

- [ ] **Step 3: Widget test free path still works**

Update `test/bookings_test.dart` full flow: still uses SoftPrimaryButton on confirm for free morning slots. Prefer tapping a slot that is not premium: e.g. find text without “Premium” or inject store with controlled slots.

Inject:

```dart
// Prefer explicit: use BookingStore with single listener and known free slots only for free test.
```

Add new test:

```dart
testWidgets('Premium slot opens checkout and pays with card 4242', (tester) async {
  // Build slot with requiresPremium true — either navigate until Premium chip, or
  // open BookingConfirmScreen / CheckoutScreen directly with fakes.
  final store = BookingStore(seedBookings: []);
  final membership = MembershipStore();
  final listener = store.listeners.first;
  final slot = TimeSlot(
    start: DateTime.now().add(const Duration(days: 2, hours: 3)),
    requiresPremium: true,
  );

  await tester.pumpWidget(MaterialApp(
    home: CheckoutScreen(
      store: store,
      membershipStore: membership,
      listener: listener,
      slot: slot,
      paymentService: PaymentService(delay: Duration.zero),
    ),
  ));

  await tester.enterText(find.byKey(const Key('card_number')), '4242424242424242');
  await tester.enterText(find.byKey(const Key('card_exp')), '12/30');
  await tester.enterText(find.byKey(const Key('card_cvc')), '123');
  await tester.tap(find.text('Pay \$12'));
  await tester.pumpAndSettle();

  expect(store.upcomingConfirmed, isNotEmpty);
  expect(store.upcomingConfirmed.last.paymentStatus, 'paid');
});
```

Add `Key`s on card fields in CheckoutScreen.

- [ ] **Step 4: Decline test**

```dart
// card 4000 → snackbar / no booking
await tester.enterText(..., '4000000000000000');
await tester.tap(find.text('Pay \$12'));
await tester.pumpAndSettle();
expect(store.upcomingConfirmed, isEmpty);
```

- [ ] **Step 5: Run tests**

```bash
flutter test test/payment_checkout_flow_test.dart test/bookings_test.dart
```

Expected: PASS

- [ ] **Step 6: Commit**

```bash
git commit -am "feat: multi-method checkout and booking success flow"
```

---

### Task 5: Bookings list filters, premium badges, reschedule

**Files:**
- Create: `lib/widgets/premium_badge.dart`
- Create: `lib/widgets/language_filter_chips.dart`
- Modify: `lib/widgets/listener_card.dart`
- Modify: `lib/screens/bookings_screen.dart`
- Modify: `lib/screens/slot_picker_screen.dart`
- Modify: `lib/widgets/upcoming_booking_tile.dart`

- [ ] **Step 1: `PremiumBadge` widget**

Gold border chip: label `Premium`, icon `workspace_premium_outlined`, color `AppTheme.premiumAccent(scheme)`.

- [ ] **Step 2: Language filter chips**

Stateful filter on Bookings find-tab: `All` + unique languages from store. Filter `store.listeners` by selected language.

- [ ] **Step 3: ListenerCard shows PremiumBadge when `listener.isPremium`**

- [ ] **Step 4: Slot picker**

For each slot chip, if `requiresPremium` show small `Premium · $12` caption. Pass membershipStore through if needed for hints “Included in plan”.

- [ ] **Step 5: Reschedule**

On `UpcomingBookingTile`, add `TextButton` `Reschedule` next to cancel. Opens SlotPicker for same listener; on pick:

```dart
// If new slot premium and !membership.hasActivePlan → Checkout then rescheduleBooking or cancel+confirm new
// Else rescheduleBooking(bookingId, newStart)
```

Simplest v1: cancel old + confirmBooking new (with payment if needed) to avoid half-paid states.

- [ ] **Step 6: Manual/widget smoke**

```bash
flutter test test/bookings_test.dart
```

- [ ] **Step 7: Commit**

```bash
git commit -am "feat: booking filters, premium badges, reschedule"
```

---

### Task 6: Home depth

**Files:**
- Create: `lib/widgets/plan_status_chip.dart`
- Modify: `lib/screens/home_screen.dart`
- Modify: `lib/main.dart` (inject MembershipStore + optional BookingStore)
- Modify: `lib/widgets/mood_check_in.dart` (history strip)
- Modify: `test/widget_test.dart` as needed

- [ ] **Step 1: Provide stores from main**

```dart
// EmoSupApp holds MembershipStore + BookingStore (or create on Home)
// Pass to HomeScreen:
//   membershipStore, bookingStore (optional; Home can create BookingStore() for demo)
```

Prefer single `BookingStore` instance shared Home ↔ Bookings so upcoming card matches.

```dart
class EmoSupApp extends StatefulWidget { ... }

// Or Stateless with final BookingStore bookingStore = BookingStore();
```

- [ ] **Step 2: Home UI**

- Greeting: `_greeting()` based on `DateTime.now().hour` + username  
- `PlanStatusChip(hasPlan: membershipStore.hasActivePlan)`  
- Mood history: horizontal list of last 5 `moodStore.entries` as small emoji circles  
- Upcoming SoftCard if `bookingStore.upcomingConfirmed.isNotEmpty`  
- Keep one primary CTA: Talk to Someone  
- Book later secondary card  

- [ ] **Step 3: Tests**

```dart
testWidgets('Home shows greeting and plan chip', (tester) async {
  await tester.pumpWidget(buildTestApp());
  expect(find.textContaining('Good'), findsOneWidget);
  expect(find.textContaining('Free'), findsWidgets); // plan chip
});
```

- [ ] **Step 4: Commit**

```bash
git commit -am "feat: richer home greeting, mood strip, plan and upcoming cards"
```

---

### Task 7: Chat depth

**Files:**
- Modify: `lib/screens/chat_screen.dart`
- Modify: `lib/widgets/message_bubble.dart`
- Modify: `lib/data/chat_store.dart` (status progression if needed)
- Modify: `test/chat_test.dart`

- [ ] **Step 1: Session banner**

Below app bar: SoftCard strip “You’re in a private session with {name}” + TrustChip.

- [ ] **Step 2: Status ticks on own bubbles**

In `MessageBubble`, if mine: show `✓` for sent, `✓✓` for delivered/read (use `message.status`).

- [ ] **Step 3: ChatStore send path**

On send: create as `sending` → shortly `sent` → `delivered` (existing mock reply path; add `Future.delayed` status upgrades).

- [ ] **Step 4: End session**

Overflow menu item `End session` → dialog → pop chat with closed flag; show simple “Session ended” full-screen or snackbar + pop.

- [ ] **Step 5: Report still ≤2 taps**

Keep overflow Report & block + Safety.

- [ ] **Step 6: Tests + commit**

```bash
flutter test test/chat_test.dart
git commit -am "feat: chat session banner, delivery ticks, end session"
```

---

### Task 8: Safety & Privacy polish

**Files:**
- Modify: `lib/screens/safety_privacy_screen.dart`
- Modify: `test/safety_privacy_test.dart`

- [ ] **Step 1: Crisis resource cards**

Use SoftCard per resource with icon, title, subtitle, tappable `url_launcher` **only if already a dependency** — if not, show dialog “Open in browser (stub)” with resource name. **Do not add packages.**

- [ ] **Step 2: Report/block wizard**

Bottom sheet or multi-step: reason chips (`Unwanted contact`, `Felt unsafe`, `Spam`, `Other`) → confirm → snackbar “Report submitted (demo)”.

- [ ] **Step 3: Delete my data**

Dialog listing consequences (messages, bookings, mood history) → TextField require typing `DELETE` → clear local stores if injectable, snackbar.

- [ ] **Step 4: Tests + commit**

```bash
flutter test test/safety_privacy_test.dart
git commit -am "feat: richer safety hub report and delete flows"
```

---

### Task 9: Auth welcome polish

**Files:**
- Modify: `lib/screens/auth/welcome_screen.dart`
- Modify: `lib/screens/auth/display_name_screen.dart`
- Modify: `test/auth_flow_test.dart`

- [ ] **Step 1: Welcome**

Jewel gradient background, headline “Someone to talk to — privately”, TrustChip, one primary continue CTA.

- [ ] **Step 2: Display name reveal**

When name generated/shown: `AnimatedOpacity` + `AnimatedScale` 200–300ms on the anonymous name.

- [ ] **Step 3: Tests + commit**

```bash
flutter test test/auth_flow_test.dart
git commit -am "feat: jewel welcome and anonymous name reveal"
```

---

### Task 10: Listener dashboard depth

**Files:**
- Modify: `lib/screens/listener/listener_dashboard_screen.dart`
- Modify: `lib/data/listener_dashboard_store.dart` if needed
- Modify: `lib/theme/listener_theme.dart`
- Modify: `test/listener_dashboard_test.dart`

- [ ] **Step 1: Availability toggle**

Large switch: Online / Away with color change (secondary / outline).

- [ ] **Step 2: Queue cards**

List anonymous user names with “Open chat” → existing ChatScreen listener perspective.

- [ ] **Step 3: Today summary SoftCard**

`Sessions today: N` · `Est. earnings: $X (demo)` — pure stub math from store counts.

- [ ] **Step 4: Theme align**

Listener primary can stay plum; surfaces use same soft gradient pattern as jewel.

- [ ] **Step 5: Tests + commit**

```bash
flutter test test/listener_dashboard_test.dart
git commit -am "feat: listener availability, queue cards, earnings stub"
```

---

### Task 11: Full regression + copy pass

**Files:**
- All tests under `test/`
- Grep copy for therapy/clinical words

- [ ] **Step 1: Run full test suite**

```bash
cd /Users/admin/workspace/emo_sup && flutter test
```

Expected: all PASS. Fix any broken finders from copy changes.

- [ ] **Step 2: Guardrail grep**

```bash
rg -n -i "therap|diagnos|clinical|treatment|patient" lib/ --glob '*.dart'
```

Expected: only negative disclaimers (“not therapy”) if any; no positive clinical claims. Fix violations.

- [ ] **Step 3: Demo payment disclaimer present**

```bash
rg -n "Demo payment only" lib/
```

Expected: hit in checkout.

- [ ] **Step 4: Final commit**

```bash
git commit -am "chore: regression fixes and copy guardrail pass"
```

---

## Spec coverage checklist

| Spec item | Task |
|-----------|------|
| Jewel calm light-first theme | 1 |
| Payment methods card/ecocash/netone/innbucks | 2, 4 |
| Hybrid free / pay / plan | 3, 4 |
| MembershipStore + PaymentService | 2 |
| Booking payment metadata | 3 |
| Checkout + success | 4 |
| Filters, premium badge, reschedule | 5 |
| Home depth | 6 |
| Chat depth | 7 |
| Safety polish | 8 |
| Auth polish | 9 |
| Listener depth | 10 |
| Tests + guardrails | 2–4, 11 |
| No new packages | All tasks |
| Safety never gated | 4, 8 (quick bar on checkout) |

---

## Self-review notes

- No TBD placeholders in task steps.
- Types consistent: `PaymentMethod`, `PaymentStatus`, `MembershipTier`, `ListenerTier`, `paymentStatus` string values `'free'|'paid'|'plan'|'none'`.
- Demo prices fixed: 1200 / 2900 cents.
- Commit steps optional when git is unavailable.
