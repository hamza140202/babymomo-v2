import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../../momo_ui/theme/momo_theme.dart';
import '../../services/download_notification_service.dart';
import '../model_hub/models/app_model_item.dart';
import '../chat/engine/momo_chat_engine.dart';

/// Global controller managing app navigation, active companion model, and downloads.
class NavigationController extends GetxController {
  final RxInt currentIndex = 0.obs;
  final RxBool isDarkMode = true.obs;

  // ── Active Model State ──
  final Rxn<AppModelItem> activeModel = Rxn<AppModelItem>();
  final Rxn<AppModelItem> activeImageModel = Rxn<AppModelItem>();
  final RxBool isLoadingModel = false.obs;

  // ── Models Catalog ──
  late final List<AppModelItem> allModels;

  // ── Chat State ──
  final RxList<Map<String, dynamic>> chatMessages = <Map<String, dynamic>>[
    {
      'role': 'momo',
      'content':
          'Hey there! 👋 I\'m Babymomo — your living AI companion. I\'m here to chat, remember everything you tell me as your second brain, and create with you. What\'s on your mind today? 💜',
      'image': null,
    }
  ].obs;
  final RxBool isTyping = false.obs;
  final RxString streamBuffer = ''.obs;

  @override
  void onInit() {
    super.onInit();
    allModels = AppModelItem.getDefaultCatalog();
    DownloadNotificationService.initialize();
    _checkLocalFiles();
  }

