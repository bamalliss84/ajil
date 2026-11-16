import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;

import '../../core/theme.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';

/// الأجهزة (للمالك): اعتماد جهاز موظف، إلغاء جوال ضائع، آخر مزامنة
class DevicesScreen extends ConsumerStatefulWidget {
  const DevicesScreen({super.key});
  @override
  ConsumerState<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends ConsumerState<DevicesScreen> {
  List<Map<String, dynamic>>? _devices;

  Future<void> _load() async {
    try {
      final d = await ref.read(sessionProvider).api.devices();
      if (mounted) setState(() => _devices = d);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _act(String id, {bool approve = false, bool revoke = false}) async {
    if (revoke) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('إلغاء الجهاز؟'),
          content: const Text('يُرفض دخوله فوراً، وتُمسح بياناته المحلية عند أول اتصال. لا يمكن التراجع.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('رجوع')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: FilledButton.styleFrom(backgroundColor: AjilColors.debt, minimumSize: const Size(90, 44)),
              child: const Text('إلغاء الجهاز'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    try {
      await ref.read(sessionProvider).api.setDevice(id, approve: approve, revoke: revoke);
      await _load();
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mine = sessionOf(ref).deviceId;
    final list = _devices;
    final dt = intl.DateFormat('d/M h:mm a', 'ar');
    return Scaffold(
      appBar: const AjilHeader(title: 'الأجهزة'),
      body: list == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (_, i) {
                  final d = list[i];
                  final revoked = d['revoked_at'] != null;
                  final approved = d['approved'] == true;
                  final last = d['last_sync_at'] == null ? null : DateTime.parse(d['last_sync_at']).toLocal();
                  final stale = last != null && DateTime.now().difference(last).inDays >= 3;
                  return ListTile(
                    tileColor: Colors.white,
                    leading: CircleAvatar(
                      backgroundColor: revoked ? AjilColors.divider : AjilColors.primaryLight,
                      child: Text(d['device_letter'] ?? '?', style: const TextStyle(color: AjilColors.primaryDark)),
                    ),
                    title: Text('${d['label'] ?? 'جهاز'}${d['id'] == mine ? ' (هذا الجهاز)' : ''}'),
                    subtitle: Text(
                      revoked
                          ? 'ملغى'
                          : !approved
                              ? 'بانتظار الاعتماد'
                              : last == null
                                  ? 'لم يتزامن بعد'
                                  : 'آخر مزامنة: ${dt.format(last)}${stale ? ' — منذ أكثر من 3 أيام' : ''}',
                      style: TextStyle(color: stale || !approved ? AjilColors.pendingText : null),
                    ),
                    trailing: revoked
                        ? null
                        : Row(mainAxisSize: MainAxisSize.min, children: [
                            if (!approved)
                              FilledButton(
                                onPressed: () => _act(d['id'], approve: true),
                                style: FilledButton.styleFrom(minimumSize: const Size(70, 40)),
                                child: const Text('اعتماد'),
                              ),
                            if (d['id'] != mine)
                              IconButton(
                                onPressed: () => _act(d['id'], revoke: true),
                                icon: const Icon(Icons.block, color: AjilColors.debt),
                                tooltip: 'إلغاء الجهاز',
                              ),
                          ]),
                  );
                },
              ),
            ),
    );
  }
}
