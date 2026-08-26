import 'dart:async';
import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../models/translation_result.dart';
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

class _LiveClassScreenState extends State<LiveClassScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _srcLangCode = 'hin_Deva';
  String _tgtLangCode = 'sat_Olck';
  bool _autoPlaySpeaker = true;

  bool _isListening = false;
  bool _isTranslating = false;
  String _liveSpokenText = '';

  final List<TranslationResult> _messages = [];

  final List<Map<String, String>> _languages = [
    {'code': 'hin_Deva', 'name': '🇮🇳 Hindi (हिन्दी)'},
    {'code': 'sat_Olck', 'name': '🌾 Santali (ᱥᱟᱱᱛᱟᱲᱤ)'},
    {'code': 'hoc_Wara', 'name': '🌲 Ho (ᱦᱳ)'},
    {'code': 'unr_Mund', 'name': '🏔️ Mundari (ᱢᱩᱱᱰᱟᱨᱤ)'},
  ];

  final List<String> _classroomQuickPrompts = [
    'अपनी किताब खोलो',
    'आज हम गिनती सीखेंगे',
    'नमस्ते',
    'बहुत अच्छा, शाबाश!',
    'बच्चों, ध्यान से सुनो',
    'पानी पियो',
  ];

  @override
  void initState() {
    super.initState();
    widget.speechService.requestMicPermission();
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
      final temp = _srcLangCode;
      _srcLangCode = _tgtLangCode;
      _tgtLangCode = temp;
    });
  }

  void _processTeacherSpeech(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return;

    _textController.clear();
    setState(() {
      _isTranslating = true;
      _liveSpokenText = '';
    });

    try {
      final result = await widget.translationService.translateBidirectional(
        text: clean,
        srcLangCode: _srcLangCode,
        tgtLangCode: _tgtLangCode,
      );

      if (mounted) {
        setState(() {
          _messages.add(result);
          _isTranslating = false;
        });
        _scrollToBottom();

        // Automatically speak aloud via phone speaker / classroom sound system
        if (_autoPlaySpeaker) {
          widget.ttsService.generateSantaliSpeech(
            santaliText: result.santaliOlChiki,
            speaker: 'Phulmani',
          );
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isTranslating = false);
      }
    }
  }

  void _toggleLiveMic() async {
    if (_isListening) {
      await widget.speechService.stopListening();
      setState(() => _isListening = false);
      if (_liveSpokenText.isNotEmpty) {
        _processTeacherSpeech(_liveSpokenText);
      }
    } else {
      setState(() {
        _isListening = true;
        _liveSpokenText = '';
      });

      final success = await widget.speechService.startListening(
        onResult: (spoken) {
          if (mounted) {
            setState(() {
              _liveSpokenText = spoken;
              _textController.text = spoken;
            });
          }
        },
        onStatusUpdate: (msg) {
          if (mounted && msg.isNotEmpty && !msg.startsWith("Listening")) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
            );
          }
        },
      );

      if (!success && mounted) {
        setState(() => _isListening = false);
      }
    }
  }

  String _getLangName(String code) {
    return _languages.firstWhere((l) => l['code'] == code, orElse: () => {'name': code})['name']!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Top Language Selector & Auto-Speaker Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: const Border(bottom: BorderSide(color: AppColors.line)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  // Source Language Dropdown
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _srcLangCode,
                          isExpanded: true,
                          items: _languages.map((l) {
                            return DropdownMenuItem<String>(
                              value: l['code'],
                              child: Text(
                                l['name']!,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _srcLangCode = val);
                          },
                        ),
                      ),
                    ),
                  ),

                  // Swap Button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: IconButton(
                      icon: const Icon(Icons.swap_horiz_rounded, color: AppColors.purple, size: 24),
                      tooltip: 'Swap Languages',
                      onPressed: _swapLanguages,
                    ),
                  ),

                  // Target Language Dropdown
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _tgtLangCode,
                          isExpanded: true,
                          items: _languages.map((l) {
                            return DropdownMenuItem<String>(
                              value: l['code'],
                              child: Text(
                                l['name']!,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _tgtLangCode = val);
                          },
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Auto-Speaker Toggle
                  InkWell(
                    onTap: () {
                      setState(() => _autoPlaySpeaker = !_autoPlaySpeaker);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_autoPlaySpeaker ? '🔊 Auto-Speaker ON (Voice speaks aloud automatically)' : '🔇 Auto-Speaker OFF'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _autoPlaySpeaker ? AppColors.purpleLight : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _autoPlaySpeaker ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                        color: _autoPlaySpeaker ? AppColors.purple : Colors.grey.shade600,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Classroom Conversation / Translation Feed
          Expanded(
            child: _messages.isEmpty
                ? Center(
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
                            child: const Icon(Icons.record_voice_over_rounded, size: 48, color: AppColors.purple),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Teacher Live Voice Assistant',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.navy),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Speak in Hindi — the phone instantly translates and speaks aloud in ${_getLangName(_tgtLangCode)} for your classroom.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5, height: 1.4),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Quick Classroom Phrases:',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: _classroomQuickPrompts.map((prompt) {
                              return ActionChip(
                                label: Text(prompt, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.purple)),
                                backgroundColor: Colors.white,
                                side: const BorderSide(color: AppColors.line),
                                elevation: 1,
                                onPressed: () => _processTeacherSpeech(prompt),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(14),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final item = _messages[index];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
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
                              // Header: Source Phrase + Speaker Button
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _getLangName(_srcLangCode),
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item.originalHindi,
                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.navy),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.greenLight,
                                      foregroundColor: AppColors.greenOk,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    onPressed: () {
                                      widget.ttsService.generateSantaliSpeech(
                                        santaliText: item.santaliOlChiki,
                                        speaker: 'Phulmani',
                                      );
                                    },
                                    icon: const Icon(Icons.volume_up_rounded, size: 16, color: AppColors.greenOk),
                                    label: const Text('Speak', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),
                              const Divider(height: 1, color: AppColors.line),
                              const SizedBox(height: 12),

                              // Target Translated Vernacular Script
                              Text(
                                _getLangName(_tgtLangCode),
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.purple),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.santaliOlChiki,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.navy,
                                  height: 1.3,
                                ),
                              ),
                              if (item.transliteration.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  item.transliteration,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // Bottom Teacher Voice Console
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: const Border(top: BorderSide(color: AppColors.line)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Microphone Button
                  GestureDetector(
                    onTap: _toggleLiveMic,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _isListening ? Colors.redAccent : AppColors.purple,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (_isListening ? Colors.redAccent : AppColors.purple).withOpacity(0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

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
                        decoration: InputDecoration(
                          hintText: _isListening ? 'Listening to teacher...' : 'Speak or type classroom instruction...',
                          hintStyle: TextStyle(
                            color: _isListening ? Colors.redAccent : AppColors.textMuted,
                            fontWeight: _isListening ? FontWeight.bold : FontWeight.normal,
                            fontSize: 13.5,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onSubmitted: _processTeacherSpeech,
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Send Button
                  IconButton(
                    onPressed: _isTranslating ? null : () => _processTeacherSpeech(_textController.text),
                    icon: _isTranslating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.purple),
                          )
                        : const Icon(Icons.send_rounded, color: AppColors.purple, size: 24),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
