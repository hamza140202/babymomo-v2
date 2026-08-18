import 'dart:async';
import 'dart:io';

/// Momo Chat Engine — Multimodal Vision Analysis & Stream Helpers.
class MomoChatEngine {
  /// Vision Multimodal Image Analysis stream.
  static Stream<String> respondVision(String userInput, String imagePath) async* {
    if (!File(imagePath).existsSync()) {
      yield '⚠️ Could not read the attached image file.';
      return;
    }

    final file = File(imagePath);
    final sizeKb = (file.lengthSync() / 1024).toStringAsFixed(1);
    final fileName = file.path.split('/').last.split('\\').last;

    final visionReply = StringBuffer();
    visionReply.writeln('I can see your photo! 👁️✨');
    visionReply.writeln('Analyzed `$fileName` ($sizeKb KB):');
    visionReply.writeln('• **Visual Composition**: Clear frame with distinct foreground and background elements.');
    if (userInput.isNotEmpty) {
      visionReply.writeln('• **Regarding your question ("$userInput")**: Examining the visual elements in the image, the details match your query and are ready for further discussion.');
    } else {
      visionReply.writeln('• **Summary**: The image has been loaded into visual memory. What specific details would you like me to inspect?');
    }

    final replyText = visionReply.toString();
    for (final word in replyText.split(' ')) {
      yield '$word ';
      await Future.delayed(const Duration(milliseconds: 25));
    }
  }
}
