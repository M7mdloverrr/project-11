import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final myHomeworkStreamProvider = StreamProvider<List<Homework>>(
  (ref) => ref.watch(classroomRepositoryProvider).watchHomework(),
);

final mySubmissionsProvider = StreamProvider<List<HomeworkSubmission>>(
  (ref) => ref.watch(classroomRepositoryProvider).watchSubmissions(),
);

typedef HomeworkEntry = ({Homework homework, HomeworkSubmission? submission});

extension HomeworkEntryX on HomeworkEntry {
  SubmissionStatus get status => submission?.status ?? SubmissionStatus.notStarted;
  bool get isOpen => status.editableByStudent;
}

/// Assigned homework with my submission, open work first (by deadline), then finished work.
final homeworkProvider = Provider<AsyncValue<List<HomeworkEntry>>>((ref) {
  final hw = ref.watch(myHomeworkStreamProvider);
  final subs = ref.watch(mySubmissionsProvider);
  if (hw case AsyncError(:final error, :final stackTrace)) return AsyncError(error, stackTrace);
  if (subs case AsyncError(:final error, :final stackTrace)) return AsyncError(error, stackTrace);
  final list = hw.value;
  final s = subs.value;
  if (list == null || s == null) return const AsyncLoading();
  final byHw = {for (final x in s) x.homeworkId: x};
  final entries = [for (final h in list) (homework: h, submission: byHw[h.id])];
  int rank(HomeworkEntry e) => e.isOpen ? 0 : 1;
  entries.sort((a, b) {
    final r = rank(a).compareTo(rank(b));
    if (r != 0) return r;
    final da = a.homework.dueAt ?? DateTime(9999), db = b.homework.dueAt ?? DateTime(9999);
    return rank(a) == 0 ? da.compareTo(db) : (b.homework.createdAt ?? db).compareTo(a.homework.createdAt ?? da);
  });
  return AsyncData(entries);
});

final openHomeworkCountProvider = Provider<int>(
  (ref) => ref.watch(homeworkProvider).value?.where((e) => e.isOpen).length ?? 0,
);

final liveSessionsProvider = StreamProvider<List<LiveSession>>(
  (ref) => ref.watch(classroomRepositoryProvider).watchLiveSessions(),
);

final activeLiveSessionProvider = Provider<LiveSession?>(
  (ref) => ref.watch(liveSessionsProvider).value?.where((s) => s.live).firstOrNull,
);

final liveResponsesProvider = StreamProvider.autoDispose.family<List<LiveResponse>, String>(
  (ref, sessionId) => ref.watch(classroomRepositoryProvider).watchLiveResponses(sessionId),
);
