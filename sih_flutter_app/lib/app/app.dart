import 'package:flutter/material.dart';
import '../services/speech_service.dart';
import '../services/translation_service.dart';
import '../services/tts_service.dart';
import '../screens/home_screen.dart';
import '../screens/live_class_screen.dart';
import '../screens/lessons_screen.dart';
import '../screens/activity_screen.dart';
import '../screens/worksheets_screen.dart';
import '../screens/settings_screen.dart';
import '../widgets/app_header.dart';
import '../widgets/app_navigation.dart';
import 'theme.dart';

class SihApp extends StatefulWidget {
  const SihApp({super.key});

  @override
  State<SihApp> createState() => _SihAppState();
}

class _SihAppState extends State<SihApp> {
  int _currentTabIndex = 0; // 0: Home, 1: Live, 2: Lessons, 3: Worksheets

  // Active activity state
  bool _isInActivity = false;
  int _activityGrade = 2;
  String _activitySubject = 'Mathematics';
  int _activityLessonIndex = 0;

  final SpeechService _speechService = SpeechService();
  final TranslationService _translationService = TranslationService();
  final TtsService _ttsService = TtsService();

  void _onNavigateTab(int index) {
    setState(() {
      _currentTabIndex = index;
      _isInActivity = false;
    });
  }

  void _startActivity(int grade, String subject, int index) {
    setState(() {
      _activityGrade = grade;
      _activitySubject = subject;
      _activityLessonIndex = index;
      _isInActivity = true;
    });
  }

  void _backToLessons() {
    setState(() {
      _isInActivity = false;
      _currentTabIndex = 2; // Return to Lessons tab
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bhasha Setu',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              // Master Top App Header
              const AppHeader(),

              // Full Width Content Page
              Expanded(child: _buildCurrentContent()),
            ],
          ),
        ),
        bottomNavigationBar: AppBottomNavBar(
          currentIndex: _isInActivity ? 2 : _currentTabIndex,
          onTap: _onNavigateTab,
        ),
      ),
    );
  }

  Widget _buildCurrentContent() {
    if (_isInActivity) {
      return ActivityScreen(
        grade: _activityGrade,
        subject: _activitySubject,
        lessonIndex: _activityLessonIndex,
        ttsService: _ttsService,
        onBackToLessons: _backToLessons,
      );
    }

    switch (_currentTabIndex) {
      case 0:
        return HomeScreen(
          onNavigateTab: _onNavigateTab,
          onContinueLesson: () => _startActivity(2, 'Mathematics', 0),
        );
      case 1:
        return LiveClassScreen(
          speechService: _speechService,
          translationService: _translationService,
          ttsService: _ttsService,
        );
      case 2:
        return LessonsScreen(
          onStartLesson: _startActivity,
          ttsService: _ttsService,
        );
      case 3:
        return WorksheetsScreen(ttsService: _ttsService);
      case 4:
        return const SettingsScreen();
      default:
        return HomeScreen(
          onNavigateTab: _onNavigateTab,
          onContinueLesson: () => _startActivity(2, 'Mathematics', 0),
        );
    }
  }
}
