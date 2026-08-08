import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _notificationsPrefsKey = 'notifications_enabled';

  /// Initialize local notifications
  static Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
    );
  }

  /// Request permissions from the OS using permission_handler
  static Future<bool> requestPermission() async {
    final status = await Permission.notification.request();
    final isGranted = status.isGranted;
    
    // Also try platform-specific built-in requests as fallback/secondary check
    if (!isGranted) {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        final granted = await androidImplementation.requestNotificationsPermission();
        if (granted == true) {
          await setNotificationsEnabled(true);
          return true;
        }
      }

      final iosImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      if (iosImplementation != null) {
        final granted = await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        if (granted == true) {
          await setNotificationsEnabled(true);
          return true;
        }
      }
    }

    await setNotificationsEnabled(isGranted);
    return isGranted;
  }

  /// Check if notifications are enabled in local app settings
  static Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    // Default to true or check if permission is granted
    if (!prefs.containsKey(_notificationsPrefsKey)) {
      final status = await Permission.notification.status;
      return status.isGranted;
    }
    return prefs.getBool(_notificationsPrefsKey) ?? false;
  }

  /// Save notification toggle setting in preferences
  static Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsPrefsKey, enabled);
  }

  /// Display a local notification with meal details
  static Future<void> showMealAnalysisNotification(String mealName, int kcal) async {
    final enabled = await areNotificationsEnabled();
    if (!enabled) return;

    // Check OS level permission status before showing
    final status = await Permission.notification.status;
    if (!status.isGranted) return;

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'meal_logs_channel',
      'Meal Logging Notifications',
      channelDescription: 'Notifications shown when a user logs a meal.',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails darwinPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: darwinPlatformChannelSpecifics,
    );

    await _notificationsPlugin.show(
      id: (DateTime.now().millisecondsSinceEpoch ~/ 1000) & 0x7FFFFFFF,
      title: 'Meal Logged! 🥗',
      body: 'Successfully logged "$mealName" ($kcal kcal) to history.',
      notificationDetails: platformChannelSpecifics,
    );
  }
}
