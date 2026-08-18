import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service managing background download notifications.
class DownloadNotificationService {
  static final FlutterLocalNotificationsPlugin _notif =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    await _notif
        .initialize(const InitializationSettings(android: androidSettings));

    await _notif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
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
      'model_downloads',
      'Model Downloads',
      channelDescription: 'Shows progress for on-device AI model downloads',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: !isDone && !isPaused,
      showProgress: !isDone,
      maxProgress: 100,
      progress: progress,
      onlyAlertOnce: true,
      icon: '@mipmap/launcher_icon',
      subText: statusText,
    );

    await _notif.show(
      id,
      isDone
          ? '✅ $modelName — Ready!'
          : isPaused
              ? '⏸ $modelName — Paused'
              : '⬇️ Downloading: $modelName',
      isDone
          ? 'Model installed and ready for on-device companion chats.'
          : isPaused
              ? 'Tap Resume inside Babymomo to continue.'
              : statusText,
      NotificationDetails(android: androidDetails),
    );
  }

  static Future<void> cancel(int id) async {
    await _notif.cancel(id);
  }
}
