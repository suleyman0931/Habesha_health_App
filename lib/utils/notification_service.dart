import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzData;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    tzData.initializeTimeZones();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/notification_icon');
    final DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );
    final InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );
    await _notificationsPlugin.initialize(initializationSettings);
  }

  static Future<void> scheduleWaterReminder() async {
    await _notificationsPlugin.zonedSchedule(
      0,
      'Water Reminder',
      'Time to drink water and stay hydrated!',
      _nextInstanceOfTime(),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'water_channel',
          'Water Reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> scheduleExerciseReminder(DateTime time) async {
    await _notificationsPlugin.zonedSchedule(
      1,
      'Exercise Reminder',
      'It\'s time to get moving with your workout!',
      tz.TZDateTime.from(time, tz.local), // Corrected: Use tz.local (getter)
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'exercise_channel',
          'Exercise Reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  static Future<void> scheduleMotivation() async {
    final random = (DateTime.now().millisecondsSinceEpoch % 4) + 1;
    final messages = [
      'You\'re doing great! Keep it up!',
      'Every step brings you closer to your goal!',
      'Stay strong, Habesha warrior!',
      'Hydration is power—drink up!',
    ];
    await _notificationsPlugin.zonedSchedule(
      2,
      'Motivation',
      messages[random],
      tz.TZDateTime.now(
        tz.local,
      ).add(Duration(hours: random)), // Corrected: Use tz.local (getter)
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'motivation_channel',
          'Motivational Messages',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static tz.TZDateTime _nextInstanceOfTime() {
    final now = tz.TZDateTime.now(tz.local); // Corrected: Use tz.local (getter)
    int hour = 8;
    if (now.hour >= 20) {
      return tz.TZDateTime(
        tz.local,
        now.day + 1,
        now.month,
        now.year,
        8,
      ); // Corrected: Use tz.local (getter)
    }
    while (hour < 20) {
      if (now.hour < hour) {
        return tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          hour,
        ); // Corrected: Use tz.local (getter)
      }
      hour += 2;
    }
    return tz.TZDateTime(
      tz.local,
      now.day + 1,
      now.month,
      now.year,
      8,
    ); // Corrected: Use tz.local (getter)
  }
}
