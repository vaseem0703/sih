import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import '../models/classroom_session.dart';
import 'translation_service.dart';

class OfflineClassroomService {
  static final OfflineClassroomService _instance =
      OfflineClassroomService._internal();
  factory OfflineClassroomService() => _instance;
  OfflineClassroomService._internal();

  final TranslationService _translationService = TranslationService();

  HttpServer? _server;
  WebSocket? _clientSocket;
  final List<WebSocket> _connectedClients = [];

  ClassroomRole? _currentRole;
  String _roomCode = '';
  String _hostIp = '127.0.0.1';
  int _connectedStudentCount = 0;

  // Stream Controllers for UI
  final _broadcastStream = StreamController<ClassroomBroadcast>.broadcast();
  final _raiseHandStream = StreamController<Map<String, dynamic>>.broadcast();
  final _studentQueryStream = StreamController<StudentQuery>.broadcast();
  final _speakingPermissionStream = StreamController<bool>.broadcast();
  final _statusStream = StreamController<String>.broadcast();
  final _studentCountStream = StreamController<int>.broadcast();

  Stream<ClassroomBroadcast> get onBroadcast => _broadcastStream.stream;
  Stream<Map<String, dynamic>> get onRaiseHand => _raiseHandStream.stream;
  Stream<StudentQuery> get onStudentQuery => _studentQueryStream.stream;
  Stream<bool> get onSpeakingPermission => _speakingPermissionStream.stream;
  Stream<String> get onStatus => _statusStream.stream;
  Stream<int> get onStudentCount => _studentCountStream.stream;

  String get roomCode => _roomCode;
  String get hostIp => _hostIp;
  ClassroomRole? get currentRole => _currentRole;
  int get connectedStudentCount => _connectedStudentCount;

