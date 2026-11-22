import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';

TeacherStudentLink _link(LinkStatus status) =>
    TeacherStudentLink(id: 'l1', teacherId: 't1', studentId: 's1', status: status, updatedAt: DateTime.utc(2026));

void main() {
  group('StudentLinkView.fromLink', () {
    test('no link → NoTeacherLinked, can link', () {
      final v = StudentLinkView.fromLink(null);
      expect(v, isA<NoTeacherLinked>());
      expect(v.canLinkNewTeacher, isTrue);
    });

    test('pending → LinkPendingApproval, cannot link another teacher', () {
      final v = StudentLinkView.fromLink(_link(LinkStatus.pending));
      expect(v, isA<LinkPendingApproval>());
      expect(v.canLinkNewTeacher, isFalse);
    });

    test('active → LinkActive, cannot link another teacher', () {
      final v = StudentLinkView.fromLink(_link(LinkStatus.active));
      expect(v, isA<LinkActive>());
      expect(v.canLinkNewTeacher, isFalse);
    });

    test('disconnected → LinkDisconnected, can link again', () {
      final v = StudentLinkView.fromLink(_link(LinkStatus.disconnected));
      expect(v, isA<LinkDisconnected>());
      expect(v.canLinkNewTeacher, isTrue);
    });
  });

  group('LinkStatus', () {
    test('allowed transitions mirror the backend', () {
      expect(LinkStatus.pending.canTransitionTo(LinkStatus.active), isTrue);
      expect(LinkStatus.pending.canTransitionTo(LinkStatus.disconnected), isTrue);
      expect(LinkStatus.active.canTransitionTo(LinkStatus.disconnected), isTrue);
      expect(LinkStatus.disconnected.canTransitionTo(LinkStatus.pending), isTrue);
    });

    test('forbidden transitions', () {
      expect(LinkStatus.active.canTransitionTo(LinkStatus.pending), isFalse);
      expect(LinkStatus.disconnected.canTransitionTo(LinkStatus.active), isFalse);
      for (final s in LinkStatus.values) {
        expect(s.canTransitionTo(s), isFalse);
      }
    });

    test('parses database values', () {
      expect(LinkStatus.parse('active'), LinkStatus.active);
      expect(LinkStatus.parse('disconnected'), LinkStatus.disconnected);
      expect(LinkStatus.parse('pending'), LinkStatus.pending);
    });
  });

  test('TeacherStudentLink.fromJson reads the embedded teacher profile', () {
    final link = TeacherStudentLink.fromJson({
      'id': 'l1',
      'teacher_id': 't1',
      'student_id': 's1',
      'status': 'active',
      'created_at': '2026-11-22T10:00:00Z',
      'updated_at': '2026-11-22T11:00:00Z',
      'teacher': {'display_name': 'Frau Weber', 'avatar_url': null},
    });
    expect(link.status, LinkStatus.active);
    expect(link.teacher?.displayName, 'Frau Weber');
    expect(link.teacher?.id, 't1');
    expect(link.student, isNull);
    expect(StudentLinkView.fromLink(link), isA<LinkActive>());
  });
}
