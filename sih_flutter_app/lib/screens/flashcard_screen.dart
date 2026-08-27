import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../services/curriculum_generator_service.dart';
import '../services/tts_service.dart';

class FlashcardScreen extends StatefulWidget {
  final GeneratedCurriculumLesson lesson;
  final TtsService ttsService;

  const FlashcardScreen({
    super.key,
    required this.lesson,
    required this.ttsService,
  });

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.88);
  int _currentPage = 0;
  bool _isPlayingAudio = false;

  void _playAudio(VocabularyItem item) async {
    if (_isPlayingAudio) return;
    setState(() => _isPlayingAudio = true);

    if (item.audioAsset != null && item.audioAsset!.isNotEmpty) {
      await widget.ttsService.playAudio(item.audioAsset!);
    } else {
      await widget.ttsService.generateSantaliSpeech(
        santaliText: item.termSat,
        speaker: 'Phulmani (Female)',
      );
    }

    await Future.delayed(const Duration(milliseconds: 1600));
    if (mounted) setState(() => _isPlayingAudio = false);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vocabList = widget.lesson.keyVocabulary;

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
          'Visual Flashcards (ᱪᱤᱛᱟᱹᱨ ᱠᱟᱨᱰ)',
          style: TextStyle(
            color: AppColors.textHeadline,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.purpleLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                '${_currentPage + 1} / ${vocabList.length}',
                style: const TextStyle(
                  color: AppColors.purple,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                'Swipe left or right to study key terms in Hindi and Santali.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),

            // Flashcards PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: vocabList.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final item = vocabList[index];
                  return _buildFlashcard(item, index == _currentPage);
                },
              ),
            ),

            const SizedBox(height: 16),

            // Navigation Controls
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 12.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton.filledTonal(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _currentPage > 0
                        ? () => _pageController.previousPage(
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
                        width: _currentPage == i ? 18 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: _currentPage == i
                              ? AppColors.navy
                              : AppColors.line,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  IconButton.filledTonal(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _currentPage < vocabList.length - 1
                        ? () => _pageController.nextPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                          )
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.purple,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.menu_book, size: 16),
              label: const Text(
                'View Lesson (Return to Lesson Plan)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildFlashcard(VocabularyItem item, bool isCurrent) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isCurrent ? AppColors.navy : AppColors.line,
          width: isCurrent ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isCurrent ? 0.08 : 0.04),
            blurRadius: isCurrent ? 16 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Emoji / Visual Asset
            Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                color: AppColors.purpleLight,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                item.emoji ?? '📖',
                style: const TextStyle(fontSize: 42),
              ),
            ),
            const SizedBox(height: 18),

            // Santali Ol Chiki Term
            Text(
              item.termSat,
              style: const TextStyle(
                fontSize: 28,
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
                fontSize: 15,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 12),

            const Divider(height: 16, thickness: 1, color: AppColors.line),

            // Hindi Meaning
            Text(
              item.termHi,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textHeadline,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),

            // English Subtitle
            Text(
              item.termEn,
              style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),

            const SizedBox(height: 16),

            // Audio Pronunciation Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _isPlayingAudio
                    ? AppColors.greenOk
                    : AppColors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () => _playAudio(item),
              icon: Icon(
                _isPlayingAudio ? Icons.volume_up : Icons.play_arrow,
                size: 18,
              ),
              label: Text(
                _isPlayingAudio ? 'Playing...' : 'Pronounce (ᱨᱚᱲ ᱟᱸᱡᱚᱢ)',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
