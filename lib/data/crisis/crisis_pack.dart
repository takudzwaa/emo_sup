import 'dart:convert';

import 'package:flutter/services.dart';

/// Offline crisis resource pack (PR 18).
///
/// **Hard gate:** [partnerSignOff] must be present for production-facing builds.
/// sn/nd packs are deferred until partner-reviewed.
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

  bool get isSignedOff =>
      partnerSignOff.partner.isNotEmpty &&
      partnerSignOff.signedAt.isNotEmpty &&
      partnerSignOff.reviewer.isNotEmpty;

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

/// Loads bundled EN Zimbabwe pack.
class CrisisPackLoader {
  static const assetPath = 'assets/crisis/zw_en.json';

  static Future<CrisisPack> loadEnZw() async {
    final raw = await rootBundle.loadString(assetPath);
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final pack = CrisisPack.fromJson(map);
    if (!pack.isSignedOff) {
      throw StateError(
        'Crisis pack missing partnerSignOff — do not ship (PR 18 hard gate).',
      );
    }
    return pack;
  }
}
