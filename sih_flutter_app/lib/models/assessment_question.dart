import 'language_mode.dart';

class AssessmentQuestion {
  final String id;
  final String questionHi;
  final String questionSat;
  final String questionSatRoman;
  final List<String> optionsHi;
  final List<String> optionsSat;
  final int correctOptionIndex;
  final String explanationHi;
  final String explanationSat;
  final String hazardDomain;

  const AssessmentQuestion({
    required this.id,
    required this.questionHi,
    required this.questionSat,
    required this.questionSatRoman,
    required this.optionsHi,
    required this.optionsSat,
    required this.correctOptionIndex,
    required this.explanationHi,
    required this.explanationSat,
    required this.hazardDomain,
  });

  String getQuestion(AppLanguage lang) =>
      lang == AppLanguage.santali ? '\n()' : questionHi;

  List<String> getOptions(AppLanguage lang) =>
      lang == AppLanguage.santali ? optionsSat : optionsHi;

  String getExplanation(AppLanguage lang) =>
      lang == AppLanguage.santali ? explanationSat : explanationHi;
}
