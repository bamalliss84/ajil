import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config.dart';
import 'data/device_identity.dart';
import 'security/app_lock.dart';
import 'services/notifications.dart';
import 'state/providers.dart';
import 'state/session_controller.dart';
import 'state/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar');
  // التواريخ تتبع إعداد الأرقام (الافتراضي 123) — intl يستخدم الهندية لـ ar افتراضياً
  DateFormat.useNativeDigitsByDefaultFor('ar', false);
  await Supabase.initialize(url: AppConfig.supabaseUrl, anonKey: AppConfig.supabaseAnonKey);

  const storage = FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true));
  final identity = DeviceIdentity(storage);
  await identity.ensure();

  // المظهر يُطبَّق قبل أول إطار، من التخزين المحلي (بدون نت)
  final theme = ThemeController(storage);
  await theme.init();

  final notifications = Notifications();
  await notifications.init();

  final session = SessionController(
    supabase: Supabase.instance.client,
    storage: storage,
    identity: identity,
    lock: AppLock(storage),
    notifications: notifications,
    theme: theme,
  );
  await session.restore();

  runApp(ProviderScope(
    overrides: [
      sessionProvider.overrideWith((ref) => session),
      notificationsProvider.overrideWithValue(notifications),
      themeProvider.overrideWith((ref) => theme),
    ],
    child: const AjilApp(),
  ));
}
