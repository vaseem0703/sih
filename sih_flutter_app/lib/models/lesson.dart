import 'package:flutter/material.dart';

class LessonItem {
  final String id;
  final String hindiText;
  final String santaliText;
  final String transliteration;
  final String? audioAsset;
  final String? iconEmoji;

  const LessonItem({
    required this.id,
    required this.hindiText,
    required this.santaliText,
    required this.transliteration,
    this.audioAsset,
    this.iconEmoji,
  });
}

class Lesson {
  final String id;
  final int number;
  final String titleHindi;
  final String titleSantali;
  final String description;
  final Color themeColor;
  final Color lightColor;
  final String iconEmoji;
  final List<LessonItem> items;

  const Lesson({
    required this.id,
    required this.number,
    required this.titleHindi,
    required this.titleSantali,
    required this.description,
    required this.themeColor,
    required this.lightColor,
    required this.iconEmoji,
    required this.items,
  });
}
