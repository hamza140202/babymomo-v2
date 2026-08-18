import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service managing background download notifications and foreground channels.
class DownloadNotificationService {
  static final FlutterLocalNotificationsPlugin _notif =
      FlutterLocalNotificationsPlugin();

  static const String channelId = 'model_downloads_v2';
  static const String channelName = 'AI Model Downloads';
  static const String channelDesc = 'Real-time progress for on-device AI model downloads';

  static Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notif.initialize(initSettings);

    // Explicitly create the high-visibility notification channel for Android
    final androidPlugin = _notif.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          channelId,
          channelName,
          description: channelDesc,
          importance: Importance.defaultImportance,
          playSound: false,
          enableVibration: false,
          showBadge: true,
        ),
      );

      await androidPlugin.requestNotificationsPermission();
    }

    // Also request via permission_handler for Android 13+
    try {
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }
    } catch (_) {}
  }

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
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      category: AndroidNotificationCategory.progress,
      ongoing: !isDone && !isPaused,
      autoCancel: isDone,
      showProgress: !isDone,
      maxProgress: 100,
      progress: progress,
      onlyAlertOnce: true,
      playSound: false,
      enableVibration: false,
      icon: '@mipmap/launcher_icon',
      subText: isDone ? '100%' : '$progress%',
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
  }
}
