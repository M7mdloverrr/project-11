/// Form validators returning bilingual (Arabic • German) messages, or null when valid.
abstract final class AuthValidators {
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$');
  static const minPasswordLength = 8;

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'أدخل بريدك الإلكتروني • E-Mail eingeben';
    if (!_email.hasMatch(v)) return 'بريد إلكتروني غير صالح • Ungültige E-Mail-Adresse';
    return null;
  }

  /// Login only checks presence; the server decides if it is correct.
  static String? loginPassword(String? value) =>
      (value ?? '').isEmpty ? 'أدخل كلمة المرور • Passwort eingeben' : null;

  static String? newPassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'أدخل كلمة المرور • Passwort eingeben';
    if (v.length < minPasswordLength) {
      return 'على الأقل $minPasswordLength أحرف • Mindestens $minPasswordLength Zeichen';
    }
    if (!RegExp(r'[A-Za-z]').hasMatch(v) || !RegExp(r'\d').hasMatch(v)) {
      return 'استخدم حروفاً وأرقاماً • Buchstaben und Ziffern verwenden';
    }
    return null;
  }

  static String? Function(String?) confirmPassword(String Function() original) =>
      (value) => value != original() ? 'كلمتا المرور غير متطابقتين • Passwörter stimmen nicht überein' : null;

  static String? displayName(String? value) {
    final v = value?.trim() ?? '';
    if (v.length < 2) return 'أدخل اسمك (حرفان على الأقل) • Name eingeben (mind. 2 Zeichen)';
    if (v.length > 40) return 'الاسم طويل جداً • Name ist zu lang';
    return null;
  }
}