  // ==========================================
  // 1. TEACHER: CREATE CLASSROOM (SERVER)
  // ==========================================
  Future<String> createClassroom() async {
    await leaveClassroom();
    _currentRole = ClassroomRole.teacher;

    // Generate random 4-digit room code
    _roomCode = (1000 + Random().nextInt(9000)).toString();

    // Determine local network IP
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback) {
            _hostIp = addr.address;
            break;
          }
        }
      }
    } catch (_) {
      _hostIp = '127.0.0.1';
    }

    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, 8888);
      _server!.listen(_handleIncomingConnection);
      _statusStream.add('Classroom Live (Code: $_roomCode)');
      return _roomCode;
    } catch (e) {
      _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8888);
      _server!.listen(_handleIncomingConnection);
      _statusStream.add('Classroom Live on Localhost (Code: $_roomCode)');
      return _roomCode;
    }
  }

  void _handleIncomingConnection(HttpRequest request) {
    if (WebSocketTransformer.isUpgradeRequest(request)) {
      WebSocketTransformer.upgrade(request).then((WebSocket socket) {
        _connectedClients.add(socket);
        _connectedStudentCount = _connectedClients.length;
        _studentCountStream.add(_connectedStudentCount);

        socket.listen(
          (message) {
            _handleTeacherReceivedMessage(message, socket);
          },
          onDone: () {
            _connectedClients.remove(socket);
            _connectedStudentCount = _connectedClients.length;
            _studentCountStream.add(_connectedStudentCount);
          },
          onError: (_) {
            _connectedClients.remove(socket);
            _connectedStudentCount = _connectedClients.length;
            _studentCountStream.add(_connectedStudentCount);
          },
        );
      });
    }
  }

  void _handleTeacherReceivedMessage(dynamic rawMsg, WebSocket sender) async {
    try {
      final data = jsonDecode(rawMsg.toString()) as Map<String, dynamic>;
      final type = data['type'];

      if (type == 'RAISE_HAND') {
        _raiseHandStream.add(data);
      } else if (type == 'STUDENT_QUERY') {
        final queryText = data['text'] ?? '';
        final studentLang = data['lang'] ?? 'sat_Olck';
        final studentName = data['name'] ?? 'Student';

        // Translate student's mother-tongue question to Hindi for Teacher
        final translation = await _translationService.translateBidirectional(
          text: queryText,
          srcLangCode: studentLang,
          tgtLangCode: 'hin_Deva',
        );

        final query = StudentQuery(
          studentName: studentName,
          studentLang: studentLang,
          originalQuery: queryText,
          translatedHindi: translation.santaliOlChiki,
          timestamp: DateTime.now(),
        );

        _studentQueryStream.add(query);

        // Also broadcast the query to all students
        broadcastTeacherSpeech(
          originalHindi: "${studentName}: $queryText",
          senderName: studentName,
          senderRole: ClassroomRole.student,
        );
      }
    } catch (_) {}
  }

  // Teacher broadcasts Hindi speech ➔ translates to all tribal languages
  Future<ClassroomBroadcast> broadcastTeacherSpeech({
    required String originalHindi,
    String senderName = 'Teacher',
    ClassroomRole senderRole = ClassroomRole.teacher,
  }) async {
    // Translate in parallel to Santali, Ho, and Mundari
    final satRes = await _translationService.translateBidirectional(
      text: originalHindi,
      srcLangCode: 'hin_Deva',
      tgtLangCode: 'sat_Olck',
    );

    final hoRes = await _translationService.translateBidirectional(
      text: originalHindi,
      srcLangCode: 'hin_Deva',
      tgtLangCode: 'hoc_Wara',
    );

    final munRes = await _translationService.translateBidirectional(
      text: originalHindi,
      srcLangCode: 'hin_Deva',
      tgtLangCode: 'unr_Mund',
    );

    final broadcast = ClassroomBroadcast(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderName: senderName,
      senderRole: senderRole,
      originalText: originalHindi,
      sourceLangCode: 'hin_Deva',
      translations: {
        'sat_Olck': satRes.santaliOlChiki,
        'hoc_Wara': hoRes.santaliOlChiki,
        'unr_Mund': munRes.santaliOlChiki,
        'hin_Deva': originalHindi,
      },
      transliterations: {
        'sat_Olck': satRes.transliteration,
        'hoc_Wara': hoRes.transliteration,
        'unr_Mund': munRes.transliteration,
        'hin_Deva': 'Hindi (Devanagari)',
      },
      timestamp: DateTime.now(),
    );

    // Send payload to all connected student sockets
    final payload = jsonEncode({
      'type': 'CLASS_BROADCAST',
      'payload': broadcast.toJson(),
    });

    for (final client in List<WebSocket>.from(_connectedClients)) {
      try {
        client.add(payload);
      } catch (_) {}
    }

    _broadcastStream.add(broadcast);
    return broadcast;
  }

  void allowStudentToSpeak(String studentName) {
    final payload = jsonEncode({
      'type': 'ALLOW_SPEAK',
      'studentName': studentName,
    });

    for (final client in List<WebSocket>.from(_connectedClients)) {
      try {
        client.add(payload);
      } catch (_) {}
    }
  }

  // ==========================================
  // 2. STUDENT: JOIN CLASSROOM (CLIENT)
  // ==========================================
  Future<bool> joinClassroom({
    required String roomCode,
    String hostAddress = '127.0.0.1',
    String studentName = 'Student',
    String preferredLanguage = 'sat_Olck',
  }) async {
    await leaveClassroom();
    _currentRole = ClassroomRole.student;
    _roomCode = roomCode;

    final candidateHosts = [hostAddress, '127.0.0.1', '10.0.2.2'];

    for (final host in candidateHosts) {
      try {
        final uri = Uri.parse('ws://$host:8888');
        _clientSocket = await WebSocket.connect(
          uri.toString(),
        ).timeout(const Duration(seconds: 3));

        _clientSocket!.listen(
          (message) {
            _handleStudentReceivedMessage(message);
          },
          onDone: () => _statusStream.add('Disconnected from class'),
          onError: (_) => _statusStream.add('Connection error'),
        );

        // Send JOIN registration
        _clientSocket!.add(
          jsonEncode({
            'type': 'JOIN',
            'roomCode': roomCode,
            'name': studentName,
            'lang': preferredLanguage,
          }),
        );

        _statusStream.add('Joined Class (Room: $roomCode)');
        return true;
      } catch (_) {}
    }

    _statusStream.add('Could not find host on local network');
    return false;
  }

  void _handleStudentReceivedMessage(dynamic rawMsg) {
    try {
      final data = jsonDecode(rawMsg.toString()) as Map<String, dynamic>;
      final type = data['type'];

      if (type == 'CLASS_BROADCAST') {
        final bcastJson = data['payload'] as Map<String, dynamic>;
        final bcast = ClassroomBroadcast.fromJson(bcastJson);
        _broadcastStream.add(bcast);
      } else if (type == 'ALLOW_SPEAK') {
        _speakingPermissionStream.add(true);
      }
    } catch (_) {}
  }

  // Student raises hand
  void studentRaiseHand({required String studentName, required String lang}) {
    if (_clientSocket != null) {
      _clientSocket!.add(
        jsonEncode({
          'type': 'RAISE_HAND',
          'name': studentName,
          'lang': lang,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
    }
  }

  // Student sends question in mother tongue
  void studentSendQuery({
    required String queryText,
    required String studentName,
    required String lang,
  }) {
    if (_clientSocket != null) {
      _clientSocket!.add(
        jsonEncode({
          'type': 'STUDENT_QUERY',
          'text': queryText,
          'name': studentName,
          'lang': lang,
        }),
      );
    }
  }

  // ==========================================
  // 3. CLEANUP & LEAVE
  // ==========================================
  Future<void> leaveClassroom() async {
    for (final client in _connectedClients) {
      try {
        await client.close();
      } catch (_) {}
    }
    _connectedClients.clear();

    if (_server != null) {
      try {
        await _server!.close(force: true);
      } catch (_) {}
      _server = null;
    }

    if (_clientSocket != null) {
      try {
        await _clientSocket!.close();
      } catch (_) {}
      _clientSocket = null;
    }

    _currentRole = null;
    _roomCode = '';
    _connectedStudentCount = 0;
  }
}
