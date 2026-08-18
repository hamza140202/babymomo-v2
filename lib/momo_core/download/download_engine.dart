import 'dart:async';
import 'dart:io';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import '../storage/storage_service.dart';
import '../security/security_engine.dart';

/// Represents the active state of a model download task.
enum DownloadStatus { pending, downloading, paused, completed, failed, hashing }

/// Represents a model download task.
class DownloadTask {
  final String id;
  final String modelName;
  final String url;
  final String destinationPath;
  final int totalBytes;
  final int downloadedBytes;
  final double speedMBps;
  final DownloadStatus status;
  final String expectedHash;
  final String? errorMessage;

  const DownloadTask({
    required this.id,
    required this.modelName,
    required this.url,
    required this.destinationPath,
    this.totalBytes = 0,
    this.downloadedBytes = 0,
    this.speedMBps = 0.0,
    required this.status,
    required this.expectedHash,
    this.errorMessage,
  });

  double get progress => totalBytes > 0 ? downloadedBytes / totalBytes : 0.0;

  DownloadTask copyWith({
    String? id,
    String? modelName,
    String? url,
    String? destinationPath,
    int? totalBytes,
    int? downloadedBytes,
    double? speedMBps,
    DownloadStatus? status,
    String? expectedHash,
    String? errorMessage,
  }) {
    return DownloadTask(
      id: id ?? this.id,
      modelName: modelName ?? this.modelName,
      url: url ?? this.url,
      destinationPath: destinationPath ?? this.destinationPath,
      totalBytes: totalBytes ?? this.totalBytes,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      speedMBps: speedMBps ?? this.speedMBps,
      status: status ?? this.status,
      expectedHash: expectedHash ?? this.expectedHash,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'modelName': modelName,
      'url': url,
      'destinationPath': destinationPath,
      'totalBytes': totalBytes,
      'downloadedBytes': downloadedBytes,
      'speedMBps': speedMBps,
      'status': status.name,
      'expectedHash': expectedHash,
      'errorMessage': errorMessage,
    };
  }

  factory DownloadTask.fromMap(Map<dynamic, dynamic> map) {
    return DownloadTask(
      id: map['id'] as String,
      modelName: map['modelName'] as String,
      url: map['url'] as String,
      destinationPath: map['destinationPath'] as String,
      totalBytes: map['totalBytes'] as int? ?? 0,
      downloadedBytes: map['downloadedBytes'] as int? ?? 0,
      speedMBps: (map['speedMBps'] as num?)?.toDouble() ?? 0.0,
      status: DownloadStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => DownloadStatus.pending,
      ),
      expectedHash: map['expectedHash'] as String? ?? '',
      errorMessage: map['errorMessage'] as String?,
    );
  }
}

/// MOMO Core — Download Engine.
///
/// Manages high-performance model downloads, range-based resumable chunks,
/// and automated cryptographic JNI hashing on task completion.
/// Enforces a Single Active Task Queue (FIFO) to limit hardware/bandwidth bottlenecks.
class DownloadEngine extends GetxService {
  static const _wakeLockChannel = MethodChannel('com.momoai.babymomo/wakelock');
  final _dio = Dio();
  final RxMap<String, DownloadTask> downloads = <String, DownloadTask>{}.obs;
  
  // Tracks cancellation tokens of running tasks
  final Map<String, CancelToken> _cancelTokens = {};
  
  String? _activeTaskId;

  @override
  void onInit() {
    super.onInit();
    _loadPersistedTasks();
  }

  Future<void> _acquireWakeLock() async {
    try {
      await _wakeLockChannel.invokeMethod('acquire');
    } catch (_) {}
  }

  Future<void> _releaseWakeLock() async {
    try {
      await _wakeLockChannel.invokeMethod('release');
    } catch (_) {}
  }

  void _updateInMemoryTask(DownloadTask task) {
    downloads[task.id] = task;
  }

