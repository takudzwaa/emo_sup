import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/booking_store.dart';
import '../../data/membership_store.dart';
import '../../data/repositories/memory_booking_checkout_repository.dart';
import '../../domain/repositories/booking_checkout_repository.dart';
import '../../models/booking.dart';
import '../../models/listener_profile.dart';
import '../../models/payment_method.dart';
import '../../models/payment_result.dart';
import '../../services/payment_service.dart';
import '../../widgets/safety_quick_access_bar.dart';
import '../../widgets/soft_surface.dart';
import 'booking_success_screen.dart';

/// Demo multi-method checkout for premium sessions (PR 13–14).
///
/// Flow: [BookingCheckoutRepository.createBookingCheckout] (pending_payment)
/// → [PaymentGateway.charge] (FakePaymentGateway) → confirmPayment.
/// Never charges real money in Phase A.
class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    super.key,
    required this.store,
    required this.membershipStore,
    required this.listener,
    required this.slot,
    this.paymentService,
    this.checkoutRepository,
  });

  final BookingStore store;
  final MembershipStore membershipStore;
  final ListenerProfile listener;
  final TimeSlot slot;

  /// Injectable for tests (use [PaymentService] with [Duration.zero] delay).
  final PaymentService? paymentService;

  /// Injectable checkout (memory stand-in for CF createBookingCheckout).
  final BookingCheckoutRepository? checkoutRepository;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late final PaymentService _paymentService =
      widget.paymentService ?? PaymentService();
  late final BookingCheckoutRepository _checkout =
      widget.checkoutRepository ?? MemoryBookingCheckoutRepository();

  PaymentMethod _method = PaymentMethod.card;
  bool _processing = false;

  final _cardNumber = TextEditingController();
  final _cardExp = TextEditingController();
  final _cardCvc = TextEditingController();
  final _phone = TextEditingController();
  final _pin = TextEditingController();

  static const _sessionDollars =
      PaymentService.sessionPriceCents ~/ 100; // 12
  static const _planDollars = PaymentService.planPriceCents ~/ 100; // 29

  @override
  void dispose() {
    _cardNumber.dispose();
    _cardExp.dispose();
    _cardCvc.dispose();
    _phone.dispose();
    _pin.dispose();
    super.dispose();
  }

  Future<void> _paySession() async {
    if (_processing) return;
    setState(() => _processing = true);

    // Hold slot as pending_payment (server-authoritative path).
    final hold = await _checkout.createBookingCheckout(
      userId: widget.store.currentUserId,
      listenerId: widget.listener.id,
      slotStart: widget.slot.start,
      settlement: CheckoutSettlement.paid,
      priceCents: PaymentService.sessionPriceCents,
    );

    final result = await _paymentService.charge(
      method: _method,
      amountCents: PaymentService.sessionPriceCents,
      purpose: 'booking',
      bookingId: hold.booking.id,
      cardNumber: _cardNumber.text,
      exp: _cardExp.text,
      cvc: _cardCvc.text,
      phone: _phone.text,
      pin: _pin.text,
    );

    if (!mounted) return;

    if (!result.isSuccess) {
      await _checkout.cancelBooking(hold.booking.id);
      setState(() => _processing = false);
      _showDecline(result);
      return;
    }

    final confirmed = await _checkout.confirmPayment(
      bookingId: hold.booking.id,
      paymentId: hold.paymentId ?? 'pay_unknown',
      method: _method,
    );

    // Mirror into UI store for prototype lists.
    final booking = widget.store.confirmBooking(
      listenerId: widget.listener.id,
      slotStart: widget.slot.start,
      priceCents: PaymentService.sessionPriceCents,
      planApplied: false,
      paymentMethod: _method,
      paymentStatus: 'paid',
    );

    await _finishSuccess(
      booking.copyWith(id: confirmed.id),
      result.message,
    );
  }

  Future<void> _subscribePlan() async {
    if (_processing) return;
    setState(() => _processing = true);

    final result = await _paymentService.subscribe(
      method: _method,
      amountCents: PaymentService.planPriceCents,
      cardNumber: _cardNumber.text,
      exp: _cardExp.text,
      cvc: _cardCvc.text,
      phone: _phone.text,
      pin: _pin.text,
    );

    if (!mounted) return;

    if (!result.isSuccess) {
      setState(() => _processing = false);
      _showDecline(result);
      return;
    }

    widget.membershipStore.activatePlan();

    final booking = widget.store.confirmBooking(
      listenerId: widget.listener.id,
      slotStart: widget.slot.start,
      priceCents: 0,
      planApplied: true,
      paymentMethod: _method,
      paymentStatus: 'plan',
    );

    await _finishSuccess(booking, result.message);
  }

  void _showDecline(PaymentResult result) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.message.isEmpty
              ? 'Payment declined (demo). Try again.'
              : result.message,
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _finishSuccess(Booking booking, String receiptLine) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => BookingSuccessScreen(
          booking: booking,
          listener: widget.listener,
          receiptLine: receiptLine,
        ),
      ),
    );
    if (!mounted) return;
    Navigator.of(context).pop(booking);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isCard = _method == PaymentMethod.card;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: SoftGradientBackground(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Demo-only banner
                        SoftCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 18,
                                color: scheme.tertiary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Demo payment only — you will not be charged.',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurface
                                        .withValues(alpha: 0.75),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SoftCard(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Text(
                                'Session',
                                style: textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurface
                                      .withValues(alpha: 0.55),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '\$$_sessionDollars',
                                style: textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: scheme.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'with ${widget.listener.displayName}',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurface
                                      .withValues(alpha: 0.65),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Payment method',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final method in PaymentMethod.values)
                              _MethodChip(
                                method: method,
                                selected: _method == method,
                                onTap: _processing
                                    ? null
                                    : () => setState(() => _method = method),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (isCard) ...[
                          TextField(
                            key: const Key('card_number'),
                            controller: _cardNumber,
                            enabled: !_processing,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(16),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Card number',
                              hintText: '4242 4242 4242 4242',
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  key: const Key('card_exp'),
                                  controller: _cardExp,
                                  enabled: !_processing,
                                  keyboardType: TextInputType.datetime,
                                  decoration: const InputDecoration(
                                    labelText: 'Exp',
                                    hintText: 'MM/YY',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  key: const Key('card_cvc'),
                                  controller: _cardCvc,
                                  enabled: !_processing,
                                  keyboardType: TextInputType.number,
                                  obscureText: true,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(4),
                                  ],
                                  decoration: const InputDecoration(
                                    labelText: 'CVC',
                                    hintText: '123',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          TextField(
                            key: const Key('mm_phone'),
                            controller: _phone,
                            enabled: !_processing,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Mobile number',
                              hintText: '07XX XXX XXX',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            key: const Key('mm_pin'),
                            controller: _pin,
                            enabled: !_processing,
                            keyboardType: TextInputType.number,
                            obscureText: true,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Demo PIN',
                              hintText: '0000',
                              helperText: 'Use PIN 0000 to succeed (demo)',
                            ),
                          ),
                        ],
                        const SizedBox(height: 28),
                        SoftPrimaryButton(
                          onPressed: _processing ? null : _paySession,
                          label: _processing
                              ? 'Processing…'
                              : 'Pay \$$_sessionDollars',
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _processing ? null : _subscribePlan,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            side: BorderSide(
                              color: scheme.outline.withValues(alpha: 0.45),
                            ),
                          ),
                          child: Text(
                            'Get Plan · \$$_planDollars/mo',
                            style: textTheme.labelLarge?.copyWith(
                              fontSize: 15,
                              color: scheme.onSurface.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Private payment details stay on this device in the demo.',
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.45),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                Divider(
                  height: 1,
                  color: scheme.outline.withValues(alpha: 0.2),
                ),
                const SafetyQuickAccessBar(),
              ],
            ),
            if (_processing)
              Positioned.fill(
                child: ColoredBox(
                  color: scheme.surface.withValues(alpha: 0.35),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MethodChip extends StatelessWidget {
  const _MethodChip({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  final PaymentMethod method;
  final bool selected;
  final VoidCallback? onTap;

  IconData get _icon {
    switch (method) {
      case PaymentMethod.card:
        return Icons.credit_card_rounded;
      case PaymentMethod.ecocash:
        return Icons.phone_android_rounded;
      case PaymentMethod.netone:
        return Icons.smartphone_rounded;
      case PaymentMethod.innbucks:
        return Icons.account_balance_wallet_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? scheme.primary.withValues(alpha: 0.14)
                : scheme.surfaceContainerHighest.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? scheme.primary.withValues(alpha: 0.55)
                  : scheme.outline.withValues(alpha: 0.22),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _icon,
                size: 18,
                color: selected
                    ? scheme.primary
                    : scheme.onSurface.withValues(alpha: 0.55),
              ),
              const SizedBox(width: 8),
              Text(
                method.displayName,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? scheme.primary : scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
