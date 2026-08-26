import 'package:flutter/material.dart';

class AppColors {
  // Master Design Theme
  static const Color navy = Color(0xFF173B5F);
  static const Color navyDark = Color(0xFF102B48);
  static const Color purple = Color(0xFF7134B9);
  static const Color purpleLight = Color(0xFFF0EBFA);
  static const Color purpleAccent = Color(0xFF7650C7);
  static const Color gold = Color(0xFFC18A2D);
  static const Color goldLight = Color(0xFFF5EAD2);

  static const Color background = Color(0xFFFBFAFF);
  static const Color pageBackground = Color(0xFFF0EDF5);
  static const Color card = Colors.white;
  static const Color line = Color(0xFFE5E1EB);

  static const Color textPrimary = Color(0xFF182235);
  static const Color textHeadline = Color(0xFF152F4D);
  static const Color textSecondary = Color(0xFF5F6675);
  static const Color textMuted = Color(0xFF717887);

  static const Color greenOk = Color(0xFF3F9561);
  static const Color greenLight = Color(0xFFEDF7F0);
  static const Color greenDark = Color(0xFF2D6A3F);

  static const Color redError = Color(0xFFA4433E);
  static const Color redLight = Color(0xFFFAEAEA);

  // Backward compatibility aliases
  static const Color primary = navy;
  static const Color primaryLight = purpleLight;
  static const Color orange = gold;
  static const Color orangeLight = goldLight;
  static const Color blue = navy;
  static const Color blueLight = purpleLight;
  static const Color green = greenOk;
  static const Color border = line;
  static const Color surface = card;
  static const Color cardBackground = card;

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF173B5F), Color(0xFF304575), Color(0xFF7134B9)],
  );

  static const LinearGradient primaryButtonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFF173B5F), Color(0xFF7134B9)],
  );

  static const LinearGradient micButtonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF173B5F), Color(0xFF7134B9)],
  );

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: const Color(0xFF242334).withOpacity(0.055),
      blurRadius: 24,
      offset: const Offset(0, 7),
    ),
  ];

  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: const Color(0xFF242334).withOpacity(0.04),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get heroShadow => [
    BoxShadow(
      color: const Color(0xFF362A68).withOpacity(0.16),
      blurRadius: 38,
      offset: const Offset(0, 16),
    ),
  ];

  static List<BoxShadow> get micShadow => [
    BoxShadow(
      color: const Color(0xFF502D8F).withOpacity(0.22),
      blurRadius: 22,
      offset: const Offset(0, 9),
    ),
  ];
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.navy,
        primary: AppColors.navy,
        secondary: AppColors.purple,
        surface: AppColors.card,
      ),
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
    );
  }
}
