import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import '../../../momo_core/momo_core.dart';

enum ImageGenStatus { idle, generating, success, error }

class ImageGenController extends GetxController {
  final StorageService _storage = Get.find<StorageService>();
  final InferenceRouter _router = Get.find<InferenceRouter>();

  final promptController = TextEditingController();
  final negativePromptController = TextEditingController();

  final selectedAspect = 'square'.obs; // square (1:1), landscape (16:9), portrait (9:16)
  final steps = 20.obs;
  final cfgScale = 7.5.obs;
  final seed = RxnInt();

  final progress = 0.0.obs;
  final status = ImageGenStatus.idle.obs;
  final generatedImagePath = RxnString();
  final history = <Map<String, String>>[].obs;
  final errorMessage = ''.obs;

  Timer? _progressTimer;

  @override
  void onInit() {
    super.onInit();
    _loadHistory();
  }

  @override
  void onClose() {
    promptController.dispose();
    negativePromptController.dispose();
    _progressTimer?.cancel();
    super.onClose();
  }

  void selectAspect(String aspect) {
    selectedAspect.value = aspect;
  }

  Future<void> _loadHistory() async {
    try {
      final stored = await _storage.get<List<dynamic>>(StorageBoxes.settings, 'image_history');
      if (stored != null) {
        history.value = stored.map((item) => Map<String, String>.from(item)).toList();
      }
    } catch (_) {
      // Gracefully ignore history load errors
    }
  }

  Future<void> _saveHistory() async {
    try {
      await _storage.put(StorageBoxes.settings, 'image_history', history.toList());
    } catch (_) {}
  }

  Future<void> generateImage() async {
    final prompt = promptController.text.trim();
    if (prompt.isEmpty) {
      Get.snackbar(
        'Required',
        'Please enter a detailed prompt to create an image.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
      return;
    }

    status.value = ImageGenStatus.generating;
    progress.value = 0.0;
    generatedImagePath.value = null;
    errorMessage.value = '';

    // Animate progress simulation to 90% while native code processes
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (progress.value < 0.90) {
        progress.value += 0.05;
      } else {
        timer.cancel();
      }
    });

    int width = 512;
    int height = 512;
    if (selectedAspect.value == 'landscape') {
      width = 768;
      height = 432;
    } else if (selectedAspect.value == 'portrait') {
      width = 432;
      height = 768;
    }

    try {
      final reqId = const Uuid().v4();
      final request = InferenceRequest(
        id: reqId,
        prompt: prompt,
        modality: Modality.image,
        parameters: InferenceParameters(
          steps: steps.value,
          cfgScale: cfgScale.value,
          width: width,
          height: height,
          negativePrompt: negativePromptController.text.trim(),
          seed: seed.value,
        ),
      );

      String? resultPath;
      final completer = Completer<String>();

      _router.route(request).listen(
        (result) {
          if (result.isError) {
            completer.completeError(result.content);
          } else if (result.content.isNotEmpty && !result.isDone) {
            resultPath = result.content;
          }
        },
        onError: (err) {
          if (!completer.isCompleted) completer.completeError(err);
        },
        onDone: () {
          if (!completer.isCompleted) {
            if (resultPath != null) {
              completer.complete(resultPath!);
            } else {
              completer.completeError('Generation completed but no path was returned.');
            }
          }
        },
        cancelOnError: true,
      );

      final finalPath = await completer.future;

      _progressTimer?.cancel();
      progress.value = 1.0;
      generatedImagePath.value = finalPath;
      status.value = ImageGenStatus.success;

      // Add to history
      final newItem = {
        'path': finalPath,
        'prompt': prompt,
        'aspect': selectedAspect.value,
        'timestamp': DateTime.now().toIso8601String(),
      };
      history.insert(0, newItem);
      await _saveHistory();

    } catch (e) {
      _progressTimer?.cancel();
      errorMessage.value = e.toString();
      status.value = ImageGenStatus.error;
      Get.snackbar(
        'Generation Failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    }
  }

  Future<void> saveToGallery() async {
    final path = generatedImagePath.value;
    if (path == null) return;

    try {
      final file = File(path);
      if (!await file.exists()) {
        Get.snackbar('Error', 'File does not exist.');
        return;
      }

      // Procedural Permanent Saver
      // Copies the cached image to the app document directory
      final appDocDir = await getApplicationDocumentsDirectory();
      final targetDir = Directory('${appDocDir.path}/MOMO_Saved');
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      final fileName = 'MOMO_${DateTime.now().millisecondsSinceEpoch}.png';
      final newFile = await file.copy('${targetDir.path}/$fileName');

      Get.snackbar(
        'Saved Successfully',
        'Image exported to local documents:\n${newFile.path}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withValues(alpha: 0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      Get.snackbar('Save Failed', 'Could not export file: $e');
    }
  }

  void clearHistory() async {
    history.clear();
    await _storage.delete(StorageBoxes.settings, 'image_history');
    Get.snackbar('Cleared', 'History successfully deleted.');
  }
}
