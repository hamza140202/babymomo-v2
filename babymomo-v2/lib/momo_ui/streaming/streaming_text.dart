import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../momo_core/inference/inference_result.dart';
import '../theme/momo_colors.dart';
import '../theme/momo_typography.dart';

/// MOMO UI — Streaming Text Widget.
///
/// Renders inference results token-by-token with smooth animation.
/// Designed for emotional, living-feeling text that appears organically
/// rather than clinical terminal-style rendering.
class StreamingText extends StatefulWidget {
  /// The stream of inference results to render.
  final Stream<InferenceResult>? stream;

  /// Pre-populated text (for completed messages).
  final String? initialText;

  /// Text style override.
  final TextStyle? style;

  /// Called when streaming completes.
  final ValueChanged<String>? onComplete;

  /// Called when an error occurs.
  final ValueChanged<String>? onError;

  const StreamingText({
    super.key,
    this.stream,
    this.initialText,
    this.style,
    this.onComplete,
    this.onError,
  });

  @override
  State<StreamingText> createState() => _StreamingTextState();
}

class _StreamingTextState extends State<StreamingText> {
  final StringBuffer _buffer = StringBuffer();
  bool _isStreaming = false;
  bool _isDone = false;
  InferenceMetrics? _metrics;

  @override
  void initState() {
    super.initState();
    if (widget.initialText != null) {
      _buffer.write(widget.initialText);
      _isDone = true;
    }
    if (widget.stream != null) {
      _startListening();
    }
  }

  @override
  void didUpdateWidget(StreamingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.stream != oldWidget.stream && widget.stream != null) {
      _buffer.clear();
      _isDone = false;
      _startListening();
    }
  }

  void _startListening() {
    _isStreaming = true;
    widget.stream!.listen(
      (result) {
        if (result.isError) {
          setState(() {
            _isStreaming = false;
            _isDone = true;
          });
          widget.onError?.call(result.error!);
          return;
        }

        if (result.isDone) {
          setState(() {
            _isStreaming = false;
            _isDone = true;
            _metrics = result.metrics;
          });
          widget.onComplete?.call(_buffer.toString());
          return;
        }

        setState(() {
          _buffer.write(result.content);
        });
      },
      onError: (error) {
        setState(() {
          _isStreaming = false;
          _isDone = true;
        });
        widget.onError?.call(error.toString());
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = _buffer.toString();
    final textStyle = widget.style ??
        MomoTypography.bodyLarge.copyWith(
          color: MomoColors.textPrimary,
          height: 1.6,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main text content
        if (text.isNotEmpty)
          SelectableText(
            text,
            style: textStyle,
          ),

        // Typing indicator while streaming
        if (_isStreaming && !_isDone)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: _TypingCursor(),
          ),

        // Performance metrics (subtle, non-intrusive)
        if (_isDone && _metrics != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${_metrics!.tokensPerSecond.toStringAsFixed(1)} tok/s',
              style: MomoTypography.labelSmall.copyWith(
                color: MomoColors.textMuted.withValues(alpha: 0.5),
              ),
            ),
          ).animate().fadeIn(duration: 300.ms),
      ],
    );
  }
}

/// Soft pulsing cursor — feels alive, not mechanical.
class _TypingCursor extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: MomoColors.primary.withValues(alpha: 0.7),
            shape: BoxShape.circle,
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(
              begin: const Offset(0.6, 0.6),
              end: const Offset(1.0, 1.0),
              duration: 600.ms,
              delay: Duration(milliseconds: index * 150),
              curve: Curves.easeInOut,
            )
            .fadeIn(
              duration: 400.ms,
              delay: Duration(milliseconds: index * 150),
            );
      }),
    );
  }
}
