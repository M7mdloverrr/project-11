import '../models/lesson.dart';

/// Lessons for everyone; progress for students; editing for admins.
abstract interface class LessonRepository {
  /// Published lessons (all lessons for admins), without items.
  Future<List<Lesson>> listLessons();

  /// One lesson with its items in order.
  Future<Lesson> fetchLesson(String lessonId);

  /// Progress of [studentId]; defaults to the signed-in user.
  Future<List<LessonProgress>> fetchProgress({String? studentId});

  Future<LessonProgress> completeLesson(String lessonId, {required int score, required int maxScore});

  // Admin authoring.
  Future<Lesson> saveLesson(Lesson lesson);
  Future<void> deleteLesson(String lessonId);
  Future<void> saveItems(String lessonId, List<LessonItem> items);

  /// Homework of the signed-in student, or of [studentId] for their teacher.
  Future<List<LessonAssignment>> fetchAssignments({String? studentId});
  Future<LessonAssignment> assignLesson({required String studentId, required String lessonId, String note = ''});
  Future<void> removeAssignment(String assignmentId);
}
