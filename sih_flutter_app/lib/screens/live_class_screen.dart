import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app/theme.dart';
import '../models/classroom_session.dart';
import '../services/offline_classroom_service.dart';
import '../services/speech_service.dart';
import '../services/translation_service.dart';
import '../services/tts_service.dart';

class LiveClassScreen extends StatefulWidget {
  final SpeechService speechService;
  final TranslationService translationService;
  final TtsService ttsService;

  const LiveClassScreen({
    super.key,
    required this.speechService,
    required this.translationService,
    required this.ttsService,
  });

  @override
  State<LiveClassScreen> createState() => _LiveClassScreenState();
}

class _LiveClassScreenState extends State<LiveClassScreen> {
  final OfflineClassroomService _classroomService = OfflineClassroomService();
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _joinCodeController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Active Session State
  ClassroomRole? _currentRole;
  String _activeRoomCode = '';
  String _studentPreferredLang = 'sat_Olck'; // Default: Santali
  int _connectedStudentCount = 0;

  // Stream Feed
  final List<ClassroomBroadcast> _broadcasts = [];
  Map<String, dynamic>? _activeRaiseHandAlert;
  bool _canStudentSpeak = false;

  bool _isListening = false;
  bool _isTranslating = false;
  String _liveSpokenText = '';

  // Stream Subscriptions
  StreamSubscription? _broadcastSub;
  StreamSubscription? _raiseHandSub;
  StreamSubscription? _permissionSub;
  StreamSubscription? _studentCountSub;

  final List<Map<String, String>> _tribalLanguages = [
    {'code': 'sat_Olck', 'name': '🌾 Santali (ᱥᱟᱱᱛᱟᱲᱤ)'},
    {'code': 'hoc_Wara', 'name': '🌲 Ho (ᱦᱳ)'},
    {'code': 'unr_Mund', 'name': '🏔️ Mundari (ᱢᱩᱱᱰᱟᱨᱤ)'},
  ];

  final List<String> _studentQuickQuestions = [
    'ᱱᱚᱣᱟ ᱫᱚ ᱪᱮᱫ? (What is this?)',
    'ᱫᱟᱜ ᱧᱩᱭ ᱢᱮ ᱾ (May I drink water?)',
    'ᱤᱧᱟᱜ ᱠᱩᱠᱞᱤ ᱢᱮᱱᱟᱜᱼᱟ ᱾ (I have a question)',
    'ᱟᱨ ᱢᱤᱫ ᱫᱷᱟᱣ ᱞᱟᱹᱭ ᱢᱮ ᱾ (Please repeat)',
  ];

  @override
  void initState() {
    super.initState();
    widget.speechService.requestMicPermission();

    _broadcastSub = _classroomService.onBroadcast.listen((bcast) {
      if (mounted) {
        setState(() => _broadcasts.add(bcast));
        _scrollToBottom();
        // Play audio if student mode
        if (_currentRole == ClassroomRole.student) {
          final translatedText = bcast.translations[_studentPreferredLang] ?? bcast.originalText;
          widget.ttsService.generateSantaliSpeech(
            santaliText: translatedText,
            speaker: 'Phulmani',
          );
        }
      }
    });

    _raiseHandSub = _classroomService.onRaiseHand.listen((alert) {
      if (mounted && _currentRole == ClassroomRole.teacher) {
        setState(() => _activeRaiseHandAlert = alert);
      }
    });

    _permissionSub = _classroomService.onSpeakingPermission.listen((allowed) {
      if (mounted && _currentRole == ClassroomRole.student && allowed) {
        setState(() => _canStudentSpeak = true);
        _showStudentSpeakingModal();
      }
    });

    _studentCountSub = _classroomService.onStudentCount.listen((count) {
      if (mounted) {
        setState(() => _connectedStudentCount = count);
      }
    });
  }

