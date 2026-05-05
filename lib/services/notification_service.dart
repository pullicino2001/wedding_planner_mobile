import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import '../models/task_item.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    final tzInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(tzInfo.identifier));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    // Create Android notification channel
    const channel = AndroidNotificationChannel(
      'wedding_tasks',
      'Wedding Tasks',
      description: 'Reminders for your wedding tasks',
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Request Android 13+ notification permission
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  // Stable notification ID from UUID (first 7 hex chars = 28 bits, fits int32)
  static int _notifId(String taskId) {
    final hex = taskId.replaceAll('-', '').substring(0, 7);
    return int.parse(hex, radix: 16);
  }

  static Future<void> scheduleTask(TaskItem task) async {
    if (!_initialized) await init();

    if (task.dueDate == null || task.isDone) {
      await cancel(task.id);
      return;
    }

    int hour = 10, minute = 0;
    if (task.dueTime.isNotEmpty) {
      final parts = task.dueTime.split(':');
      if (parts.length == 2) {
        hour = int.tryParse(parts[0]) ?? 10;
        minute = int.tryParse(parts[1]) ?? 0;
      }
    }

    final scheduled = tz.TZDateTime(
      tz.local,
      task.dueDate!.year,
      task.dueDate!.month,
      task.dueDate!.day,
      hour,
      minute,
    );

    // Don't schedule if in the past
    if (scheduled.isBefore(tz.TZDateTime.now(tz.local))) return;

    final assignee = task.assignedTo.isNotEmpty ? ' · ${task.assignedTo}' : '';
    final body = 'Due today${task.notes.isNotEmpty ? ' — ${task.notes}' : ''}$assignee';

    await _plugin.zonedSchedule(
      _notifId(task.id),
      task.title,
      body,
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'wedding_tasks',
          'Wedding Tasks',
          channelDescription: 'Reminders for your wedding tasks',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancel(String taskId) async {
    if (!_initialized) await init();
    await _plugin.cancel(_notifId(taskId));
  }

  static Future<void> cancelAll() async {
    if (!_initialized) await init();
    await _plugin.cancelAll();
  }

  /// Re-schedule all tasks (call on app startup to survive device restarts).
  static Future<void> rescheduleAll(List<TaskItem> tasks) async {
    if (!_initialized) await init();
    for (final task in tasks) {
      await scheduleTask(task);
    }
  }
}
