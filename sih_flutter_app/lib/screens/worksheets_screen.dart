import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../data/curriculum_data.dart';
import '../services/curriculum_generator_service.dart';
import '../services/tts_service.dart';
import 'lesson_worksheet_screen.dart';
import 'teaching_package_screen.dart';

/// Centralized Learning Materials Library (Worksheets & Visual Flashcards).
/// Integrates seamlessly with Curriculum and Teaching Packages using single-source lessonId.
class WorksheetsScreen extends StatefulWidget {
  final int? initialGrade;
  final String? initialSubject;
  final String? initialTopicTitle;
  final String? initialLessonId;
  final int initialSubTab; // 0: Worksheets, 1: Flashcards
  final TtsService? ttsService;

  const WorksheetsScreen({
    super.key,
    this.initialGrade,
    this.initialSubject,
    this.initialTopicTitle,
    this.initialLessonId,
    this.initialSubTab = 0,
    this.ttsService,
  });

  @override
  State<WorksheetsScreen> createState() => _WorksheetsScreenState();
}

class _WorksheetsScreenState extends State<WorksheetsScreen> {
  late int _selectedTab; // 0: Worksheets, 1: Flashcards
  late int _selectedGrade;
  late String _selectedSubject;
  String? _activeFilterTopic;
  String? _activeFilterLessonId;
  int _selectedFlashcardTopicIndex = 0;
  final PageController _flashcardController = PageController(
    viewportFraction: 0.88,
  );
  int _currentFlashcardIndex = 0;
  bool _isPlayingAudio = false;

  final CurriculumGeneratorService _generator = CurriculumGeneratorService();
  late final TtsService _ttsService;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialSubTab;
    _ttsService = widget.ttsService ?? TtsService();

