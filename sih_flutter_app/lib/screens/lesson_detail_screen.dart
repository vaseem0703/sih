import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../models/lesson.dart';
import '../services/lesson_service.dart';
import '../widgets/audio_button.dart';

class LessonDetailScreen extends StatefulWidget {
  final Lesson lesson;
  final LessonService lessonService;
  final ValueChanged<Lesson> onNavigateLesson;

  const LessonDetailScreen({
    super.key,
    required this.lesson,
    required this.lessonService,
    required this.onNavigateLesson,
  });

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  late Lesson _currentLesson;

  @override
  void initState() {
    super.initState();
    _currentLesson = widget.lesson;
  }

  @override
  void didUpdateWidget(covariant LessonDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lesson.id != widget.lesson.id) {
      setState(() {
        _currentLesson = widget.lesson;
      });
    }
  }

  void _navigateToPrevious() {
    final allLessons = widget.lessonService.getAllLessons();
    final currentIndex = allLessons.indexWhere(
      (l) => l.id == _currentLesson.id,
    );
    if (currentIndex > 0) {
      final prev = allLessons[currentIndex - 1];
      setState(() => _currentLesson = prev);
      widget.onNavigateLesson(prev);
    }
  }

  void _navigateToNext() {
    final allLessons = widget.lessonService.getAllLessons();
    final currentIndex = allLessons.indexWhere(
      (l) => l.id == _currentLesson.id,
    );
    if (currentIndex >= 0 && currentIndex < allLessons.length - 1) {
      final next = allLessons[currentIndex + 1];
      setState(() => _currentLesson = next);
      widget.onNavigateLesson(next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allLessons = widget.lessonService.getAllLessons();
    final currentIndex = allLessons.indexWhere(
      (l) => l.id == _currentLesson.id,
    );
    final hasPrev = currentIndex > 0;
    final hasNext = currentIndex < allLessons.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(_currentLesson.titleHindi), elevation: 0),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: _currentLesson.lightColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: _currentLesson.themeColor.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _currentLesson.iconEmoji,
                            style: const TextStyle(fontSize: 48),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _currentLesson.titleHindi,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: _currentLesson.themeColor,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _currentLesson.titleSantali,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _currentLesson.description,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    const Text(
                      'Vocabulary List',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Vocabulary Items List
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _currentLesson.items.length,
                      itemBuilder: (context, index) {
                        final item = _currentLesson.items[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border),
                            boxShadow: AppColors.softShadow,
                          ),
                          child: Row(
                            children: [
                              if (item.iconEmoji != null) ...[
                                Text(
                                  item.iconEmoji!,
                                  style: const TextStyle(fontSize: 28),
                                ),
                                const SizedBox(width: 14),
                              ],
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.hindiText,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.santaliText,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: _currentLesson.themeColor,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      item.transliteration,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              AudioButton(
                                audioAsset: item.audioAsset,
                                color: _currentLesson.themeColor,
                                label: 'Listen',
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Previous / Next Controls
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: hasPrev ? _navigateToPrevious : null,
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Previous'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _currentLesson.themeColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.border,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                  ),
                  Text(
                    '${currentIndex + 1} of ${allLessons.length}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: hasNext ? _navigateToNext : null,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text('Next'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _currentLesson.themeColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.border,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
