import 'package:ajil_core/ajil_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;

import '../../core/theme.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';

/// كل الحركات التي لم تصل للخادم بعد، أو رفضها مع السبب
class UnsyncedScreen extends ConsumerWidget {
  const UnsyncedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sessionProvider);
    final list = ref.watch(unsyncedProvider).valueOrNull ?? const [];
    final customers = {for (final c in ref.watch(customersProvider).valueOrNull ?? const []) c.customer.id: c.customer.name};
    final f = ref.watch(moneyFormatProvider);
    return Scaffold(
      appBar: const AjilHeader(title: 'حركات غير متزامنة'),
      body: Column(children: [
        ListTile(
          tileColor: context.ajil.surface,
          leading: Icon(s.online ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
              color: s.online ? context.ajil.paid : context.ajil.pendingText),
          title: Text(s.online ? 'متصل' : 'غير متصل'),
          subtitle: Text(s.lastSync == null
              ? 'لم تتم مزامنة بعد'
              : 'آخر مزامنة: ${intl.DateFormat('h:mm a', 'ar').format(s.lastSync!)}${s.lastSyncError == null ? '' : ' · ${s.lastSyncError!.message}'}'),
          trailing: FilledButton.tonal(
            onPressed: () => s.sync?.syncNow(verify: true),
            style: FilledButton.styleFrom(minimumSize: const Size(110, 44)),
            child: const Text('مزامنة الآن'),
          ),
        ),
        const Divider(),
        Expanded(
          child: list.isEmpty
              ? Center(child: Text('كل الحركات متزامنة ✓', style: TextStyle(color: context.ajil.paid, fontSize: 16)))
              : ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (_, i) {
                    final t = list[i];
                    return ListTile(
                      tileColor: context.ajil.surface,
                      title: Text('${customers[t.customerId] ?? ''} · ${t.kind.labelAr}'),
                      subtitle: Text(t.sync == SyncState.failed
                          ? 'مرفوضة: ${t.syncError ?? ''}'
                          : 'رقم الجهاز ${t.deviceSeq} · ${intl.DateFormat('d/M h:mm a', 'ar').format(t.createdAt)}'),
                      trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text(f.amount(t.amount, t.currency, withSymbol: true), style: const TextStyle(fontWeight: FontWeight.w600)),
                        SyncBadge(t.sync),
                      ]),
                      onTap: t.sync == SyncState.failed
                          ? () => repoOf(ref).retry(t.id).then((_) => s.kick())
                          : null,
                    );
                  },
                ),
        ),
      ]),
    );
  }
}