    if (widget.initialLessonId != null) {
      final ctx = _generator.findLessonContextById(widget.initialLessonId!);
      if (ctx != null) {
        _selectedGrade = ctx['grade'] as int;
        _selectedSubject = ctx['subject'] as String;
        final topic = ctx['topic'] as LessonContent;
        _activeFilterTopic = topic.titleEn;
        _activeFilterLessonId = widget.initialLessonId;
      } else {
        _selectedGrade = widget.initialGrade ?? 1;
        _selectedSubject = widget.initialSubject ?? 'Mathematics';
        _activeFilterTopic = widget.initialTopicTitle;
        _activeFilterLessonId = widget.initialLessonId;
      }
    } else {
      _selectedGrade = widget.initialGrade ?? 1;
      _selectedSubject = widget.initialSubject ?? 'Mathematics';
      _activeFilterTopic = widget.initialTopicTitle;
      _activeFilterLessonId = null;
    }
  }

  @override
  void dispose() {
    _flashcardController.dispose();
    super.dispose();
  }

  void _clearFilter() {
    setState(() {
      _activeFilterTopic = null;
      _activeFilterLessonId = null;
      _selectedFlashcardTopicIndex = 0;
      _currentFlashcardIndex = 0;
    });
  }

  void _navigateToLessonOverview(
    int grade,
    String subject,
    LessonContent topic,
  ) {
    final generator = CurriculumGeneratorService();
    final lesson = generator.generateLessonPlan(
      grade: grade,
      subject: subject,
      topic: topic,
      targetLanguage: 'sat_Olck',
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            TeachingPackageScreen(lesson: lesson, ttsService: _ttsService),
      ),
    );
  }

  void _playFlashcardAudio(VocabularyItem item) async {
    if (_isPlayingAudio) return;
    setState(() => _isPlayingAudio = true);

    if (item.audioAsset != null && item.audioAsset!.isNotEmpty) {
      await _ttsService.playAudio(item.audioAsset!);
    } else {
      await _ttsService.generateSantaliSpeech(
        santaliText: item.termSat,
        speaker: 'Phulmani (Female)',
      );
    }

    await Future.delayed(const Duration(milliseconds: 1600));
    if (mounted) setState(() => _isPlayingAudio = false);
  }

  @override
  Widget build(BuildContext context) {
    final isFiltered = _activeFilterTopic != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: isFiltered
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.navy),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: Text(
                _selectedTab == 0 ? 'Lesson Worksheets' : 'Lesson Flashcards',
                style: const TextStyle(
                  color: AppColors.textHeadline,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header (when opened from root bottom navigation)
                if (!isFiltered) ...[
                  const Text(
                    'MATERIALS LIBRARY',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Learning Materials',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textHeadline,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Access all printable bilingual worksheets and audio visual flashcards offline.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 18),
                ],

                // 1. TOP SEGMENTED CONTROL: [ Worksheets ] [ Flashcards ]
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSegmentButton(
                          label: '📝 Worksheets',
                          isSelected: _selectedTab == 0,
                          onTap: () => setState(() => _selectedTab = 0),
                        ),
                      ),
                      Expanded(
                        child: _buildSegmentButton(
                          label: '🖼 Flashcards',
                          isSelected: _selectedTab == 1,
                          onTap: () => setState(() => _selectedTab = 1),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // 2. ACTIVE FILTER BANNER OR GRADE/SUBJECT SELECTORS
                if (isFiltered)
                  _buildActiveFilterBanner()
                else
                  _buildGradeSubjectSelectors(),

                const SizedBox(height: 20),

                // 3. TAB CONTENT
                if (_selectedTab == 0)
                  _buildWorksheetsList()
                else
                  _buildFlashcardsSection(),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? AppColors.navy : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildActiveFilterBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.purpleLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE1D5F0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_alt, size: 22, color: AppColors.purple),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MATERIALS FOR ${_activeFilterTopic?.toUpperCase() ?? ""}',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: AppColors.purple,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'Grade $_selectedGrade • $_selectedSubject',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textHeadline,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.navy,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: AppColors.line),
              ),
            ),
            onPressed: _clearFilter,
            icon: const Icon(Icons.clear_all, size: 16),
            label: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Show All Materials',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeSubjectSelectors() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Grade Selector
        Row(
          children: [1, 2, 3].map((g) {
            final isSelected = _selectedGrade == g;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: g == 3 ? 0 : 8),
                child: GestureDetector(
                  onTap: () => setState(() {
                    _selectedGrade = g;
                    _selectedFlashcardTopicIndex = 0;
                    _currentFlashcardIndex = 0;
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.navy : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? AppColors.navy : AppColors.line,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Grade $g',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : AppColors.navy,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),

        // Subject Selector
        Row(
          children: ['Mathematics', 'Language', 'EVS'].map((s) {
            final isSelected = _selectedSubject == s;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: s == 'EVS' ? 0 : 8),
                child: GestureDetector(
                  onTap: () => setState(() {
                    _selectedSubject = s;
                    _selectedFlashcardTopicIndex = 0;
                    _currentFlashcardIndex = 0;
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.purple
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? AppColors.purple : AppColors.line,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      s,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 1. WORKSHEETS TAB CONTENT
  // ---------------------------------------------------------------------------
  Widget _buildWorksheetsList() {
    final allTopics =
        CurriculumData.curriculum[_selectedGrade]?[_selectedSubject] ?? [];
    final displayedTopics = _activeFilterLessonId != null
        ? allTopics.where((t) {
            final l = _generator.generateLessonPlan(
              grade: _selectedGrade,
              subject: _selectedSubject,
              topic: t,
            );
            return l.lessonId == _activeFilterLessonId;
          }).toList()
        : (_activeFilterTopic != null
              ? allTopics.where((t) => t.titleEn == _activeFilterTopic).toList()
              : allTopics);

    if (displayedTopics.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: const Text('No worksheets found for this selection.'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Available Worksheets (${displayedTopics.length})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textHeadline,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.greenOk.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '✓ Offline Ready',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.greenOk,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        ...displayedTopics.map((topic) {
          final lesson = _generator.generateLessonPlan(
            grade: _selectedGrade,
            subject: _selectedSubject,
            topic: topic,
          );
          return _buildWorksheetCard(lesson, topic);
        }),
      ],
    );
  }

  Widget _buildWorksheetCard(
    GeneratedCurriculumLesson lesson,
    LessonContent topic,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            alignment: WrapAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.purpleLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'GRADE ${lesson.grade} • ${lesson.subject.toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.purple,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    lesson.competencyId,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const Text(
                'HINDI + SANTHALI',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF65349F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Title
          Text(
            '📝 ${topic.titleEn} Worksheet',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.textHeadline,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${topic.titleHi} • ᱥᱟᱱᱛᱟᱲᱤ: ${topic.titleSat}',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),

          // Outcome Banner
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                const Text('🎯', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    lesson.learningOutcomeHi,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF92400E),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Action Buttons: [ Preview Worksheet ] and [ 📖 View Lesson ]
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            LessonWorksheetScreen(lesson: lesson),
                      ),
                    );
                  },
                  icon: const Icon(Icons.description, size: 16),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Preview Worksheet',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.purple,
                    side: const BorderSide(color: AppColors.purple),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => _navigateToLessonOverview(
                    lesson.grade,
                    lesson.subject,
                    topic,
                  ),
                  icon: const Icon(Icons.menu_book, size: 15),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'View Lesson',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. FLASHCARDS TAB CONTENT
  // ---------------------------------------------------------------------------
  Widget _buildFlashcardsSection() {
    final allTopics =
        CurriculumData.curriculum[_selectedGrade]?[_selectedSubject] ?? [];

    if (allTopics.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: const Text('No flashcards found for this selection.'),
      );
    }

    final activeIndex = _activeFilterLessonId != null
        ? allTopics.indexWhere((t) {
            final l = _generator.generateLessonPlan(
              grade: _selectedGrade,
              subject: _selectedSubject,
              topic: t,
            );
            return l.lessonId == _activeFilterLessonId;
          })
        : (_activeFilterTopic != null
              ? allTopics.indexWhere((t) => t.titleEn == _activeFilterTopic)
              : _selectedFlashcardTopicIndex);

    final validIndex = (activeIndex >= 0 && activeIndex < allTopics.length)
        ? activeIndex
        : 0;
    final selectedTopic = allTopics[validIndex];

    final lesson = _generator.generateLessonPlan(
      grade: _selectedGrade,
      subject: _selectedSubject,
      topic: selectedTopic,
    );
    final vocabList = lesson.keyVocabulary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Topic Selector Pills (if not single filtered)
        if (_activeFilterTopic == null) ...[
          const Text(
            'Select Lesson for Flashcards:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textHeadline,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: allTopics.asMap().entries.map((entry) {
                final i = entry.key;
                final t = entry.value;
                final isCur = i == validIndex;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(t.titleEn),
                    selected: isCur,
                    selectedColor: AppColors.purple,
                    labelStyle: TextStyle(
                      color: isCur ? Colors.white : AppColors.textHeadline,
                      fontWeight: isCur ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    onSelected: (_) {
                      setState(() {
                        _selectedFlashcardTopicIndex = i;
                        _currentFlashcardIndex = 0;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Flashcards Carousel Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                '${selectedTopic.titleEn} Flashcards',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textHeadline,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${_currentFlashcardIndex + 1} / ${vocabList.length}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Carousel Container
        SizedBox(
          height: 340,
          child: PageView.builder(
            controller: _flashcardController,
            itemCount: vocabList.length,
            onPageChanged: (idx) =>
                setState(() => _currentFlashcardIndex = idx),
            itemBuilder: (context, index) {
              final item = vocabList[index];
              return _buildCarouselCard(item, index == _currentFlashcardIndex);
            },
          ),
        ),

        const SizedBox(height: 12),

        // Bottom Controls with Swipe & View Lesson button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton.filledTonal(
              icon: const Icon(Icons.chevron_left),
              onPressed: _currentFlashcardIndex > 0
                  ? () => _flashcardController.previousPage(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                    )
                  : null,
            ),
            Row(
              children: List.generate(
                vocabList.length,
                (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentFlashcardIndex == i ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _currentFlashcardIndex == i
                        ? AppColors.purple
                        : AppColors.line,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
            IconButton.filledTonal(
              icon: const Icon(Icons.chevron_right),
              onPressed: _currentFlashcardIndex < vocabList.length - 1
                  ? () => _flashcardController.nextPage(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                    )
                  : null,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Bidirectional Link: View Lesson
        Center(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.navy,
              side: const BorderSide(color: AppColors.navy),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => _navigateToLessonOverview(
              lesson.grade,
              lesson.subject,
              selectedTopic,
            ),
            icon: const Icon(Icons.menu_book_rounded, size: 16),
            label: Text(
              'View Lesson: ${selectedTopic.titleEn}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCarouselCard(VocabularyItem item, bool isCurrent) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCurrent ? AppColors.purple : AppColors.line,
          width: isCurrent ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isCurrent ? 0.08 : 0.04),
            blurRadius: isCurrent ? 14 : 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Emoji Avatar
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: AppColors.purpleLight,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              item.emoji ?? '📖',
              style: const TextStyle(fontSize: 36),
            ),
          ),
          const SizedBox(height: 16),

          // Santali Ol Chiki Term
          Text(
            item.termSat,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.purple,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),

          // Transliteration
          Text(
            item.transliteration,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),

          const Divider(height: 20, thickness: 1, color: AppColors.line),

          // Hindi Meaning
          Text(
            item.termHi,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textHeadline,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.termEn,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),

          const Spacer(),

          // Pronounce Audio Button
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _isPlayingAudio
                  ? AppColors.greenOk
                  : AppColors.purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: () => _playFlashcardAudio(item),
            icon: Icon(
              _isPlayingAudio ? Icons.volume_up : Icons.play_arrow,
              size: 18,
            ),
            label: Text(
              _isPlayingAudio ? 'Playing...' : 'Pronounce (ᱨᱚᱲ ᱟᱸᱡᱚᱢ)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
