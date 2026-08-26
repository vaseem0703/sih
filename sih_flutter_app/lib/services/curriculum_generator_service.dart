import 'package:shared_preferences/shared_preferences.dart';
import '../data/curriculum_data.dart';

/// Key vocabulary entry with English, Hindi, and Santali (Ol Chiki) representations.
class VocabularyItem {
  final String termEn;
  final String termHi;
  final String termSat;
  final String transliteration;
  final String? emoji;
  final String? audioAsset;

  const VocabularyItem({
    required this.termEn,
    required this.termHi,
    required this.termSat,
    required this.transliteration,
    this.emoji,
    this.audioAsset,
  });
}

/// A structured question for formative assessment during/after the lesson.
class GeneratedAssessmentQuestion {
  final String id;
  final String questionEn;
  final String questionHi;
  final String questionSat;
  final String questionType;
  final List<String> optionsHi;
  final List<String> optionsSat;
  final int correctOptionIndex;
  final String explanationHi;
  final String explanationSat;
  final String learningOutcome;

  const GeneratedAssessmentQuestion({
    required this.id,
    this.questionEn = '',
    required this.questionHi,
    required this.questionSat,
    this.questionType = 'Multiple Choice',
    required this.optionsHi,
    required this.optionsSat,
    required this.correctOptionIndex,
    required this.explanationHi,
    required this.explanationSat,
    this.learningOutcome = '',
  });
}

/// A step in the pedagogical lesson delivery script for teachers.
class TeacherScriptStep {
  final int stepNumber;
  final String phaseName;
  final String dialogueHi;
  final String dialogueSat;
  final String teacherAction;
  final String? audioAsset;

  const TeacherScriptStep({
    required this.stepNumber,
    required this.phaseName,
    required this.dialogueHi,
    required this.dialogueSat,
    required this.teacherAction,
    this.audioAsset,
  });

  TeacherScriptStep copyWith({
    int? stepNumber,
    String? phaseName,
    String? dialogueHi,
    String? dialogueSat,
    String? teacherAction,
    String? audioAsset,
  }) {
    return TeacherScriptStep(
      stepNumber: stepNumber ?? this.stepNumber,
      phaseName: phaseName ?? this.phaseName,
      dialogueHi: dialogueHi ?? this.dialogueHi,
      dialogueSat: dialogueSat ?? this.dialogueSat,
      teacherAction: teacherAction ?? this.teacherAction,
      audioAsset: audioAsset ?? this.audioAsset,
    );
  }
}

/// A structured hands-on classroom activity tailored for primary tribal learners.
class ClassroomActivityPlan {
  final int activityNumber;
  final String activityNameHi;
  final String activityNameSat;
  final String objective;
  final String teacherInstruction;
  final String studentInstruction;
  final String contentHi;
  final String contentSat;
  final List<String> materialsNeeded;
  final int durationMinutes;

  const ClassroomActivityPlan({
    this.activityNumber = 1,
    required this.activityNameHi,
    required this.activityNameSat,
    required this.objective,
    required this.teacherInstruction,
    required this.studentInstruction,
    required this.contentHi,
    required this.contentSat,
    required this.materialsNeeded,
    this.durationMinutes = 15,
  });
}

/// Fully structured generated curriculum lesson package.
class GeneratedCurriculumLesson {
  final String lessonId;
  final int grade;
  final String subject;
  final String topicTitleEn;
  final String topicTitleHi;
  final String topicTitleSat;
  final String competencyId;
  final String learningOutcomeEn;
  final String learningOutcomeHi;
  final String targetLanguage;
  final int estimatedDurationMinutes;
  final List<TeacherScriptStep> teacherScript;
  final List<ClassroomActivityPlan> activities;
  final List<GeneratedAssessmentQuestion> assessmentQuestions;
  final List<VocabularyItem> keyVocabulary;
  final bool isTeacherReviewed;

  const GeneratedCurriculumLesson({
    required this.lessonId,
    required this.grade,
    required this.subject,
    required this.topicTitleEn,
    required this.topicTitleHi,
    required this.topicTitleSat,
    required this.competencyId,
    required this.learningOutcomeEn,
    required this.learningOutcomeHi,
    required this.targetLanguage,
    this.estimatedDurationMinutes = 35,
    required this.teacherScript,
    required this.activities,
    required this.assessmentQuestions,
    required this.keyVocabulary,
    this.isTeacherReviewed = false,
  });

  GeneratedCurriculumLesson copyWith({
    String? lessonId,
    int? grade,
    String? subject,
    String? topicTitleEn,
    String? topicTitleHi,
    String? topicTitleSat,
    String? competencyId,
    String? learningOutcomeEn,
    String? learningOutcomeHi,
    String? targetLanguage,
    int? estimatedDurationMinutes,
    List<TeacherScriptStep>? teacherScript,
    List<ClassroomActivityPlan>? activities,
    List<GeneratedAssessmentQuestion>? assessmentQuestions,
    List<VocabularyItem>? keyVocabulary,
    bool? isTeacherReviewed,
  }) {
    return GeneratedCurriculumLesson(
      lessonId: lessonId ?? this.lessonId,
      grade: grade ?? this.grade,
      subject: subject ?? this.subject,
      topicTitleEn: topicTitleEn ?? this.topicTitleEn,
      topicTitleHi: topicTitleHi ?? this.topicTitleHi,
      topicTitleSat: topicTitleSat ?? this.topicTitleSat,
      competencyId: competencyId ?? this.competencyId,
      learningOutcomeEn: learningOutcomeEn ?? this.learningOutcomeEn,
      learningOutcomeHi: learningOutcomeHi ?? this.learningOutcomeHi,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      estimatedDurationMinutes:
          estimatedDurationMinutes ?? this.estimatedDurationMinutes,
      teacherScript: teacherScript ?? this.teacherScript,
      activities: activities ?? this.activities,
      assessmentQuestions: assessmentQuestions ?? this.assessmentQuestions,
      keyVocabulary: keyVocabulary ?? this.keyVocabulary,
      isTeacherReviewed: isTeacherReviewed ?? this.isTeacherReviewed,
    );
  }
}

/// Offline-first Curriculum Generator Service for SIH Problem Statement 26042.
/// Generates deterministic, culturally responsive mother-tongue lesson packages
/// with rigorous grade-level pedagogical differentiation aligned with FLN competencies.
class CurriculumGeneratorService {
  static const String _keyEditPrefix = 'curriculum_edit_';
  static const String _keyReviewedPrefix = 'curriculum_reviewed_';

  /// Generates a structured teaching package for Grade, Subject, Topic, and Target Language.
  GeneratedCurriculumLesson generateLessonPlan({
    required int grade,
    required String subject,
    required LessonContent topic,
    String targetLanguage = 'sat_Olck',
  }) {
    final compId = topic.competencyId.isNotEmpty
        ? topic.competencyId
        : 'FLN-G$grade-${subject.substring(0, 1).toUpperCase()}';

    // -------------------------------------------------------------------------
    // GRADE 1 MATHEMATICS ROUTING
    // -------------------------------------------------------------------------
    if (grade == 1 && subject.toLowerCase() == 'mathematics') {
      if (topic.titleEn.contains('Counting') || compId == 'FLN-M1-01') {
        return _buildG1CountingLesson(grade, subject, topic, targetLanguage);
      } else if (topic.titleEn.contains('Recognition') || compId == 'FLN-M1-02') {
        return _buildG1RecognitionLesson(grade, subject, topic, targetLanguage);
      } else if (topic.titleEn.contains('Matching') || compId == 'FLN-M1-03') {
        return _buildG1MatchingLesson(grade, subject, topic, targetLanguage);
      }
    }

    // -------------------------------------------------------------------------
    // GRADE 2 MATHEMATICS ROUTING
    // -------------------------------------------------------------------------
    if (grade == 2 && subject.toLowerCase() == 'mathematics') {
      if (topic.titleEn.contains('Ordering') || compId == 'FLN-M2-01') {
        return _buildG2OrderingLesson(grade, subject, topic, targetLanguage);
      } else if (topic.titleEn.contains('Addition') || compId == 'FLN-M2-02') {
        return _buildG2AdditionLesson(grade, subject, topic, targetLanguage);
      } else if (topic.titleEn.contains('Comparison') || compId == 'FLN-M2-03') {
        return _buildG2ComparisonLesson(grade, subject, topic, targetLanguage);
      }
    }

    // -------------------------------------------------------------------------
    // GRADE 3 MATHEMATICS ROUTING
    // -------------------------------------------------------------------------
    if (grade == 3 && subject.toLowerCase() == 'mathematics') {
      if (topic.titleEn.contains('Addition and Subtraction') || compId == 'FLN-M3-01') {
        return _buildG3AddSubLesson(grade, subject, topic, targetLanguage);
      } else if (topic.titleEn.contains('Patterns') || compId == 'FLN-M3-02') {
        return _buildG3PatternsLesson(grade, subject, topic, targetLanguage);
      } else if (topic.titleEn.contains('Word Problems') || compId == 'FLN-M3-03') {
        return _buildG3WordProblemsLesson(grade, subject, topic, targetLanguage);
      }
    }

    return _buildGenericLesson(grade, subject, topic, targetLanguage);
  }

