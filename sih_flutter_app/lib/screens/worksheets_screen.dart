import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../data/curriculum_data.dart';

class WorksheetsScreen extends StatefulWidget {
  const WorksheetsScreen({super.key});

  @override
  State<WorksheetsScreen> createState() => _WorksheetsScreenState();
}

class _WorksheetsScreenState extends State<WorksheetsScreen> {
  int _selectedGrade = 2;
  String _selectedSubject = 'Mathematics';
  bool _isWorksheetGenerated = false;

  void _generateWorksheet() {
    setState(() {
      _isWorksheetGenerated = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Grade $_selectedGrade • $_selectedSubject worksheet generated',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _saveWorksheet() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Worksheet saved for offline use'),
        backgroundColor: AppColors.greenOk,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _printWorksheet() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Print preview opened'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final questions =
        CurriculumData.worksheets[_selectedGrade]?[_selectedSubject] ?? [];

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
                'TEACHER TOOL',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Worksheets',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textHeadline,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Choose a grade and subject to generate the matching Hindi + Santhali worksheet.',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),

              const SizedBox(height: 20),

              // Dropdown Selection Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 500;
                  final classDropdown = _buildDropdownField(
                    label: 'CLASS',
                    value: _selectedGrade,
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('Grade 1')),
                      DropdownMenuItem(value: 2, child: Text('Grade 2')),
                      DropdownMenuItem(value: 3, child: Text('Grade 3')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedGrade = val;
                          _isWorksheetGenerated = false;
                        });
                      }
                    },
                  );

                  final subjectDropdown = _buildDropdownField(
                    label: 'SUBJECT',
                    value: _selectedSubject,
                    items: const [
                      DropdownMenuItem(
                        value: 'Mathematics',
                        child: Text('Mathematics'),
                      ),
                      DropdownMenuItem(
                        value: 'Language',
                        child: Text('Language'),
                      ),
                      DropdownMenuItem(value: 'EVS', child: Text('EVS')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedSubject = val;
                          _isWorksheetGenerated = false;
                        });
                      }
                    },
                  );

                  if (isWide) {
                    return Row(
                      children: [
                        Expanded(child: classDropdown),
                        const SizedBox(width: 14),
                        Expanded(child: subjectDropdown),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        classDropdown,
                        const SizedBox(height: 12),
                        subjectDropdown,
                      ],
                    );
                  }
                },
              ),

              const SizedBox(height: 16),

              // Generation Summary Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.line),
                  boxShadow: AppColors.cardShadow,
                ),
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
                      child: const Text(
                        'HINDI + SANTHALI',
                        style: TextStyle(
                          color: Color(0xFF65349F),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Grade $_selectedGrade • $_selectedSubject',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textHeadline,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${questions.length} curriculum-based questions ready.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _generateWorksheet,
                      child: const Text(
                        'Generate Worksheet',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // GENERATED WORKSHEET PREVIEW
              if (_isWorksheetGenerated) ...[
                const SizedBox(height: 28),
                const Text(
                  'Generated Worksheet',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textHeadline,
                  ),
                ),
                const SizedBox(height: 12),

                Container(
                  width: double.infinity,
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
                      // Top navy border strip
                      Container(
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 18),
                        decoration: BoxDecoration(
                          color: AppColors.navy,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),

                      // Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Grade $_selectedGrade • $_selectedSubject',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textHeadline,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'नाम / ᱧᱩᱛ: ____________________     दिनांक / ᱫᱤᱱ: __________',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
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

                      const Divider(height: 32, color: AppColors.line),

                      // Questions List
                      Column(
                        children: questions.asMap().entries.map((entry) {
                          final i = entry.key;
                          final q = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${i + 1}. ${q.instructionHi}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textHeadline,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  q.instructionSat,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                if (q.prompt.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    q.prompt,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.navy,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                const Text(
                                  'उत्तर / ᱡᱚᱵᱟᱵ: __________________',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                if (i < questions.length - 1)
                                  const Divider(
                                    height: 24,
                                    color: AppColors.line,
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Save & Print Actions
                Row(
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 13,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _saveWorksheet,
                      child: const Text(
                        'Save Worksheet',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.navy,
                        side: const BorderSide(color: AppColors.line),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 13,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _printWorksheet,
                      child: const Text(
                        'Print',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: AppColors.line),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              items: items,
              onChanged: onChanged,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