  Future<void> _checkLocalFiles() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      for (final model in allModels) {
        final file = File('${dir.path}/${model.id}.bin');
        final exists = await file.exists();
        model.isDownloaded.value = exists;
        if (exists) {
          if (activeModel.value == null && model.type == 'Text LLM') {
            activeModel.value = model;
          }
          // Auto-load first downloaded diffusion model for Studio
          // Prefer LCM models for fastest 4-step turbo generation (local-dream)
          if (activeImageModel.value == null && model.type == 'Image Diffusion') {
            activeImageModel.value = model;
          } else if (model.type == 'Image Diffusion' &&
              activeImageModel.value != null &&
              !activeImageModel.value!.name.toLowerCase().contains('lcm') &&
              model.name.toLowerCase().contains('lcm')) {
            // Auto-prefer LCM model over standard if both are downloaded
            activeImageModel.value = model;
          }
        }
      }
    } catch (_) {}
  }

  // ─── Resumable Chunked Downloader ─────────────────────────────────────────
  Future<void> startDownload(AppModelItem model) async {
    if (model.isDownloading.value) return;

    model.isDownloading.value = true;
    model.isPaused.value = false;
    model.statusMessage.value = 'Connecting...';

    // Start Android Foreground Service so download never suspends in background
    await DownloadNotificationService.startBackgroundExecution(model.name);

    final dir = await getApplicationDocumentsDirectory();
    final tempPath = '${dir.path}/${model.id}.tmp';
    final finalPath = '${dir.path}/${model.id}.bin';

    int retryCount = 0;
    const maxRetries = 8;

    while (retryCount <= maxRetries) {
      final tempFile = File(tempPath);
      int downloadedBytes = 0;

      if (await tempFile.exists()) {
        downloadedBytes = await tempFile.length();
      }

      final cancelToken = model.createCancelToken();

      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(minutes: 60),
        sendTimeout: const Duration(seconds: 30),
      ));

      try {
        final initialMb = (downloadedBytes / (1024 * 1024)).toStringAsFixed(1);
        model.statusMessage.value = downloadedBytes > 0
            ? 'Resuming from $initialMb MB...'
            : 'Connecting to server...';

        await DownloadNotificationService.showProgress(
          id: model.notifId,
          modelName: model.name,
          progress: (model.downloadProgress.value * 100).toInt(),
          statusText: model.statusMessage.value,
        );

        final response = await dio.get<ResponseBody>(
          model.url,
          cancelToken: cancelToken,
          options: Options(
            responseType: ResponseType.stream,
            followRedirects: true,
            headers: {
              if (downloadedBytes > 0) 'Range': 'bytes=$downloadedBytes-',
              'User-Agent': 'Mozilla/5.0 (Android; Mobile; Babymomo/2.0)',
            },
          ),
        );

        final contentLength =
            int.tryParse(response.headers.value('content-length') ?? '0') ?? 0;
        final totalBytes = downloadedBytes + contentLength;

        final sink = tempFile.openWrite(mode: FileMode.append);
        int currentBytes = downloadedBytes;
        int lastNotifUpdate = -1;
        DateTime lastNotifTime = DateTime.now();
        DateTime lastSpeedCheck = DateTime.now();
        int bytesSinceLastSpeedCheck = 0;
        String speedText = '';

        await response.data!.stream.listen((chunk) {
          currentBytes += chunk.length;
          bytesSinceLastSpeedCheck += chunk.length;
          sink.add(chunk);

          final progress = totalBytes > 0 ? currentBytes / totalBytes : 0.0;
          model.downloadProgress.value = progress;

          final now = DateTime.now();
          final elapsedMs = now.difference(lastSpeedCheck).inMilliseconds;
          if (elapsedMs >= 600) {
            final speedBytesPerSec =
                (bytesSinceLastSpeedCheck * 1000) / elapsedMs;
            final speedMBps = speedBytesPerSec / (1024 * 1024);
            speedText = '${speedMBps.toStringAsFixed(1)} MB/s';
            bytesSinceLastSpeedCheck = 0;
            lastSpeedCheck = now;
          }

          final mbDone = (currentBytes / (1024 * 1024)).toStringAsFixed(1);
          final mbTotal = (totalBytes / (1024 * 1024)).toStringAsFixed(1);
          model.statusMessage.value = speedText.isNotEmpty
              ? '$mbDone / $mbTotal MB ($speedText)'
              : '$mbDone / $mbTotal MB';

          final pct = (progress * 100).toInt();
          if (pct != lastNotifUpdate &&
              (now.difference(lastNotifTime).inMilliseconds >= 400 ||
                  pct == 100)) {
            lastNotifUpdate = pct;
            lastNotifTime = now;
            DownloadNotificationService.showProgress(
              id: model.notifId,
              modelName: model.name,
              progress: pct,
              statusText: model.statusMessage.value,
            );
          }
        }, cancelOnError: true).asFuture();

        await sink.flush();
        await sink.close();

        // Rename temp → final
        if (await File(finalPath).exists()) await File(finalPath).delete();
        await tempFile.rename(finalPath);

        model.isDownloaded.value = true;
        model.isDownloading.value = false;
        model.isPaused.value = false;
        model.statusMessage.value = 'Installed';
        model.downloadProgress.value = 1.0;

        await DownloadNotificationService.stopBackgroundExecution();

        DownloadNotificationService.showProgress(
          id: model.notifId,
          modelName: model.name,
          progress: 100,
          statusText: 'Complete',
          isDone: true,
        );

        // Auto-load model if it's the user's first text model
        if (model.type == 'Text LLM' && activeModel.value == null) {
          loadModelForChat(model, notify: false);
        }

        Get.snackbar(
          '✅ Download Complete',
          '${model.name.split('(').first.trim()} is installed & ready!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF10B981),
          colorText: Colors.white,
          duration: const Duration(seconds: 4),
        );
        return;
      } on DioException catch (e) {
        if (e.type == DioExceptionType.cancel) {
          model.isDownloading.value = false;
          model.isPaused.value = true;
          model.statusMessage.value =
              'Paused at ${(model.downloadProgress.value * 100).toStringAsFixed(0)}%';
          await DownloadNotificationService.stopBackgroundExecution();
          DownloadNotificationService.showProgress(
            id: model.notifId,
            modelName: model.name,
            progress: (model.downloadProgress.value * 100).toInt(),
            statusText: model.statusMessage.value,
            isPaused: true,
          );
          return;
        }

        retryCount++;
        final waitSecs = retryCount * 3;
        model.statusMessage.value =
            'Network hiccup — retrying in ${waitSecs}s ($retryCount/$maxRetries)...';

        DownloadNotificationService.showProgress(
          id: model.notifId,
          modelName: model.name,
          progress: (model.downloadProgress.value * 100).toInt(),
          statusText: model.statusMessage.value,
        );

        if (retryCount > maxRetries) break;
        await Future.delayed(Duration(seconds: waitSecs));
      } catch (e) {
        retryCount++;
        if (retryCount > maxRetries) break;
        await Future.delayed(const Duration(seconds: 4));
      }
    }

    model.isDownloading.value = false;
    model.isPaused.value = true;
    model.statusMessage.value = 'Check network & tap Resume';
    await DownloadNotificationService.stopBackgroundExecution();
    DownloadNotificationService.showProgress(
      id: model.notifId,
      modelName: model.name,
      progress: (model.downloadProgress.value * 100).toInt(),
      statusText: 'Network unavailable. Tap Resume inside Babymomo.',
      isPaused: true,
    );

    Get.snackbar(
      '📶 Network Disconnected',
      'Download paused with progress saved. Tap Resume when reconnected.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: MomoColors.amber,
      colorText: Colors.white,
      duration: const Duration(seconds: 5),
    );
  }

  void pauseDownload(AppModelItem model) {
    model.cancelDownload();
    DownloadNotificationService.stopBackgroundExecution();
  }

  void stopDownload(AppModelItem model) async {
    model.cancelDownload();
    await Future.delayed(const Duration(milliseconds: 300));
    model.isDownloading.value = false;
    model.isPaused.value = false;
    model.downloadProgress.value = 0.0;
    model.statusMessage.value = '';
    DownloadNotificationService.cancel(model.notifId);

    try {
      final dir = await getApplicationDocumentsDirectory();
      final tempFile = File('${dir.path}/${model.id}.tmp');
      if (await tempFile.exists()) await tempFile.delete();
    } catch (_) {}

    Get.snackbar(
      'Download Stopped',
      '${model.name.split('(').first.trim()} download cancelled.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: MomoColors.textSecondary,
      colorText: Colors.white,
    );
  }

  // ─── Chat Actions ─────────────────────────────────────────────────────────
  Future<void> sendChat(String text, {File? imageFile}) async {
    if (text.trim().isEmpty && imageFile == null) return;
    if (isTyping.value) return;

    chatMessages.add({
      'role': 'user',
      'content': text.trim().isNotEmpty ? text.trim() : 'Analyse this image for me 📸',
      'image': imageFile?.path,
    });

    isTyping.value = true;
    streamBuffer.value = '';

    chatMessages.add({'role': 'momo', 'content': '__typing__', 'image': null});

    final input = imageFile != null
        ? 'Image attached. ${text.trim()}'
        : text.trim();

    try {
      await for (final partial in MomoChatEngine.respond(
        text.trim(),
        activeModelName: activeModel.value?.name,
        imagePath: imageFile?.path,
        isVision: activeModel.value?.isVision ?? false,
      )) {
        streamBuffer.value = partial;
        chatMessages[chatMessages.length - 1] = {
          'role': 'momo',
          'content': partial,
          'image': null,
        };
      }
    } finally {
      isTyping.value = false;
    }
  }

  Future<void> loadModelForChat(AppModelItem model, {bool notify = true}) async {
    if (!model.isDownloaded.value) return;
    if (activeModel.value?.id == model.id) {
      if (notify) {
        Get.snackbar(
          'Already Active 🧠',
          '${model.name.split('(').first.trim()} is already your active brain model!',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF10B981),
          colorText: Colors.white,
        );
      }
      return;
    }

    isLoadingModel.value = true;
    await Future.delayed(const Duration(milliseconds: 600));
    activeModel.value = model;
    isLoadingModel.value = false;

    chatMessages.add({
      'role': 'momo',
      'content':
          'I\'ve loaded ${model.name.split('(').first.trim()} as my active brain! 🧠✨ My memory and reasoning are fully primed. What shall we explore?',
      'image': null,
    });

    currentIndex.value = 1;

    if (notify) {
      Get.snackbar(
        '🧠 Brain Model Loaded!',
        '${model.name.split('(').first.trim()} is active. Let\'s chat!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: MomoColors.primary,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  Future<void> loadModelForStudio(AppModelItem model, {bool notify = true}) async {
    if (!model.isDownloaded.value) return;
    activeImageModel.value = model;
    currentIndex.value = 2; // Switch to Studio tab

    if (notify) {
      Get.snackbar(
        '🎨 Diffusion Model Loaded!',
        '${model.name.split('(').first.trim()} active in Studio.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: MomoColors.rose,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  void clearChat() {
    chatMessages.clear();
    chatMessages.add({
      'role': 'momo',
      'content': 'Fresh start! 🌟 I\'m right here whenever you\'re ready.',
      'image': null,
    });
  }

  void toggleTheme() {
    isDarkMode.value = !isDarkMode.value;
    Get.changeTheme(
        isDarkMode.value ? MomoTheme.darkTheme : MomoTheme.lightTheme);
  }

  void changeTab(int index) => currentIndex.value = index;
}