  /// Retrieves a specific GeneratedCurriculumLesson by its unique lessonId.
  GeneratedCurriculumLesson? getLessonById(
    String lessonId, {
    String targetLanguage = 'sat_Olck',
  }) {
    for (final gradeEntry in CurriculumData.curriculum.entries) {
      final grade = gradeEntry.key;
      for (final subjectEntry in gradeEntry.value.entries) {
        final subject = subjectEntry.key;
        for (final topic in subjectEntry.value) {
          final lesson = generateLessonPlan(
            grade: grade,
            subject: subject,
            topic: topic,
            targetLanguage: targetLanguage,
          );
          if (lesson.lessonId == lessonId) {
            return lesson;
          }
        }
      }
    }
    return null;
  }

  /// Finds the metadata context (grade, subject, topic) by lessonId.
  Map<String, dynamic>? findLessonContextById(String lessonId) {
    for (final gradeEntry in CurriculumData.curriculum.entries) {
      final grade = gradeEntry.key;
      for (final subjectEntry in gradeEntry.value.entries) {
        final subject = subjectEntry.key;
        for (final topic in subjectEntry.value) {
          final lesson = generateLessonPlan(
            grade: grade,
            subject: subject,
            topic: topic,
          );
          if (lesson.lessonId == lessonId) {
            return {
              'grade': grade,
              'subject': subject,
              'topic': topic,
              'lesson': lesson,
            };
          }
        }
      }
    }
    return null;
  }

  /// Returns all available lessons across all grades and subjects.
  List<GeneratedCurriculumLesson> getAllLessons({
    String targetLanguage = 'sat_Olck',
  }) {
    final list = <GeneratedCurriculumLesson>[];
    for (final gradeEntry in CurriculumData.curriculum.entries) {
      final grade = gradeEntry.key;
      for (final subjectEntry in gradeEntry.value.entries) {
        final subject = subjectEntry.key;
        for (final topic in subjectEntry.value) {
          list.add(
            generateLessonPlan(
              grade: grade,
              subject: subject,
              topic: topic,
              targetLanguage: targetLanguage,
            ),
          );
        }
      }
    }
    return list;
  }

  /// Checks if lesson-specific localized materials (worksheet & flashcards) are available.
  bool isMaterialAvailable(GeneratedCurriculumLesson lesson) {
    return !lesson.competencyId.startsWith('FLN-G') &&
        lesson.keyVocabulary.isNotEmpty &&
        lesson.assessmentQuestions.isNotEmpty;
  }

  /// Checks if lesson has valid formative worksheet questions.
  bool hasWorksheetContent(GeneratedCurriculumLesson lesson) {
    return lesson.assessmentQuestions.isNotEmpty;
  }

  /// Checks if lesson has valid key vocabulary flashcards.
  bool hasFlashcards(GeneratedCurriculumLesson lesson) {
    return lesson.keyVocabulary.isNotEmpty;
  }

