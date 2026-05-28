import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // Navigation callback — main.dart da set qilinadi
  static void Function(String route)? _onNotifTap;
  static void setNavigationCallback(void Function(String) cb) {
    _onNotifTap = cb;
  }

  static Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (details) {
        final payload = details.payload ?? '/daily-check';
        _onNotifTap?.call(payload);
      },
    );

    // App closed holda notif bosilganini tekshirish
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp == true) {
      final payload =
          launchDetails?.notificationResponse?.payload ?? '/daily-check';
      Future.delayed(const Duration(milliseconds: 600), () {
        _onNotifTap?.call(payload);
      });
    }

    _initialized = true;
  }

  static Future<void> requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Har kuni berilgan vaqtda kunlik tekshiruv bildiruvchisi
  static Future<void> scheduleDailyCheck({
    int hour = 9,
    int minute = 0,
  }) async {
    await _plugin.cancel(1);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      1,
      '🌸 Onamiz — Kunlik tekshiruv',
      'Bugungi holatingizni tekshirish vaqti keldi',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_check',
          'Kunlik tekshiruv',
          channelDescription: 'Har kunlik sog\'liq tekshiruvi',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: '/daily-check',
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Reminder bildiruvchi (agar kunlik tekshiruv bajarilmasa)
  static Future<void> scheduleEvening({int hour = 20, int minute = 0}) async {
    await _plugin.cancel(2);

    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      2,
      '🤰 Onamiz — Eslatma',
      'Bugungi tekshiruvni hali bajarmagansiz',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'reminder',
          'Eslatma',
          channelDescription: 'Kunlik tekshiruv eslatmasi',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: false,
          presentSound: false,
        ),
      ),
      payload: '/daily-check',
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelAll() => _plugin.cancelAll();
}
