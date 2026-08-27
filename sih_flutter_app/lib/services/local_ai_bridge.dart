import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class LocalAiBridge {
  static String? _workingUrl;
  static String get activeBaseUrl => _workingUrl ?? 'http://127.0.0.1:8080';
  static final List<String> candidateUrls = [
    'http://127.0.0.1:8080',
    'http://10.0.2.2:8080',
    'http://localhost:8080',
  ];

  static Future<String?> getWorkingBaseUrl({bool forceRefresh = false}) async {
    if (_workingUrl != null && !forceRefresh) {
      return _workingUrl;
    }
    for (final url in candidateUrls) {
      try {
        final response = await http
            .get(Uri.parse('$url/status'))
            .timeout(const Duration(milliseconds: 3000));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['status'] == 'online') {
            _workingUrl = url;
            return url;
          }
        }
      } catch (_) {}
    }
    return _workingUrl;
  }

  static Future<bool> checkServerStatus() async {
    final url = await getWorkingBaseUrl(forceRefresh: true);
    return url != null;
  }

  /// Sends real recorded WAV audio file to IndicConformer ASR on local AI server
  static Future<Map<String, dynamic>?> transcribeAudio(File audioFile) async {
    final baseUrl = await getWorkingBaseUrl();
    if (baseUrl == null) return null;

    try {
      final uri = Uri.parse('$baseUrl/asr');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(
        await http.MultipartFile.fromPath('audio', audioFile.path),
      );

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 15),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes))
            as Map<String, dynamic>;
      }
    } catch (_) {
      _workingUrl = null;
    }
    return null;
  }

  static Future<Map<String, dynamic>?> translateText(
    String text, {
    String src = 'hin_Deva',
    String tgt = 'sat_Olck',
  }) async {
    final baseUrl = await getWorkingBaseUrl();
    if (baseUrl == null) return null;

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/translate'),
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode({'text': text, 'src': src, 'tgt': tgt}),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes))
            as Map<String, dynamic>;
      }
    } catch (_) {
      _workingUrl = null;
    }
    return null;
  }

  static Future<Map<String, dynamic>?> generateTts(
    String santaliText, {
    String speaker = 'Phulmani',
  }) async {
    final baseUrl = await getWorkingBaseUrl();
    if (baseUrl == null) return null;

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/tts'),
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode({'text': santaliText, 'speaker': speaker}),
          )
          .timeout(const Duration(seconds: 35));

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes))
            as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }
}
