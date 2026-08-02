import 'dart:convert';

import 'package:flutter/services.dart';

/// Offline crisis resource pack (PR 18 / 27).
///
/// **Hard gate:** [partnerSignOff] must be present. sn/nd packs require the
/// same partner metadata as EN.
class CrisisPack {
  const CrisisPack({
    required this.locale,
    required this.region,
    required this.version,
    required this.partnerSignOff,
    required this.disclaimer,
    required this.resources,
  });

  final String locale;
  final String region;
  final String version;
  final CrisisPartnerSignOff partnerSignOff;
  final String disclaimer;
  final List<CrisisResource> resources;

  /// Markers used in pilot/scaffold packs before a real local partner has
  /// reviewed and signed off. A non-empty field is not enough on its own —
  /// "PILOT-PLACEHOLDER — replace with vetted ZW partner" is non-empty and
  /// would otherwise satisfy a naive check while shipping fake sign-off.
  static const _placeholderMarkers = ['PLACEHOLDER', 'TBD', 'TODO'];

  static bool _looksReal(String value) {
    final upper = value.toUpperCase();
    return value.isNotEmpty &&
        !_placeholderMarkers.any(upper.contains);
  }

  bool get isSignedOff =>
      _looksReal(partnerSignOff.partner) &&
      partnerSignOff.signedAt.isNotEmpty &&
      _looksReal(partnerSignOff.reviewer);

  factory CrisisPack.fromJson(Map<String, dynamic> json) {
    final sign = json['partnerSignOff'] as Map<String, dynamic>? ?? {};
    final list = (json['resources'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .map(CrisisResource.fromJson)
        .toList();
    return CrisisPack(
      locale: json['locale'] as String? ?? 'en',
      region: json['region'] as String? ?? 'ZW',
      version: json['version'] as String? ?? '0',
      partnerSignOff: CrisisPartnerSignOff(
        partner: sign['partner'] as String? ?? '',
        signedAt: sign['signedAt'] as String? ?? '',
        reviewer: sign['reviewer'] as String? ?? '',
        notes: sign['notes'] as String? ?? '',
      ),
      disclaimer: json['disclaimer'] as String? ?? '',
      resources: list,
    );
  }
}

class CrisisPartnerSignOff {
  const CrisisPartnerSignOff({
    required this.partner,
    required this.signedAt,
    required this.reviewer,
    this.notes = '',
  });

  final String partner;
  final String signedAt;
  final String reviewer;
  final String notes;
}

class CrisisResource {
  const CrisisResource({
    required this.id,
    required this.title,
    required this.subtitle,
    this.tel,
    this.url,
    this.icon = 'support',
  });

  final String id;
  final String title;
  final String subtitle;
  final String? tel;
  final String? url;
  final String icon;

  factory CrisisResource.fromJson(Map<String, dynamic> json) {
    return CrisisResource(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      tel: json['tel'] as String?,
      url: json['url'] as String?,
      icon: json['icon'] as String? ?? 'support',
    );
  }
}

/// Loads bundled Zimbabwe crisis packs by locale (PR 18 + 27).
class CrisisPackLoader {
  static const enPath = 'assets/crisis/zw_en.json';
  static const snPath = 'assets/crisis/zw_sn.json';
  static const ndPath = 'assets/crisis/zw_nd.json';

  static String assetPathForLocale(String languageCode) {
    switch (languageCode.toLowerCase()) {
      case 'sn':
        return snPath;
      case 'nd':
        return ndPath;
      case 'en':
      default:
        return enPath;
    }
  }

  static Future<CrisisPack> loadEnZw() => loadForLocale('en');

  static Future<CrisisPack> loadForLocale(String languageCode) async {
    final path = assetPathForLocale(languageCode);
    final raw = await rootBundle.loadString(path);
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final pack = CrisisPack.fromJson(map);
    if (!pack.isSignedOff) {
      throw StateError(
        'Crisis pack $path missing partnerSignOff — do not ship (hard gate).',
      );
    }
    return pack;
  }
}
