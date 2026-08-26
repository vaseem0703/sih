import 'dart:convert';
import 'dart:io';
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

  /// Sends real recorded WAV audio file to IndicConformer ASR on local AI server
  static Future<Map<String, dynamic>?> transcribeAudio(File audioFile) async {
    try {
      final uri = Uri.parse('$activeBaseUrl/asr');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('audio', audioFile.path));

      final streamedResponse = await request.send().timeout(const Duration(seconds: 25));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        return data;
      }
    } catch (_) {
      // Fallback to base64 JSON if multipart fails
      try {
        final bytes = await audioFile.readAsBytes();
        final base64Audio = base64Encode(bytes);
        final response = await http
            .post(
              Uri.parse('$activeBaseUrl/asr'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'audio_base64': base64Audio, 'format': 'wav'}),
            )
            .timeout(const Duration(seconds: 25));

        if (response.statusCode == 200) {
          return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        }
      } catch (_) {}
    }
    return null;
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
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode({'text': text, 'src': src, 'tgt': tgt}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
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
            headers: {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode({'text': santaliText, 'speaker': speaker}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }
}
