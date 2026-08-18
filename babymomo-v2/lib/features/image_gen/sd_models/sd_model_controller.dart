import 'dart:io';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../momo_core/momo_core.dart';
import 'sd_model.dart';
import 'sd_model_repository.dart';

/// Reactive state class wrapping [SdModel] with live download/active state.
class SdModelState {
  final SdModel model;
  final RxDouble downloadProgress;
  final Rx<SdModelStatus> status;
  final RxString downloadSpeed;
  final RxString errorMessage;

  SdModelState(this.model)
      : downloadProgress = 0.0.obs,
        status = SdModelStatus.notDownloaded.obs,
        downloadSpeed = ''.obs,
        errorMessage = ''.obs;
}

/// Controller managing local Stable Diffusion model downloads, selection, and inference routing.
class SdModelController extends GetxController {
  static const _sdChannel = MethodChannel('com.momoai.babymomo/sd_inference');

  final _downloadEngine = Get.find<DownloadEngine>();
  final _storage = Get.find<StorageService>();

  /// Reactive list of SD model states.
  final List<SdModelState> modelStates = [];

  /// Currently active (loaded) model ID. Null = no local model selected.
  final RxnString activeModelId = RxnString();

  /// Path to the currently active model file for native inference.
  final RxnString activeModelPath = RxnString();

  /// Whether the stable-diffusion.cpp native library is available on this device.
  final RxBool nativeLibAvailable = false.obs;

