import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sih_flutter_app/app/app.dart';
import 'package:sih_flutter_app/data/curriculum_data.dart';
import 'package:sih_flutter_app/screens/flashcard_screen.dart';
import 'package:sih_flutter_app/screens/generated_lesson_screen.dart';
import 'package:sih_flutter_app/screens/lesson_worksheet_screen.dart';
import 'package:sih_flutter_app/screens/lessons_screen.dart';
import 'package:sih_flutter_app/screens/teaching_package_screen.dart';
import 'package:sih_flutter_app/services/curriculum_generator_service.dart';
import 'package:sih_flutter_app/services/tts_service.dart';

void main() {
  testWidgets('SIH App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const SihApp());
    await tester.pumpAndSettle();
    expect(find.textContaining('Teacher'), findsWidgets);
  });

  test('CurriculumGeneratorService generates Grade 1 Counting lesson plan', () {
    final generator = CurriculumGeneratorService();
    final topic = CurriculumData.curriculum[1]!['Mathematics']![0];
    final lesson = generator.generateLessonPlan(
      grade: 1,
      subject: 'Mathematics',
      topic: topic,
    );

    expect(lesson.competencyId, equals('FLN-M1-01'));
    expect(lesson.activities.isNotEmpty, isTrue);
    expect(lesson.teacherScript.isNotEmpty, isTrue);
    expect(lesson.assessmentQuestions.isNotEmpty, isTrue);
    expect(lesson.keyVocabulary.isNotEmpty, isTrue);
    expect(generator.hasWorksheetContent(lesson), isTrue);
    expect(generator.hasFlashcards(lesson), isTrue);
  });

  test('Preserves lesson and topic context across materials', () {
    final generator = CurriculumGeneratorService();
    final topic =
        CurriculumData.curriculum[2]!['Mathematics']![1]; // Addition Within 10
    final lesson = generator.generateLessonPlan(
      grade: 2,
      subject: 'Mathematics',
      topic: topic,
    );

    expect(lesson.grade, equals(2));
    expect(lesson.subject, equals('Mathematics'));
    expect(lesson.topicTitleEn, equals('Addition Within 10'));
    expect(lesson.competencyId, equals('FLN-M2-02'));
  });

  test('Gracefully handles unsupported / future topic without crashing', () {
    final generator = CurriculumGeneratorService();
    const unsupportedTopic = LessonContent(
      titleEn: 'Solar System Exploration',
      titleHi: 'सौर मंडल',
      titleSat: 'ᱥᱤᱝ ᱪᱟᱸᱫᱚ',
    );

    final lesson = generator.generateLessonPlan(
      grade: 3,
      subject: 'Science',
      topic: unsupportedTopic,
    );

    expect(lesson, isNotNull);
    expect(lesson.topicTitleEn, equals('Solar System Exploration'));
    expect(generator.isMaterialAvailable(lesson), isFalse);
  });

  testWidgets(
    'LessonsScreen Start Lesson navigates directly to TeachingPackageScreen',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(home: LessonsScreen(ttsService: TtsService())),
      );
      await tester.pumpAndSettle();

      // Verify topic cards are displayed
      expect(find.text('Start Lesson'), findsWidgets);

      // Tap first Start Lesson button
      await tester.tap(find.text('Start Lesson').first);
      await tester.pumpAndSettle();

      // Verify it navigated directly to TeachingPackageScreen
      expect(find.byType(TeachingPackageScreen), findsOneWidget);
      expect(find.textContaining('Teaching Package:'), findsOneWidget);
      expect(find.text('📖 Bilingual Lesson Script'), findsOneWidget);
      expect(find.text('Open Worksheet'), findsOneWidget);
      expect(find.text('Open Flashcards'), findsOneWidget);

      // Verify activities and formative assessment sections are not in simplified Teaching Package
      expect(find.text('🎲 Classroom Activities'), findsNothing);
      expect(find.text('❓ Formative Assessment'), findsNothing);

      // Tap Open Worksheet from Teaching Package
      await tester.scrollUntilVisible(
        find.text('Open Worksheet'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open Worksheet'));
      await tester.pumpAndSettle();
      expect(find.byType(LessonWorksheetScreen), findsOneWidget);

      // Return to Teaching Package
      await tester.scrollUntilVisible(
        find.text('View Lesson (Return to Lesson Plan)'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('View Lesson (Return to Lesson Plan)'));
      await tester.pumpAndSettle();
      expect(find.byType(TeachingPackageScreen), findsOneWidget);

      // Tap Open Flashcards from Teaching Package
      await tester.tap(find.text('Open Flashcards'));
      await tester.pumpAndSettle();
      expect(find.byType(FlashcardScreen), findsOneWidget);

      // Return to Teaching Package
      await tester.tap(find.text('View Lesson (Return to Lesson Plan)'));
      await tester.pumpAndSettle();
      expect(find.byType(TeachingPackageScreen), findsOneWidget);
    },
  );

  testWidgets(
    'GeneratedLessonScreen renders and links to Worksheet & Flashcards',
    (WidgetTester tester) async {
      final generator = CurriculumGeneratorService();
      final topic = CurriculumData.curriculum[1]!['Mathematics']![0];
      final lesson = generator.generateLessonPlan(
        grade: 1,
        subject: 'Mathematics',
        topic: topic,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: GeneratedLessonScreen(lesson: lesson, ttsService: TtsService()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Counting 1–10'), findsWidgets);

      // Scroll to materials section
      await tester.scrollUntilVisible(
        find.text('Generate Worksheet'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Generate Worksheet'), findsOneWidget);
      expect(find.text('Generate Flashcards'), findsOneWidget);

      // Tap Generate Worksheet
      await tester.tap(find.text('Generate Worksheet'));
      await tester.pumpAndSettle();
      expect(find.byType(LessonWorksheetScreen), findsOneWidget);
      expect(find.textContaining('Counting 1–10'), findsWidgets);

      // Return to Lesson from Worksheet
      await tester.scrollUntilVisible(
        find.text('View Lesson (Return to Lesson Plan)'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('View Lesson (Return to Lesson Plan)'));
      await tester.pumpAndSettle();
      expect(find.byType(GeneratedLessonScreen), findsOneWidget);

      // Scroll to Generate Flashcards
      await tester.scrollUntilVisible(
        find.text('Generate Flashcards'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Tap Generate Flashcards
      await tester.tap(find.text('Generate Flashcards'));
      await tester.pumpAndSettle();
      expect(find.byType(FlashcardScreen), findsOneWidget);

      // Return to Lesson
      await tester.tap(find.text('View Lesson (Return to Lesson Plan)'));
      await tester.pumpAndSettle();
      expect(find.byType(GeneratedLessonScreen), findsOneWidget);
    },
  );

  testWidgets(
    'Responsive Layout test on narrow 320px screen across all curriculum screens without RenderFlex overflow',
    (WidgetTester tester) async {
      // Configure narrow screen constraint (320px width)
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final generator = CurriculumGeneratorService();
      final ttsService = TtsService();

      // 1. Test LessonsScreen on narrow screen
      await tester.pumpWidget(
        MaterialApp(home: LessonsScreen(ttsService: ttsService)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(LessonsScreen), findsOneWidget);

      // Switch subject to Language (long topics)
      await tester.tap(find.text('Language'));
      await tester.pumpAndSettle();
      expect(find.text('Reading Simple Sentences'), findsWidgets);

      // Switch to Grade 3 EVS (Clean Water and Air)
      await tester.tap(find.text('Grade 3'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('EVS'));
      await tester.pumpAndSettle();
      expect(find.text('Clean Water and Air'), findsWidgets);

      // 2. Test TeachingPackageScreen with long topic on narrow screen
      final g3EvsTopic =
          CurriculumData.curriculum[3]!['EVS']![0]; // Clean Water and Air
      final g3EvsLesson = generator.generateLessonPlan(
        grade: 3,
        subject: 'EVS',
        topic: g3EvsTopic,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TeachingPackageScreen(
            lesson: g3EvsLesson,
            ttsService: ttsService,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TeachingPackageScreen), findsOneWidget);

      // 3. Test GeneratedLessonScreen with long topic on narrow screen
      final g2MathTopic =
          CurriculumData.curriculum[2]!['Mathematics']![2]; // Numbers up to 100
      final g2MathLesson = generator.generateLessonPlan(
        grade: 2,
        subject: 'Mathematics',
        topic: g2MathTopic,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: GeneratedLessonScreen(
            lesson: g2MathLesson,
            ttsService: ttsService,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(GeneratedLessonScreen), findsOneWidget);

      // 4. Test SihApp full navigation on narrow screen
      await tester.pumpWidget(const SihApp());
      await tester.pumpAndSettle();
      expect(find.textContaining('Teacher'), findsWidgets);
    },
  );
}
