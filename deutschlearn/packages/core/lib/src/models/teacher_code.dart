/// Teacher code format `TCH-XXXXXX`. Must stay in sync with
/// supabase/functions/_shared/teacher_code.ts and the SQL check constraint.
abstract final class TeacherCodeFormat {
  static const prefix = 'TCH-';
  static const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static const length = 6;
  static final pattern = RegExp(r'^TCH-[ABCDEFGHJKLMNPQRSTUVWXYZ23456789]{6}$');

  /// Canonical code for user input like "tch-ab12cd", "TCH AB12CD" or
  /// "ab12cd", or null when it cannot be a valid code.
  static String? normalize(String input) {
    var s = input.toUpperCase().replaceAll(RegExp(r'[\s_]'), '');
    if (s.startsWith('TCH-')) {
      s = s.substring(4);
    } else if (s.startsWith('TCH')) {
      s = s.substring(3);
    }
    s = s.replaceAll('-', '');
    final code = '$prefix$s';
    return pattern.hasMatch(code) ? code : null;
  }

  static bool isValid(String input) => normalize(input) != null;
}

class TeacherCode {
  const TeacherCode({required this.id, required this.code, required this.revoked, required this.createdAt});

  factory TeacherCode.fromJson(Map<String, dynamic> json) => TeacherCode(
    id: json['id'] as String,
    code: json['code'] as String,
    revoked: (json['revoked'] as bool?) ?? false,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  final String id;
  final String code;
  final bool revoked;
  final DateTime createdAt;

  bool get isActive => !revoked;
}
