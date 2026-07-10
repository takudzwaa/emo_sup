import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:emo_sup/data/booking_store.dart';
import 'package:emo_sup/data/membership_store.dart';
import 'package:emo_sup/models/listener_profile.dart';
import 'package:emo_sup/screens/payment/checkout_screen.dart';
import 'package:emo_sup/services/payment_service.dart';
import 'package:emo_sup/theme/app_theme.dart';

void main() {
  late BookingStore store;
  late MembershipStore membership;
  late ListenerProfile listener;
  late TimeSlot premiumSlot;

  setUp(() {
    store = BookingStore(seedBookings: []);
    membership = MembershipStore();
    listener = store.listeners.first;
    premiumSlot = TimeSlot(
      start: DateTime.now().add(const Duration(days: 2, hours: 3)),
      requiresPremium: true,
    );
  });

  Future<void> pumpCheckout(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: CheckoutScreen(
          store: store,
          membershipStore: membership,
          listener: listener,
          slot: premiumSlot,
          paymentService: PaymentService(delay: Duration.zero),
        ),
      ),
    );
  }

  testWidgets('Premium checkout pays with card 4242', (tester) async {
    await pumpCheckout(tester);

    await tester.enterText(
      find.byKey(const Key('card_number')),
      '4242424242424242',
    );
    await tester.enterText(find.byKey(const Key('card_exp')), '12/30');
    await tester.enterText(find.byKey(const Key('card_cvc')), '123');
    final payBtn = find.text('Pay \$12');
    await tester.ensureVisible(payBtn);
    await tester.pumpAndSettle();
    await tester.tap(payBtn);
    await tester.pumpAndSettle();

    expect(store.upcomingConfirmed, isNotEmpty);
    expect(store.upcomingConfirmed.last.paymentStatus, 'paid');
    expect(store.upcomingConfirmed.last.priceCents, 1200);
    expect(find.text("You're booked"), findsOneWidget);
  });

  testWidgets('card 4000 declines without booking', (tester) async {
    await pumpCheckout(tester);

    await tester.enterText(
      find.byKey(const Key('card_number')),
      '4000000000000000',
    );
    await tester.enterText(find.byKey(const Key('card_exp')), '12/30');
    await tester.enterText(find.byKey(const Key('card_cvc')), '123');
    final payBtn = find.text('Pay \$12');
    await tester.ensureVisible(payBtn);
    await tester.pumpAndSettle();
    await tester.tap(payBtn);
    await tester.pumpAndSettle();

    expect(store.upcomingConfirmed, isEmpty);
    expect(find.textContaining('declined'), findsOneWidget);
    expect(find.text('Checkout'), findsOneWidget);
  });

  testWidgets('plan subscribe then booking', (tester) async {
    await pumpCheckout(tester);

    await tester.enterText(
      find.byKey(const Key('card_number')),
      '4242424242424242',
    );
    await tester.enterText(find.byKey(const Key('card_exp')), '12/30');
    await tester.enterText(find.byKey(const Key('card_cvc')), '123');
    final planBtn = find.text('Get Plan · \$29/mo');
    await tester.ensureVisible(planBtn);
    await tester.pumpAndSettle();
    await tester.tap(planBtn);
    await tester.pumpAndSettle();

    expect(membership.hasActivePlan, isTrue);
    expect(store.upcomingConfirmed, isNotEmpty);
    expect(store.upcomingConfirmed.last.paymentStatus, 'plan');
    expect(store.upcomingConfirmed.last.planApplied, isTrue);
    expect(store.upcomingConfirmed.last.priceCents, 0);
    expect(find.text("You're booked"), findsOneWidget);
  });
}
