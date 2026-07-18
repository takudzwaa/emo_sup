import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:emo_sup/data/booking_store.dart';
import 'package:emo_sup/main.dart';
import 'package:emo_sup/models/booking.dart';
import 'package:emo_sup/screens/bookings_screen.dart';
import 'package:emo_sup/utils/date_format.dart';
import 'package:emo_sup/widgets/listener_card.dart';
import 'package:emo_sup/widgets/premium_badge.dart';
import 'package:emo_sup/widgets/soft_surface.dart';

void main() {
  testWidgets('Bookings lists listeners with next slot preview', (tester) async {
    final store = BookingStore(seedBookings: []);
    await tester.pumpWidget(
      MaterialApp(home: BookingsScreen(bookingStore: store)),
    );

    expect(find.text('Find a listener'), findsWidgets);
    expect(find.text('Listener — Harbor'), findsOneWidget);
    expect(find.textContaining('Next:'), findsWidgets);
    // Scroll to ensure all listener cards are reachable (soft spacing).
    await tester.drag(find.byType(ListView).first, const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(find.text('Listener — Lantern'), findsOneWidget);
    expect(find.byType(ListenerCard), findsWidgets);
  });

  testWidgets('Premium badge appears for Lantern', (tester) async {
    final store = BookingStore(seedBookings: []);
    await tester.pumpWidget(
      MaterialApp(home: BookingsScreen(bookingStore: store)),
    );

    await tester.drag(find.byType(ListView).first, const Offset(0, -400));
    await tester.pumpAndSettle();

    expect(find.text('Listener — Lantern'), findsOneWidget);
    expect(find.byType(PremiumBadge), findsOneWidget);
    expect(find.text('Premium'), findsOneWidget);
  });

  testWidgets('Language filter narrows listener list', (tester) async {
    final store = BookingStore(seedBookings: []);
    await tester.pumpWidget(
      MaterialApp(home: BookingsScreen(bookingStore: store)),
    );

    expect(find.text('All'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilterChip, 'Shona'));
    await tester.pumpAndSettle();

    // Harbor and Cedar speak Shona; Moss is English + Ndebele only.
    expect(find.text('Listener — Harbor'), findsOneWidget);
    expect(find.text('Listener — Cedar'), findsOneWidget);
    expect(find.text('Listener — Moss'), findsNothing);
  });

  testWidgets('Tapping listener opens slot picker', (tester) async {
    final store = BookingStore(seedBookings: []);
    await tester.pumpWidget(
      MaterialApp(home: BookingsScreen(bookingStore: store)),
    );

    await tester.tap(find.text('Listener — Moss'));
    await tester.pumpAndSettle();

    expect(find.text('Choose a time'), findsOneWidget);
    expect(find.text('Listener — Moss'), findsWidgets);
  });

  testWidgets('Full booking flow confirms and shows upcoming', (tester) async {
    final store = BookingStore(seedBookings: []);
    await tester.pumpWidget(
      MaterialApp(home: BookingsScreen(bookingStore: store)),
    );

    await tester.tap(find.text('Listener — Harbor'));
    await tester.pumpAndSettle();

    // Pick first time chip (contains AM or PM).
    final timeFinder = find.textContaining('AM');
    expect(timeFinder, findsWidgets);
    await tester.tap(timeFinder.first);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Confirm booking'), findsWidgets);
    expect(find.textContaining("You're booking with"), findsOneWidget);

    // Soft primary CTA (not Material FilledButton).
    await tester.tap(find.byType(SoftPrimaryButton));
    await tester.pumpAndSettle();

    expect(store.upcomingConfirmed, isNotEmpty);
    expect(find.textContaining('My upcoming'), findsWidgets);
    expect(find.text('Listener — Harbor'), findsWidgets);
    expect(find.text('Cancel booking'), findsOneWidget);
  });

  testWidgets('Upcoming tab can cancel a booking', (tester) async {
    final store = BookingStore();
    await tester.pumpWidget(
      MaterialApp(
        home: BookingsScreen(bookingStore: store, initialTabIndex: 1),
      ),
    );

    expect(store.upcomingConfirmed, isNotEmpty);
    expect(find.text('Cancel booking'), findsOneWidget);

    await tester.tap(find.text('Cancel booking'));
    await tester.pumpAndSettle();
    // Dialog also has "Cancel booking" — tap the last (dialog confirm).
    await tester.tap(find.text('Cancel booking').last);
    await tester.pumpAndSettle();

    expect(store.upcomingConfirmed, isEmpty);
    expect(find.text('No upcoming sessions'), findsOneWidget);
  });

  testWidgets('Home navigates to Bookings', (tester) async {
    await tester.pumpWidget(buildTestApp());

    // Upcoming card + book-later card may sit below the fold.
    await tester.ensureVisible(find.text('Book a session for later'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Book a session for later'));
    await tester.pumpAndSettle();

    expect(find.text('Book a session'), findsOneWidget);
    expect(find.text('Find a listener'), findsWidgets);
  });

  test('Booking model serializes for Firestore shape', () {
    final booking = Booking(
      id: 'b1',
      userId: 'u1',
      listenerId: 'l1',
      slotStart: DateTime.utc(2026, 7, 10, 14),
      status: BookingStatus.confirmed,
    );
    final map = booking.toMap();
    expect(map['status'], 'confirmed');
    expect(Booking.fromMap(map), booking);
  });

  test('BookingStore generates mock slots for next days', () {
    final store = BookingStore(seedBookings: []);
    final slots = store.slotsForListener('listener_harbor');
    expect(slots, isNotEmpty);
    // Spread across more than one day.
    final days = slots.map((s) => DateTime(s.start.year, s.start.month, s.start.day)).toSet();
    expect(days.length, greaterThan(1));
  });

  test('AppDateFormat formats slot labels', () {
    final d = DateTime(2026, 7, 9, 14, 0);
    expect(AppDateFormat.timeOfDay(d), '2:00 PM');
    expect(AppDateFormat.mediumDate(d), 'Jul 9, 2026');
    expect(AppDateFormat.slotLabel(d), contains('2:00 PM'));
  });
}
