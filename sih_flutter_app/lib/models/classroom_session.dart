enum ClassroomRole { teacher, student }

class ClassroomRoom {
  final String roomCode;
  final String hostIp;
  final int port;
  final String teacherName;
  final DateTime createdAt;

  ClassroomRoom({
    required this.roomCode,
    required this.hostIp,
    required this.port,
    this.teacherName = 'Teacher',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'roomCode': roomCode,
    'hostIp': hostIp,
    'port': port,
    'teacherName': teacherName,
    'createdAt': createdAt.toIso8601String(),
  };
}

class ClassroomBroadcast {
  final String id;
  final String senderName;
  final ClassroomRole senderRole;
  final String originalText;
  final String sourceLangCode;
  final Map<String, String> translations;
  final Map<String, String> transliterations;
  final DateTime timestamp;

  ClassroomBroadcast({
    required this.id,
    required this.senderName,
    required this.senderRole,
    required this.originalText,
    required this.sourceLangCode,
    required this.translations,
    required this.transliterations,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'senderName': senderName,
    'senderRole': senderRole.name,
    'originalText': originalText,
    'sourceLangCode': sourceLangCode,
    'translations': translations,
    'transliterations': transliterations,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ClassroomBroadcast.fromJson(Map<String, dynamic> json) {
    return ClassroomBroadcast(
      id: json['id'] ?? '',
      senderName: json['senderName'] ?? 'Teacher',
      senderRole: json['senderRole'] == 'student'
          ? ClassroomRole.student
          : ClassroomRole.teacher,
      originalText: json['originalText'] ?? '',
      sourceLangCode: json['sourceLangCode'] ?? 'hin_Deva',
      translations: Map<String, String>.from(json['translations'] ?? {}),
      transliterations: Map<String, String>.from(
        json['transliterations'] ?? {},
      ),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }
}

class StudentQuery {
  final String studentName;
  final String studentLang;
  final String originalQuery;
  final String translatedHindi;
  final DateTime timestamp;

  StudentQuery({
    required this.studentName,
    required this.studentLang,
    required this.originalQuery,
    required this.translatedHindi,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'studentName': studentName,
    'studentLang': studentLang,
    'originalQuery': originalQuery,
    'translatedHindi': translatedHindi,
    'timestamp': timestamp.toIso8601String(),
  };
}
