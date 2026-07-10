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
