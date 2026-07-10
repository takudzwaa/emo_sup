/// Listener access tier for premium-gated slots and profiles.
enum ListenerTier { standard, premium }

/// Anonymous listener card data for booking (no photos, no last names).
///
/// Firestore (later):
/// ```
/// listeners/{listenerId}
/// ```
class ListenerProfile {
  const ListenerProfile({
    required this.id,
    required this.displayName,
    required this.bio,
    required this.languages,
    this.tier = ListenerTier.standard,
  });

  final String id;

  /// e.g. "Listener — Harbor" — never a real full name.
  final String displayName;

  /// Short self-written bio, 1–2 lines.
  final String bio;

  /// Languages the listener can support, e.g. ["English", "Spanish"].
  final List<String> languages;

  final ListenerTier tier;

  bool get isPremium => tier == ListenerTier.premium;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'displayName': displayName,
      'bio': bio,
      'languages': languages,
      'tier': tier.name,
    };
  }

  factory ListenerProfile.fromMap(Map<String, dynamic> map) {
    return ListenerProfile(
      id: map['id'] as String,
      displayName: map['displayName'] as String,
      bio: map['bio'] as String,
      languages: (map['languages'] as List<dynamic>).cast<String>(),
      tier: ListenerTier.values.firstWhere(
        (t) => t.name == map['tier'],
        orElse: () => ListenerTier.standard,
      ),
    );
  }
}

/// A bookable time slot for a listener.
///
/// Not a Firestore document by itself — typically derived from
/// `listeners/{listenerId}/availability` later.
class TimeSlot {
  const TimeSlot({
    required this.start,
    this.requiresPremium = false,
  });

  final DateTime start;

  /// Prototype-only tag; does not block booking.
  final bool requiresPremium;

  DateTime get end => start.add(const Duration(minutes: 45));
}
