/// Error categories the UI knows how to explain.
enum FailureKind {
  backendNotConfigured,
  network,
  invalidCredentials,
  emailNotConfirmed,
  emailInUse,
  weakPassword,
  invalidCodeFormat,
  codeNotFound,
  alreadyLinked,
  rateLimited,
  forbidden,
  notFound,
  unknown,
}

/// A user-facing failure with bilingual text (Arabic first, then German).
class AppFailure implements Exception {
  const AppFailure(this.kind, [this.detail]);

  final FailureKind kind;

  /// Raw message from the backend, for logs only.
  final String? detail;

  String get messageAr => switch (kind) {
    FailureKind.backendNotConfigured => 'الخادم غير مُعدّ بعد. أضف بيانات Supabase ثم أعد تشغيل التطبيق.',
    FailureKind.network => 'تعذّر الاتصال بالخادم. تحقق من الإنترنت وحاول مجدداً.',
    FailureKind.invalidCredentials => 'البريد الإلكتروني أو كلمة المرور غير صحيحة.',
    FailureKind.emailNotConfirmed => 'يرجى تأكيد بريدك الإلكتروني أولاً من الرسالة التي أرسلناها.',
    FailureKind.emailInUse => 'هذا البريد الإلكتروني مسجّل بالفعل.',
    FailureKind.weakPassword => 'كلمة المرور ضعيفة جداً.',
    FailureKind.invalidCodeFormat => 'صيغة الرمز غير صحيحة. مثال: TCH-AB12CD',
    FailureKind.codeNotFound => 'لم يتم العثور على معلم بهذا الرمز، أو تم إلغاء الرمز.',
    FailureKind.alreadyLinked => 'أنت مرتبط بمعلم آخر بالفعل. افصل الارتباط الحالي أولاً.',
    FailureKind.rateLimited => 'محاولات كثيرة. انتظر بضع دقائق ثم حاول مجدداً.',
    FailureKind.forbidden => 'ليست لديك صلاحية لهذا الإجراء.',
    FailureKind.notFound => 'العنصر غير موجود أو تمت معالجته بالفعل.',
    FailureKind.unknown => 'حدث خطأ غير متوقع. حاول مجدداً.',
  };

  String get messageDe => switch (kind) {
    FailureKind.backendNotConfigured => 'Backend nicht konfiguriert.',
    FailureKind.network => 'Keine Verbindung zum Server.',
    FailureKind.invalidCredentials => 'E-Mail oder Passwort falsch.',
    FailureKind.emailNotConfirmed => 'Bitte bestätige zuerst deine E-Mail.',
    FailureKind.emailInUse => 'Diese E-Mail ist bereits registriert.',
    FailureKind.weakPassword => 'Passwort zu schwach.',
    FailureKind.invalidCodeFormat => 'Ungültiges Code-Format.',
    FailureKind.codeNotFound => 'Kein Lehrer mit diesem Code gefunden.',
    FailureKind.alreadyLinked => 'Bereits mit einem anderen Lehrer verbunden.',
    FailureKind.rateLimited => 'Zu viele Versuche. Bitte später erneut.',
    FailureKind.forbidden => 'Keine Berechtigung.',
    FailureKind.notFound => 'Nicht gefunden.',
    FailureKind.unknown => 'Unerwarteter Fehler.',
  };

  String get message => '$messageAr\n$messageDe';

  @override
  String toString() => 'AppFailure($kind${detail == null ? '' : ': $detail'})';
}