  /// Recover previously saved tasks from Hive storage.
  Future<void> _loadPersistedTasks() async {
    final storage = Get.find<StorageService>();
    try {
      final persisted = await storage.getAll<Map<dynamic, dynamic>>(StorageBoxes.downloads);
      for (final map in persisted) {
        final task = DownloadTask.fromMap(map);
        // Interrupted tasks are marked as paused or failed to allow resuming
        if (task.status == DownloadStatus.downloading || task.status == DownloadStatus.hashing) {
          downloads[task.id] = task.copyWith(status: DownloadStatus.paused, speedMBps: 0.0);
        } else {
          downloads[task.id] = task;
        }
      }
    } catch (_) {}
  }

  Future<void> _saveTask(DownloadTask task) async {
    final storage = Get.find<StorageService>();
    downloads[task.id] = task;
    await storage.put(StorageBoxes.downloads, task.id, task.toMap());
  }

  Future<void> _deleteTask(String taskId) async {
    final storage = Get.find<StorageService>();
    downloads.remove(taskId);
    await storage.delete(StorageBoxes.downloads, taskId);
  }

  /// Place a download task in the FIFO queue and process immediately.
  Future<void> startDownload(DownloadTask task) async {
    if (task.status == DownloadStatus.completed) return;
    
    await _saveTask(task.copyWith(status: DownloadStatus.pending));
    _processQueue();
  }

  /// Pause an active or pending download.
  Future<void> pauseDownload(String taskId) async {
    final task = downloads[taskId];
    if (task == null) return;
    
    if (_cancelTokens.containsKey(taskId)) {
      _cancelTokens[taskId]!.cancel();
      _cancelTokens.remove(taskId);
    }
    
    await _saveTask(task.copyWith(status: DownloadStatus.paused, speedMBps: 0.0));
    
    if (_activeTaskId == taskId) {
      _activeTaskId = null;
    }
    
    _processQueue();
  }

  /// Cancel and wipe a download task completely, deleting any partial file.
  Future<void> cancelDownload(String taskId) async {
    final task = downloads[taskId];
    if (task == null) return;
    
    if (_cancelTokens.containsKey(taskId)) {
      _cancelTokens[taskId]!.cancel();
      _cancelTokens.remove(taskId);
    }
    
    await _deleteTask(taskId);
    
    final file = File(task.destinationPath);
    if (file.existsSync()) {
      try {
        file.deleteSync();
      } catch (_) {}
    }
    
    if (_activeTaskId == taskId) {
      _activeTaskId = null;
    }
    
    _processQueue();
  }

  /// Get the active progress double (0.0 to 1.0) of a task.
  double progressFor(String taskId) {
    return downloads[taskId]?.progress ?? 0.0;
  }

  /// Processes the next task in queue if there are no active downloads running.
  void _processQueue() {
    if (_activeTaskId != null) return;
    
    final pendingList = downloads.values.where(
      (t) => t.status == DownloadStatus.pending
    );
    final nextPending = pendingList.isEmpty ? null : pendingList.first;
    
    if (nextPending != null) {
      _startDownloadLoop(nextPending);
    }
  }

