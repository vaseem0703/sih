import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../services/curriculum_generator_service.dart';

class LessonWorksheetScreen extends StatefulWidget {
  final GeneratedCurriculumLesson lesson;

  const LessonWorksheetScreen({super.key, required this.lesson});

  @override
  State<LessonWorksheetScreen> createState() => _LessonWorksheetScreenState();
}

class _LessonWorksheetScreenState extends State<LessonWorksheetScreen> {
  final TextEditingController _studentNameController = TextEditingController();
  final TextEditingController _rollNoController = TextEditingController();
  bool _isSaved = false;

  @override
  void dispose() {
    _studentNameController.dispose();
    _rollNoController.dispose();
    super.dispose();
  }

  void _saveWorksheet() {
    setState(() => _isSaved = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ Worksheet saved offline for classroom printing'),
        backgroundColor: AppColors.greenOk,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showPrintPreview() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.print, color: AppColors.navy),
            SizedBox(width: 8),
            Text('Print / Share Preview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Bilingual FLN Worksheet for "${widget.lesson.topicTitleEn}" is ready to print or export as PDF for primary school distribution.',
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.navy,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Print job sent to local printer.')),
              );
            },
            child: const Text('Print Now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.navy),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Bilingual Worksheet (ᱠᱟᱹᱢᱤ ᱥᱟᱠᱟᱢ)',
          style: TextStyle(
            color: AppColors.textHeadline,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined, color: AppColors.navy),
            tooltip: 'Print Preview',
            onPressed: _showPrintPreview,
          ),
          IconButton(
            icon: Icon(
              _isSaved ? Icons.bookmark : Icons.bookmark_border,
              color: _isSaved ? AppColors.greenOk : AppColors.navy,
            ),
            tooltip: 'Save Offline',
            onPressed: _saveWorksheet,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Printable Sheet Canvas Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.line),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // School Header
                      Center(
                        child: Column(
                          children: [
                            const Text(
                              'झारखंड प्राथमिक विद्यालय • FLN WORK SHEET',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.navy,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'ᱥᱟᱱᱛᱟᱲᱤ ᱟᱨ ᱦᱤᱱᱫᱤ ᱢᱮᱥᱟ ᱠᱟᱹᱢᱤ ᱥᱟᱠᱟᱢ',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.purple,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Grade ${lesson.grade} • ${lesson.subject} • ${lesson.topicTitleEn}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textHeadline,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: AppColors.line),
                      const SizedBox(height: 12),

                      // Student Info Fields
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: _studentNameController,
                              decoration: const InputDecoration(
                                labelText: 'Student Name / ᱯᱟᱹᱴᱷᱩᱣᱟᱹ ᱧᱩᱛᱩᱢ',
                                isDense: true,
                                border: UnderlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            flex: 1,
                            child: TextField(
                              controller: _rollNoController,
                              decoration: const InputDecoration(
                                labelText: 'Roll No',
                                isDense: true,
                                border: UnderlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Learning Outcome Indicator
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Row(
                          children: [
                            const Text('🎯', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${lesson.competencyId}: ${lesson.learningOutcomeHi}',
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
                      const SizedBox(height: 24),

                      // Section A: Vocabulary / Number Match
                      const Text(
                        'Section A: Vocabulary & Symbol Matching (ᱥᱟᱵᱫ ᱢᱮᱞᱟᱣ)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textHeadline,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...lesson.keyVocabulary.take(4).map(
                        (v) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              Text(v.emoji ?? '▪', style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${v.termHi} (${v.termSat})',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('____________', style: TextStyle(color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                      const Divider(color: AppColors.line),
                      const SizedBox(height: 16),

                      // Section B: Questions
                      const Text(
                        'Section B: Questions & Practice (ᱠᱩᱠᱞᱤ ᱠᱚ)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textHeadline,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...lesson.assessmentQuestions.asMap().entries.map((e) {
                        final i = e.key;
                        final q = e.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.line),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${i + 1}. ${q.questionHi}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                '   ${q.questionSat}',
                                style: const TextStyle(fontSize: 12, color: AppColors.purple, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 12,
                                children: q.optionsHi.map((opt) => Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.radio_button_unchecked, size: 14, color: AppColors.textMuted),
                                    const SizedBox(width: 4),
                                    Text(opt, style: const TextStyle(fontSize: 12)),
                                  ],
                                )).toList(),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Bottom Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppColors.navy),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _saveWorksheet,
                        icon: const Icon(Icons.save_alt, size: 18),
                        label: const Text('Save Offline'),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.navy,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _showPrintPreview,
                        icon: const Icon(Icons.print, size: 18),
                        label: const Text('Print Preview'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.purple,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.menu_book, size: 16),
                    label: const Text(
                      'View Lesson (Return to Lesson Plan)',
                      style: TextStyle(fontWeight: FontWeight.bold),
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
}
