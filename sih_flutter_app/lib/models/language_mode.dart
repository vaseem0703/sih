enum AppLanguage { hindi, santali }

class LocalizationHelper {
  static String getText({
    required AppLanguage lang,
    required String hi,
    required String satOlck,
    String? satRoman,
  }) {
    if (lang == AppLanguage.santali) {
      if (satRoman != null && satRoman.isNotEmpty) {
        return '\n()';
      }
      return satOlck;
    }
    return hi;
  }

  static String getTitle({
    required AppLanguage lang,
    required String hi,
    required String sat,
  }) {
    return lang == AppLanguage.santali ? sat : hi;
  }
}
