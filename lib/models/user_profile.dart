/// How the user authenticated (credential type only — not displayed publicly).
enum AuthMethod {
  email,
  phone,
}

/// App-facing identity. No real name, email, or phone fields stored here —
/// Firebase Auth holds login credentials separately.
///
/// Firestore (later):
/// ```
/// users/{uid}
/// ```
class UserProfile {
  const UserProfile({
    required this.uid,
    required this.anonymousName,
    required this.authMethod,
    required this.createdAt,
  });

  final String uid;

  /// Only visible identity in the app (e.g. "Quiet River").
  final String anonymousName;

  final AuthMethod authMethod;
  final DateTime createdAt;

  UserProfile copyWith({
    String? uid,
    String? anonymousName,
    AuthMethod? authMethod,
    DateTime? createdAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      anonymousName: anonymousName ?? this.anonymousName,
      authMethod: authMethod ?? this.authMethod,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'anonymousName': anonymousName,
      'authMethod': authMethod.name,
      'createdAt': createdAt.toIso8601String(),
      // Future Firestore: prefer Timestamp.fromDate(createdAt)
      // Do NOT write email/phone here — those stay in Firebase Auth only.
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] as String,
      anonymousName: map['anonymousName'] as String,
      authMethod: AuthMethod.values.firstWhere(
        (m) => m.name == map['authMethod'],
        orElse: () => AuthMethod.email,
      ),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is UserProfile &&
            runtimeType == other.runtimeType &&
            uid == other.uid &&
            anonymousName == other.anonymousName &&
            authMethod == other.authMethod &&
            createdAt == other.createdAt;
  }

  @override
  int get hashCode =>
      Object.hash(uid, anonymousName, authMethod, createdAt);
}
