// lib/services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // Timezone setup
    tzdata.initializeTimeZones();
    // tz.setLocalLocation(...) can be added if you use a timezone plugin.

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(
      android: androidInit,
    );

    await _plugin.initialize(initSettings);
  }

  static Future<void> scheduleEventReminder({
    required String id,
    required String title,
    required String body,
    required DateTime eventTime,
    Duration offset = const Duration(hours: 2),
  }) async {
    final scheduledTime = eventTime.subtract(offset);

    // Don’t schedule notifications in the past
    if (scheduledTime.isBefore(DateTime.now())) {
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'event_reminders', // channel ID
      'Event Reminders', // channel name
      channelDescription: 'Reminders before your campus events',
      importance: Importance.high,
      priority: Priority.high,
    );

    await _plugin.zonedSchedule(
      id.hashCode,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      androidAllowWhileIdle: true,
    );
  }
}
