class TranslationResult {
  final String originalHindi;
  final String santaliOlChiki;
  final String transliteration;
  final String? audioPath;
  final double latencySeconds;
  final bool isOffline;
  final String source; // 'REAL_LOCAL_AI' or 'DEMO_FALLBACK'

  const TranslationResult({
    required this.originalHindi,
    required this.santaliOlChiki,
    required this.transliteration,
    this.audioPath,
    required this.latencySeconds,
    required this.isOffline,
    required this.source,
  });
}
