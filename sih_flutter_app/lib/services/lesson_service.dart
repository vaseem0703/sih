import '../data/sample_lessons.dart';
import '../models/lesson.dart';

class LessonService {
  List<Lesson> getAllLessons() {
    return SampleLessonsData.lessons;
  }

  Lesson? getLessonById(String id) {
    try {
      return SampleLessonsData.lessons.firstWhere((l) => l.id == id);
    } catch (_) {
      return null;
    }
  }
}
