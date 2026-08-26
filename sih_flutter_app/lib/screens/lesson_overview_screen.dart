import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../data/curriculum_data.dart';
import '../services/curriculum_generator_service.dart';
import '../services/tts_service.dart';
import 'teaching_package_screen.dart';

class LessonOverviewScreen extends StatelessWidget {
  final int grade;
  final String subject;
  final LessonContent topic;
  final TtsService ttsService;

  const LessonOverviewScreen({
    super.key,
    required this.grade,
    required this.subject,
    required this.topic,
    required this.ttsService,
  });

  @override
  Widget build(BuildContext context) {
    final generator = CurriculumGeneratorService();
    final lesson = generator.generateLessonPlan(
      grade: grade,
      subject: subject,
      topic: topic,
    );

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
          topic.titleEn,
          style: const TextStyle(
            color: AppColors.textHeadline,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.greenOk.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.greenOk.withValues(alpha: 0.3),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, size: 13, color: AppColors.greenOk),
                SizedBox(width: 4),
                Text(
                  'Offline Ready',
                  style: TextStyle(
                    color: AppColors.greenOk,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ],
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
                // Badge & Subtitle
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.purpleLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'GRADE $grade • ${subject.toUpperCase()}',
                        style: const TextStyle(
                          color: AppColors.purple,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        lesson.competencyId,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Title in English, Hindi & Santali
                Text(
                  lesson.topicTitleEn,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textHeadline,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${lesson.topicTitleHi} • ᱥᱟᱱᱛᱟᱲᱤ: ${lesson.topicTitleSat}',
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 24),

                // 🎯 LEARNING OUTCOME BOX
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD97706).withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Text('🎯', style: TextStyle(fontSize: 22)),
                          SizedBox(width: 8),
                          Text(
                            'Learning Outcome (अधिगम प्रतिफल)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF92400E),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        lesson.learningOutcomeEn,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF78350F),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        lesson.learningOutcomeHi,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF92400E),
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // LESSON METRICS & INFO GRID
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoItem(
                        icon: Icons.timer_outlined,
                        label: 'Duration',
                        value: '${lesson.estimatedDurationMinutes} mins',
                      ),
                      _buildDivider(),
                      _buildInfoItem(
                        icon: Icons.menu_book_outlined,
                        label: 'Subject',
                        value: subject,
                      ),
                      _buildDivider(),
                      _buildInfoItem(
                        icon: Icons.translate,
                        label: 'Language',
                        value: 'Hindi + Santali',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'Curriculum Teaching Package',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textHeadline,
                  ),
                ),
                const SizedBox(height: 12),

                // 3 Content Section Cards
                _buildSectionPreviewCard(
                  emoji: '📖',
                  title: 'Bilingual Lesson Script',
                  subtitle:
                      'Teacher dialogue and step-by-step guidance in Hindi & Santali Ol Chiki.',
                  itemsCount: '${lesson.teacherScript.length} Phases',
                ),
                const SizedBox(height: 10),
                _buildSectionPreviewCard(
                  emoji: '🎲',
                  title: 'Classroom Activities',
                  subtitle:
                      'Culturally grounded hands-on tribal classroom activities & games.',
                  itemsCount: '${lesson.activities.length} Activities',
                ),
                const SizedBox(height: 10),
                _buildSectionPreviewCard(
                  emoji: '❓',
                  title: 'Formative Assessment',
                  subtitle:
                      'Outcome-aligned questions to check student mastery.',
                  itemsCount: '${lesson.assessmentQuestions.length} Questions',
                ),

                const SizedBox(height: 32),

                // PRIMARY CTA: Prepare Lesson
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      foregroundColor: Colors.white,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => TeachingPackageScreen(
                            lesson: lesson,
                            ttsService: ttsService,
                          ),
                        ),
                      );
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Prepare Lesson',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 22, color: AppColors.navy),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textHeadline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(height: 36, width: 1, color: AppColors.line);
  }

  Widget _buildSectionPreviewCard({
    required String emoji,
    required String title,
    required String subtitle,
    required String itemsCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.purpleLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textHeadline,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              itemsCount,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
