import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../momo_ui/theme/momo_theme.dart';
import '../../shell/navigation_controller.dart';

/// Standalone Chat surface with real multimodal vision, speech recognition, and instant responses.
class ChatSurface extends StatefulWidget {
  const ChatSurface({super.key});

  @override
  State<ChatSurface> createState() => _ChatSurfaceState();
}

class _ChatSurfaceState extends State<ChatSurface> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _picker = ImagePicker();
  final _speech = stt.SpeechToText();

  bool _isListening = false;
  bool _speechAvailable = false;
  File? _pendingImage;

  late final NavigationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<NavigationController>();
    _initSpeech();
  }

  Future<bool> _initSpeech() async {
    try {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        _speechAvailable = false;
        return false;
      }

      _speechAvailable = await _speech.initialize(
        onError: (e) {
          if (mounted) setState(() => _isListening = false);
        },
        onStatus: (s) {
          if (s == 'done' || s == 'notListening') {
            if (mounted) setState(() => _isListening = false);
          }
        },
      );
      return _speechAvailable;
    } catch (_) {
      _speechAvailable = false;
      return false;
    }
  }

  Future<void> _toggleMic() async {
    if (!_speechAvailable) {
      final ok = await _initSpeech();
      if (!ok) {
        Get.snackbar(
          'Microphone Permission Needed 🎙️',
          'Please allow microphone permission to talk with Babymomo.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: MomoColors.rose,
          colorText: Colors.white,
        );
        return;
      }
    }

    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
    } else {
      if (mounted) setState(() => _isListening = true);

      final initialText = _textCtrl.text;
      await _speech.listen(
        onResult: (result) {
          if (mounted) {
            setState(() {
              final newWords = result.recognizedWords;
              _textCtrl.text = initialText.isNotEmpty
                  ? '$initialText $newWords'
                  : newWords;
              _textCtrl.selection = TextSelection.fromPosition(
                TextPosition(offset: _textCtrl.text.length),
              );
            });
            if (result.finalResult) {
              setState(() => _isListening = false);
            }
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.dictation,
      );
    }
  }

  Future<void> _send() async {
    final text = _textCtrl.text.trim();
    final img = _pendingImage;
    if (text.isEmpty && img == null) return;

    _textCtrl.clear();
    setState(() => _pendingImage = null);

    await _ctrl.sendChat(text, imageFile: img);
    _scrollToBottom();
  }

  @override
  void dispose() {
    _speech.stop();
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Chat',
                            style: Theme.of(context).textTheme.displayMedium),
                        Obx(() {
                          final m = _ctrl.activeModel.value;
                          return Text(
                            m != null
                                ? '🧠 ${m.name.split('(').first.trim()} Active'
                                : '🧠 Momo Core Active',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF10B981),
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }),
                      ]),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: MomoColors.textSecondary),
                  onPressed: _ctrl.clearChat,
                ),
              ],
            ),
          ),

          // ── Messages ────────────────────────────────────────────────────────
          Expanded(
            child: Obx(() {
              _scrollToBottom();
              final messages = _ctrl.chatMessages;
              return ListView.builder(
                controller: _scrollCtrl,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: messages.length,
                itemBuilder: (context, i) {
                  final msg = messages[i];
                  final isUser = msg['role'] == 'user';
                  final isTypingPlaceholder = msg['content'] == '__typing__';

                  return Align(
                    alignment:
                        isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 5),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.82),
                      decoration: BoxDecoration(
                        color: isUser
                            ? MomoColors.primary
                            : MomoColors.surfaceLight,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(isUser ? 16 : 4),
                          bottomRight: Radius.circular(isUser ? 4 : 16),
                        ),
                        border: Border.all(color: MomoColors.glassBorder),
                      ),
                      child: isTypingPlaceholder
                          ? const _TypingDots()
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (msg['image'] != null) ...[
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      File(msg['image']!),
                                      height: 160,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                Text(
                                  msg['content'] ?? '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.06),
                  );
                },
              );
            }),
          ),

          // ── Pending Image Preview ────────────────────────────────────────────
          if (_pendingImage != null)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_pendingImage!,
                        height: 80, width: 80, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => setState(() => _pendingImage = null),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                            color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.close,
                            size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── Input Bar ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: _pickImage,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(Icons.add_photo_alternate_outlined,
                          color: _pendingImage != null
                              ? MomoColors.cyan
                              : MomoColors.textSecondary,
                          size: 24),
                    ),
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: _toggleMic,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        _isListening ? Icons.mic : Icons.mic_none_outlined,
                        color: _isListening
                            ? MomoColors.rose
                            : MomoColors.textSecondary,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: MomoColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: _isListening
                              ? MomoColors.rose
                              : MomoColors.glassBorder),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 2),
                    child: TextField(
                      controller: _textCtrl,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 14),
                      maxLines: 4,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText: _isListening
                            ? '🎙️ Listening...'
                            : 'Message Babymomo...',
                        hintStyle: TextStyle(
                            color: _isListening
                                ? MomoColors.rose
                                : MomoColors.textMuted),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Obx(() => _ctrl.isTyping.value
                    ? const SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: MomoColors.primary))
                    : IconButton.filled(
                        icon: const Icon(Icons.arrow_upward, size: 20),
                        style: IconButton.styleFrom(
                            backgroundColor: MomoColors.primary,
                            padding: const EdgeInsets.all(10)),
                        onPressed: _send)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final v = _c.value;
        return Row(mainAxisSize: MainAxisSize.min, children: [
          _dot(v, 0.0),
          const SizedBox(width: 4),
          _dot(v, 0.3),
          const SizedBox(width: 4),
          _dot(v, 0.6),
        ]);
      },
    );
  }

  Widget _dot(double v, double offset) {
    final phase = ((v - offset) % 1.0).clamp(0.0, 1.0);
    final opacity =
        (0.3 + 0.7 * (1 - (2 * phase - 1).abs())).clamp(0.3, 1.0);
    return Opacity(
      opacity: opacity,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
            color: Colors.white60, shape: BoxShape.circle),
      ),
    );
  }
}
