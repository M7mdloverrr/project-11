import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:core/testing.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('sends a message and shows incoming replies live', (tester) async {
    final repo = FakeChatRepository(myId: 'student-1');
    await tester.pumpWidget(
      ProviderScope(
        retry: noRetry,
        overrides: [
          chatRepositoryProvider.overrideWithValue(repo),
          currentProfileProvider.overrideWithValue(
            const Profile(id: 'student-1', role: Role.student, displayName: 'Sara'),
          ),
        ],
        child: MaterialApp(
          theme: DLTheme.light(),
          home: const Scaffold(
            body: ChatThreadView(teacherId: 'teacher-1', studentId: 'student-1'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Noch keine Nachrichten'), findsOneWidget);

    await tester.tap(find.byKey(const Key('chat-send')));
    await tester.pumpAndSettle();
    expect(repo.messages, isEmpty, reason: 'empty messages are not sent');

    await tester.enterText(find.byKey(const Key('chat-input')), '  Hallo!  ');
    await tester.tap(find.byKey(const Key('chat-send')));
    await tester.pumpAndSettle();
    expect(repo.messages.single.body, 'Hallo!');
    expect(find.text('Hallo!'), findsOneWidget);

    repo.receive(
      ChatMessage(
        id: 'r1',
        teacherId: 'teacher-1',
        studentId: 'student-1',
        senderId: 'teacher-1',
        body: 'Hallo Sara!',
        createdAt: DateTime.now(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Hallo Sara!'), findsOneWidget);

    repo.nextError = const AppFailure(FailureKind.network);
    await tester.enterText(find.byKey(const Key('chat-input')), 'Noch da?');
    await tester.tap(find.byKey(const Key('chat-send')));
    await tester.pumpAndSettle();
    expect(repo.messages, hasLength(2));
    expect(find.byType(DLBanner), findsOneWidget);
  });
}
