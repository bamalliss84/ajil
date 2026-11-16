import 'package:ajil_core/ajil_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// التنبيهات محلية ومجدولة على الجوال — تعمل بدون إنترنت.
/// بعد كل مزامنة نعيد جدولة كل شيء من البيانات المحلية (بسيط وموثوق).
class Notifications {
  final _plugin = FlutterLocalNotificationsPlugin();

  /// مسار يُفتح عند الضغط على التنبيه (مثل /notices) — يراقبه التطبيق وينتقل إليه
  static final tapRoute = ValueNotifier<String?>(null);
  bool _ready = false;

  static const _channel = AndroidNotificationDetails(
    'ajil_collection', 'التحصيل',
    channelDescription: 'مواعيد السداد والمطالبة الشهرية',
    importance: Importance.high,
    priority: Priority.high,
  );

  Future<void> init() async {
    if (kIsWeb || _ready) return;
    tzdata.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation(await FlutterTimezone.getLocalTimezone()));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Asia/Aden'));
    }
    await _plugin.initialize(
      const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')),
      onDidReceiveNotificationResponse: (r) => tapRoute.value = r.payload,
    );
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp == true) tapRoute.value = launch!.notificationResponse?.payload;
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    _ready = true;
  }

  /// يعيد جدولة: الوعود (يوم الموعد وقبله بيوم)، مواعيد الفواتير، المطالبة الشهرية
  Future<void> reschedule({
    required List<PaymentPromise> promises,
    required Map<String, String> customerNames,
    required List<LedgerTx> dueDebts,
    required bool monthlyEnabled,
    required int monthlyDay, // 0 = آخر يوم
    required int hour,
    required int minute,
  }) async {
    if (kIsWeb || !_ready) return;
    await _plugin.cancelAll();
    final now = tz.TZDateTime.now(tz.local);
    var id = 1;

    Future<void> at(DateTime day, String title, String body, {String? route}) async {
      final when = tz.TZDateTime(tz.local, day.year, day.month, day.day, hour, minute);
      if (when.isBefore(now) || id > 400) return; // Android يحد عدد التنبيهات المجدولة
      await _plugin.zonedSchedule(id++, title, body, when, const NotificationDetails(android: _channel),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          payload: route);
    }

    for (final p in promises.where((p) => p.status == PromiseStatus.open)) {
      final name = customerNames[p.customerId] ?? 'زبون';
      await at(p.promisedDate, 'وعد بالسداد اليوم', '$name وعد بالسداد اليوم');
      if (p.remindDayBefore) {
        await at(p.promisedDate.subtract(const Duration(days: 1)), 'وعد بالسداد غداً', '$name وعد بالسداد غداً');
      }
    }
    for (final t in dueDebts) {
      if (t.dueDate == null) continue;
      await at(t.dueDate!, 'موعد سداد فاتورة', '${customerNames[t.customerId] ?? 'زبون'} — ${t.invoiceNo ?? ''}');
    }
    if (monthlyEnabled) {
      for (var m = 0; m < 3; m++) {
        final month = DateTime(now.year, now.month + m, 1);
        final day = monthlyDay == 0 ? DateTime(month.year, month.month + 1, 0) : DateTime(month.year, month.month, monthlyDay);
        await at(day, 'يوم المطالبة الشهري', 'اضغط لإرسال أرصدة الزبائن عبر واتساب', route: '/notices');
      }
    }
  }
}
