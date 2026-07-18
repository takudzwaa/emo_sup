/// Build flavor via `--dart-define=FLAVOR=prototype|staging|prod`.
///
/// Default is [AppFlavor.prototype] so local runs and widget tests work
/// without a linked Firebase project.
enum AppFlavor {
  /// In-memory stores + [PrototypeAuthService]; no network required.
  prototype,

  /// Real Firebase project with staging keys / App Check debug tokens.
  staging,

  /// Production Firebase project.
  prod,
}

/// Resolved at compile time from `--dart-define=FLAVOR=...`.
class AppFlavorConfig {
  AppFlavorConfig._();

  static const String _raw = String.fromEnvironment(
    'FLAVOR',
    defaultValue: 'prototype',
  );

  static AppFlavor get current {
    switch (_raw.toLowerCase().trim()) {
      case 'staging':
      case 'stage':
        return AppFlavor.staging;
      case 'prod':
      case 'production':
        return AppFlavor.prod;
      case 'prototype':
      case 'proto':
      case 'demo':
      default:
        return AppFlavor.prototype;
    }
  }

  static bool get usesFirebase =>
      current == AppFlavor.staging || current == AppFlavor.prod;

  static bool get isPrototype => current == AppFlavor.prototype;

  /// Human-readable label for debug banners / logs.
  static String get label => current.name;
}
