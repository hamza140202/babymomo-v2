import 'package:flutter/material.dart';
import '../theme/momo_colors.dart';
import '../theme/momo_typography.dart';

/// MOMO UI — AI Card Widget.
///
/// A premium, glassmorphism-styled card for displaying AI content.
/// Used throughout the app for messages, suggestions, actions.
/// Per MINDUSAGE.md: soft, cinematic, tactile.
class AICard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final LinearGradient? gradient;
  final bool elevated;
  final VoidCallback? onTap;

  const AICard({
    super.key,
    required this.child,
    this.padding,
    this.gradient,
    this.elevated = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: elevated ? MomoColors.surfaceLight : MomoColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: MomoColors.surfaceBright.withValues(alpha: 0.5),
            width: 1,
          ),
          gradient: gradient,
          boxShadow: elevated
              ? [
                  BoxShadow(
                    color: MomoColors.primary.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: child,
      ),
    );
  }

  /// Factory: User message card (right-aligned, gradient).
  factory AICard.userMessage({
    required Widget child,
    VoidCallback? onTap,
  }) {
    return AICard(
      gradient: LinearGradient(
        colors: [
          MomoColors.primary.withValues(alpha: 0.15),
          MomoColors.primary.withValues(alpha: 0.05),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      onTap: onTap,
      child: child,
    );
  }

  /// Factory: Assistant message card (neutral surface).
  factory AICard.assistantMessage({
    required Widget child,
    VoidCallback? onTap,
  }) {
    return AICard(
      onTap: onTap,
      child: child,
    );
  }

  /// Factory: Action card with icon and label.
  factory AICard.action({
    required IconData icon,
    required String label,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return AICard(
      elevated: true,
      onTap: onTap,
      child: Row(
        children: [
          ShaderMask(
            shaderCallback: (bounds) =>
                MomoColors.primaryGradient.createShader(bounds),
            child: Icon(icon, size: 24, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: MomoTypography.labelLarge.copyWith(
                    color: MomoColors.textPrimary,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: MomoTypography.bodySmall.copyWith(
                      color: MomoColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: MomoColors.textMuted,
            size: 20,
          ),
        ],
      ),
    );
  }
}
