import 'package:ajil_core/ajil_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../data/repository.dart';
import '../services/notifications.dart';
import 'session_controller.dart';
import 'theme_controller.dart';

/// يُستبدل في main() بالنسخة المهيأة
final sessionProvider = ChangeNotifierProvider<SessionController>((ref) => throw UnimplementedError());
/// مظهر المستخدم الحالي — MaterialApp يعيد البناء فوراً عند التبديل
final themeProvider = ChangeNotifierProvider<ThemeController>((ref) => ThemeController(const FlutterSecureStorage()));
final notificationsProvider = Provider<Notifications>((ref) => throw UnimplementedError());

final moneyFormatProvider = StateProvider<MoneyFormat>((ref) => const MoneyFormat());

LedgerRepository repoOf(WidgetRef ref) => ref.read(sessionProvider).repo!;
WorkSession sessionOf(WidgetRef ref) => ref.read(sessionProvider).session!;

final customersProvider = StreamProvider.autoDispose<List<CustomerWithBalance>>((ref) {
  final s = ref.watch(sessionProvider);
  if (s.repo == null) return const Stream.empty();
  return s.repo!.watchCustomers();
});

final customerProvider = StreamProvider.autoDispose.family<Customer?, String>((ref, id) {
  return ref.watch(sessionProvider).repo!.watchCustomer(id);
});

final customerTxsProvider = StreamProvider.autoDispose.family<List<LedgerTx>, String>((ref, id) {
  return ref.watch(sessionProvider).repo!.watchTxs(id);
});

final branchTxsProvider = StreamProvider.autoDispose<List<LedgerTx>>((ref) {
  final s = ref.watch(sessionProvider);
  if (s.repo == null) return const Stream.empty();
  return s.repo!.watchBranchTxs();
});

final unsyncedProvider = StreamProvider.autoDispose<List<LedgerTx>>((ref) {
  return ref.watch(sessionProvider).repo!.watchUnsynced();
});

final promisesProvider = StreamProvider.autoDispose.family<List<PaymentPromise>, String?>((ref, customerId) {
  return ref.watch(sessionProvider).repo!.watchPromises(customerId: customerId);
});
