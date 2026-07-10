import 'payment_method.dart';

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
