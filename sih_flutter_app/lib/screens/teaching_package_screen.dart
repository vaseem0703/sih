import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../services/curriculum_generator_service.dart';
import '../services/tts_service.dart';
import 'flashcard_screen.dart';
import 'lesson_worksheet_screen.dart';

class TeachingPackageScreen extends StatefulWidget {
  final GeneratedCurriculumLesson lesson;
  final TtsService ttsService;

  const TeachingPackageScreen({
    super.key,
    required this.lesson,
    required this.ttsService,
  });

  @override
  State<TeachingPackageScreen> createState() => _TeachingPackageScreenState();
}

class _TeachingPackageScreenState extends State<TeachingPackageScreen> {
  late GeneratedCurriculumLesson _currentLesson;
  final CurriculumGeneratorService _generatorService =
      CurriculumGeneratorService();
  bool _isPlayingAudio = false;
  int? _playingStepIndex;

  @override
  void initState() {
    super.initState();
    _currentLesson = widget.lesson;
    _loadTeacherState();
  }

  void _loadTeacherState() async {
    final updated = await _generatorService.loadTeacherReviewedLesson(
      widget.lesson,
    );
    if (mounted) {
      setState(() => _currentLesson = updated);
    }
  }

  void _playAudio(String? assetPath, String santaliText, int stepIndex) async {
    if (_isPlayingAudio) return;
    setState(() {
      _isPlayingAudio = true;
      _playingStepIndex = stepIndex;
    });

    if (assetPath != null && assetPath.isNotEmpty) {
      await widget.ttsService.playAudio(assetPath);
    } else {
      await widget.ttsService.generateSantaliSpeech(
        santaliText: santaliText,
        speaker: 'Phulmani (Female)',
      );
    }

    await Future.delayed(const Duration(milliseconds: 1800));
    if (mounted) {
      setState(() {
        _isPlayingAudio = false;
        _playingStepIndex = null;
      });
    }
  }

