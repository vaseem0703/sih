import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';

class SettingsService {
  static const String _keyLanguage = 'pref_language';
  static const String _keyVoice = 'pref_voice';
  static const String _keyVolume = 'pref_volume';

  Future<AppSettings> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lang = prefs.getString(_keyLanguage) ?? 'Hindi ↔ Santali';
      final voice = prefs.getString(_keyVoice) ?? 'Phulmani (Female)';
      final vol = prefs.getDouble(_keyVolume) ?? 0.8;
      return AppSettings(
        languageMode: lang,
        ttsSpeaker: voice,
        volume: vol,
        isOfflineReady: true,
        modelBackendStatus: 'Local Offline Ready',
      );
    } catch (_) {
      return const AppSettings();
    }
  }

  Future<void> saveSettings(AppSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLanguage, settings.languageMode);
      await prefs.setString(_keyVoice, settings.ttsSpeaker);
      await prefs.setDouble(_keyVolume, settings.volume);
    } catch (_) {}
  }
}
