import 'dart:convert';
import 'package:http/http.dart' as http;

class LocalAiBridge {
  static String activeBaseUrl = 'http://127.0.0.1:8080';
  static final List<String> candidateUrls = [
    'http://127.0.0.1:8080',
    'http://10.0.2.2:8080',
  ];

  static Future<bool> checkServerStatus() async {
    for (final url in candidateUrls) {
      try {
        final response = await http
            .get(Uri.parse('$url/status'))
            .timeout(const Duration(milliseconds: 1200));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['status'] == 'online') {
            activeBaseUrl = url;
            return true;
          }
        }
      } catch (_) {}
    }
    return false;
  }

  static Future<Map<String, dynamic>?> translateText(
    String text, {
    String src = 'hin_Deva',
    String tgt = 'sat_Olck',
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$activeBaseUrl/translate'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'text': text, 'src': src, 'tgt': tgt}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>?> generateTts(
    String santaliText, {
    String speaker = 'Phulmani',
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$activeBaseUrl/tts'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'text': santaliText, 'speaker': speaker}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }
}
