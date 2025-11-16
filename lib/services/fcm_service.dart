import 'package:firebase_messaging/firebase_messaging.dart';
import 'notification_service.dart';

// Top-level function for background message handling
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background message received: ${message.notification?.title}');
  
  // Show notification even when app is closed
  if (message.data.containsKey('callerId')) {
    final notificationService = NotificationService();
    await notificationService.initialize();
    await notificationService.showIncomingCallNotification(
      callerId: message.data['callerId'] ?? 'Unknown',
      onAccept: () {},
      onDecline: () {},
    );
  }
}

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  Future<void> initialize() async {
    // Request permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('FCM Permission status: ${settings.authorizationStatus}');

    // Get FCM token
    _fcmToken = await _messaging.getToken();
    print('FCM Token: $_fcmToken');

    // Listen to token refresh
    _messaging.onTokenRefresh.listen((token) {
      _fcmToken = token;
      print('FCM Token refreshed: $token');
      // TODO: Send token to your server
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground message received: ${message.notification?.title}');
      
      if (message.data.containsKey('callerId')) {
        // Show local notification
        final notificationService = NotificationService();
        notificationService.showIncomingCallNotification(
          callerId: message.data['callerId'] ?? 'Unknown',
          onAccept: () {},
          onDecline: () {},
        );
      }
    });

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification opened app from background: ${message.data}');
      // TODO: Navigate to call screen
    });

    // Check if app was opened from terminated state
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      print('App opened from terminated state: ${initialMessage.data}');
      // TODO: Navigate to call screen
    }
  }

  // Send FCM token to server when connecting
  Future<void> sendTokenToServer(String serverUrl, String socketId) async {
    // TODO: Send FCM token to your backend server
    // The server will use this token to send push notifications
    print('Would send FCM token $_fcmToken for socket $socketId to $serverUrl');
  }
}
