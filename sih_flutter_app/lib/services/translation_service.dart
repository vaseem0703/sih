import 'package:flutter/foundation.dart';
import '../models/translation_result.dart';
import 'local_ai_bridge.dart';

class TranslationService {
  Future<TranslationResult> translateBidirectional({
    required String text,
    required String srcLangCode,
    required String tgtLangCode,
  }) async {
    final stopwatch = Stopwatch()..start();
    final cleanInput = text.trim();

    debugPrint('==================================================');
    debugPrint('[TRANSLATION DEBUG]');
    debugPrint('MODEL: ai4bharat/indictrans2-indic-indic-dist-320M');
    debugPrint('SOURCE: $srcLangCode | TARGET: $tgtLangCode');
    debugPrint('INPUT: "$cleanInput"');

    // Always enforce Hindi Devanagari as source for speech ASR inputs if input contains Devanagari
    final effectiveSrc = (srcLangCode == tgtLangCode || srcLangCode == 'sat_Olck')
        ? 'hin_Deva'
        : srcLangCode;

    // 1. Direct call to LocalAiBridge.translateText (with automatic connection retry)
    final res = await LocalAiBridge.translateText(
      cleanInput,
      src: effectiveSrc,
      tgt: tgtLangCode,
    );

    if (res != null && res['translation'] != null) {
      stopwatch.stop();
      final outText = res['translation'].toString().trim();
      debugPrint('OUTPUT SANTALI (IndicTrans2): "$outText"');
      debugPrint('LATENCY: ${stopwatch.elapsedMilliseconds / 1000.0}s');
      debugPrint('==================================================');

      return TranslationResult(
        originalHindi: cleanInput,
        santaliOlChiki: outText,
        transliteration: res['transliteration'] ?? 'Santali (Ol Chiki)',
        latencySeconds: stopwatch.elapsedMilliseconds / 1000.0,
        isOffline: true,
        source: 'REAL_LOCAL_AI (IndicTrans2)',
      );
    }

    stopwatch.stop();
    debugPrint('OUTPUT: Translation unavailable (Local AI Server Unreachable)');
    debugPrint('==================================================');

    return TranslationResult(
      originalHindi: cleanInput,
      santaliOlChiki: 'Translation unavailable',
      transliteration: 'IndicTrans2 Offline (Ensure local_ai_server.py is running)',
      latencySeconds: stopwatch.elapsedMilliseconds / 1000.0,
      isOffline: true,
      source: 'TRANSLATION_FAILURE',
    );
  }

  Future<TranslationResult> translateHindiToTarget({
    required String hindiText,
    String targetLangCode = 'sat_Olck',
  }) {
    return translateBidirectional(
      text: hindiText,
      srcLangCode: 'hin_Deva',
      tgtLangCode: targetLangCode,
    );
  }

  Future<TranslationResult> translateHindiToSantali(String hindiText) {
    return translateHindiToTarget(
      hindiText: hindiText,
      targetLangCode: 'sat_Olck',
    );
  }
}