  void _showEditScriptDialog(int stepIndex) {
    final step = _currentLesson.teacherScript[stepIndex];
    final controller = TextEditingController(text: step.dialogueSat);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.edit, color: AppColors.purple, size: 20),
            const SizedBox(width: 8),
            Text(
              'Edit Santali Script (Phase ${step.stepNumber})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hindi Reference:',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              step.dialogueHi,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 14),
            const Text(
              'Santali Translation (Ol Chiki / Dialect):',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await _generatorService.restoreOriginalContent(
                _currentLesson.lessonId,
              );
              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
              _loadTeacherState();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Restored original translation'),
                  ),
                );
              }
            },
            child: const Text(
              'Restore Original',
              style: TextStyle(color: Colors.red),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navy,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final newText = controller.text.trim();
              if (newText.isNotEmpty) {
                final updatedScript = List<TeacherScriptStep>.from(
                  _currentLesson.teacherScript,
                );
                updatedScript[stepIndex] = updatedScript[stepIndex].copyWith(
                  dialogueSat: newText,
                );
                setState(() {
                  _currentLesson = _currentLesson.copyWith(
                    teacherScript: updatedScript,
                    isTeacherReviewed: true,
                  );
                });
                await _generatorService.saveTeacherReview(
                  lessonId: _currentLesson.lessonId,
                  isReviewed: true,
                  editedScriptSat: newText,
                );
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✓ Teacher correction saved offline'),
                      backgroundColor: AppColors.greenOk,
                    ),
                  );
                }
              }
            },
            child: const Text('Save Correction'),
          ),
        ],
      ),
    );
  }

  void _toggleTeacherReview() async {
    final newStatus = !_currentLesson.isTeacherReviewed;
    setState(() {
      _currentLesson = _currentLesson.copyWith(isTeacherReviewed: newStatus);
    });
    await _generatorService.saveTeacherReview(
      lessonId: _currentLesson.lessonId,
      isReviewed: newStatus,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus ? '✓ Marked as Teacher Reviewed' : 'Review badge removed',
          ),
          backgroundColor: newStatus ? AppColors.greenOk : AppColors.navy,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final lesson = _currentLesson;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.navy),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Teaching Package: ${lesson.topicTitleEn}',
          style: const TextStyle(
            color: AppColors.textHeadline,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        actions: [
          // Teacher Reviewed Status Toggle
          GestureDetector(
            onTap: _toggleTeacherReview,
            child: Container(
              margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: lesson.isTeacherReviewed
                    ? AppColors.greenOk.withValues(alpha: 0.12)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: lesson.isTeacherReviewed
                      ? AppColors.greenOk
                      : AppColors.line,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    lesson.isTeacherReviewed
                        ? Icons.verified
                        : Icons.edit_note_outlined,
                    size: 14,
                    color: lesson.isTeacherReviewed
                        ? AppColors.greenOk
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    lesson.isTeacherReviewed
                        ? '✓ Teacher Reviewed'
                        : 'Review Lesson',
                    style: TextStyle(
                      color: lesson.isTeacherReviewed
                          ? AppColors.greenOk
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. 🎯 LEARNING OUTCOME BANNER
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('🎯', style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LEARNING OUTCOME (${lesson.competencyId})',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF92400E),
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              lesson.learningOutcomeEn,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF78350F),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              lesson.learningOutcomeHi,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF92400E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // 2. 📖 LESSON SCRIPT SECTION
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Flexible(
                      child: Text(
                        '📖 Bilingual Lesson Script',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textHeadline,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${lesson.teacherScript.length} PHASES',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                ...lesson.teacherScript.asMap().entries.map((entry) {
                  final index = entry.key;
                  final step = entry.value;
                  return _buildScriptStepCard(step, index);
                }),

                const SizedBox(height: 28),

                // 3. 📦 LEARNING MATERIALS SECTION
                const Text(
                  '📦 Lesson Materials & Practice',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textHeadline,
                  ),
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    // Worksheet Card
                    Expanded(
                      child: _buildMaterialActionCard(
                        emoji: '📝',
                        title: 'Worksheet',
                        subtitle:
                            'Printable practice worksheet for ${lesson.topicTitleEn}.',
                        buttonLabel: 'Open Worksheet',
                        color: AppColors.purple,
                        lightColor: AppColors.purpleLight,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  LessonWorksheetScreen(lesson: lesson),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Flashcards Card
                    Expanded(
                      child: _buildMaterialActionCard(
                        emoji: '🖼',
                        title: 'Flashcards',
                        subtitle:
                            '${lesson.keyVocabulary.length} cards with Santali Ol Chiki & audio.',
                        buttonLabel: 'Open Flashcards',
                        color: AppColors.navy,
                        lightColor: const Color(0xFFF1F5F9),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => FlashcardScreen(
                                lesson: lesson,
                                ttsService: widget.ttsService,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScriptStepCard(TeacherScriptStep step, int index) {
    final isPlaying = _isPlayingAudio && _playingStepIndex == index;

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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.navy,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'PHASE ${step.stepNumber}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  step.phaseName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textHeadline,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                tooltip: 'Edit Santali translation',
                color: AppColors.purple,
                onPressed: () => _showEditScriptDialog(index),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Hindi Block
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'HINDI TEACHER DIALOGUE',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  step.dialogueHi,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textHeadline,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Santali Block with Audio Play
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.purpleLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE1D5F0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SANTHALI (OL CHIKI)',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppColors.purple,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        step.dialogueSat.isNotEmpty
                            ? step.dialogueSat
                            : 'Translation not available yet',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: step.dialogueSat.isNotEmpty
                              ? const Color(0xFF3B1861)
                              : AppColors.textMuted,
                          fontStyle: step.dialogueSat.isNotEmpty
                              ? FontStyle.normal
                              : FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: isPlaying
                        ? AppColors.greenOk
                        : AppColors.purple,
                    foregroundColor: Colors.white,
                  ),
                  icon: Icon(
                    isPlaying ? Icons.volume_up : Icons.play_arrow,
                    size: 18,
                  ),
                  tooltip: 'Play Santali Voice',
                  onPressed: () =>
                      _playAudio(step.audioAsset, step.dialogueSat, index),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Teacher Physical Action Hint
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.lightbulb_outline,
                size: 16,
                color: Color(0xFFD97706),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Action: ${step.teacherAction}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialActionCard({
    required String emoji,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required Color color,
    required Color lightColor,
    required VoidCallback onTap,
  }) {
    return Container(
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: lightColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 24)),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.textHeadline,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: onTap,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  buttonLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
