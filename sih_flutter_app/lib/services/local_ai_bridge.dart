import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class LocalAiBridge {
  static const List<String> _possibleUrls = [
    'http://127.0.0.1:8080',
    'http://10.0.2.2:8080',
    'http://localhost:8080',
  ];

  static String? _workingUrl;

  static String? get activeBaseUrl => _workingUrl;

  static Future<String?> getWorkingBaseUrl({bool forceRefresh = false}) async {
    if (_workingUrl != null && !forceRefresh) return _workingUrl;

    for (final url in _possibleUrls) {
      try {
        final res = await http
            .get(Uri.parse('$url/status'))
            .timeout(const Duration(seconds: 5));
        if (res.statusCode == 200) {
          _workingUrl = url;
          debugPrint('[LocalAiBridge] Connected to local AI server: $url');
          return _workingUrl;
        }
      } catch (e) {
        debugPrint('[LocalAiBridge] Server probe failed for $url: $e');
      }
    }
    return _workingUrl;
  }

  static Future<bool> checkServerStatus() async {
    final url = await getWorkingBaseUrl(forceRefresh: true);
    return url != null;
  }

  static Future<Map<String, dynamic>?> translateText(
    String text, {
    String src = 'hin_Deva',
    String tgt = 'sat_Olck',
  }) async {
    String? baseUrl = await getWorkingBaseUrl();
    if (baseUrl == null) {
      baseUrl = await getWorkingBaseUrl(forceRefresh: true);
    }
    if (baseUrl == null) {
      debugPrint(
        '[LocalAiBridge] ERROR: Local AI server unreachable on all endpoints',
      );
      return null;
    }

    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/translate'),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode({'text': text, 'src': src, 'tgt': tgt}),
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      } else {
        debugPrint('[LocalAiBridge] HTTP error ${res.statusCode}: ${res.body}');
      }
    } catch (e) {
      debugPrint('[LocalAiBridge] Translation request exception: $e');
      _workingUrl = null;
    }
    return null;
  }

  static Future<Map<String, dynamic>?> synthesizeSpeech(
    String text, {
    String speaker = 'Phulmani',
  }) async {
    final baseUrl = await getWorkingBaseUrl();
    if (baseUrl == null) return null;

    try {
      final res = await http
          .post(
            Uri.parse('$baseUrl/tts'),
            headers: {'Content-Type': 'application/json; charset=UTF-8'},
            body: jsonEncode({'text': text, 'speaker': speaker}),
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode == 200) {
        return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('[LocalAiBridge] TTS request failed: $e');
      _workingUrl = null;
    }
    return null;
  }

  static Future<Map<String, dynamic>?> generateTts(
    String text, {
    String speaker = 'Phulmani',
  }) async {
    return synthesizeSpeech(text, speaker: speaker);
  }
}
