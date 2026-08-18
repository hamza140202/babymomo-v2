import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../../momo_ui/momo_ui.dart';
import '../../momo_core/momo_core.dart';
import 'chat_controller.dart';

class ChatPage extends GetView<ChatController> {
  final bool isTab;
  const ChatPage({super.key, this.isTab = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MomoColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: isTab
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: MomoColors.textPrimary, size: 20),
                onPressed: () => Get.back(),
              ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tiny Momo presence indicator
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: MomoColors.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: MomoColors.primary.withValues(alpha: 0.5),
                    blurRadius: 8,
                  )
                ],
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: const Duration(seconds: 2))
                .shimmer(duration: const Duration(seconds: 3)),
            const SizedBox(width: 8),
            Text(
              'Momo',
              style: MomoTypography.displaySmall.copyWith(
                color: MomoColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          // Glowing "Agent Assist" mode switch
          Obx(() {
            final isAgent = controller.isAgentMode.value;
            return GestureDetector(
              onTap: () {
                controller.isAgentMode.value = !isAgent;
              },
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: isAgent ? MomoColors.primary.withValues(alpha: 0.12) : Colors.transparent,
                  border: Border.all(
                    color: isAgent ? MomoColors.primary : MomoColors.surfaceLight,
                    width: 1.5,
                  ),
                  boxShadow: [
                    if (isAgent)
                      BoxShadow(
                        color: MomoColors.primary.withValues(alpha: 0.2),
                        blurRadius: 8,
                        spreadRadius: 1,
                      )
                  ],
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 13,
                        color: isAgent ? MomoColors.primary : MomoColors.textMuted,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Agent Assist',
                        style: MomoTypography.labelSmall.copyWith(
                          color: isAgent ? MomoColors.primary : MomoColors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (controller.messages.isEmpty && !controller.isGenerating.value) {
                return _buildWelcomeState(context);
              }
              
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                itemCount: controller.messages.length + (controller.isGenerating.value ? 1 : 0),
                itemBuilder: (context, index) {
                  // If generating, render the active progress bubble / terminal
                  if (controller.isGenerating.value && index == controller.messages.length) {
                    if (controller.isThinking.value) {
                      return ThinkingTerminal(steps: controller.agentSteps);
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16, right: 48),
                      child: AICard.assistantMessage(
                        child: StreamingText(
                          initialText: controller.currentStreamContent.value,
                        ),
                      ),
                    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, curve: Curves.easeOut);
                  }

                  final msg = controller.messages[index];
                  final isUser = msg.role == 'user';
                  final isSystem = msg.role == 'system';

                  if (isSystem) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          msg.content,
                          style: MomoTypography.bodySmall.copyWith(
                            color: Colors.redAccent,
                          ),
                        ),
                      ),
                    );
                  }

                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: 16,
                      left: isUser ? 48 : 0,
                      right: isUser ? 0 : 48,
                    ),
                    child: isUser
                        ? AICard.userMessage(
                            child: Text(
                              msg.content,
                              style: MomoTypography.bodyMedium.copyWith(
                                color: MomoColors.textPrimary,
                              ),
                            ),
                          )
                        : AICard.assistantMessage(
                            child: AICardContent(content: msg.content),
                          ),
                  ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, curve: Curves.easeOut);
                },
              );
            }),
          ),

          // Input Surface
          Obx(
            () => PromptSurface(
              isGenerating: controller.isGenerating.value,
              onSubmit: controller.sendMessage,
              onCancel: controller.cancelGeneration,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeState(BuildContext context) {
    final chips = [
      "Tell me a joke, Momo! 🤖",
      "Draw a neon cyberpunk cityscape! 🎨",
      "Give me some cool tech advice! 💡",
      "Check my system telemetry 📊",
    ];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 30),
          // Bouncing mascot logo
          Center(
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: MomoColors.surfaceLight.withValues(alpha: 0.1),
                border: Border.all(
                  color: MomoColors.primary.withValues(alpha: 0.2),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: MomoColors.primary.withValues(alpha: 0.15),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.cover,
                ),
              ),
            )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .slideY(
              begin: 0.0,
              end: -0.08,
              duration: 1200.ms,
              curve: Curves.easeInOut,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Hey — what's on your mind? 💡",
            style: MomoTypography.displayLarge.copyWith(
              color: MomoColors.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2),
          const SizedBox(height: 8),
          Text(
            "Ask me anything. I run entirely on your device.",
            style: MomoTypography.bodyMedium.copyWith(
              color: MomoColors.textMuted,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
          const SizedBox(height: 32),
          // Suggested prompts header
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "QUICK SUGGESTIONS",
              style: MomoTypography.labelSmall.copyWith(
                color: MomoColors.primaryLight.withValues(alpha: 0.8),
                letterSpacing: 1.6,
                fontWeight: FontWeight.bold,
              ),
            ),
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 12),
          // Suggested prompt chips
          Column(
            children: chips.asMap().entries.map((entry) {
              final idx = entry.key;
              final prompt = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                width: double.infinity,
                child: InkWell(
                  onTap: () {
                    controller.sendMessage(prompt);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: MomoColors.surface.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: MomoColors.surfaceLight.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            prompt,
                            style: MomoTypography.bodyMedium.copyWith(
                              color: MomoColors.textPrimary,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: MomoColors.primaryLight,
                        ),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: (400 + idx * 80).ms, duration: 300.ms).slideX(begin: 0.1);
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Custom parser that renders text along with native generated local files.
class AICardContent extends StatelessWidget {
  final String content;
  const AICardContent({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    final regex = RegExp(r'!\[draw\]\(file://(.*?)\)');
    final matches = regex.allMatches(content);

    if (matches.isEmpty) {
      return Text(
        content,
        style: MomoTypography.bodyMedium.copyWith(
          color: MomoColors.textPrimary,
          height: 1.6,
        ),
      );
    }

    final List<Widget> children = [];
    int lastIndex = 0;

    for (final match in matches) {
      if (match.start > lastIndex) {
        children.add(Text(
          content.substring(lastIndex, match.start).trim(),
          style: MomoTypography.bodyMedium.copyWith(
            color: MomoColors.textPrimary,
            height: 1.6,
          ),
        ));
        children.add(const SizedBox(height: 10));
      }

      final path = match.group(1)!;
      children.add(
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: MomoColors.primary.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: MomoColors.primary.withValues(alpha: 0.1),
                blurRadius: 12,
                spreadRadius: 2,
              )
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.file(
            File(path),
            fit: BoxFit.contain,
          ),
        ),
      );

      lastIndex = match.end;
    }

    if (lastIndex < content.length) {
      final trailingText = content.substring(lastIndex).trim();
      if (trailingText.isNotEmpty) {
        children.add(const SizedBox(height: 10));
        children.add(Text(
          trailingText,
          style: MomoTypography.bodyMedium.copyWith(
            color: MomoColors.textPrimary,
            height: 1.6,
          ),
        ));
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

/// Collapsible, glowing terminal card reflecting ReAct status logs.
class ThinkingTerminal extends StatefulWidget {
  final List<AgentStep> steps;
  const ThinkingTerminal({super.key, required this.steps});

  @override
  State<ThinkingTerminal> createState() => _ThinkingTerminalState();
}

class _ThinkingTerminalState extends State<ThinkingTerminal> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    if (widget.steps.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF070714),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: MomoColors.primary.withValues(alpha: 0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: MomoColors.primary.withValues(alpha: 0.1),
            blurRadius: 12,
            spreadRadius: 2,
          )
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: MomoColors.surfaceLight.withValues(alpha: 0.3),
              child: Row(
                children: [
                  const Icon(Icons.terminal_rounded, color: MomoColors.primary, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Thinking Terminal',
                    style: MomoTypography.code.copyWith(
                      color: MomoColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: MomoColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'RE-ACT LOOP',
                      style: MomoTypography.labelSmall.copyWith(
                        color: MomoColors.primary,
                        fontSize: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: MomoColors.primary,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Container(
              constraints: const BoxConstraints(maxHeight: 250),
              padding: const EdgeInsets.all(12),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: widget.steps.length,
                itemBuilder: (context, idx) {
                  final step = widget.steps[idx];
                  Color bulletColor = MomoColors.primary;
                  if (step.type == 'action') bulletColor = MomoColors.accent;
                  if (step.type == 'observation') bulletColor = MomoColors.info;
                  if (step.type == 'error') bulletColor = MomoColors.error;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '» ',
                              style: MomoTypography.code.copyWith(
                                color: bulletColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '[${step.title}]',
                                style: MomoTypography.code.copyWith(
                                  color: bulletColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 14, top: 2, bottom: 6),
                          child: Text(
                            step.content,
                            style: MomoTypography.code.copyWith(
                              color: MomoColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}
