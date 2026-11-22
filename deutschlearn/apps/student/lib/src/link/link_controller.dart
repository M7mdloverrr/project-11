import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The student's current teacher link, refreshed after every change.
final studentLinkProvider = AsyncNotifierProvider<StudentLinkController, StudentLinkView>(StudentLinkController.new);

class StudentLinkController extends AsyncNotifier<StudentLinkView> {
  @override
  Future<StudentLinkView> build() async =>
      StudentLinkView.fromLink(await ref.watch(linkRepositoryProvider).fetchStudentLink());

  Future<void> refresh() async {
    ref.invalidateSelf();
    try {
      await future;
    } on Object {
      // Shown through the provider's AsyncError state.
    }
  }

  Future<void> disconnect(String linkId) async {
    final link = await ref.read(linkRepositoryProvider).disconnect(linkId);
    state = AsyncData(StudentLinkView.fromLink(link));
  }
}

/// Steps of the "enter code → preview teacher → confirm" flow.
sealed class LinkFlowState {
  const LinkFlowState();
}

final class LinkFlowEntering extends LinkFlowState {
  const LinkFlowEntering([this.error]);
  final AppFailure? error;
}

final class LinkFlowLookingUp extends LinkFlowState {
  const LinkFlowLookingUp();
}

final class LinkFlowPreview extends LinkFlowState {
  const LinkFlowPreview(this.code, this.teacher, {this.submitting = false, this.error});
  final String code;
  final TeacherPublicInfo teacher;
  final bool submitting;
  final AppFailure? error;
}

final class LinkFlowRequested extends LinkFlowState {
  const LinkFlowRequested(this.result);
  final LinkRequestResult result;
}

final linkFlowProvider = NotifierProvider.autoDispose<LinkFlowController, LinkFlowState>(LinkFlowController.new);

class LinkFlowController extends Notifier<LinkFlowState> {
  @override
  LinkFlowState build() => const LinkFlowEntering();

  Future<void> lookup(String input) async {
    final code = TeacherCodeFormat.normalize(input);
    if (code == null) {
      state = const LinkFlowEntering(AppFailure(FailureKind.invalidCodeFormat));
      return;
    }
    state = const LinkFlowLookingUp();
    try {
      final teacher = await ref.read(linkRepositoryProvider).lookupTeacher(code);
      if (!ref.mounted) return;
      state = teacher == null
          ? const LinkFlowEntering(AppFailure(FailureKind.codeNotFound))
          : LinkFlowPreview(code, teacher);
    } on AppFailure catch (f) {
      if (ref.mounted) state = LinkFlowEntering(f);
    }
  }

  Future<void> confirm() async {
    final s = state;
    if (s is! LinkFlowPreview || s.submitting) return;
    state = LinkFlowPreview(s.code, s.teacher, submitting: true);
    try {
      final result = await ref.read(linkRepositoryProvider).requestLink(s.code);
      if (!ref.mounted) return;
      state = LinkFlowRequested(result);
      await ref.read(studentLinkProvider.notifier).refresh();
    } on AppFailure catch (f) {
      if (ref.mounted) state = LinkFlowPreview(s.code, s.teacher, error: f);
    }
  }

  void reset() => state = const LinkFlowEntering();
}
