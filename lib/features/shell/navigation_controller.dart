import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../momo_core/momo_core.dart';
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
    final trimmed = text.trim();
    if (trimmed.isEmpty && imageFile == null) return;
    if (isTyping.value) return;

    chatMessages.add({
      'role': 'user',
      'content': trimmed.isNotEmpty ? trimmed : 'Analyse this image for me 📸',
      'image': imageFile?.path,
    });

    isTyping.value = true;
    streamBuffer.value = '';

    chatMessages.add({'role': 'momo', 'content': '__typing__', 'image': null});
    final lastIndex = chatMessages.length - 1;

    try {
      // 1. Vision Multimodal Analysis
      if (imageFile != null) {
        await for (final partial in MomoChatEngine.respondVision(trimmed, imageFile.path)) {
          streamBuffer.value = partial;
          chatMessages[lastIndex] = {
            'role': 'momo',
            'content': partial,
            'image': null,
          };
        }
        return;
      }

      // 2. On-Device Model Inference
      final currentModel = activeModel.value;
      if (currentModel == null) {
        chatMessages[lastIndex] = {
          'role': 'momo',
          'content':
              '⚠️ **No Brain Model Loaded**\n\nPlease switch to the **Hub** tab to download and activate an on-device model (such as Llama 3.2, Qwen 2.5, or DeepSeek R1)! 🧠✨',
          'image': null,
        };
        return;
      }

      final dir = await getApplicationDocumentsDirectory();
      final modelFile = File('${dir.path}/${currentModel.id}.bin');
      if (!await modelFile.exists()) {
        chatMessages[lastIndex] = {
          'role': 'momo',
          'content':
              '⚠️ **Model File Missing**\n\nThe local binary file for ${currentModel.name} was not found on device storage. Please redownload it from the **Hub** tab.',
          'image': null,
        };
        return;
      }

      // Ensure inference runtime engines are initialized
      final (:registry, :router) = _ensureInferenceEngines();
      final localAdapter = registry.resolve('llama_cpp') as LlamaCppAdapter?;
      if (localAdapter != null && localAdapter.loadedModelPath != modelFile.path) {
        await localAdapter.loadModel(modelFile.path);
      }

      // Build contextual messages
      final contextList = <ContextMessage>[
        ContextMessage(
          role: 'system',
          content: 'You are Babymomo, a friendly, intelligent on-device AI companion.',
          timestamp: DateTime.now(),
        ),
      ];

      // Append recent history
      final historySlice = chatMessages.take(chatMessages.length - 2).toList();
      for (final msg in historySlice.reversed.take(6).toList().reversed) {
        if (msg['role'] == 'user' || msg['role'] == 'momo') {
          contextList.add(ContextMessage(
            role: msg['role'] == 'user' ? 'user' : 'assistant',
            content: msg['content']?.toString() ?? '',
            timestamp: DateTime.now(),
          ));
        }
      }

      final reqId = const Uuid().v4();
      final request = InferenceRequest(
        id: reqId,
        prompt: trimmed,
        systemPrompt: 'You are Babymomo, a friendly, intelligent on-device AI companion.',
        context: contextList,
        modality: Modality.text,
        parameters: const InferenceParameters(
          temperature: 0.7,
          maxTokens: 512,
        ),
      );

      final stream = router.route(request);

      final tokenBuffer = StringBuffer();
      await for (final res in stream) {
        if (res.isError) {
          tokenBuffer.write('\n\n*(Inference error: ${res.error})*');
          chatMessages[lastIndex] = {
            'role': 'momo',
            'content': tokenBuffer.toString(),
            'image': null,
          };
          break;
        }

        tokenBuffer.write(res.content);
        streamBuffer.value = tokenBuffer.toString();
        chatMessages[lastIndex] = {
          'role': 'momo',
          'content': tokenBuffer.toString(),
          'image': null,
        };

        if (res.isDone) break;
      }
    } catch (e) {
      chatMessages[lastIndex] = {
        'role': 'momo',
        'content': '❌ Error during local inference: $e',
        'image': null,
      };
    } finally {
      isTyping.value = false;
    }
  }

  ({RuntimeRegistry registry, InferenceRouter router}) _ensureInferenceEngines() {
    RuntimeRegistry registry;
    if (Get.isRegistered<RuntimeRegistry>()) {
      registry = Get.find<RuntimeRegistry>();
    } else {
      registry = RuntimeRegistry();
      Get.put<RuntimeRegistry>(registry, permanent: true);
    }

    if (registry.resolve('llama_cpp') == null) {
      final localAdapter = LlamaCppAdapter();
      localAdapter.initialize(const RuntimeConfig(contextLength: 2048, useGPU: true));
      registry.register(localAdapter);
    }

    InferenceRouter router;
    if (Get.isRegistered<InferenceRouter>()) {
      router = Get.find<InferenceRouter>();
    } else {
      router = InferenceRouter(registry: registry);
      Get.put<InferenceRouter>(router, permanent: true);
    }

    return (registry: registry, router: router);
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
    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/${model.id}.bin';

      final (:registry, router: _) = _ensureInferenceEngines();
      final localAdapter = registry.resolve('llama_cpp') as LlamaCppAdapter?;
      if (localAdapter != null) {
        await localAdapter.loadModel(filePath);
      }

      activeModel.value = model;

      chatMessages.add({
        'role': 'momo',
        'content':
            'I\'ve loaded ${model.name.split('(').first.trim()} as my active brain! 🧠✨ My on-device neural core is fully primed. What shall we explore?',
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
    } catch (e) {
      Get.snackbar(
        'Model Load Error',
        'Could not initialize local model: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: MomoColors.rose,
        colorText: Colors.white,
      );
    } finally {
      isLoadingModel.value = false;
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
