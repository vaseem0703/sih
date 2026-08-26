import 'package:flutter/material.dart';
import '../models/language_mode.dart';

class LanguageSelectorWidget extends StatelessWidget {
  final AppLanguage currentLanguage;
  final ValueChanged<AppLanguage> onLanguageChanged;

  const LanguageSelectorWidget({
    super.key,
    required this.currentLanguage,
    required this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPill(
            lang: AppLanguage.hindi,
            label: 'हिंदी (Hindi)',
            isSelected: currentLanguage == AppLanguage.hindi,
          ),
          const SizedBox(width: 4),
          _buildPill(
            lang: AppLanguage.santali,
            label: 'ᱥᱟᱱᱛᱟᱲᱤ (Santali)',
            isSelected: currentLanguage == AppLanguage.santali,
          ),
        ],
      ),
    );
  }

  Widget _buildPill({
    required AppLanguage lang,
    required String label,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => onLanguageChanged(lang),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE65100) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF475569),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
