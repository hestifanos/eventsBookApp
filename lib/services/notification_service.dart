
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  // Initialize plugin + ask for notification permission (Android 13+).
  static Future<void> init() async {
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(initSettings);

    final androidImpl =
    _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();

    _initialized = true;
    debugPrint('NotificationService: initialized');
  }

  // Schedule reminder with rules:
  // - If eventTime > 2h from now  => fire 2h before the event.
  // - If eventTime ≤ 2h from now  => fire 10s after tap.
  // Caller must ensure eventTime is in the future.
  static Future<void> scheduleEventReminder({
    required String id,
    required String title,
    required String body,
    required DateTime eventTime,
  }) async {
    await init();

    final now = DateTime.now();
    final diff = eventTime.difference(now);

    Duration delay;

    if (diff > const Duration(hours: 2)) {
      // hours before event
      delay = diff - const Duration(hours: 2);
      debugPrint(
        'NotificationService: "$title" scheduled 2h before, '
            'delay = $delay',
      );
    } else {
      // Event is within 2h
      delay = const Duration(seconds: 10);
      debugPrint(
        'NotificationService: "$title" within 2h, '
            'scheduled after $delay',
      );
    }

    // Use a Timer so the app shows the notification even without alarms.
    Timer(delay, () async {
      const androidDetails = AndroidNotificationDetails(
        'events_channel',
        'Event reminders',
        channelDescription: 'Reminders for upcoming campus events',
        importance: Importance.max,
        priority: Priority.high,
      );

      const details = NotificationDetails(android: androidDetails);

      await _plugin.show(
        id.hashCode,
        title,
        body,
        details,
      );
      debugPrint('NotificationService: notification fired for "$title"');
    });
  }
}
