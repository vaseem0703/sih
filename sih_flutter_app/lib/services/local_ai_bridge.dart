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
            .timeout(const Duration(seconds: 4));
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
    List<String> targetUrls = [];
    if (_workingUrl != null) {
      targetUrls.add(_workingUrl!);
    }
    for (final url in _possibleUrls) {
      if (!targetUrls.contains(url)) {
        targetUrls.add(url);
      }
    }

    for (final url in targetUrls) {
      try {
        debugPrint('[LocalAiBridge] Attempting translation via $url');
        final res = await http
            .post(
              Uri.parse('$url/translate'),
              headers: {'Content-Type': 'application/json; charset=UTF-8'},
              body: jsonEncode({'text': text, 'src': src, 'tgt': tgt}),
            )
            .timeout(const Duration(seconds: 30));

        if (res.statusCode == 200) {
          _workingUrl = url;
          return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        }
      } catch (e) {
        debugPrint(
          '[LocalAiBridge] Translation request exception for $url: $e',
        );
      }
    }

    _workingUrl = null;
    debugPrint('[LocalAiBridge] ERROR: All local server endpoints failed');
    return null;
  }

  static Future<Map<String, dynamic>?> synthesizeSpeech(
    String text, {
    String speaker = 'Phulmani',
  }) async {
    List<String> targetUrls = [];
    if (_workingUrl != null) {
      targetUrls.add(_workingUrl!);
    }
    for (final url in _possibleUrls) {
      if (!targetUrls.contains(url)) {
        targetUrls.add(url);
      }
    }

    for (final url in targetUrls) {
      try {
        final res = await http
            .post(
              Uri.parse('$url/tts'),
              headers: {'Content-Type': 'application/json; charset=UTF-8'},
              body: jsonEncode({'text': text, 'speaker': speaker}),
            )
            .timeout(const Duration(seconds: 30));

        if (res.statusCode == 200) {
          _workingUrl = url;
          return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
        }
      } catch (e) {
        debugPrint('[LocalAiBridge] TTS request failed for $url: $e');
      }
    }

    _workingUrl = null;
    return null;
  }

  static Future<Map<String, dynamic>?> generateTts(
    String text, {
    String speaker = 'Phulmani',
  }) async {
    return synthesizeSpeech(text, speaker: speaker);
  }
}
