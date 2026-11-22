import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TeacherCodeFormat.normalize', () {
    test('accepts canonical codes', () {
      expect(TeacherCodeFormat.normalize('TCH-7K2P9Q'), 'TCH-7K2P9Q');
    });

    test('normalizes casing, spaces, underscores and missing prefix/dash', () {
      expect(TeacherCodeFormat.normalize('tch-7k2p9q'), 'TCH-7K2P9Q');
      expect(TeacherCodeFormat.normalize('  TCH 7K2 P9Q '), 'TCH-7K2P9Q');
      expect(TeacherCodeFormat.normalize('TCH7K2P9Q'), 'TCH-7K2P9Q');
      expect(TeacherCodeFormat.normalize('7k2-p9q'), 'TCH-7K2P9Q');
      expect(TeacherCodeFormat.normalize('tch_7k2p9q'), 'TCH-7K2P9Q');
    });

    test('rejects wrong length', () {
      expect(TeacherCodeFormat.normalize(''), isNull);
      expect(TeacherCodeFormat.normalize('TCH-'), isNull);
      expect(TeacherCodeFormat.normalize('TCH-7K2P9'), isNull);
      expect(TeacherCodeFormat.normalize('TCH-7K2P9QQ'), isNull);
    });

    test('rejects look-alike characters excluded from the alphabet', () {
      for (final c in ['0', 'O', '1', 'I']) {
        expect(TeacherCodeFormat.normalize('TCH-7K2P9$c'), isNull, reason: c);
      }
    });

    test('rejects other prefixes and symbols', () {
      expect(TeacherCodeFormat.normalize('ABC-7K2P9Q'), isNull);
      expect(TeacherCodeFormat.normalize('TCH-7K2P9!'), isNull);
      expect(TeacherCodeFormat.isValid('TCH-ABCDEF'), isTrue);
      expect(TeacherCodeFormat.isValid('hello'), isFalse);
    });

    test('alphabet has 32 unambiguous symbols', () {
      expect(TeacherCodeFormat.alphabet.length, 32);
      expect(TeacherCodeFormat.alphabet.split('').toSet().length, 32);
      expect(TeacherCodeFormat.alphabet, isNot(contains(RegExp('[01IO]'))));
    });
  });
}
