import 'dart:ui' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service managing background download notifications, WakeLocks,
/// and Android Foreground Task execution so model downloads never freeze when backgrounded.
/// Configures high-fidelity Babymomo app icon as largeIcon and clean silhouette as smallIcon.
class DownloadNotificationService {
  static final FlutterLocalNotificationsPlugin _notif =
      FlutterLocalNotificationsPlugin();

  static const String channelId = 'model_downloads_v5';
  static const String channelName = 'AI Model Downloads';
  static const String channelDesc =
      'Real-time status and progress for on-device AI model downloads';

  static int _activeDownloads = 0;

  static Future<void> initialize() async {
    // 1. Initialize Foreground Task for persistent background download execution with official icon
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: channelId,
        channelName: channelName,
        channelDescription: channelDesc,
        channelImportance: NotificationChannelImportance.MAX,
        priority: NotificationPriority.MAX,
        enableVibration: false,
        playSound: false,
        showWhen: true,
        iconData: const NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
        ),
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );

    // 2. Initialize local notifications plugin with transparent silhouette icon
    const androidSettings =
        AndroidInitializationSettings('@drawable/ic_notification');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notif.initialize(initSettings);

    final androidPlugin = _notif.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          channelId,
          channelName,
          description: channelDesc,
          importance: Importance.max,
          playSound: false,
          enableVibration: false,
          showBadge: true,
        ),
      );

      await androidPlugin.requestNotificationsPermission();
    }

    // 3. Request runtime notification permissions for Android 13+
    try {
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }
    } catch (_) {}
  }

  /// Starts the Android foreground service to prevent OS suspension during downloads.
  static Future<void> startBackgroundExecution(String modelName) async {
    _activeDownloads++;
    try {
      if (!await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.startService(
          notificationTitle: '⬇️ Babymomo Downloader',
          notificationText: 'Downloading $modelName in background...',
        );
      }
    } catch (_) {}
  }

  /// Stops the background service when all active downloads finish or pause.
  static Future<void> stopBackgroundExecution() async {
    _activeDownloads = (_activeDownloads - 1).clamp(0, 999);
    try {
      if (_activeDownloads == 0 &&
          await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.stopService();
      }
    } catch (_) {}
  }

  /// Updates the progress bar and status in the active Android notification tray.
  /// Uses official Babymomo full-color mascot as largeIcon and clean silhouette as smallIcon.
  static Future<void> showProgress({
    required int id,
    required String modelName,
    required int progress,
    required String statusText,
    bool isDone = false,
    bool isPaused = false,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDesc,
      importance: Importance.max,
      priority: Priority.max,
      category: AndroidNotificationCategory.progress,
      ongoing: !isDone && !isPaused,
      autoCancel: isDone,
      showProgress: !isDone,
      maxProgress: 100,
      progress: progress,
      onlyAlertOnce: true,
      playSound: false,
      enableVibration: false,
      icon: '@drawable/ic_notification',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      color: const Color(0xFFFF6B8B),
      subText: isDone ? '100%' : '$progress%',
      showWhen: true,
    );

    final title = isDone
        ? '✅ $modelName — Ready!'
        : isPaused
            ? '⏸ $modelName — Paused'
            : '⬇️ Downloading: $modelName ($progress%)';

    final body = isDone
        ? 'Model installed and ready for on-device companion chats.'
        : isPaused
            ? 'Paused at $progress%. Tap Resume inside Babymomo to continue.'
            : statusText;

    await _notif.show(
      id,
      title,
      body,
      NotificationDetails(android: androidDetails),
    );
  }

  static Future<void> cancel(int id) async {
    await _notif.cancel(id);
    await stopBackgroundExecution();
  }
}