  /// Loads teacher review state and custom edits from SharedPreferences offline.
  Future<GeneratedCurriculumLesson> loadTeacherReviewedLesson(
    GeneratedCurriculumLesson lesson,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isReviewed =
          prefs.getBool('$_keyReviewedPrefix${lesson.lessonId}') ?? false;
      final editedScriptSat = prefs.getString(
        '$_keyEditPrefix${lesson.lessonId}_script',
      );

      if (editedScriptSat != null && lesson.teacherScript.isNotEmpty) {
        final updatedScript = List<TeacherScriptStep>.from(
          lesson.teacherScript,
        );
        updatedScript[0] = updatedScript[0].copyWith(
          dialogueSat: editedScriptSat,
        );
        return lesson.copyWith(
          teacherScript: updatedScript,
          isTeacherReviewed: isReviewed,
        );
      }

      return lesson.copyWith(isTeacherReviewed: isReviewed);
    } catch (_) {
      return lesson;
    }
  }

  /// Saves teacher review status and text corrections locally.
  Future<void> saveTeacherReview({
    required String lessonId,
    required bool isReviewed,
    String? editedScriptSat,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('$_keyReviewedPrefix$lessonId', isReviewed);
      if (editedScriptSat != null) {
        await prefs.setString(
          '$_keyEditPrefix${lessonId}_script',
          editedScriptSat,
        );
      }
    } catch (_) {}
  }

  /// Restores original content by clearing teacher edits.
  Future<void> restoreOriginalContent(String lessonId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_keyReviewedPrefix$lessonId');
      await prefs.remove('$_keyEditPrefix${lessonId}_script');
    } catch (_) {}
  }

  // ===========================================================================
  // GRADE 1 MATHEMATICS LESSONS (Focus: Concrete One-to-One, Sensory Counting)
  // ===========================================================================

  /// G1 - Lesson 1: Counting 1–10 (FLN-M1-01)
  GeneratedCurriculumLesson _buildG1CountingLesson(
    int grade,
    String subject,
    LessonContent topic,
    String targetLanguage,
  ) {
    return GeneratedCurriculumLesson(
      lessonId: 'g1_math_counting_1_10',
      grade: grade,
      subject: subject,
      topicTitleEn: 'Counting 1–10',
      topicTitleHi: 'वस्तुओं की गिनती 1–10',
      topicTitleSat: 'ᱮᱞ ᱑–᱑᱐',
      competencyId: 'FLN-M1-01',
      learningOutcomeEn:
          'Count concrete physical and visual objects from 1 to 10 with one-to-one correspondence.',
      learningOutcomeHi:
          '1 से 10 तक की ठोस और दृश्य वस्तुओं को एक-एक करके सही क्रम में गिनना।',
      targetLanguage: targetLanguage,
      estimatedDurationMinutes: 35,
      teacherScript: const [
        TeacherScriptStep(
          stepNumber: 1,
          phaseName: 'Concrete Modeling (मूर्त वस्तुओं से गिनती)',
          dialogueHi: 'बच्चों, देखिए मेरी मेज पर कितने कंकड़ हैं! एक, दो, तीन!',
          dialogueSat: 'ᱜᱤᱫᱽᱨᱟᱹ ᱠᱚ, ᱧᱮᱞ ᱯᱮ ᱤᱧᱟᱜ ᱢᱮᱡᱽ ᱪᱮᱛᱟᱱ ᱨᱮ ᱛᱤᱱᱟᱹᱜ ᱫᱷᱤᱨᱤ ᱢᱮᱱᱟᱜᱼᱟ! ᱢᱤᱫ, ᱵᱟᱨ, ᱯᱮ!',
          teacherAction:
              'Point to each pebble with your index finger as you count aloud.',
          audioAsset: 'assets/audio/santali_numbers_phulmani.wav',
        ),
        TeacherScriptStep(
          stepNumber: 2,
          phaseName: 'Choral Touch Counting (साथ में छूकर गिनना)',
          dialogueHi: 'सभी बच्चे अपनी उंगलियाँ उठाइए और मेरे साथ गिनिए: 1, 2, 3, 4, 5!',
          dialogueSat: 'ᱡᱚᱛᱚ ᱜᱤᱫᱽᱨᱟᱹ ᱛᱤ ᱠᱟᱹᱴᱩᱵ ᱛᱩᱞ ᱯᱮ ᱟᱨ ᱤᱧ ᱥᱟᱶ ᱞᱮᱠᱷᱟᱭ ᱯᱮ: ᱑, ᱒, ᱓, ᱔, ᱕!',
          teacherAction: 'Raise hand and show finger counts sequentially.',
          audioAsset: 'assets/audio/santali_short_phulmani.wav',
        ),
      ],
      activities: const [
        ClassroomActivityPlan(
          activityNumber: 1,
          activityNameHi: 'कंकड़ और बीजों की गिनती',
          activityNameSat: 'ᱫᱷᱤᱨᱤ ᱟᱨ ᱡᱟᱝ ᱮᱞ ᱠᱟᱹᱢᱤ',
          objective: 'Count physical pebbles one by one up to 10.',
          teacherInstruction:
              'Give 10 tamarind seeds/pebbles to each student pair and ask them to count 6 seeds.',
          studentInstruction:
              'Line up your seeds and count them aloud in Santali and Hindi.',
          contentHi: 'छात्र कंकड़ों को एक पंक्ति में रखकर 1 से 10 तक गिनेंगे।',
          contentSat: 'ᱯᱟᱹᱴᱷᱩᱣᱟᱹ ᱠᱚ ᱫᱷᱤᱨᱤ ᱞᱟᱭᱤᱱ ᱨᱮ ᱫᱚᱦᱚ ᱠᱟᱛᱮ ᱑ ᱠᱷᱚᱱ ᱑᱐ ᱦᱟᱹᱵᱤᱡ ᱠᱚ ᱮᱞᱟ ᱾',
          materialsNeeded: ['10 pebbles or seeds per pair', 'Counting mat'],
          durationMinutes: 15,
        ),
      ],
      assessmentQuestions: const [
        GeneratedAssessmentQuestion(
          id: 'G1-CNT-01',
          questionEn: 'How many leaves are in the picture? (🍃 🍃 🍃 🍃 🍃 🍃)',
          questionHi: 'चित्र में कितनी पत्तियाँ हैं? (🍃 🍃 🍃 🍃 🍃 🍃)',
          questionSat: 'ᱪᱤᱛᱟᱹᱨ ᱨᱮ ᱛᱤᱱᱟᱹᱜ ᱥᱟᱠᱟᱢ ᱢᱮᱱᱟᱜᱼᱟ? (🍃 🍃 🍃 🍃 🍃 🍃)',
          questionType: 'Visual Object Count',
          optionsHi: ['4 (चार)', '6 (छह)', '8 (आठ)'],
          optionsSat: ['᱔ (ᱯᱩᱱ)', '᱖ (ᱛᱩᱨᱩᱭ)', '᱘ (ᱤᱨᱟᱹᱞ)'],
          correctOptionIndex: 1,
          explanationHi: 'यहाँ कुल 6 पत्तियाँ हैं।',
          explanationSat: 'ᱱᱚᱸᱰᱮ ᱡᱚᱛᱚ ᱛᱮ ᱖ (ᱛᱩᱨᱩᱭ) ᱜᱚᱴᱟᱝ ᱥᱟᱠᱟᱢ ᱢᱮᱱᱟᱜᱼᱟ ᱾',
          learningOutcome: 'FLN-M1-01: Object Counting',
        ),
      ],
      keyVocabulary: const [
        VocabularyItem(
          termEn: 'One (1)',
          termHi: 'एक (1)',
          termSat: 'ᱢᱤᱫ (᱑)',
          transliteration: 'Mid (1)',
          emoji: '1️⃣',
          audioAsset: 'assets/audio/santali_numbers_phulmani.wav',
        ),
        VocabularyItem(
          termEn: 'Three (3)',
          termHi: 'तीन (3)',
          termSat: 'ᱯᱮ (᱓)',
          transliteration: 'Pe (3)',
          emoji: '3️⃣',
        ),
        VocabularyItem(
          termEn: 'Six (6)',
          termHi: 'छह (6)',
          termSat: 'ᱛᱩᱨᱩᱭ (᱖)',
          transliteration: 'Turui (6)',
          emoji: '6️⃣',
        ),
      ],
    );
  }

  /// G1 - Lesson 2: Number Recognition 1–10 (FLN-M1-02)
  GeneratedCurriculumLesson _buildG1RecognitionLesson(
    int grade,
    String subject,
    LessonContent topic,
    String targetLanguage,
  ) {
    return GeneratedCurriculumLesson(
      lessonId: 'g1_math_recognition_1_10',
      grade: grade,
      subject: subject,
      topicTitleEn: 'Number Recognition 1–10',
      topicTitleHi: 'संख्या पहचान 1–10',
      topicTitleSat: 'ᱮᱞ ᱩᱨᱩᱢ ᱑–᱑᱐',
      competencyId: 'FLN-M1-02',
      learningOutcomeEn:
          'Recognize, identify, and name numerals from 1 to 10 in standard and mother-tongue script.',
      learningOutcomeHi:
          '1 से 10 तक के संख्या अंकों को पहचानना और मातृभाषा में उनका नाम बोलना।',
      targetLanguage: targetLanguage,
      estimatedDurationMinutes: 35,
      teacherScript: const [
        TeacherScriptStep(
          stepNumber: 1,
          phaseName: 'Symbol Introduction (अंक प्रतीक प्रदर्शन)',
          dialogueHi: 'यह देखिए, यह संख्या "5" है! संथाली में इसे "ᱢᱚᱬᱮ" (5) लिखते हैं।',
          dialogueSat: 'ᱱᱚᱣᱟ ᱧᱮᱞ ᱯᱮ, ᱱᱚᱣᱟ ᱫᱚ ᱮᱞ "᱕" ᱠᱟᱱᱟ! ᱥᱟᱱᱛᱟᱲᱤ ᱛᱮ ᱱᱚᱣᱟ ᱫᱚ "ᱢᱚᱬᱮ" (᱕) ᱠᱚ ᱚᱞᱟ ᱾',
          teacherAction:
              'Display large flashcard showing Hindi numeral 5 and Ol Chiki numeral ᱕ side by side.',
          audioAsset: 'assets/audio/santali_educational_sido.wav',
        ),
        TeacherScriptStep(
          stepNumber: 2,
          phaseName: 'Sound-Symbol Association (ध्वनि और अंक मिलान)',
          dialogueHi: 'जब मैं कार्ड दिखाऊँ, तो जोर से संख्या का नाम बोलिए!',
          dialogueSat: 'ᱡᱚᱠᱷᱚᱱ ᱤᱧ ᱠᱟᱨᱰ ᱩᱫᱩᱜᱟᱹᱧ, ᱩᱱ ᱡᱚᱦᱚᱜ ᱮᱞ ᱧᱩᱛᱩᱢ ᱡᱚᱨ ᱛᱮ ᱨᱚᱲ ᱯᱮ!',
          teacherAction:
              'Hold up cards in random order and prompt whole-class naming.',
        ),
      ],
      activities: const [
        ClassroomActivityPlan(
          activityNumber: 1,
          activityNameHi: 'संख्या फ्लैशकार्ड पहचान खेल',
          activityNameSat: 'ᱮᱞ ᱠᱟᱨᱰ ᱩᱨᱩᱢ ᱠᱷᱮᱞᱚᱸᱰ',
          objective: 'Quickly identify written numeral digits 1 through 10.',
          teacherInstruction:
              'Flash a card for 3 seconds. First group to call out the Santali numeral gets a point.',
          studentInstruction:
              'Look at the card and speak the number in Santali Ol Chiki and Hindi.',
          contentHi: 'अंक देखकर तुरंत संथाली और हिंदी में संख्या का नाम बोलना।',
          contentSat: 'ᱮᱞ ᱠᱟᱨᱰ ᱧᱮᱞ ᱠᱟᱛᱮ ᱥᱟᱱᱛᱟᱲᱤ ᱟᱨ ᱦᱤᱱᱫᱤ ᱛᱮ ᱞᱟᱹᱭ ᱯᱮ ᱾',
          materialsNeeded: ['Flashcards 1 to 10 with Hindi & Ol Chiki numerals'],
          durationMinutes: 15,
        ),
      ],
      assessmentQuestions: const [
        GeneratedAssessmentQuestion(
          id: 'G1-REC-01',
          questionEn: 'Which numeral represents "Seven" (7) in Ol Chiki?',
          questionHi: 'सात (7) के लिए कौन सा ओल चिकी अंक सही है?',
          questionSat: 'ᱮᱭᱟᱭ (᱗) ᱞᱟᱹᱜᱤᱫ ᱚᱠᱟ ᱚᱞ ᱪᱤᱠᱤ ᱮᱞ ᱴᱷᱤᱠᱟᱹ?',
          questionType: 'Numeral Identification',
          optionsHi: ['5 (५ / ᱕)', '7 (७ / ᱗)', '9 (९ / ᱙)'],
          optionsSat: ['᱕ (ᱢᱚᱬᱮ)', '᱗ (ᱮᱭᱟᱭ)', '᱙ (ᱟᱨᱮ)'],
          correctOptionIndex: 1,
          explanationHi: '7 को ओल चिकी में "᱗" (एयाय) लिखा जाता है।',
          explanationSat: '᱗ ᱫᱚ ᱚᱞ ᱪᱤᱠᱤ ᱛᱮ "ᱮᱭᱟᱭ" ᱠᱚ ᱢᱮᱛᱟᱜᱼᱟ ᱾',
          learningOutcome: 'FLN-M1-02: Numeral Recognition',
        ),
      ],
      keyVocabulary: const [
        VocabularyItem(
          termEn: 'Number / Numeral',
          termHi: 'संख्या / अंक',
          termSat: 'ᱮᱞ / ᱪᱤᱠᱤ',
          transliteration: 'El / Chiki',
          emoji: '🔢',
        ),
        VocabularyItem(
          termEn: 'Seven (7)',
          termHi: 'सात (7)',
          termSat: 'ᱮᱭᱟᱭ (᱗)',
          transliteration: 'Eyay (7)',
          emoji: '7️⃣',
        ),
        VocabularyItem(
          termEn: 'Nine (9)',
          termHi: 'नौ (9)',
          termSat: 'ᱟᱨᱮ (᱙)',
          transliteration: 'Are (9)',
          emoji: '9️⃣',
        ),
      ],
    );
  }

  /// G1 - Lesson 3: Number Matching 1–10 (FLN-M1-03)
  GeneratedCurriculumLesson _buildG1MatchingLesson(
    int grade,
    String subject,
    LessonContent topic,
    String targetLanguage,
  ) {
    return GeneratedCurriculumLesson(
      lessonId: 'g1_math_matching_1_10',
      grade: grade,
      subject: subject,
      topicTitleEn: 'Number Matching 1–10',
      topicTitleHi: 'संख्या और मात्रा मिलान',
      topicTitleSat: 'ᱮᱞ ᱟᱨ ᱡᱤᱱᱤᱥ ᱢᱮᱞᱟᱣ',
      competencyId: 'FLN-M1-03',
      learningOutcomeEn:
          'Match numerals 1–10 with their corresponding collections and quantities of objects.',
      learningOutcomeHi:
          '1 से 10 तक के अंकों को उनकी संगत वस्तुओं के समूह और मात्रा से मिलाना।',
      targetLanguage: targetLanguage,
      estimatedDurationMinutes: 35,
      teacherScript: const [
        TeacherScriptStep(
          stepNumber: 1,
          phaseName: 'Quantity-Numeral Pairing (मात्रा और अंक का मिलान)',
          dialogueHi: 'यहाँ 4 फूल हैं! अब कार्ड में से "4" (४ / ᱔) ढूँढकर इसके पास रखिए।',
          dialogueSat: 'ᱱᱚᱸᱰᱮ ᱔ ᱵᱟᱦᱟ ᱢᱮᱱᱟᱜᱼᱟ! ᱱᱤᱛᱚᱜ ᱠᱟᱨᱰ ᱠᱷᱚᱱ "᱔" (ᱯᱩᱱ) ᱯᱟᱱᱛᱮ ᱠᱟᱛᱮ ᱥᱩᱨ ᱨᱮ ᱫᱚᱦᱚᱭ ᱯᱮ ᱾',
          teacherAction:
              'Place 4 cut-out flowers on the floor and pair with numeral card 4.',
          audioAsset: 'assets/audio/santali_longer_sido.wav',
        ),
      ],
      activities: const [
        ClassroomActivityPlan(
          activityNumber: 1,
          activityNameHi: 'टोकरी और संख्या मिलान खेल',
          activityNameSat: 'ᱴᱩᱠᱨᱤ ᱟᱨ ᱮᱞ ᱢᱮᱞᱟᱣ ᱠᱷᱮᱞᱚᱸᱰ',
          objective: 'Match group of objects with exact numeral tag.',
          teacherInstruction:
              'Place baskets with varying quantities of mango cut-outs. Children place matching number card in each basket.',
          studentInstruction:
              'Count the items in your basket and place the correct number card inside.',
          contentHi: 'टोकरी में रखी वस्तुओं को गिनकर सही संख्या कार्ड टोकरी में रखना।',
          contentSat: 'ᱴᱩᱠᱨᱤ ᱨᱮᱱᱟᱜ ᱡᱤᱱᱤᱥ ᱮᱞ ᱠᱟᱛᱮ ᱴᱷᱤᱠ ᱮᱞ ᱠᱟᱨᱰ ᱵᱷᱤᱛᱨᱤ ᱨᱮ ᱫᱚᱦᱚᱭ ᱯᱮ ᱾',
          materialsNeeded: ['3 plastic baskets', 'Cut-out mangoes/apples', 'Number cards 1–10'],
          durationMinutes: 15,
        ),
      ],
      assessmentQuestions: const [
        GeneratedAssessmentQuestion(
          id: 'G1-MTC-01',
          questionEn: 'Which group of dots matches the number 4 (४ / ᱔)?',
          questionHi: 'संख्या 4 (४ / ᱔) के साथ कौन सा बिंदुओं का समूह मिलता है?',
          questionSat: 'ᱮᱞ ᱔ (ᱯᱩᱱ) ᱥᱟᱶ ᱚᱠᱟ ᱴᱩᱰᱟᱹᱜ ᱜᱟᱫᱮᱞ ᱢᱮᱞᱟᱜᱼᱟ?',
          questionType: 'Quantity Matching',
          optionsHi: ['● ● ● (3)', '● ● ● ● (4)', '● ● ● ● ● (5)'],
          optionsSat: ['● ● ● (᱓)', '● ● ● ● (᱔)', '● ● ● ● ● (᱕)'],
          correctOptionIndex: 1,
          explanationHi: 'संख्या 4 के लिए 4 बिंदु (● ● ● ●) सही हैं।',
          explanationSat: 'ᱮᱞ ᱔ ᱞᱟᱹᱜᱤᱫ ᱔ ᱴᱩᱰᱟᱹᱜ (● ● ● ●) ᱴᱷᱤᱠᱟ ᱾',
          learningOutcome: 'FLN-M1-03: Number-Quantity Matching',
        ),
      ],
      keyVocabulary: const [
        VocabularyItem(
          termEn: 'Match',
          termHi: 'मिलाना / जोड़ना',
          termSat: 'ᱢᱮᱞᱟᱣ / ᱡᱚᱲᱟᱣ',
          transliteration: 'Melaw / Joraw',
          emoji: '🔗',
        ),
        VocabularyItem(
          termEn: 'Quantity / Group',
          termHi: 'मात्रा / समूह',
          termSat: 'ᱜᱟᱫᱮᱞ / ᱞᱮᱠᱷᱟ',
          transliteration: 'Gadel / Lekha',
          emoji: '📦',
        ),
      ],
    );
  }

  // ===========================================================================
  // GRADE 2 MATHEMATICS LESSONS (Focus: Ordering, Addition, Comparison)
  // ===========================================================================

  /// G2 - Lesson 1: Counting and Ordering 1–10 (FLN-M2-01)
  GeneratedCurriculumLesson _buildG2OrderingLesson(
    int grade,
    String subject,
    LessonContent topic,
    String targetLanguage,
  ) {
    return GeneratedCurriculumLesson(
      lessonId: 'g2_math_ordering_1_10',
      grade: grade,
      subject: subject,
      topicTitleEn: 'Counting and Ordering 1–10',
      topicTitleHi: 'संख्या क्रमबद्धता 1–10',
      topicTitleSat: 'ᱮᱞ ᱠᱚ ᱞᱟᱭᱤᱱ ᱫᱚᱦᱚ',
      competencyId: 'FLN-M2-01',
      learningOutcomeEn:
          'Count, arrange, and order numbers 1–10 in ascending and descending sequence, identifying missing numbers.',
      learningOutcomeHi:
          '1 से 10 तक की संख्याओं को आगे और पीछे के क्रम में लगाना तथा छूटी हुई संख्याएँ पहचानना।',
      targetLanguage: targetLanguage,
      estimatedDurationMinutes: 40,
      teacherScript: const [
        TeacherScriptStep(
          stepNumber: 1,
          phaseName: 'Sequence Line Concept (संख्या रेखा और क्रम)',
          dialogueHi: 'बच्चों, संख्याएँ हमेशा एक निश्चित क्रम में चलती हैं: 1, 2, 3, 4, 5!',
          dialogueSat: 'ᱜᱤᱫᱽᱨᱟᱹ ᱠᱚ, ᱮᱞ ᱫᱚ ᱡᱟᱣᱜᱮ ᱥᱟᱡᱟᱣ ᱛᱮ ᱪᱟᱞᱟᱜᱼᱟ: ᱑, ᱒, ᱓, ᱔, ᱕!',
          teacherAction:
              'Draw a number line 1 to 10 on the chalkboard with chalk footprints.',
          audioAsset: 'assets/audio/santali_numbers_phulmani.wav',
        ),
        TeacherScriptStep(
          stepNumber: 2,
          phaseName: 'Missing Number Investigation (छूटी हुई संख्या खोजना)',
          dialogueHi: 'देखिए: 1, 2, __, 4, 5। बीच में कौन सी संख्या छूट गई है?',
          dialogueSat: 'ᱧᱮᱞ ᱯᱮ: ᱑, ᱒, __, ᱔, ᱕ ᱾ ᱛᱟᱞᱟ ᱨᱮ ᱚᱠᱟ ᱮᱞ ᱵᱟᱹᱜᱤ ᱮᱱᱟ?',
          teacherAction:
              'Erase numeral 3 from the board and encourage students to fill the blank.',
        ),
      ],
      activities: const [
        ClassroomActivityPlan(
          activityNumber: 1,
          activityNameHi: 'संख्या रेलगाड़ी खेल (Number Train)',
          activityNameSat: 'ᱮᱞ ᱨᱮᱞᱜᱟᱹᱰᱤ ᱠᱷᱮᱞᱚᱸᱰ',
          objective: 'Order shuffled number cards from 1 to 10 in ascending order.',
          teacherInstruction:
              'Hand 10 children mixed cards. Ask them to stand in the correct line from 1 to 10.',
          studentInstruction:
              'Look at your number and arrange yourself in the train order quickly.',
          contentHi: 'छात्र कार्ड लेकर सही क्रम 1 से 10 में खड़े होकर रेलगाड़ी बनाएँगे।',
          contentSat: 'ᱯᱟᱹᱴᱷᱩᱣᱟᱹ ᱠᱚ ᱠᱟᱨᱰ ᱥᱟᱵ ᱠᱟᱛᱮ ᱑ ᱠᱷᱚᱱ ᱑᱐ ᱞᱟᱭᱤᱱ ᱨᱮ ᱛᱤᱸᱜᱩ ᱠᱟᱛᱮ ᱨᱮᱞᱜᱟᱹᱰᱤ ᱠᱚ ᱵᱮᱱᱟᱣᱟ ᱾',
          materialsNeeded: ['Large number cards 1–10 for chest tags'],
          durationMinutes: 20,
        ),
      ],
      assessmentQuestions: const [
        GeneratedAssessmentQuestion(
          id: 'G2-ORD-01',
          questionEn: 'Which number is missing in the sequence: 4, 5, __, 7, 8?',
          questionHi: 'क्रम में छूटी हुई संख्या कौन सी है: 4, 5, __, 7, 8?',
          questionSat: 'ᱱᱚᱣᱟ ᱞᱟᱭᱤᱱ ᱨᱮ ᱚᱠᱟ ᱮᱞ ᱵᱟᱹᱜᱤ ᱮᱱᱟ: ᱔, ᱕, __, ᱗, ᱘?',
          questionType: 'Sequence Completion',
          optionsHi: ['6 (छह)', '3 (तीन)', '9 (नौ)'],
          optionsSat: ['᱖ (ᱛᱩᱨᱩᱭ)', '᱓ (ᱯᱮ)', '᱙ (ᱟᱨᱮ)'],
          correctOptionIndex: 0,
          explanationHi: '5 के बाद और 7 से पहले संख्या 6 आती है।',
          explanationSat: '᱕ ᱛᱟᱭᱚᱢ ᱟᱨ ᱗ ᱞᱟᱦᱟ ᱨᱮ ᱖ ᱮᱞ ᱦᱤᱡᱩᱜᱼᱟ ᱾',
          learningOutcome: 'FLN-M2-01: Number Sequencing and Missing Numbers',
        ),
      ],
      keyVocabulary: const [
        VocabularyItem(
          termEn: 'In Order / Line',
          termHi: 'क्रम में / पंक्ति',
          termSat: 'ᱞᱟᱭᱤᱱ ᱨᱮ / ᱥᱟᱡᱟᱣ',
          transliteration: 'Line re / Sajaw',
          emoji: '➡️',
        ),
        VocabularyItem(
          termEn: 'Before / Earlier',
          termHi: 'पहले',
          termSat: 'ᱞᱟᱦᱟ',
          transliteration: 'Laha',
          emoji: '⬅️',
        ),
        VocabularyItem(
          termEn: 'After / Later',
          termHi: 'बाद में',
          termSat: 'ᱛᱟᱭᱚᱢ',
          transliteration: 'Tayom',
          emoji: '🔜',
        ),
      ],
    );
  }

  /// G2 - Lesson 2: Addition Within 10 (FLN-M2-02)
  GeneratedCurriculumLesson _buildG2AdditionLesson(
    int grade,
    String subject,
    LessonContent topic,
    String targetLanguage,
  ) {
    return GeneratedCurriculumLesson(
      lessonId: 'g2_math_addition_within_10',
      grade: grade,
      subject: subject,
      topicTitleEn: 'Addition Within 10',
      topicTitleHi: '10 तक का जोड़',
      topicTitleSat: '᱑᱐ ᱦᱟᱹᱵᱤᱡ ᱡᱚᱲ',
      competencyId: 'FLN-M2-02',
      learningOutcomeEn:
          'Combine two groups of objects and calculate sums up to 10 using concrete materials and symbols.',
      learningOutcomeHi:
          'ठोस वस्तुओं और चित्रों की सहायता से दो समूहों को मिलाकर 10 तक का जोड़ करना।',
      targetLanguage: targetLanguage,
      estimatedDurationMinutes: 40,
      teacherScript: const [
        TeacherScriptStep(
          stepNumber: 1,
          phaseName: 'Combining Sets (दो समूहों को मिलाना)',
          dialogueHi: 'मेरे बाएँ हाथ में 3 कंकड़ हैं और दाएँ हाथ में 2 कंकड़। जब दोनों को मिलाया, तो कुल कितने हुए? 5!',
          dialogueSat: 'ᱤᱧᱟᱜ ᱞᱮᱸᱜᱟ ᱛᱤ ᱨᱮ ᱓ ᱫᱷᱤᱨᱤ ᱟᱨ ᱡᱚᱡᱚᱢ ᱛᱤ ᱨᱮ ᱒ ᱫᱷᱤᱨᱤ ᱾ ᱢᱮᱥᱟ ᱠᱟᱛᱮ ᱛᱤᱱᱟᱹᱜ ᱦᱩᱭ ᱮᱱᱟ? ᱕ (ᱢᱚᱬᱮ)!',
          teacherAction:
              'Hold pebbles in both open hands, bring hands together, and count total.',
          audioAsset: 'assets/audio/santali_educational_sido.wav',
        ),
        TeacherScriptStep(
          stepNumber: 2,
          phaseName: 'Symbolic Addition Representation (जोड़ चिन्ह "+" की समझ)',
          dialogueHi: 'हम इसे गणित में लिखते हैं: 3 + 2 = 5। "+" का मतलब है मिलाना।',
          dialogueSat: 'ᱟᱵᱚ ᱦᱤᱥᱟᱹᱵᱽ ᱛᱮ ᱵᱚᱱ ᱚᱞᱟ: ᱓ + ᱒ = ᱕ ᱾ "+" ᱨᱮᱱᱟᱜ ᱢᱮᱱᱮᱛ ᱫᱚ ᱢᱮᱥᱟ ᱾',
          teacherAction: 'Write "3 + 2 = 5" on the blackboard in both Hindi and Ol Chiki numerals.',
        ),
      ],
      activities: const [
        ClassroomActivityPlan(
          activityNumber: 1,
          activityNameHi: 'दो कटोरी जोड़ खेल (Two-Bowl Addition)',
          activityNameSat: 'ᱵᱟᱨ ᱵᱟᱹᱴᱤ ᱡᱚᱲ ᱠᱷᱮᱞᱚᱸᱰ',
          objective: 'Physically combine objects from two containers to find the sum.',
          teacherInstruction:
              'Put 4 sticks in bowl A and 3 sticks in bowl B. Ask students to pour into bowl C and count.',
          studentInstruction:
              'Pour the sticks together into the big bowl and write the addition sentence on your slate.',
          contentHi: 'छात्र दो कटोरियों की तीलियों को एक साथ मिलाकर कुल जोड़ निकालेंगे।',
          contentSat: 'ᱯᱟᱹᱴᱷᱩᱣᱟᱹ ᱠᱚ ᱵᱟᱨ ᱵᱟᱹᱴᱤ ᱨᱮᱱᱟᱜ ᱠᱟᱹᱴᱷᱤ ᱢᱤᱫ ᱴᱷᱮᱱ ᱢᱮᱥᱟ ᱠᱟᱛᱮ ᱡᱚᱛᱚ ᱛᱮ ᱠᱚ ᱦᱤᱥᱟᱹᱵᱟ ᱾',
          materialsNeeded: ['Small bowls/cups', 'Matchsticks/twigs', 'Slates and chalk'],
          durationMinutes: 20,
        ),
      ],
      assessmentQuestions: const [
        GeneratedAssessmentQuestion(
          id: 'G2-ADD-01',
          questionEn: 'What is 4 + 3?',
          questionHi: '4 + 3 का मान क्या होगा?',
          questionSat: '᱔ + ᱓ ᱨᱮᱱᱟᱜ ᱡᱚᱛᱚ ᱛᱮ ᱛᱤᱱᱟᱹᱜ ᱦᱩᱭᱩᱜᱼᱟ?',
          questionType: 'Addition Problem',
          optionsHi: ['6 (छह)', '7 (सात)', '8 (आठ)'],
          optionsSat: ['᱖ (ᱛᱩᱨᱩᱭ)', '᱗ (ᱮᱭᱟᱭ)', '᱘ (ᱤᱨᱟᱹᱞ)'],
          correctOptionIndex: 1,
          explanationHi: '4 में 3 जोड़ने पर कुल 7 होता है (4 + 3 = 7)।',
          explanationSat: '᱔ ᱥᱟᱶ ᱓ ᱢᱮᱥᱟ ᱞᱮᱠᱷᱟᱱ ᱗ ᱦᱩᱭᱩᱜᱼᱟ (᱔ + ᱓ = ᱗) ᱾',
          learningOutcome: 'FLN-M2-02: Addition within 10',
        ),
      ],
      keyVocabulary: const [
        VocabularyItem(
          termEn: 'Add / Plus (+)',
          termHi: 'जोड़ / मिलाना (+)',
          termSat: 'ᱡᱚᱲ / ᱢᱮᱥᱟ (+)',
          transliteration: 'Jor / Mesa (+)',
          emoji: '➕',
        ),
        VocabularyItem(
          termEn: 'Total / Equals (=)',
          termHi: 'कुल / बराबर (=)',
          termSat: 'ᱡᱚᱛᱚ ᱛᱮ / ᱵᱟᱨᱟᱵᱟᱹᱨᱤ (=)',
          transliteration: 'Joto te / Barabari (=)',
          emoji: '🟰',
        ),
      ],
    );
  }

  /// G2 - Lesson 3: Number Comparison 1–10 (FLN-M2-03)
  GeneratedCurriculumLesson _buildG2ComparisonLesson(
    int grade,
    String subject,
    LessonContent topic,
    String targetLanguage,
  ) {
    return GeneratedCurriculumLesson(
      lessonId: 'g2_math_comparison_1_10',
      grade: grade,
      subject: subject,
      topicTitleEn: 'Number Comparison 1–10',
      topicTitleHi: 'संख्या तुलना: बड़ा, छोटा',
      topicTitleSat: 'ᱮᱞ ᱠᱚ ᱛᱩᱞᱟᱹᱡᱚᱠᱷᱟ',
      competencyId: 'FLN-M2-03',
      learningOutcomeEn:
          'Compare two numbers or quantities up to 10 using concepts of greater than, less than, and equal to.',
      learningOutcomeHi:
          '10 तक की दो संख्याओं या मात्राओं की तुलना करके बड़ा, छोटा या बराबर बताना।',
      targetLanguage: targetLanguage,
      estimatedDurationMinutes: 40,
      teacherScript: const [
        TeacherScriptStep(
          stepNumber: 1,
          phaseName: 'Visual Quantity Contrast (मात्रा तुलना)',
          dialogueHi: 'इस ढेर में 7 बेर हैं और इस ढेर में 3 बेर। किसमें ज्यादा हैं? 7 में!',
          dialogueSat: 'ᱱᱚᱣᱟ ᱜᱟᱫᱮᱞ ᱨᱮ ᱗ ᱡᱟᱹᱱᱩᱢ ᱟᱨ ᱱᱚᱣᱟ ᱨᱮ ᱓ ᱡᱟᱹᱱᱩᱢ ᱾ ᱚᱠᱟ ᱨᱮ ᱰᱷᱮᱨ ᱢᱮᱱᱟᱜᱼᱟ? ᱗ ᱨᱮ!',
          teacherAction:
              'Display two piles of fruits and introduce vocabulary for greater (ᱰᱷᱮᱨ) and smaller (ᱠᱚᱢ).',
          audioAsset: 'assets/audio/santali_short_phulmani.wav',
        ),
      ],
      activities: const [
        ClassroomActivityPlan(
          activityNumber: 1,
          activityNameHi: 'मगरमच्छ का मुँह तुलना खेल (Comparison Game)',
          activityNameSat: 'ᱛᱩᱞᱟᱹᱡᱚᱠᱷᱟ ᱠᱷᱮᱞᱚᱸᱰ',
          objective: 'Identify which number is greater (>) or smaller (<).',
          teacherInstruction:
              'Hold up two numbers (e.g., 8 and 5). Have students make crocodile jaws opening toward the bigger number.',
          studentInstruction:
              'Show your arms opening toward the bigger number and shout "ᱰᱷᱮᱨ" (Greater!).',
          contentHi: 'छात्र दो संख्याओं में से बड़ी संख्या की ओर मुँह खोलकर बड़ा/छोटा बताएंगे।',
          contentSat: 'ᱯᱟᱹᱴᱷᱩᱣᱟᱹ ᱠᱚ ᱞᱟᱹᱴᱩ ᱮᱞ ᱥᱮᱫ ᱛᱤ ᱢᱮᱞᱟᱣ ᱠᱟᱛᱮ "ᱰᱷᱮᱨ" ᱠᱚ ᱨᱚᱲᱟ ᱾',
          materialsNeeded: ['Comparison cards with > and < signs'],
          durationMinutes: 15,
        ),
      ],
      assessmentQuestions: const [
        GeneratedAssessmentQuestion(
          id: 'G2-CMP-01',
          questionEn: 'Which number is greater: 8 or 5?',
          questionHi: '8 और 5 में से कौन सी संख्या बड़ी है?',
          questionSat: '᱘ ᱟᱨ ᱕ ᱢᱩᱫᱽ ᱨᱮ ᱚᱠᱟ ᱮᱞ ᱰᱷᱮᱨᱟ (ᱞᱟᱹᱴᱩ)?',
          questionType: 'Number Comparison',
          optionsHi: ['8 (आठ बड़ा है)', '5 (पाँच बड़ा है)', 'दोनों बराबर हैं'],
          optionsSat: ['᱘ (ᱤᱨᱟᱹᱞ ᱰᱷᱮᱨᱟ)', '᱕ (ᱢᱚᱬᱮ ᱰᱷᱮᱨᱟ)', 'ᱵᱟᱱᱟᱨ ᱵᱟᱨᱟᱵᱟᱹᱨᱤ'],
          correctOptionIndex: 0,
          explanationHi: '8 संख्या 5 से बड़ी है (8 > 5)।',
          explanationSat: '᱘ ᱮᱞ ᱫᱚ ᱕ ᱠᱷᱚᱱ ᱰᱷᱮᱨᱟ (᱘ > ᱕) ᱾',
          learningOutcome: 'FLN-M2-03: Number Comparison',
        ),
      ],
      keyVocabulary: const [
        VocabularyItem(
          termEn: 'Greater / More',
          termHi: 'बड़ा / अधिक',
          termSat: 'ᱰᱷᱮᱨ / ᱞᱟᱹᱴᱩ',
          transliteration: 'Dher / Latu',
          emoji: '🔺',
        ),
        VocabularyItem(
          termEn: 'Smaller / Less',
          termHi: 'छोटा / कम',
          termSat: 'ᱠᱚᱢ / ᱠᱟᱹᱴᱤᱡ',
          transliteration: 'Kom / Katij',
          emoji: '🔻',
        ),
      ],
    );
  }

  // ===========================================================================
  // GRADE 3 MATHEMATICS LESSONS (Focus: Operations, Patterns, Word Problems)
  // ===========================================================================

  /// G3 - Lesson 1: Addition and Subtraction Within 10 (FLN-M3-01)
  GeneratedCurriculumLesson _buildG3AddSubLesson(
    int grade,
    String subject,
    LessonContent topic,
    String targetLanguage,
  ) {
    return GeneratedCurriculumLesson(
      lessonId: 'g3_math_add_sub_within_10',
      grade: grade,
      subject: subject,
      topicTitleEn: 'Addition and Subtraction Within 10',
      topicTitleHi: 'जोड़ और घटाव (10 के भीतर)',
      topicTitleSat: 'ᱡᱚᱲ ᱟᱨ ᱠᱟᱹᱴ',
      competencyId: 'FLN-M3-01',
      learningOutcomeEn:
          'Fluently perform both addition and subtraction operations within 10 to solve combined arithmetic tasks.',
      learningOutcomeHi:
          '10 के भीतर जोड़ और घटाव दोनों संक्रियाओं को धाराप्रवाह रूप से हल करना।',
      targetLanguage: targetLanguage,
      estimatedDurationMinutes: 45,
      teacherScript: const [
        TeacherScriptStep(
          stepNumber: 1,
          phaseName: 'Inverse Operations Concept (जोड़ और घटाव का संबंध)',
          dialogueHi: 'यदि पेड़ पर 8 चिड़ियाँ थीं और 3 उड़ गईं, तो 5 बचीं (8 - 3 = 5)। यदि 3 वापस आ गईं, तो फिर से 8 हो गईं (5 + 3 = 8)।',
          dialogueSat: 'ᱡᱩᱫᱤ ᱫᱟᱨᱮ ᱨᱮ ᱘ ᱪᱮᱬᱮ ᱠᱚ ᱛᱟᱦᱮᱸ ᱠᱟᱱᱟ ᱟᱨ ᱓ ᱠᱚ ᱩᱰᱟᱹᱣ ᱮᱱᱟ, ᱛᱚᱵᱮ ᱕ ᱥᱟᱨᱮᱡ ᱮᱱᱟ (᱘ - ᱓ = ᱕) ᱾ ᱡᱩᱫᱤ ᱓ ᱠᱚ ᱨᱩᱣᱟᱹᱲ ᱦᱮᱡ ᱮᱱᱟ, ᱟᱨᱦᱚᱸ ᱘ ᱦᱩᱭ ᱮᱱᱟ (᱕ + ᱓ = ᱘) ᱾',
          teacherAction:
              'Draw tree with birds on the board, demonstrating removal and addition.',
          audioAsset: 'assets/audio/santali_longer_sido.wav',
        ),
      ],
      activities: const [
        ClassroomActivityPlan(
          activityNumber: 1,
          activityNameHi: 'टोकन बैंक खेल (Classroom Token Bank)',
          activityNameSat: 'ᱴᱳᱠᱮᱱ ᱵᱮᱸᱠ ᱠᱷᱮᱞᱚᱸᱰ',
          objective: 'Practice combined addition and subtraction with trade tokens.',
          teacherInstruction:
              'Give 9 tokens to each student. Call out events: "+2 tokens from teacher", "-4 tokens for book".',
          studentInstruction:
              'Perform the addition/subtraction on your desk and announce your remaining balance in Santali.',
          contentHi: 'छात्र टोकनों के माध्यम से जोड़ और घटाव की मिली-जुली संक्रियाएँ करेंगे।',
          contentSat: 'ᱯᱟᱹᱴᱷᱩᱣᱟᱹ ᱠᱚ ᱴᱳᱠᱮᱱ ᱛᱮ ᱡᱚᱲ ᱟᱨ ᱠᱟᱹᱴ ᱢᱮᱥᱟ ᱠᱟᱹᱢᱤ ᱠᱚ ᱯᱩᱨᱟᱹᱣᱟ ᱾',
          materialsNeeded: ['10 plastic coins/tokens per student'],
          durationMinutes: 20,
        ),
      ],
      assessmentQuestions: const [
        GeneratedAssessmentQuestion(
          id: 'G3-OPS-01',
          questionEn: 'Calculate: 9 - 4 + 2 = ?',
          questionHi: 'हल कीजिए: 9 - 4 + 2 = ?',
          questionSat: 'ᱦᱤᱥᱟᱹᱵᱽ ᱯᱮ: ᱙ - ᱔ + ᱒ = ?',
          questionType: 'Combined Arithmetic',
          optionsHi: ['7 (सात)', '5 (पाँच)', '8 (आठ)'],
          optionsSat: ['᱗ (ᱮᱭᱟᱭ)', '᱕ (ᱢᱚᱬᱮ)', '᱘ (ᱤᱨᱟᱹᱞ)'],
          correctOptionIndex: 0,
          explanationHi: '9 में से 4 घटाने पर 5 आता है, और 5 में 2 जोड़ने पर 7 आता है।',
          explanationSat: '᱙ ᱠᱷᱚᱱ ᱔ ᱠᱟᱹᱴ ᱞᱮᱠᱷᱟᱱ ᱕ ᱟᱨ ᱕ ᱥᱟᱶ ᱒ ᱡᱚᱲ ᱞᱮᱠᱷᱟᱱ ᱗ ᱦᱩᱭᱩᱜᱼᱟ ᱾',
          learningOutcome: 'FLN-M3-01: Fluent Addition and Subtraction',
        ),
      ],
      keyVocabulary: const [
        VocabularyItem(
          termEn: 'Subtract / Minus (-)',
          termHi: 'घटाव / कम करना (-)',
          termSat: 'ᱠᱟᱹᱴ / ᱠᱚᱢ (-)',
          transliteration: 'Kat / Kom (-)',
          emoji: '➖',
        ),
        VocabularyItem(
          termEn: 'Remaining / Left',
          termHi: 'बचे हुए / शेष',
          termSat: 'ᱥᱟᱨᱮᱡ',
          transliteration: 'Sarej',
          emoji: '🏷️',
        ),
      ],
    );
  }

  /// G3 - Lesson 2: Number Patterns (FLN-M3-02)
  GeneratedCurriculumLesson _buildG3PatternsLesson(
    int grade,
    String subject,
    LessonContent topic,
    String targetLanguage,
  ) {
    return GeneratedCurriculumLesson(
      lessonId: 'g3_math_patterns',
      grade: grade,
      subject: subject,
      topicTitleEn: 'Number Patterns',
      topicTitleHi: 'संख्या पैटर्न',
      topicTitleSat: 'ᱮᱞ ᱯᱮᱴᱟᱨᱱ',
      competencyId: 'FLN-M3-02',
      learningOutcomeEn:
          'Identify, extend, and construct repeating and growing number patterns (e.g. skip counting by 2s).',
      learningOutcomeHi:
          'संख्याओं के दोहराव और वृद्धि पैटर्न (जैसे 2-2 की छलांग) को पहचानना और आगे बढ़ाना।',
      targetLanguage: targetLanguage,
      estimatedDurationMinutes: 40,
      teacherScript: const [
        TeacherScriptStep(
          stepNumber: 1,
          phaseName: 'Pattern Discovery (पैटर्न की पहचान)',
          dialogueHi: 'बच्चों, ध्यान से देखिए: 2, 4, 6, 8, 10! हम हर बार 2 कदम आगे कूद रहे हैं।',
          dialogueSat: 'ᱜᱤᱫᱽᱨᱟᱹ ᱠᱚ, ᱫᱷᱮᱭᱟᱱ ᱛᱮ ᱧᱮᱞ ᱯᱮ: ᱒, ᱔, ᱖, ᱘, ᱑᱐! ᱟᱵᱚ ᱡᱟᱣ ᱫᱷᱟᱣ ᱒ ᱫᱷᱟᱯ ᱞᱟᱦᱟ ᱥᱮᱫ ᱵᱚᱱ ᱫᱚᱱ ᱮᱫᱟ ᱾',
          teacherAction:
              'Hop along chalk circles on the floor drawn at numbers 2, 4, 6, 8, 10.',
          audioAsset: 'assets/audio/santali_numbers_phulmani.wav',
        ),
      ],
      activities: const [
        ClassroomActivityPlan(
          activityNumber: 1,
          activityNameHi: 'मेंढक कूद पैटर्न खेल (Frog Hop Pattern)',
          activityNameSat: 'ᱪᱮᱛᱮ ᱫᱚᱱ ᱯᱮᱴᱟᱨᱱ ᱠᱷᱮᱞᱚᱸᱰ',
          objective: 'Extend a +2 growing pattern across classroom stepping stones.',
          teacherInstruction:
              'Draw numbers 1 to 10 on the floor. Ask children to hop only on even numbers: 2, 4, 6, 8, 10.',
          studentInstruction:
              'Hop on the pattern squares and call out each number loudly in Ol Chiki.',
          contentHi: 'छात्र 2-2 की छलांग लगाकर संख्या पैटर्न पूरा करेंगे।',
          contentSat: 'ᱯᱟᱹᱴᱷᱩᱣᱟᱹ ᱠᱚ ᱒-᱒ ᱫᱚᱱ ᱠᱟᱛᱮ ᱮᱞ ᱯᱮᱴᱟᱨᱱ ᱠᱚ ᱯᱩᱨᱟᱹᱣᱟ ᱾',
          materialsNeeded: ['Floor chalk grid 1–10'],
          durationMinutes: 20,
        ),
      ],
      assessmentQuestions: const [
        GeneratedAssessmentQuestion(
          id: 'G3-PAT-01',
          questionEn: 'What is the next number in the pattern: 2, 4, 6, 8, [ ? ]',
          questionHi: 'पैटर्न में अगली संख्या क्या होगी: 2, 4, 6, 8, [ ? ]',
          questionSat: 'ᱱᱚᱣᱟ ᱯᱮᱴᱟᱨᱱ ᱨᱮ ᱛᱟᱭᱚᱢ ᱮᱞ ᱫᱚ ᱪᱮᱫ ᱦᱩᱭᱩᱜᱼᱟ: ᱒, ᱔, ᱖, ᱘, [ ? ]',
          questionType: 'Pattern Prediction',
          optionsHi: ['9 (नौ)', '10 (दस)', '12 (बारह)'],
          optionsSat: ['᱙ (ᱟᱨᱮ)', '᱑᱐ (ᱜᱮᱞ)', '᱑᱒ (ᱜᱮᱞ ᱵᱟᱨ)'],
          correctOptionIndex: 1,
          explanationHi: '2-2 के पैटर्न में 8 के बाद 10 आता है।',
          explanationSat: '᱒-᱒ ᱯᱮᱴᱟᱨᱱ ᱨᱮ ᱘ ᱛᱟᱭᱚᱢ ᱑᱐ (ᱜᱮᱞ) ᱦᱤᱡᱩᱜᱼᱟ ᱾',
          learningOutcome: 'FLN-M3-02: Pattern Identification and Extension',
        ),
      ],
      keyVocabulary: const [
        VocabularyItem(
          termEn: 'Pattern',
          termHi: 'पैटर्न / नमूना',
          termSat: 'ᱯᱮᱴᱟᱨᱱ / ᱨᱩᱯ',
          transliteration: 'Pattern / Rup',
          emoji: '🔄',
        ),
        VocabularyItem(
          termEn: 'Skip / Jump',
          termHi: 'छलांग / कूदना',
          termSat: 'ᱫᱚᱱ / ᱯᱷᱟᱨᱟᱠ',
          transliteration: 'Don / Farak',
          emoji: '🦘',
        ),
      ],
    );
  }

  /// G3 - Lesson 3: Simple Word Problems Within 10 (FLN-M3-03)
  GeneratedCurriculumLesson _buildG3WordProblemsLesson(
    int grade,
    String subject,
    LessonContent topic,
    String targetLanguage,
  ) {
    return GeneratedCurriculumLesson(
      lessonId: 'g3_math_word_problems',
      grade: grade,
      subject: subject,
      topicTitleEn: 'Simple Word Problems Within 10',
      topicTitleHi: 'सरल शब्द समस्याएँ (10 के भीतर)',
      topicTitleSat: 'ᱥᱟᱫᱷᱟᱨᱚᱱ ᱠᱟᱛᱷᱟ ᱦᱤᱥᱟᱹᱵᱽ',
      competencyId: 'FLN-M3-03',
      learningOutcomeEn:
          'Formulate mathematical operations and solve everyday contextual word problems involving numbers up to 10.',
      learningOutcomeHi:
          'दैनिक जीवन के संदर्भ वाले सरल व्यावहारिक एवं शाब्दिक प्रश्नों को समझकर 10 के भीतर हल करना।',
      targetLanguage: targetLanguage,
      estimatedDurationMinutes: 45,
      teacherScript: const [
        TeacherScriptStep(
          stepNumber: 1,
          phaseName: 'Contextual Story Math (गाँव के हाट की कहानी)',
          dialogueHi: 'सोमू हाट गया। उसने 4 अमरूद और 3 केले खरीदे। सोमू के पास कुल कितने फल हुए? 7 फल!',
          dialogueSat: 'ᱥᱳᱢᱩ ᱦᱟᱴ ᱮ ᱥᱮᱱ ᱮᱱᱟ ᱾ ᱩᱱᱤ ᱔ ᱟᱢᱨᱩᱫᱽ ᱟᱨ ᱓ ᱠᱟᱭᱨᱟ ᱠᱤᱨᱤᱧ ᱠᱮᱫᱟ ᱾ ᱥᱳᱢᱩ ᱴᱷᱮᱱ ᱡᱚᱛᱚ ᱛᱮ ᱛᱤᱱᱟᱹᱜ ᱡᱚ ᱦᱩᱭ ᱮᱱᱟ? ᱗ (ᱮᱭᱟᱭ) ᱡᱚ!',
          teacherAction:
              'Read story expressively and guide students to convert word clues into math equations.',
          audioAsset: 'assets/audio/santali_educational_sido.wav',
        ),
      ],
      activities: const [
        ClassroomActivityPlan(
          activityNumber: 1,
          activityNameHi: 'हाट-बाजार अभिनय खेल (Village Market Roleplay)',
          activityNameSat: 'ᱦᱟᱴ ᱵᱟᱡᱟᱨ ᱠᱷᱮᱞᱚᱸᱰ',
          objective: 'Translate situational verbal transactions into addition/subtraction.',
          teacherInstruction:
              'Set up a market stall with fruits and clay coins. Have student pairs roleplay buying and selling.',
          studentInstruction:
              'Act as buyer/seller, formulate the math word sentence, and compute the total.',
          contentHi: 'छात्र हाट-बाजार का अभिनय करके वस्तुओं की खरीद-बिक्री का गणित हल करेंगे।',
          contentSat: 'ᱯᱟᱹᱴᱷᱩᱣᱟᱹ ᱠᱚ ᱦᱟᱴ ᱨᱮ ᱡᱤᱱᱤᱥ ᱠᱤᱨᱤᱧ-ᱟᱹᱠᱷᱨᱤᱧ ᱨᱮᱱᱟᱜ ᱠᱟᱛᱷᱟ ᱦᱤᱥᱟᱹᱵᱽ ᱠᱚ ᱞᱟᱹᱭᱟ ᱾',
          materialsNeeded: ['Pretend fruits', 'Paper money / clay tokens', 'Market basket'],
          durationMinutes: 25,
        ),
      ],
      assessmentQuestions: const [
        GeneratedAssessmentQuestion(
          id: 'G3-WRD-01',
          questionEn: 'Rani had 8 mangoes. She gave 3 mangoes to her friend. How many mangoes are left?',
          questionHi: 'रानी के पास 8 आम थे। उसने 3 आम अपनी सहेली को दिए। अब रानी के पास कितने आम बचे?',
          questionSat: 'ᱨᱟᱹᱱᱤ ᱴᱷᱮᱱ ᱘ ᱩᱞ ᱛᱟᱦᱮᱸ ᱠᱟᱱᱟ ᱾ ᱩᱱᱤ ᱓ ᱩᱞ ᱜᱟᱛᱮ ᱮᱢᱟᱫᱮᱭᱟ ᱾ ᱱᱤᱛᱚᱜ ᱨᱟᱹᱱᱤ ᱴᱷᱮᱱ ᱛᱤᱱᱟᱹᱜ ᱩᱞ ᱥᱟᱨᱮᱡ ᱮᱱᱟ?',
          questionType: 'Word Problem Application',
          optionsHi: ['5 आम (8 - 3 = 5)', '6 आम', '11 आम'],
          optionsSat: ['᱕ ᱩᱞ (᱘ - ᱓ = ᱕)', '᱖ ᱩᱞ', '᱑᱑ ᱩᱞ'],
          correctOptionIndex: 0,
          explanationHi: '8 आमों में से 3 देने पर 5 आम बचे (8 - 3 = 5)।',
          explanationSat: '᱘ ᱩᱞ ᱠᱷᱚᱱ ᱓ ᱮᱢ ᱠᱟᱛᱮ ᱕ ᱩᱞ ᱥᱟᱨᱮᱡ ᱮᱱᱟ (᱘ - ᱓ = ᱕) ᱾',
          learningOutcome: 'FLN-M3-03: Real-World Mathematical Problem Solving',
        ),
      ],
      keyVocabulary: const [
        VocabularyItem(
          termEn: 'Market / Haat',
          termHi: 'हाट / बाजार',
          termSat: 'ᱦᱟᱴ / ᱵᱟᱡᱟᱨ',
          transliteration: 'Hat / Bajar',
          emoji: '🛒',
        ),
        VocabularyItem(
          termEn: 'Buy / Purchase',
          termHi: 'खरीदना',
          termSat: 'ᱠᱤᱨᱤᱧ',
          transliteration: 'Kirin',
          emoji: '🛍️',
        ),
        VocabularyItem(
          termEn: 'Give',
          termHi: 'देना',
          termSat: 'ᱮᱢ',
          transliteration: 'Em',
          emoji: '🤝',
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // GENERIC FALLBACK GENERATOR
  // ---------------------------------------------------------------------------
  GeneratedCurriculumLesson _buildGenericLesson(
    int grade,
    String subject,
    LessonContent topic,
    String targetLanguage,
  ) {
    final cleanId =
        'g${grade}_${subject.toLowerCase()}_${topic.titleEn.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}';

    return GeneratedCurriculumLesson(
      lessonId: cleanId,
      grade: grade,
      subject: subject,
      topicTitleEn: topic.titleEn,
      topicTitleHi: topic.titleHi,
      topicTitleSat: topic.titleSat,
      competencyId: topic.competencyId.isNotEmpty
          ? topic.competencyId
          : 'FLN-G$grade-${subject.substring(0, 1).toUpperCase()}',
      learningOutcomeEn: topic.learningOutcomeEn.isNotEmpty
          ? topic.learningOutcomeEn
          : 'Understand fundamental classroom concepts of ${topic.titleEn} for Grade $grade.',
      learningOutcomeHi: topic.learningOutcomeHi.isNotEmpty
          ? topic.learningOutcomeHi
          : 'कक्षा $grade के लिए ${topic.titleHi} की बुनियादी अवधारणाओं को समझना।',
      targetLanguage: targetLanguage,
      estimatedDurationMinutes: 35,
      teacherScript: [
        TeacherScriptStep(
          stepNumber: 1,
          phaseName: 'Introduction & Warm-up',
          dialogueHi: 'नमस्ते बच्चों! आज हम ${topic.titleHi} सीखेंगे।',
          dialogueSat: topic.titleSat.isNotEmpty
              ? 'ᱡᱚᱦᱟᱨ ᱜᱤᱫᱽᱨᱟᱹ ᱠᱚ! ᱛᱮᱦᱮᱧ ᱟᱵᱚ ${topic.titleSat} ᱵᱚᱱ ᱪᱮᱫᱟ ᱾'
              : 'Translation not available yet',
          teacherAction:
              'Introduce the lesson topic using everyday classroom examples.',
        ),
        TeacherScriptStep(
          stepNumber: 2,
          phaseName: 'Interactive Demonstration',
          dialogueHi: 'ध्यान से सुनिए और मेरे साथ अभ्यास कीजिए।',
          dialogueSat: topic.titleSat.isNotEmpty
              ? 'ᱫᱷᱮᱭᱟᱱ ᱛᱮ ᱟᱸᱡᱚᱢ ᱯᱮ ᱟᱨ ᱤᱧ ᱥᱟᱶ ᱯᱟᱲᱦᱟᱣ ᱯᱮ ᱾'
              : 'Translation not available yet',
          teacherAction: 'Demonstrate with flashcards and blackboard diagrams.',
        ),
      ],
      activities: [
        ClassroomActivityPlan(
          activityNumber: 1,
          activityNameHi: '${topic.titleHi} अभ्यास गतिविधि',
          activityNameSat: topic.titleSat.isNotEmpty
              ? '${topic.titleSat} ᱠᱟᱹᱢᱤ ᱦᱚᱨᱟ'
              : 'Activity in Santali',
          objective: 'Practice ${topic.titleEn} through collaborative actions.',
          teacherInstruction:
              'Divide the class into small groups and guide the practice.',
          studentInstruction: 'Work with your partner to complete the task.',
          contentHi: 'छात्र मिलकर अभ्यास कार्य पूरा करेंगे।',
          contentSat: topic.titleSat.isNotEmpty
              ? 'ᱯᱟᱹᱴᱷᱩᱣᱟᱹ ᱠᱚ ᱢᱮᱥᱟ ᱠᱟᱛᱮ ᱠᱟᱹᱢᱤ ᱯᱩᱨᱟᱹᱣ ᱠᱚ ᱠᱩᱨᱩᱢᱩᱴᱩᱭᱟ ᱾'
              : 'Translation not available yet',
          materialsNeeded: const ['Classroom blackboard', 'Notebooks'],
          durationMinutes: 15,
        ),
      ],
      assessmentQuestions: [
        GeneratedAssessmentQuestion(
          id: 'Q-GEN-01',
          questionEn: 'What is the main topic of today\'s lesson?',
          questionHi: 'आज हमने किस विषय पर सीखा?',
          questionSat: topic.titleSat.isNotEmpty
              ? 'ᱛᱮᱦᱮᱧ ᱟᱵᱚ ᱪᱮᱫ ᱵᱤᱥᱚᱭ ᱨᱮ ᱵᱚᱱ ᱪᱮᱫ ᱠᱮᱫᱟ?'
              : 'Translation not available yet',
          questionType: 'Topic Recall',
          optionsHi: [topic.titleHi, 'अन्य विषय', 'खेल'],
          optionsSat: [
            topic.titleSat.isNotEmpty ? topic.titleSat : topic.titleHi,
            'ᱮᱴᱟᱜ ᱠᱟᱛᱷᱟ',
            'ᱠᱷᱮᱞᱚᱸᱰ',
          ],
          correctOptionIndex: 0,
          explanationHi: 'आज का पाठ ${topic.titleHi} पर आधारित था।',
          explanationSat: topic.titleSat.isNotEmpty
              ? 'ᱛᱮᱦᱮᱧᱟᱜ ᱯᱟᱲᱦᱟᱣ ᱫᱚ ${topic.titleSat} ᱪᱮᱛᱟᱱ ᱨᱮ ᱛᱟᱦᱮᱸ ᱠᱟᱱᱟ ᱾'
              : 'Lesson was on ${topic.titleHi}',
          learningOutcome: 'Topic Comprehension',
        ),
      ],
      keyVocabulary: [
        VocabularyItem(
          termEn: topic.titleEn,
          termHi: topic.titleHi,
          termSat: topic.titleSat.isNotEmpty
              ? topic.titleSat
              : 'Translation not available yet',
          transliteration: topic.titleSat,
          emoji: '📖',
        ),
      ],
    );
  }
}