  /// Core HTTP Range chunked downloader pipeline.
  Future<void> _startDownloadLoop(DownloadTask task) async {
    _activeTaskId = task.id;
    final cancelToken = CancelToken();
    _cancelTokens[task.id] = cancelToken;
    
    await _saveTask(task.copyWith(status: DownloadStatus.downloading));
    await _acquireWakeLock();
    
    try {
      final file = File(task.destinationPath);
      final parentDir = file.parent;
      if (!parentDir.existsSync()) {
        parentDir.createSync(recursive: true);
      }
      
      int downloadedBytes = 0;
      if (file.existsSync()) {
        downloadedBytes = file.lengthSync();
      }
      
      // Perform a range request to append to existing downloaded chunks
      final options = Options(
        responseType: ResponseType.stream,
        headers: {
          if (downloadedBytes > 0) 'Range': 'bytes=$downloadedBytes-',
        },
      );
      
      final response = await _dio.get<ResponseBody>(
        task.url,
        options: options,
        cancelToken: cancelToken,
      );
      
      // Server returned 206 Partial Content if resuming is supported
      final isPartial = response.statusCode == 206;
      final startBytes = isPartial ? downloadedBytes : 0;
      
      final raf = file.openSync(mode: isPartial ? FileMode.append : FileMode.write);
      final contentLengthHeader = response.headers.value('content-length');
      int totalBytes = task.totalBytes;
      if (contentLengthHeader != null) {
        final serverRemainingBytes = int.tryParse(contentLengthHeader) ?? 0;
        totalBytes = startBytes + serverRemainingBytes;
      }
      
      await _saveTask(downloads[task.id]!.copyWith(
        status: DownloadStatus.downloading,
        totalBytes: totalBytes,
        downloadedBytes: startBytes,
      ));
      
      final stream = response.data!.stream;
      int currentDownloaded = startBytes;
      
      var lastUpdateTime = DateTime.now();
      var lastBytes = currentDownloaded;
      
      await for (final chunk in stream) {
        if (cancelToken.isCancelled) {
          throw DioException(
            requestOptions: response.requestOptions,
            type: DioExceptionType.cancel,
          );
        }
        
        raf.writeFromSync(chunk);
        currentDownloaded += chunk.length;
        
        final now = DateTime.now();
        final duration = now.difference(lastUpdateTime);
        
        // Throttling UI memory updates to 1000ms prevents main-thread bottlenecks and UI lag.
        // We update the state in-memory only (without triggering disk writes to Hive).
        if (duration.inMilliseconds > 1000) {
          final speedBytes = currentDownloaded - lastBytes;
          final elapsedSeconds = duration.inMilliseconds / 1000.0;
          final speedMBps = elapsedSeconds > 0 ? (speedBytes / 1024.0 / 1024.0) / elapsedSeconds : 0.0;
          
          _updateInMemoryTask(downloads[task.id]!.copyWith(
            downloadedBytes: currentDownloaded,
            speedMBps: speedMBps,
          ));
          
          lastUpdateTime = now;
          lastBytes = currentDownloaded;
        }
      }
      
      await raf.close();
      _cancelTokens.remove(task.id);
      
      // ── Transition to Hashing state ──
      await _saveTask(downloads[task.id]!.copyWith(
        status: DownloadStatus.hashing,
        downloadedBytes: totalBytes,
        speedMBps: 0.0,
      ));
      
      // Perform background cryptographic integrity verification
      final security = Get.find<SecurityEngine>();
      final isVerified = await security.validateModelHash(task.destinationPath, task.expectedHash);
      
      if (isVerified) {
        await _saveTask(downloads[task.id]!.copyWith(
          status: DownloadStatus.completed,
          errorMessage: null,
        ));
      } else {
        // "Sure-shot" install: if hash validation fails, we keep the file and mark as completed with a warning in errorMessage.
        await _saveTask(downloads[task.id]!.copyWith(
          status: DownloadStatus.completed,
          errorMessage: 'SHA-256 verification failed (integrity check mismatch). The downloaded model might be corrupted, but Momo has kept it so you can load and try running it anyway! ⚠️',
        ));
      }
    } catch (e) {
      _cancelTokens.remove(task.id);
      if (cancelToken.isCancelled) {
        // Paused tasks already updated state, do nothing
      } else {
        String errorMsg = e.toString();
        if (e is DioException) {
          errorMsg = e.message ?? e.toString();
        }
        final currentTask = downloads[task.id];
        if (currentTask != null) {
          await _saveTask(currentTask.copyWith(
            status: DownloadStatus.failed,
            errorMessage: 'Download error: $errorMsg',
            speedMBps: 0.0,
          ));
        }
      }
    } finally {
      await _releaseWakeLock();
      _activeTaskId = null;
      _processQueue();
    }
  }
}
