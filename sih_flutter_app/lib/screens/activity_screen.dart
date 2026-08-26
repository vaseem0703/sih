import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../data/curriculum_data.dart';
import '../services/tts_service.dart';

class ActivityScreen extends StatefulWidget {
  final int grade;
  final String subject;
  final int lessonIndex;
  final TtsService ttsService;
  final VoidCallback onBackToLessons;

  const ActivityScreen({
    super.key,
    required this.grade,
    required this.subject,
    required this.lessonIndex,
    required this.ttsService,
    required this.onBackToLessons,
  });

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  int? _selectedAnswerIndex;
  bool? _isCorrect;
  bool _isPlayingAudio = false;

  void _checkAnswer(int index, bool correct) {
    setState(() {
      _selectedAnswerIndex = index;
      _isCorrect = correct;
    });

    if (correct) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ सही उत्तर! गतिविधि पूरी हुई।'),
          backgroundColor: AppColors.greenOk,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _playAudio(String text) async {
    if (_isPlayingAudio) return;
    setState(() => _isPlayingAudio = true);

    await widget.ttsService.generateSantaliSpeech(
      santaliText: text,
      speaker: 'Phulmani (Female)',
    );

    await Future.delayed(const Duration(milliseconds: 2000));
    if (mounted) setState(() => _isPlayingAudio = false);
  }

  @override
  Widget build(BuildContext context) {
    final curriculumList =
        CurriculumData.curriculum[widget.grade]?[widget.subject];
    final currentLesson =
        (curriculumList != null && widget.lessonIndex < curriculumList.length)
        ? curriculumList[widget.lessonIndex]
        : const LessonContent(
            titleEn: 'Numbers 1–10',
            titleHi: 'संख्याएँ 1–10',
            titleSat: 'ᱮᱞ ᱑–᱑᱐',
          );

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Button
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_back_rounded,
                      size: 20,
                      color: AppColors.navy,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Back to Lessons',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.navy,
                      ),
                    ),
                  ],
                ),
                onPressed: widget.onBackToLessons,
              ),

              const SizedBox(height: 16),

              // Eyebrow & Title
              Text(
                'GRADE ${widget.grade} • ${widget.subject.toUpperCase()}',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                currentLesson.titleEn,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textHeadline,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${currentLesson.titleHi}\n${currentLesson.titleSat}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 20),

              // STUDENT ACTIVITY CONTAINER
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F1F8),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFE4DFEB)),
                ),
                child: Column(
                  children: [
                    // Activity Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.purpleLight,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE1D5F0)),
                      ),
                      child: const Text(
                        'विद्यार्थी गतिविधि / ᱪᱟᱛᱟᱹ ᱠᱟᱹᱢ',
                        style: TextStyle(
                          color: Color(0xFF65349F),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Audio Listen Button
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.navy,
                        side: const BorderSide(color: AppColors.line),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _playAudio(currentLesson.titleSat),
                      icon: Text(
                        _isPlayingAudio ? '🔊' : '🔈',
                        style: const TextStyle(fontSize: 16),
                      ),
                      label: const Text(
                        'सुनें / ᱟᱸᱡᱚᱢ ᱢᱮ',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Dynamic Interactive Question Content
                    if (widget.subject == 'Mathematics')
                      _buildMathContent()
                    else if (widget.subject == 'Language')
                      _buildLanguageContent()
                    else
                      _buildEvsContent(),

                    const SizedBox(height: 20),

                    // Feedback Banner
                    if (_isCorrect != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _isCorrect!
                              ? const Color(0xFFE9F5ED)
                              : const Color(0xFFFAEAEA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isCorrect!
                                ? const Color(0xFF61A578)
                                : const Color(0xFFC96B67),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _isCorrect!
                              ? '✓ सही! गतिविधि पूरी हुई।'
                              : '✕ फिर से कोशिश करें। / ᱫᱚᱦᱲᱟ ᱪᱮᱫ ᱢᱮ᱾',
                          style: TextStyle(
                            color: _isCorrect!
                                ? const Color(0xFF327448)
                                : const Color(0xFFA4433E),
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Continue Lesson Button
                    if (_isCorrect == true)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.navy,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: widget.onBackToLessons,
                        child: const Text(
                          'Continue Lesson',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMathContent() {
    return Column(
      children: [
        const Text(
          '● ● ● ●',
          style: TextStyle(
            fontSize: 48,
            letterSpacing: 14,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'कितने हैं? / ᱪᱤᱞᱠᱟ ᱢᱮ?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textHeadline,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildAnswerButton(0, '3', false),
            const SizedBox(width: 14),
            _buildAnswerButton(1, '4', true),
            const SizedBox(width: 14),
            _buildAnswerButton(2, '5', false),
          ],
        ),
      ],
    );
  }

  Widget _buildLanguageContent() {
    return Column(
      children: [
        const Text('📖', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 16),
        const Text(
          'सही शब्द चुनिए। / ᱥᱟᱹᱨᱤ ᱥᱟᱵᱫ ᱵᱟᱪᱷᱟᱣ ᱢᱮ᱾',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: AppColors.textHeadline,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildAnswerButton(0, 'घर', true),
            const SizedBox(width: 12),
            _buildAnswerButton(1, 'पेड़', false),
            const SizedBox(width: 12),
            _buildAnswerButton(2, 'पानी', false),
          ],
        ),
      ],
    );
  }

  Widget _buildEvsContent() {
    return Column(
      children: [
        const Text(
          '🌱 💧 🐄',
          style: TextStyle(fontSize: 44, letterSpacing: 8),
        ),
        const SizedBox(height: 16),
        const Text(
          'सही उत्तर चुनिए। / ᱥᱟᱹᱨᱤ ᱡᱚᱵᱟᱵ ᱵᱟᱪᱷᱟᱣ ᱢᱮ᱾',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: AppColors.textHeadline,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildAnswerButton(0, 'पौधा', true),
            const SizedBox(width: 12),
            _buildAnswerButton(1, 'जानवर', false),
            const SizedBox(width: 12),
            _buildAnswerButton(2, 'पानी', false),
          ],
        ),
      ],
    );
  }

  Widget _buildAnswerButton(int index, String label, bool isAnswerCorrect) {
    final isSelected = _selectedAnswerIndex == index;
    Color bg = Colors.white;
    Color borderCol = AppColors.line;
    Color textColor = AppColors.navy;

    if (isSelected) {
      if (_isCorrect == true) {
        bg = const Color(0xFFE9F5ED);
        borderCol = const Color(0xFF61A578);
        textColor = const Color(0xFF327448);
      } else {
        bg = const Color(0xFFFAEAEA);
        borderCol = const Color(0xFFC96B67);
        textColor = const Color(0xFFA4433E);
      }
    }

    return GestureDetector(
      onTap: () => _checkAnswer(index, isAnswerCorrect),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderCol, width: isSelected ? 2 : 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
