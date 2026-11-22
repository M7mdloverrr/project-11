import 'cefr_level.dart';
import 'role.dart';

class Profile {
  const Profile({
    required this.id,
    required this.role,
    required this.displayName,
    this.locale = 'ar',
    this.avatarUrl,
    this.cefrLevel = CefrLevel.a1,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    id: json['id'] as String,
    role: Role.parse(json['role']),
    displayName: (json['display_name'] as String?) ?? '',
    locale: (json['locale'] as String?) ?? 'ar',
    avatarUrl: json['avatar_url'] as String?,
    cefrLevel: CefrLevel.parse(json['cefr_level']),
  );

  final String id;
  final Role role;
  final String displayName;
  final String locale;
  final String? avatarUrl;
  final CefrLevel cefrLevel;

  bool get hasDisplayName => displayName.trim().isNotEmpty;

  Profile copyWith({String? displayName, String? locale, String? avatarUrl}) => Profile(
    id: id,
    role: role,
    displayName: displayName ?? this.displayName,
    locale: locale ?? this.locale,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    cefrLevel: cefrLevel,
  );

  @override
  bool operator ==(Object other) =>
      other is Profile &&
      other.id == id &&
      other.role == role &&
      other.displayName == displayName &&
      other.locale == locale &&
      other.avatarUrl == avatarUrl &&
      other.cefrLevel == cefrLevel;

  @override
  int get hashCode => Object.hash(id, role, displayName, locale, avatarUrl, cefrLevel);
}
