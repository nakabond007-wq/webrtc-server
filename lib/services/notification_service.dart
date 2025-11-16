import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();
  
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    // Request notification permission
    await Permission.notification.request();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        print('Notification tapped: ${response.payload}');
        if (response.payload != null) {
          // TODO: Open app and show incoming call screen
        }
      },
    );

    _initialized = true;
  }

  Future<void> showIncomingCallNotification({
    required String callerId,
    required Function() onAccept,
    required Function() onDecline,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    const androidDetails = AndroidNotificationDetails(
      'incoming_call_channel',
      'Входящие звонки',
      channelDescription: 'Уведомления о входящих звонках',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.call,
      playSound: true,
      enableVibration: true,
      ongoing: true,
      autoCancel: false,
      visibility: NotificationVisibility.public,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.critical,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      0,
      'Входящий звонок',
      'Звонок от: $callerId',
      notificationDetails,
      payload: callerId,
    );
  }

  Future<void> cancelIncomingCallNotification() async {
    await _notifications.cancel(0);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}