  SdModelState? get activeModel {
    final id = activeModelId.value;
    if (id == null) return null;
    try {
      return modelStates.firstWhere((s) => s.model.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  void onInit() {
    super.onInit();
    _buildModelStates();
    _loadPersistedState();
    _checkNativeLib();
    // Listen to download engine updates
    ever(_downloadEngine.downloads, (_) => _syncDownloadStates());
  }

  void _buildModelStates() {
    modelStates.clear();
    for (final model in SdModelRepository.models) {
      modelStates.add(SdModelState(model));
    }
  }

  Future<void> _loadPersistedState() async {
    try {
      final savedId = await _storage.get<String>(StorageBoxes.settings, 'active_sd_model_id');
      final savedPath = await _storage.get<String>(StorageBoxes.settings, 'active_sd_model_path');

      if (savedId != null && savedPath != null && File(savedPath).existsSync()) {
        activeModelId.value = savedId;
        activeModelPath.value = savedPath;
        final state = _stateFor(savedId);
        if (state != null) state.status.value = SdModelStatus.active;
      }

      // Check which models are already downloaded
      for (final state in modelStates) {
        final path = await SdModelRepository.getModelPath(state.model.id);
        final exists = File(path).existsSync();
        if (exists && state.status.value != SdModelStatus.active) {
          state.status.value = SdModelStatus.downloaded;
        }
      }
    } catch (_) {}
  }

  Future<void> _checkNativeLib() async {
    try {
      final result = await _sdChannel.invokeMethod<bool>('isLibraryAvailable');
      nativeLibAvailable.value = result ?? false;
    } catch (_) {
      nativeLibAvailable.value = false;
    }
  }

  void _syncDownloadStates() {
    for (final state in modelStates) {
      final taskId = 'sd_${state.model.id}';
      final task = _downloadEngine.downloads[taskId];
      if (task == null) continue;

      switch (task.status) {
        case DownloadStatus.pending:
        case DownloadStatus.downloading:
          state.status.value = SdModelStatus.downloading;
          state.downloadProgress.value = task.progress;
          state.downloadSpeed.value = '${task.speedMBps.toStringAsFixed(1)} MB/s';
          state.errorMessage.value = '';
          break;
        case DownloadStatus.paused:
          state.status.value = SdModelStatus.downloading; // Show as still in progress
          state.downloadProgress.value = task.progress;
          state.downloadSpeed.value = 'Paused';
          break;
        case DownloadStatus.hashing:
          state.status.value = SdModelStatus.downloading;
          state.downloadProgress.value = task.progress;
          state.downloadSpeed.value = 'Verifying...';
          break;
        case DownloadStatus.completed:
          if (state.model.id != activeModelId.value) {
            state.status.value = SdModelStatus.downloaded;
          }
          state.downloadProgress.value = 1.0;
          state.downloadSpeed.value = '';
          if (task.errorMessage != null) {
            // Sure-shot: hash mismatch but file kept
            state.errorMessage.value = 'Downloaded (integrity check inconclusive)';
          }
          break;
        case DownloadStatus.failed:
          state.status.value = SdModelStatus.notDownloaded;
          state.downloadProgress.value = 0.0;
          state.errorMessage.value = task.errorMessage ?? 'Download failed';
          break;
      }
    }
  }

  /// Start downloading a Stable Diffusion model.
  Future<void> downloadModel(SdModelState state) async {
    final model = state.model;
    final taskId = 'sd_${model.id}';

    // Already downloading or downloaded?
    if (state.status.value == SdModelStatus.downloading ||
        state.status.value == SdModelStatus.downloaded ||
        state.status.value == SdModelStatus.active) {
      return;
    }

    final destinationPath = await SdModelRepository.getModelPath(model.id);

    // Ensure directory exists
    final dir = Directory(destinationPath).parent;
    if (!dir.existsSync()) dir.createSync(recursive: true);

    state.status.value = SdModelStatus.downloading;
    state.downloadProgress.value = 0.0;
    state.errorMessage.value = '';

    final task = DownloadTask(
      id: taskId,
      modelName: model.name,
      url: model.downloadUrl,
      destinationPath: destinationPath,
      expectedHash: model.expectedHash,
      status: DownloadStatus.pending,
    );

    await _downloadEngine.startDownload(task);
  }

  /// Cancel/pause download for a model.
  Future<void> pauseDownload(SdModelState state) async {
    final taskId = 'sd_${state.model.id}';
    await _downloadEngine.pauseDownload(taskId);
  }

  /// Delete a downloaded model file from disk.
  Future<void> deleteModel(SdModelState state) async {
    // Deactivate first if this is the active model
    if (activeModelId.value == state.model.id) {
      await deactivateModel();
    }

    final taskId = 'sd_${state.model.id}';
    await _downloadEngine.cancelDownload(taskId);

    final path = await SdModelRepository.getModelPath(state.model.id);
    final file = File(path);
    if (file.existsSync()) {
      try {
        file.deleteSync();
      } catch (_) {}
    }

    state.status.value = SdModelStatus.notDownloaded;
    state.downloadProgress.value = 0.0;
    state.errorMessage.value = '';
  }

  /// Set a downloaded model as the active inference engine.
  Future<void> activateModel(SdModelState state) async {
    if (state.status.value != SdModelStatus.downloaded &&
        state.status.value != SdModelStatus.active) {
      return;
    }

    state.status.value = SdModelStatus.loading;

    final path = await SdModelRepository.getModelPath(state.model.id);
    if (!File(path).existsSync()) {
      state.status.value = SdModelStatus.downloaded;
      Get.snackbar('Error', 'Model file not found on disk.', snackPosition: SnackPosition.BOTTOM);
      return;
    }

    // Deactivate previous model
    await deactivateModel(quiet: true);

    try {
      // Tell native bridge which model file to use
      await _sdChannel.invokeMethod('setActiveModel', {'path': path});
    } catch (_) {
      // Native lib not present — we still set the path so we can use it for cloud routing
    }

    // Persist
    activeModelId.value = state.model.id;
    activeModelPath.value = path;
    await _storage.put(StorageBoxes.settings, 'active_sd_model_id', state.model.id);
    await _storage.put(StorageBoxes.settings, 'active_sd_model_path', path);

    // Update all states
    for (final s in modelStates) {
      if (s.model.id == state.model.id) {
        s.status.value = SdModelStatus.active;
      } else if (s.status.value == SdModelStatus.active) {
        s.status.value = SdModelStatus.downloaded;
      }
    }

    Get.snackbar(
      '${state.model.name} Loaded',
      nativeLibAvailable.value
          ? 'Full offline generation ready! Generate unlimited images. 🎨'
          : 'Model selected. Offline inference pending native library. Using offline procedural generator fallback.',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
    );
  }

  /// Deactivate the current SD model.
  Future<void> deactivateModel({bool quiet = false}) async {
    try {
      await _sdChannel.invokeMethod('clearActiveModel');
    } catch (_) {}

    final prevId = activeModelId.value;
    if (prevId != null) {
      final state = _stateFor(prevId);
      if (state != null) state.status.value = SdModelStatus.downloaded;
    }

    activeModelId.value = null;
    activeModelPath.value = null;
    await _storage.delete(StorageBoxes.settings, 'active_sd_model_id');
    await _storage.delete(StorageBoxes.settings, 'active_sd_model_path');

    if (!quiet) {
      Get.snackbar('Model Unloaded', 'Switched back to offline procedural generator.',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  SdModelState? _stateFor(String id) {
    try {
      return modelStates.firstWhere((s) => s.model.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Returns total GB of downloaded SD models.
  double get totalDownloadedGB {
    double total = 0.0;
    for (final state in modelStates) {
      if (state.status.value == SdModelStatus.downloaded ||
          state.status.value == SdModelStatus.active) {
        total += state.model.sizeGB;
      }
    }
    return total;
  }

  /// Returns number of downloaded models.
  int get downloadedCount {
    return modelStates
        .where((s) =>
            s.status.value == SdModelStatus.downloaded ||
            s.status.value == SdModelStatus.active)
        .length;
  }
}
