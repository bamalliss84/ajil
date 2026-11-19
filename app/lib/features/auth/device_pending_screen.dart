import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';

/// جهاز موظف جديد: ينتظر اعتماد المالك من «الإعدادات ← الأجهزة»
class DevicePendingScreen extends ConsumerWidget {
  const DevicePendingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sessionProvider);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.phonelink_lock_outlined, size: 64, color: context.ajil.primary),
            const SizedBox(height: 16),
            const Text('هذا الجوال بانتظار اعتماد المالك', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('اطلب من المالك اعتماد الجهاز من: المزيد ← الأجهزة. بعدها اضغط «تحقق».',
                textAlign: TextAlign.center, style: TextStyle(color: context.ajil.textMuted)),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: () async {
                try {
                  await s.recheckDevice();
                  if (context.mounted && s.session?.deviceId.isEmpty == true) showOk(context, 'لم يُعتمد بعد');
                } catch (e) {
                  if (context.mounted) showError(context, e);
                }
              },
              child: const Text('تحقق'),
            ),
            TextButton(onPressed: () => s.logout(), child: const Text('خروج')),
          ]),
        ),
      ),
    );
  }
}
