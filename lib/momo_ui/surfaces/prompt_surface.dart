import 'package:flutter/material.dart';
import '../theme/momo_colors.dart';
import '../theme/momo_typography.dart';
import '../motion/motion_engine.dart';

/// MOMO UI — Prompt Surface Widget.
///
/// The main text input area where users compose messages.
/// Designed to feel soft, inviting, and not like a terminal.
/// Per MINDUSAGE.md: tactile, emotionally warm.
class PromptSurface extends StatefulWidget {
  final ValueChanged<String> onSubmit;
  final VoidCallback? onCancel;
  final bool isGenerating;
  final String? hintText;

  const PromptSurface({
    super.key,
    required this.onSubmit,
    this.onCancel,
    this.isGenerating = false,
    this.hintText,
  });

  @override
  State<PromptSurface> createState() => _PromptSurfaceState();
}

class _PromptSurfaceState extends State<PromptSurface>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _hasText = false;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final hasText = _controller.text.trim().isNotEmpty;
      if (hasText != _hasText) {
        setState(() => _hasText = hasText);
      }
    });

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSubmit(text);
    _controller.clear();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          decoration: BoxDecoration(
            color: MomoColors.surface,
            border: Border(
              top: BorderSide(
                color: widget.isGenerating
                    ? Color.lerp(
                        MomoColors.surfaceLight,
                        MomoColors.primary.withValues(alpha: 0.5),
                        _glowAnimation.value,
                      )!
                    : MomoColors.surfaceLight,
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Text input
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 120),
                    decoration: BoxDecoration(
                      color: MomoColors.surfaceLight,
                      borderRadius:
                          BorderRadius.circular(MomoMotion.radiusLarge),
                    ),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      maxLines: null,
                      enabled: !widget.isGenerating,
                      style: MomoTypography.bodyMedium.copyWith(
                        color: MomoColors.textPrimary,
                      ),
                      decoration: InputDecoration(
                        hintText:
                            widget.hintText ?? 'Ask me anything...',
                        hintStyle: MomoTypography.bodyMedium.copyWith(
                          color: MomoColors.textMuted,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _handleSubmit(),
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Send / Cancel button
                AnimatedSwitcher(
                  duration: MomoMotion.fast,
                  child: widget.isGenerating
                      ? _ActionButton(
                          key: const ValueKey('cancel'),
                          icon: Icons.stop_rounded,
                          onPressed: widget.onCancel,
                          isActive: true,
                          isCancel: true,
                        )
                      : _ActionButton(
                          key: const ValueKey('send'),
                          icon: Icons.arrow_upward_rounded,
                          onPressed: _hasText ? _handleSubmit : null,
                          isActive: _hasText,
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isActive;
  final bool isCancel;

  const _ActionButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.isActive = false,
    this.isCancel = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: MomoMotion.fast,
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: isActive
              ? (isCancel
                  ? const LinearGradient(
                      colors: [Color(0xFFFF5252), Color(0xFFD32F2F)])
                  : MomoColors.primaryGradient)
              : null,
          color: isActive ? null : MomoColors.surfaceLight,
          borderRadius: BorderRadius.circular(MomoMotion.radiusMedium),
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : MomoColors.textMuted,
          size: 22,
        ),
      ),
    );
  }
}
