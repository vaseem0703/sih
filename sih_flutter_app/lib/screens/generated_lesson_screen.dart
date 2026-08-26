import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../services/curriculum_generator_service.dart';
import '../services/tts_service.dart';
import 'flashcard_screen.dart';
import 'lesson_worksheet_screen.dart';

/// Screen displaying the structured offline-generated lesson plan.
class GeneratedLessonScreen extends StatefulWidget {
  final GeneratedCurriculumLesson lesson;
  final TtsService? ttsService;

  const GeneratedLessonScreen({
    super.key,
    required this.lesson,
    this.ttsService,
  });

  @override
  State<GeneratedLessonScreen> createState() => _GeneratedLessonScreenState();
}

class _GeneratedLessonScreenState extends State<GeneratedLessonScreen> {
  late final TtsService _ttsService;
  int? _playingStepIndex;

  @override
  void initState() {
    super.initState();
    _ttsService = widget.ttsService ?? TtsService();
  }

  void _playSantaliScriptAudio(String text, int stepIndex) async {
    if (_playingStepIndex != null) return;
    setState(() => _playingStepIndex = stepIndex);

    await _ttsService.generateSantaliSpeech(
      santaliText: text,
      speaker: 'Phulmani (Female)',
    );

    await Future.delayed(const Duration(milliseconds: 1800));
    if (mounted) setState(() => _playingStepIndex = null);
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    final isTemplateSupported = !lesson.competencyId.contains('GENERIC') &&
        lesson.activities.isNotEmpty;

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
          lesson.topicTitleEn,
          style: const TextStyle(
            color: AppColors.textHeadline,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.greenOk.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.offline_bolt, size: 14, color: AppColors.greenOk),
                SizedBox(width: 4),
                Text(
                  'Offline Generated',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.greenOk,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Unsupported / Generic template notice
                if (!isTemplateSupported)
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Color(0xFFD97706)),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Standard FLN template generated. Specific mother-tongue lesson script for this topic is in development.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF92400E),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // 1. HEADER METADATA CARD
                Container(
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
                          Text(
                            lesson.competencyId,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const Text(
                            '⏱ ~35 Mins',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        lesson.topicTitleEn,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textHeadline,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${lesson.topicTitleHi} • ᱥᱟᱱᱛᱟᱲᱤ: ${lesson.topicTitleSat}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 2. 🎯 LEARNING OUTCOME SECTION
                _buildSectionHeader(
                  emoji: '🎯',
                  title: 'Learning Outcomes (NIPUN Bharat)',
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'English: ${lesson.learningOutcomeEn}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF92400E),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'हिंदी: ${lesson.learningOutcomeHi}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF78350F),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 3. 📖 TEACHER SCRIPT SECTION
                _buildSectionHeader(
                  emoji: '📖',
                  title: 'Bilingual Teacher Script',
                ),
                const SizedBox(height: 10),
                ...lesson.teacherScript.map(
                  (step) => _buildScriptStepCard(step),
                ),

                const SizedBox(height: 24),

                // 4. 🎲 CLASSROOM ACTIVITIES
                _buildSectionHeader(
                  emoji: '🎲',
                  title: 'Classroom Activities',
                ),
                const SizedBox(height: 10),
                ...lesson.activities.map((act) => _buildActivityCard(act)),

                const SizedBox(height: 24),

                // 5. 🔤 KEY VOCABULARY
                _buildSectionHeader(
                  emoji: '🔤',
                  title: 'Key Vocabulary (Mother Tongue)',
                ),
                const SizedBox(height: 10),
                _buildVocabularyList(lesson.keyVocabulary),

                const SizedBox(height: 24),

                // 6. ❓ FORMATIVE ASSESSMENT QUESTIONS
                _buildSectionHeader(
                  emoji: '❓',
                  title: 'Formative Assessment Prompts',
                ),
                const SizedBox(height: 10),
                ...lesson.assessmentQuestions.map((q) => _buildQuestionCard(q)),

                const SizedBox(height: 28),

                // 7. 📚 LESSON MATERIALS SECTION
                _buildSectionHeader(
                  emoji: '📚',
                  title: 'Lesson Materials & Teaching Resources',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Generate Worksheet Card
                    Expanded(
                      child: _buildMaterialActionCard(
                        emoji: '📝',
                        title: 'Worksheet',
                        subtitle:
                            'Printable bilingual practice sheet for ${lesson.topicTitleEn}.',
                        buttonLabel: 'Generate Worksheet',
                        color: AppColors.purple,
                        lightColor: AppColors.purpleLight,
                        onTap: () => _openGeneratedWorksheet(context),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Generate Flashcards Card
                    Expanded(
                      child: _buildMaterialActionCard(
                        emoji: '🖼',
                        title: 'Flashcards',
                        subtitle:
                            '${lesson.keyVocabulary.length} cards with Santali Ol Chiki and audio.',
                        buttonLabel: 'Generate Flashcards',
                        color: AppColors.navy,
                        lightColor: const Color(0xFFF1F5F9),
                        onTap: () => _openGeneratedFlashcards(context),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openGeneratedWorksheet(BuildContext context) {
    final generator = CurriculumGeneratorService();
    if (!generator.isMaterialAvailable(widget.lesson) &&
        widget.lesson.assessmentQuestions.isEmpty) {
      _showUnsupportedMaterialDialog(context, 'Worksheet');
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LessonWorksheetScreen(lesson: widget.lesson),
      ),
    );
  }

  void _openGeneratedFlashcards(BuildContext context) {
    final generator = CurriculumGeneratorService();
    if (!generator.isMaterialAvailable(widget.lesson) &&
        widget.lesson.keyVocabulary.isEmpty) {
      _showUnsupportedMaterialDialog(context, 'Flashcards');
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FlashcardScreen(
          lesson: widget.lesson,
          ttsService: _ttsService,
        ),
      ),
    );
  }

  void _showUnsupportedMaterialDialog(BuildContext context, String materialType) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFFD97706)),
            const SizedBox(width: 8),
            Text('$materialType Not Available Yet', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Localized $materialType for "${widget.lesson.topicTitleEn}" is under active pedagogical review and will be available in the next curriculum update.',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navy,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Return to Lesson'),
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
      padding: const EdgeInsets.all(16),
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
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: lightColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(emoji, style: const TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textHeadline,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
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

  Widget _buildSectionHeader({required String emoji, required String title}) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.textHeadline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScriptStepCard(TeacherScriptStep step) {
    final isPlaying = _playingStepIndex == step.stepNumber;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Step ${step.stepNumber} • ${step.phaseName}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (step.dialogueSat.isNotEmpty &&
                  step.dialogueSat != 'Translation not available yet') ...[
                const SizedBox(width: 6),
                IconButton(
                  icon: Icon(
                    isPlaying ? Icons.volume_up : Icons.play_circle_fill,
                    color: isPlaying ? AppColors.greenOk : AppColors.purple,
                    size: 24,
                  ),
                  onPressed: () => _playSantaliScriptAudio(
                    step.dialogueSat,
                    step.stepNumber,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'हिंदी: "${step.dialogueHi}"',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textHeadline,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'ᱥᱟᱱᱛᱟᱲᱤ: "${step.dialogueSat}"',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.purple,
            ),
          ),
          if (step.teacherAction.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '👉 Teacher Action: ${step.teacherAction}',
                style: const TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActivityCard(ClassroomActivityPlan act) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Activity ${act.activityNumber}: ${act.activityNameHi}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textHeadline,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '⏱ ${act.durationMinutes}m',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'ᱥᱟᱱᱛᱟᱲᱤ: ${act.activityNameSat}',
            style: const TextStyle(fontSize: 12, color: AppColors.purple),
          ),
          const Divider(height: 18, color: AppColors.line),
          Text(
            '🎯 Objective: ${act.objective}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textHeadline,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '📦 Materials: ${act.materialsNeeded}',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            '👨‍🏫 Teacher: ${act.teacherInstruction}',
            style: const TextStyle(fontSize: 12, color: AppColors.textHeadline),
          ),
          const SizedBox(height: 4),
          Text(
            '👦 Students: ${act.studentInstruction}',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildVocabularyList(List<VocabularyItem> vocab) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: vocab.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0),
            child: Row(
              children: [
                Text(item.emoji ?? '📖', style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item.termSat} (${item.transliteration})',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.purple,
                        ),
                      ),
                      Text(
                        '${item.termHi} • ${item.termEn}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuestionCard(GeneratedAssessmentQuestion q) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  q.questionEn.isNotEmpty ? q.questionEn : q.questionHi,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textHeadline,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.purpleLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  q.questionType.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: AppColors.purple,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'हिंदी: ${q.questionHi}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'ᱥᱟᱱᱛᱟᱲᱤ: ${q.questionSat}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.purple,
            ),
          ),
          if (q.learningOutcome.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '✓ Outcome: ${q.learningOutcome}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppColors.greenOk,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
