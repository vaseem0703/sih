import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app/theme.dart';
import '../models/translation_result.dart';
import '../services/speech_service.dart';
import '../services/translation_service.dart';
import '../services/tts_service.dart';

class ChatMessage {
  final String id;
  final String inputText;
  final String inputLangName;
  final String translatedText;
  final String transliteration;
  final String targetLangName;
  final String source;
  final DateTime timestamp;
  bool isPlayingAudio;

  ChatMessage({
    required this.id,
    required this.inputText,
    required this.inputLangName,
    required this.translatedText,
    required this.transliteration,
    required this.targetLangName,
    required this.source,
    required this.timestamp,
    this.isPlayingAudio = false,
  });
}

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
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  String _sourceLang = 'hin_Deva'; // Default: Hindi
  String _targetLang = 'sat_Olck'; // Default: Santali
  
  bool _isListening = false;
  bool _isTranslating = false;
  String _liveSpokenText = '';

  final List<Map<String, String>> _tribalLanguages = [
    {'code': 'hin_Deva', 'name': '🇮🇳 Hindi (हिन्दी)'},
    {'code': 'sat_Olck', 'name': '🌾 Santali (ᱥᱟᱱᱛᱟᱲᱤ)'},
    {'code': 'hoc_Wara', 'name': '🌲 Ho (ᱦᱳ)'},
    {'code': 'unr_Mund', 'name': '🏔️ Mundari (ᱢᱩᱱᱰᱟᱨᱤ)'},
  ];

  // Starts 100% clean with NO hardcoded dummy messages!
  final List<ChatMessage> _messages = [];

  final List<String> _quickClassroomPrompts = [
    'नमस्ते बच्चों',
    'अपनी किताब खोलो',
    'आज हम गिनती सीखेंगे',
    'पानी पियो',
    'बहुत अच्छा, शाबाश!',
    'तुम्हारा नाम क्या है?',
  ];

  @override
  void initState() {
    super.initState();
    widget.speechService.requestMicPermission().then((_) {
      widget.speechService.initialize();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
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

  void _swapLanguages() {
    setState(() {
      final temp = _sourceLang;
      _sourceLang = _targetLang;
      _targetLang = temp;
    });
  }

  void _toggleLiveMic() async {
    if (_isListening) {
      await widget.speechService.stopListening();
      setState(() => _isListening = false);
      if (_liveSpokenText.isNotEmpty) {
        _processAndSendText(_liveSpokenText);
        _liveSpokenText = '';
      }
    } else {
      final hasPerm = await widget.speechService.requestMicPermission();
      if (!hasPerm && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please grant Microphone permission to use live voice.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      setState(() {
        _isListening = true;
        _liveSpokenText = '';
      });

      final success = await widget.speechService.startListening(
        onResult: (spoken) {
          setState(() {
            _liveSpokenText = spoken;
            _textController.text = spoken;
          });
        },
        onStatusUpdate: (status) {
          if (status.contains('denied') && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(status), duration: const Duration(seconds: 2)),
            );
          }
        },
      );

      if (!success) {
        // If STT engine on phone is busy or offline, show quick speech prompt chooser
        _showQuickSpeechPicker();
      }
    }
  }

  void _showQuickSpeechPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    '🎙️ Classroom Speech Input',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Tap a classroom sentence or speak into keyboard mic:',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickClassroomPrompts.map((prompt) {
                  return ActionChip(
                    label: Text(
                      prompt,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.purple,
                      ),
                    ),
                    backgroundColor: AppColors.purpleLight,
                    side: const BorderSide(color: Color(0xFFE1D5F0)),
                    onPressed: () {
                      Navigator.pop(context);
                      _processAndSendText(prompt);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _processAndSendText(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return;

    _textController.clear();
    setState(() => _isTranslating = true);

    final res = await widget.translationService.translateBidirectional(
      text: clean,
      srcLangCode: _sourceLang,
      tgtLangCode: _targetLang,
    );

    final srcLangObj = _tribalLanguages.firstWhere(
      (l) => l['code'] == _sourceLang,
      orElse: () => {'name': 'Source'},
    );

    final tgtLangObj = _tribalLanguages.firstWhere(
      (l) => l['code'] == _targetLang,
      orElse: () => {'name': 'Target'},
    );

    final newMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      inputText: clean,
      inputLangName: srcLangObj['name']!,
      translatedText: res.santaliOlChiki,
      transliteration: res.transliteration,
      targetLangName: tgtLangObj['name']!,
      source: res.source,
      timestamp: DateTime.now(),
    );

    if (!mounted) return;
    setState(() {
      _messages.add(newMsg);
      _isTranslating = false;
    });

    _scrollToBottom();

    // Auto-play audio
    _playMessageAudio(newMsg);
  }

  void _playMessageAudio(ChatMessage msg) async {
    setState(() => msg.isPlayingAudio = true);

    await widget.ttsService.generateSantaliSpeech(
      santaliText: msg.translatedText,
      speaker: 'Phulmani (Female)',
    );

    if (mounted) {
      setState(() => msg.isPlayingAudio = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. TOP BAR: SOURCE & TARGET TRIBAL LANGUAGE SELECTOR WITH SWAP BUTTON
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: AppColors.line)),
          ),
          child: Row(
            children: [
              // Source Dropdown
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _sourceLang,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down, color: AppColors.purple, size: 20),
                      items: _tribalLanguages.map((lang) {
                        return DropdownMenuItem<String>(
                          value: lang['code'],
                          child: Text(
                            lang['name']!,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navy,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _sourceLang = val);
                        }
                      },
                    ),
                  ),
                ),
              ),

              // Swap Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: InkWell(
                  onTap: _swapLanguages,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.purpleLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.swap_horiz_rounded,
                      size: 20,
                      color: AppColors.purple,
                    ),
                  ),
                ),
              ),

              // Target Dropdown
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _targetLang,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down, color: AppColors.purple, size: 20),
                      items: _tribalLanguages.map((lang) {
                        return DropdownMenuItem<String>(
                          value: lang['code'],
                          child: Text(
                            lang['name']!,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navy,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _targetLang = val);
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // 2. CONVERSATION FEED OR CLEAN EMPTY STATE
        Expanded(
          child: _messages.isEmpty
              ? _buildEmptyClassroomState()
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Input Message Bubble (Right)
                          Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.82,
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.purple,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                  bottomLeft: Radius.circular(16),
                                  bottomRight: Radius.circular(4),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.purple.withOpacity(0.2),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '🗣️ ${msg.inputLangName}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    msg.inputText,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Vernacular AI Translation Bubble (Left)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.88,
                              ),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(4),
                                  topRight: Radius.circular(18),
                                  bottomLeft: Radius.circular(18),
                                  bottomRight: Radius.circular(18),
                                ),
                                border: Border.all(color: AppColors.line),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 8,
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
                                        msg.targetLangName,
                                        style: const TextStyle(
                                          color: AppColors.purple,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            icon: const Icon(Icons.copy, size: 16, color: AppColors.textMuted),
                                            onPressed: () {
                                              Clipboard.setData(ClipboardData(text: msg.translatedText));
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Copied'), duration: Duration(seconds: 1)),
                                              );
                                            },
                                          ),
                                          const SizedBox(width: 8),
                                          // Play Audio Button
                                          GestureDetector(
                                            onTap: () => _playMessageAudio(msg),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: AppColors.green.withOpacity(0.12),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    msg.isPlayingAudio
                                                        ? Icons.volume_up_rounded
                                                        : Icons.play_arrow_rounded,
                                                    size: 16,
                                                    color: AppColors.green,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    msg.isPlayingAudio ? 'Playing...' : 'Audio',
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppColors.green,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  // Translated Script
                                  Text(
                                    msg.translatedText,
                                    style: const TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.navy,
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  // Transliteration
                                  Text(
                                    msg.transliteration,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Model: ${msg.source}',
                                    style: const TextStyle(
                                      fontSize: 9.5,
                                      color: AppColors.purple,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),

        // Live Listening Banner
        if (_isListening)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.redAccent.withOpacity(0.1),
            child: Row(
              children: [
                const Icon(Icons.fiber_manual_record, color: Colors.redAccent, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _liveSpokenText.isEmpty ? 'Listening to speech...' : _liveSpokenText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _toggleLiveMic,
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // 3. BOTTOM INPUT & LIVE MIC BAR
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.line)),
          ),
          child: SafeArea(
            child: Row(
              children: [
                // Big Animated Mic Button
                GestureDetector(
                  onTap: _toggleLiveMic,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isListening ? Colors.redAccent : AppColors.purple,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_isListening ? Colors.redAccent : AppColors.purple).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Text Input
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: TextField(
                      controller: _textController,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(
                        hintText: 'Speak or type...',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                      onSubmitted: (val) {
                        _processAndSendText(val);
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Send Button
                IconButton(
                  onPressed: _isTranslating
                      ? null
                      : () => _processAndSendText(_textController.text),
                  icon: _isTranslating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded, color: AppColors.purple),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyClassroomState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.purpleLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mic_none_rounded,
                size: 48,
                color: AppColors.purple,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Live Classroom Ready',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tap the purple mic below or type a phrase to start real-time tribal classroom translation.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Quick Classroom Phrases:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _quickClassroomPrompts.map((p) {
                return ActionChip(
                  label: Text(
                    p,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.purple,
                    ),
                  ),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: AppColors.line),
                  onPressed: () => _processAndSendText(p),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
