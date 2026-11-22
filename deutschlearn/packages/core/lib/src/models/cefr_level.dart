/// Common European Framework levels used as the student's stage.
enum CefrLevel {
  a1,
  a2,
  b1,
  b2,
  c1,
  c2;

  String get code => name.toUpperCase();

  static CefrLevel parse(Object? value) {
    final s = value?.toString().toLowerCase();
    return CefrLevel.values.firstWhere((l) => l.name == s, orElse: () => CefrLevel.a1);
  }

  CefrLevel? get next => index + 1 < CefrLevel.values.length ? CefrLevel.values[index + 1] : null;

  static List<String> get codes => CefrLevel.values.map((l) => l.code).toList();
}
