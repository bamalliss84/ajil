import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme.dart';
import 'features/auth/device_pending_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/auth/reset_password_screen.dart';
import 'features/auth/set_pin_screen.dart';
import 'features/customers/add_customer_screen.dart';
import 'features/customers/customer_screen.dart';
import 'features/customers/customers_screen.dart';
import 'features/home/dashboard_screen.dart';
import 'features/lock/lock_screen.dart';
import 'features/notices/balance_notices_screen.dart';
import 'features/promises/promise_screen.dart';
import 'features/receipt/receipt_screen.dart';
import 'features/reports/reports_screen.dart';
import 'features/settings/devices_screen.dart';
import 'features/settings/employees_screen.dart';
import 'features/settings/reminders_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/settings/theme_screen.dart';
import 'features/sync/unsynced_screen.dart';
import 'features/tx/add_tx_screen.dart';
import 'services/notifications.dart';
import 'state/providers.dart';
import 'state/session_controller.dart';
import 'package:ajil_core/ajil_core.dart';

class AjilApp extends ConsumerStatefulWidget {
  const AjilApp({super.key});
  @override
  ConsumerState<AjilApp> createState() => _AjilAppState();
}

class _AjilAppState extends ConsumerState<AjilApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final session = ref.read(sessionProvider);
    _router = GoRouter(
      refreshListenable: session,
      initialLocation: '/',
      redirect: (context, state) {
        const public = {'/login', '/register', '/reset'};
        final loc = state.matchedLocation;
        switch (session.stage) {
          case SessionStage.loggedOut:
            return public.contains(loc) ? null : '/login';
          case SessionStage.needsPin:
            return loc == '/set-pin' ? null : '/set-pin';
          case SessionStage.locked:
            return loc == '/lock' ? null : '/lock';
          case SessionStage.pendingDeviceApproval:
            return loc == '/device-pending' ? null : '/device-pending';
          case SessionStage.ready:
            return (public.contains(loc) || {'/lock', '/set-pin', '/device-pending'}.contains(loc)) ? '/' : null;
        }
      },
      routes: [
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
        GoRoute(path: '/reset', builder: (_, __) => const ResetPasswordScreen()),
        GoRoute(path: '/set-pin', builder: (_, __) => const SetPinScreen()),
        GoRoute(path: '/lock', builder: (_, __) => const LockScreen()),
        GoRoute(path: '/device-pending', builder: (_, __) => const DevicePendingScreen()),
        GoRoute(path: '/', builder: (_, __) => const DashboardScreen()),
        GoRoute(path: '/customers', builder: (_, __) => const CustomersScreen()),
        GoRoute(path: '/customers/new', builder: (_, __) => const AddCustomerScreen()),
        GoRoute(
          path: '/customers/:id',
          builder: (_, s) => CustomerScreen(customerId: s.pathParameters['id']!),
          routes: [
            GoRoute(
              path: 'tx/:kind',
              builder: (_, s) => AddTxScreen(
                customerId: s.pathParameters['id']!,
                kind: TxKind.fromWire(s.pathParameters['kind']!),
              ),
            ),
            GoRoute(path: 'promise', builder: (_, s) => PromiseScreen(customerId: s.pathParameters['id']!)),
            GoRoute(
              path: 'receipt/:txId',
              builder: (_, s) => ReceiptScreen(customerId: s.pathParameters['id']!, txId: s.pathParameters['txId']!),
            ),
            GoRoute(path: 'edit', builder: (_, s) => AddCustomerScreen(editId: s.pathParameters['id']!)),
          ],
        ),
        GoRoute(path: '/pick/:kind', builder: (_, s) => CustomersScreen(pickFor: TxKind.fromWire(s.pathParameters['kind']!))),
        GoRoute(path: '/reports', builder: (_, __) => const ReportsScreen()),
        GoRoute(path: '/notices', builder: (_, __) => const BalanceNoticesScreen()),
        GoRoute(path: '/unsynced', builder: (_, __) => const UnsyncedScreen()),
        GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
        GoRoute(path: '/settings/reminders', builder: (_, __) => const RemindersScreen()),
        GoRoute(path: '/settings/devices', builder: (_, __) => const DevicesScreen()),
        GoRoute(path: '/settings/employees', builder: (_, __) => const EmployeesScreen()),
        GoRoute(path: '/settings/theme', builder: (_, __) => const ThemeScreen()),
      ],
    );
    Notifications.tapRoute.addListener(_openTapRoute);
    session.addListener(_openTapRoute);
    WidgetsBinding.instance.addPostFrameCallback((_) => _openTapRoute());
  }

  /// ضغطة على تنبيه (مثل يوم المطالبة): ننتقل بعد فتح القفل
  void _openTapRoute() {
    final route = Notifications.tapRoute.value;
    if (route == null || ref.read(sessionProvider).stage != SessionStage.ready) return;
    Notifications.tapRoute.value = null;
    _router.push(route);
  }

  @override
  void dispose() {
    Notifications.tapRoute.removeListener(_openTapRoute);
    ref.read(sessionProvider).removeListener(_openTapRoute);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.read(sessionProvider);
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => session.lock.touch(),
      child: MaterialApp.router(
        title: 'آجِل',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(ref.watch(themeProvider).theme),
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: _router,
      ),
    );
  }
}
