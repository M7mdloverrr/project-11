import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The teacher's active code (null when none or revoked).
final teacherCodeProvider = AsyncNotifierProvider<TeacherCodeController, TeacherCode?>(TeacherCodeController.new);

class TeacherCodeController extends AsyncNotifier<TeacherCode?> {
  @override
  Future<TeacherCode?> build() => ref.watch(linkRepositoryProvider).fetchActiveCode();

  /// Issues a new code server-side; any previous code stops working.
  Future<void> generate() async {
    final code = await ref.read(linkRepositoryProvider).generateCode();
    state = AsyncData(code);
  }

  Future<void> revoke() async {
    final code = state.value;
    if (code == null) return;
    await ref.read(linkRepositoryProvider).revokeCode(code.id);
    state = const AsyncData(null);
  }
}

final pendingRequestsProvider = AsyncNotifierProvider<PendingRequestsController, List<LinkRequest>>(
  PendingRequestsController.new,
);

class PendingRequestsController extends AsyncNotifier<List<LinkRequest>> {
  @override
  Future<List<LinkRequest>> build() => ref.watch(linkRepositoryProvider).fetchPendingRequests();

  Future<void> respond(String requestId, {required bool approve}) async {
    await ref.read(linkRepositoryProvider).respondToRequest(requestId, approve: approve);
    state = AsyncData([...?state.value?.where((r) => r.id != requestId)]);
    if (approve) ref.invalidate(linkedStudentsProvider);
  }
}

final linkedStudentsProvider = AsyncNotifierProvider<LinkedStudentsController, List<TeacherStudentLink>>(
  LinkedStudentsController.new,
);

class LinkedStudentsController extends AsyncNotifier<List<TeacherStudentLink>> {
  @override
  Future<List<TeacherStudentLink>> build() => ref.watch(linkRepositoryProvider).fetchLinkedStudents();

  Future<void> disconnect(String linkId) async {
    await ref.read(linkRepositoryProvider).disconnect(linkId);
    state = AsyncData([...?state.value?.where((l) => l.id != linkId)]);
  }
}
