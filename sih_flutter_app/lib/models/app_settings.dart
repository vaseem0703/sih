class AppSettings {
  final String languageMode; // 'Hindi ↔ Santali'
  final String ttsSpeaker; // 'Phulmani (Female)' or 'Sido (Male)'
  final double volume; // 0.0 to 1.0
  final bool isOfflineReady;
  final String modelBackendStatus;

  const AppSettings({
    this.languageMode = 'Hindi ↔ Santali',
    this.ttsSpeaker = 'Phulmani (Female)',
    this.volume = 0.8,
    this.isOfflineReady = true,
    this.modelBackendStatus = 'Local Offline Ready',
  });

  AppSettings copyWith({
    String? languageMode,
    String? ttsSpeaker,
    double? volume,
    bool? isOfflineReady,
    String? modelBackendStatus,
  }) {
    return AppSettings(
      languageMode: languageMode ?? this.languageMode,
      ttsSpeaker: ttsSpeaker ?? this.ttsSpeaker,
      volume: volume ?? this.volume,
      isOfflineReady: isOfflineReady ?? this.isOfflineReady,
      modelBackendStatus: modelBackendStatus ?? this.modelBackendStatus,
    );
  }
}