  @override
  void dispose() {
    _broadcastSub?.cancel();
    _raiseHandSub?.cancel();
    _permissionSub?.cancel();
    _studentCountSub?.cancel();
    _textController.dispose();
    _joinCodeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ==========================================
  // TEACHER ACTIONS
  // ==========================================
  void _createClassroom() async {
    setState(() => _isTranslating = true);
    final code = await _classroomService.createClassroom();
    setState(() {
      _currentRole = ClassroomRole.teacher;
      _activeRoomCode = code;
      _broadcasts.clear();
      _isTranslating = false;
    });
  }

  void _broadcastTeacherSpeech(String hindiText) async {
    final clean = hindiText.trim();
    if (clean.isEmpty) return;

    _textController.clear();
    setState(() => _isTranslating = true);

    await _classroomService.broadcastTeacherSpeech(originalHindi: clean);

    if (mounted) {
      setState(() => _isTranslating = false);
    }
  }

  void _allowStudentToSpeak() {
    if (_activeRaiseHandAlert != null) {
      final name = _activeRaiseHandAlert!['name'] ?? 'Student';
      _classroomService.allowStudentToSpeak(name);
      setState(() => _activeRaiseHandAlert = null);
    }
  }

  // ==========================================
  // STUDENT ACTIONS
  // ==========================================
  void _showJoinClassDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: const [
              Icon(Icons.login_rounded, color: AppColors.purple),
              SizedBox(width: 8),
              Text('Join Live Class', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Enter 4-digit class code provided by your teacher:', style: TextStyle(fontSize: 13)),
              const SizedBox(height: 12),
              TextField(
                controller: _joinCodeController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 6),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: '8492',
                  counterText: '',
                  filled: true,
                  fillColor: AppColors.cardBackground,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.line)),
                ),
              ),
              const SizedBox(height: 14),
              const Text('Select Your Mother Tongue:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.line),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _studentPreferredLang,
                    isExpanded: true,
                    items: _tribalLanguages.map((l) {
                      return DropdownMenuItem<String>(
                        value: l['code'],
                        child: Text(l['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _studentPreferredLang = val);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final code = _joinCodeController.text.trim();
                if (code.isNotEmpty) {
                  Navigator.pop(context);
                  setState(() => _isTranslating = true);
                  final ok = await _classroomService.joinClassroom(
                    roomCode: code,
                    preferredLanguage: _studentPreferredLang,
                  );
                  setState(() {
                    _currentRole = ClassroomRole.student;
                    _activeRoomCode = code;
                    _broadcasts.clear();
                    _isTranslating = false;
                  });
                  if (!ok && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Connected in Standalone Mode over Local Network')),
                    );
                  }
                }
              },
              child: const Text('Join Room'),
            ),
          ],
        );
      },
    );
  }

  void _studentRaiseHand() {
    _classroomService.studentRaiseHand(
      studentName: 'Santali Student',
      lang: _studentPreferredLang,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✋ Hand Raised! Waiting for teacher to allow speaking...'),
        backgroundColor: Color(0xFFF59E0B),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showStudentSpeakingModal() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.mic_rounded, color: Colors.green, size: 24),
                  SizedBox(width: 8),
                  Text('Teacher Allowed You to Speak!', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.navy)),
                ],
              ),
              const SizedBox(height: 6),
              const Text('Ask your question in Santali / your mother tongue (it will translate to Hindi for the teacher):', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _studentQuickQuestions.map((q) {
                  return ActionChip(
                    label: Text(q, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.purple, fontSize: 12.5)),
                    backgroundColor: AppColors.purpleLight,
                    side: const BorderSide(color: Color(0xFFE1D5F0)),
                    onPressed: () {
                      Navigator.pop(context);
                      _classroomService.studentSendQuery(
                        queryText: q,
                        studentName: 'Santali Student',
                        lang: _studentPreferredLang,
                      );
                      setState(() => _canStudentSpeak = false);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    setState(() => _canStudentSpeak = false);
                  },
                  child: const Text('Finished Question'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _leaveClassroom() async {
    await _classroomService.leaveClassroom();
    setState(() {
      _currentRole = null;
      _activeRoomCode = '';
      _broadcasts.clear();
      _activeRaiseHandAlert = null;
    });
  }

  void _toggleLiveMic() async {
    if (_isListening) {
      await widget.speechService.stopListening();
      setState(() => _isListening = false);
      if (_liveSpokenText.isNotEmpty) {
        _broadcastTeacherSpeech(_liveSpokenText);
        _liveSpokenText = '';
      }
    } else {
      setState(() {
        _isListening = true;
        _liveSpokenText = '';
      });

      await widget.speechService.startListening(
        onResult: (spoken) {
          setState(() {
            _liveSpokenText = spoken;
            _textController.text = spoken;
          });
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentRole == null) {
      return _buildLobbySelection();
    } else if (_currentRole == ClassroomRole.teacher) {
      return _buildTeacherClassroom();
    } else {
      return _buildStudentClassroom();
    }
  }

  // ==========================================
  // VIEW 1: LOBBY SELECTION
  // ==========================================
  Widget _buildLobbySelection() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Badge
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.purpleLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '📶 100% OFFLINE MULTI-DEVICE CLASSROOM',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.purple,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Live Mother-Tongue Classroom',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Teacher speaks in Hindi — students receive live translation & audio on their own phones in Santali, Ho, or Mundari.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 28),

              // Card 1: Create Class (Teacher)
              InkWell(
                onTap: _createClassroom,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E1B4B), Color(0xFF4338CA)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4338CA).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.school_rounded, color: Colors.white, size: 30),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              '👨‍🏫 Create Class (Teacher)',
                              style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Host a live offline session & broadcast your Hindi speech to student devices.',
                              style: TextStyle(color: Color(0xFFE0E7FF), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 18),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Card 2: Join Class (Student)
              InkWell(
                onTap: _showJoinClassDialog,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.line),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.purpleLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.groups_rounded, color: AppColors.purple, size: 30),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              '🧑‍🎓 Join Class (Student)',
                              style: TextStyle(color: AppColors.navy, fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Enter class code & receive live speech in Santali Ol Chiki, Ho, or Mundari.',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // VIEW 2: TEACHER CLASSROOM
  // ==========================================
  Widget _buildTeacherClassroom() {
    return Column(
      children: [
        // Teacher Session Header Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppColors.line)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.purpleLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'ROOM: $_activeRoomCode',
                  style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.purple, fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '👥 $_connectedStudentCount Students',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.exit_to_app_rounded, color: Colors.redAccent, size: 22),
                tooltip: 'End Class',
                onPressed: _leaveClassroom,
              ),
            ],
          ),
        ),

        // Raise Hand Alert Banner
        if (_activeRaiseHandAlert != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: const Color(0xFFFEF3C7),
            child: Row(
              children: [
                const Icon(Icons.front_hand_rounded, color: Color(0xFFD97706), size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '✋ ${_activeRaiseHandAlert!['name']} raised hand to ask a question!',
                    style: const TextStyle(color: Color(0xFF92400E), fontWeight: FontWeight.bold, fontSize: 12.5),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD97706),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _allowStudentToSpeak,
                  child: const Text('Allow to Speak', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

        // Classroom Conversation Feed
        Expanded(
          child: _broadcasts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.mic_rounded, size: 48, color: AppColors.purple),
                      SizedBox(height: 12),
                      Text('Classroom is Live', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy)),
                      SizedBox(height: 4),
                      Text('Tap the mic below and speak in Hindi to broadcast to all students.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(14),
                  itemCount: _broadcasts.length,
                  itemBuilder: (context, index) {
                    final bcast = _broadcasts[index];
                    final isTeacher = bcast.senderRole == ClassroomRole.teacher;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: isTeacher ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Container(
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.84),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isTeacher ? AppColors.purple : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: isTeacher ? null : Border.all(color: AppColors.line),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isTeacher ? '👨‍🏫 Teacher (Hindi)' : '🧑‍🎓 ${bcast.senderName} (Query)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isTeacher ? Colors.white70 : AppColors.purple,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  bcast.originalText,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isTeacher ? Colors.white : AppColors.navy,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '🌾 Santali: ${bcast.translations['sat_Olck'] ?? ''}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isTeacher ? const Color(0xFFE0E7FF) : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),

        // Live Mic & Input Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.line)),
          ),
          child: SafeArea(
            child: Row(
              children: [
                GestureDetector(
                  onTap: _toggleLiveMic,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isListening ? Colors.redAccent : AppColors.purple,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_isListening ? Icons.stop_rounded : Icons.mic_rounded, color: Colors.white, size: 24),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: 'Speak or type Hindi classroom instruction...',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onSubmitted: _broadcastTeacherSpeech,
                  ),
                ),
                IconButton(
                  onPressed: _isTranslating ? null : () => _broadcastTeacherSpeech(_textController.text),
                  icon: const Icon(Icons.send_rounded, color: AppColors.purple),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // VIEW 3: STUDENT CLASSROOM
  // ==========================================
  Widget _buildStudentClassroom() {
    final curLangObj = _tribalLanguages.firstWhere((l) => l['code'] == _studentPreferredLang, orElse: () => _tribalLanguages.first);

    return Column(
      children: [
        // Student Header Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppColors.line)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.greenLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('ROOM: $_activeRoomCode', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.greenOk, fontSize: 12)),
              ),
              const SizedBox(width: 10),
              // Preferred Language Selector
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _studentPreferredLang,
                      isExpanded: true,
                      items: _tribalLanguages.map((l) {
                        return DropdownMenuItem<String>(
                          value: l['code'],
                          child: Text(l['name']!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _studentPreferredLang = val);
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.exit_to_app_rounded, color: Colors.redAccent, size: 20),
                onPressed: _leaveClassroom,
              ),
            ],
          ),
        ),

        // Live Student Conversation Feed
        Expanded(
          child: _broadcasts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.headphones_rounded, size: 48, color: AppColors.purple),
                      const SizedBox(height: 12),
                      Text('Listening in ${curLangObj['name']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.navy)),
                      const SizedBox(height: 4),
                      const Text('When your teacher speaks, live translations & audio will appear here.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(14),
                  itemCount: _broadcasts.length,
                  itemBuilder: (context, index) {
                    final bcast = _broadcasts[index];
                    final translatedText = bcast.translations[_studentPreferredLang] ?? bcast.originalText;
                    final transliteration = bcast.transliterations[_studentPreferredLang] ?? '';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.line),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  bcast.senderRole == ClassroomRole.teacher ? '👨‍🏫 Teacher' : '🧑‍🎓 ${bcast.senderName}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.purple),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    widget.ttsService.generateSantaliSpeech(
                                      santaliText: translatedText,
                                      speaker: 'Phulmani',
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.green.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: const [
                                        Icon(Icons.volume_up_rounded, size: 14, color: AppColors.green),
                                        SizedBox(width: 4),
                                        Text('Audio', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.green)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Translated Mother-Tongue
                            Text(
                              translatedText,
                              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AppColors.navy, height: 1.3),
                            ),
                            if (transliteration.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(transliteration, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
                            ],
                            const SizedBox(height: 6),
                            Text('Original: "${bcast.originalText}"', style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),

        // Student Raise Hand Bottom Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.line)),
          ),
          child: SafeArea(
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                onPressed: _studentRaiseHand,
                icon: const Icon(Icons.front_hand_rounded, size: 22),
                label: const Text(
                  '✋ Raise Hand to Ask Question (हाथ उठाएँ)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
