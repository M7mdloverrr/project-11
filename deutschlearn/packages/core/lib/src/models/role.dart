enum Role {
  student,
  teacher,
  admin;

  static Role parse(Object? value) => switch (value) {
    'teacher' => Role.teacher,
    'admin' => Role.admin,
    _ => Role.student,
  };

  String get labelAr => switch (this) {
    Role.student => 'طالب',
    Role.teacher => 'معلم',
    Role.admin => 'مدير',
  };

  String get labelDe => switch (this) {
    Role.student => 'Schüler',
    Role.teacher => 'Lehrer',
    Role.admin => 'Admin',
  };
}
