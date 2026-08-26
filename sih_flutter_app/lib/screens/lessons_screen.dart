import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../data/curriculum_data.dart';
import '../services/curriculum_generator_service.dart';
import '../services/tts_service.dart';
import 'generated_lesson_screen.dart';
import 'teaching_package_screen.dart';

class LessonsScreen extends StatefulWidget {
  final Function(int grade, String subject, int index)? onStartLesson;
  final TtsService? ttsService;

  const LessonsScreen({
    super.key,
    this.onStartLesson,
    this.ttsService,
  });

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> {
  int _selectedGrade = 2;
  String _selectedSubject = 'Mathematics';

  @override
  Widget build(BuildContext context) {
    final items =
        CurriculumData.curriculum[_selectedGrade]?[_selectedSubject] ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Eyebrow & Title
              const Text(
                'FLN LESSONS',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Choose a Lesson',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textHeadline,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Select your grade and subject. Lessons appear automatically.',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),

              const SizedBox(height: 24),

              // 1. GRADE SELECTOR
              const Text(
                'Grade',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textHeadline,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [1, 2, 3].map((g) {
                  final isSelected = _selectedGrade == g;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: g == 3 ? 0 : 10),
                      child: _buildSelectorButton(
                        label: 'Grade $g',
                        isSelected: isSelected,
                        onTap: () => setState(() => _selectedGrade = g),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),

              // 2. SUBJECT SELECTOR
              const Text(
                'Subject',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textHeadline,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: ['Mathematics', 'Language', 'EVS'].map((s) {
                  final isSelected = _selectedSubject == s;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: s == 'EVS' ? 0 : 10),
                      child: _buildSelectorButton(
                        label: s,
                        isSelected: isSelected,
                        onTap: () => setState(() => _selectedSubject = s),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 28),

              // 3. AVAILABLE LESSONS LIST
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Flexible(
                    child: Text(
                      'Available Lessons',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textHeadline,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.purpleLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'HINDI + SANTHALI',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.purple,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Lesson Cards
              Column(
                children: items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14.0),
                    child: _buildLessonCard(item, index),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectorButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.navy : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.navy : AppColors.line,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.navy.withValues(alpha: 0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.navy,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLessonCard(LessonContent item, int index) {
    String iconEmoji = '123';
    if (_selectedSubject == 'Language') iconEmoji = 'अ';
    if (_selectedSubject == 'EVS') iconEmoji = '🌱';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.purpleLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE1D5F0)),
                  ),
                  child: Text(
                    '${_selectedSubject.toUpperCase()} • GRADE $_selectedGrade',
                    style: const TextStyle(
                      color: Color(0xFF65349F),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  item.titleEn,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textHeadline,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.titleHi,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'ᱥᱟᱱᱛᱟᱲᱤ: ${item.titleSat}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 11,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        final generator = CurriculumGeneratorService();
                        final lesson = generator.generateLessonPlan(
                          grade: _selectedGrade,
                          subject: _selectedSubject,
                          topic: item,
                          targetLanguage: 'sat_Olck',
                        );
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => TeachingPackageScreen(
                              lesson: lesson,
                              ttsService: widget.ttsService ?? TtsService(),
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        'Start Lesson',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.purple,
                        side: const BorderSide(color: AppColors.purple),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 11,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        final generator = CurriculumGeneratorService();
                        final lessonPlan = generator.generateLessonPlan(
                          grade: _selectedGrade,
                          subject: _selectedSubject,
                          topic: item,
                          targetLanguage: 'sat_Olck',
                        );
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => GeneratedLessonScreen(
                              lesson: lessonPlan,
                              ttsService: widget.ttsService ?? TtsService(),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.auto_awesome, size: 14),
                      label: const Text(
                        'Generate Lesson Plan',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.purpleLight,
              borderRadius: BorderRadius.circular(17),
            ),
            child: Text(
              iconEmoji,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Color(0xFF6333A4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
