import 'package:ajil_core/ajil_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;
import 'package:url_launcher/url_launcher.dart';

import '../../core/config.dart';
import '../../core/theme.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sessionProvider);
    final w = s.session!;
    final sub = s.subscription;
    final plan = (sub?['plans'] as Map?)?['name_ar'] ?? sub?['plan_code'] ?? '—';
    final exp = sub?['expires_at'] == null ? null : DateTime.parse(sub!['expires_at']).toLocal();
    final f = ref.watch(moneyFormatProvider);

    return Scaffold(
      appBar: AppBar(title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(w.storeName), const BranchChip()])),
      bottomNavigationBar: const AjilNavBar(index: 3),
      body: ListView(children: [
        SectionCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('الباقة: $plan', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            if (exp != null)
              Text('تنتهي: ${intl.DateFormat('d MMMM y', 'ar').format(exp)}',
                  style: TextStyle(color: s.subscriptionExpired ? AjilColors.debt : AjilColors.textMuted)),
            if (w.isOwner) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => _redeem(context, ref),
                icon: const Icon(Icons.qr_code_2_outlined),
                label: const Text('تفعيل بكود اشتراك'),
              ),
            ],
          ]),
        ),
        const SizedBox(height: 8),
        if (w.isOwner) ...[
          _tile(Icons.notifications_active_outlined, 'التنبيهات والتحصيل', () => context.push('/settings/reminders')),
          _tile(Icons.people_alt_outlined, 'الموظفون', () => context.push('/settings/employees')),
          _tile(Icons.phonelink_setup_outlined, 'الأجهزة', () => context.push('/settings/devices')),
          _tile(Icons.store_outlined, 'الفروع والعملات', () => _storeSheet(context, ref)),
        ],
        _tile(Icons.sync_outlined, 'حركات غير متزامنة', () => context.push('/unsynced'), trailing: s.pending > 0 ? '${s.pending}' : null),
        SwitchListTile(
          tileColor: Colors.white,
          secondary: const Icon(Icons.translate_outlined),
          title: const Text('الأرقام الهندية (١٢٣)'),
          value: f.arabicIndicDigits,
          onChanged: (v) => ref.read(moneyFormatProvider.notifier).state = MoneyFormat(arabicIndicDigits: v),
        ),
        _tile(Icons.password_outlined, 'تغيير كلمة المرور', () => _changePassword(context, ref)),
        if (AppConfig.supportWhatsapp.isNotEmpty)
          _tile(Icons.support_agent_outlined, 'الدعم الفني (واتساب)',
              () => launchUrl(Uri.parse('https://wa.me/${AppConfig.supportWhatsapp}'), mode: LaunchMode.externalApplication)),
        const SizedBox(height: 8),
        _tile(Icons.logout, 'خروج (لتبديل الفرع أو المستخدم)', () => s.logout(), color: AjilColors.debt),
        const SizedBox(height: 24),
      ]),
    );
  }

  Widget _tile(IconData icon, String title, VoidCallback onTap, {String? trailing, Color? color}) => ListTile(
        tileColor: Colors.white,
        leading: Icon(icon, color: color),
        title: Text(title, style: TextStyle(color: color)),
        trailing: trailing == null ? const Icon(Icons.chevron_left) : Badge(label: Text(trailing)),
        onTap: onTap,
      );

  Future<void> _redeem(BuildContext context, WidgetRef ref) async {
    final c = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('كود الاشتراك'),
        content: TextField(
          controller: c,
          textDirection: TextDirection.ltr,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(hintText: 'XXXX-XXXX-XXXX'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('رجوع')),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text), style: FilledButton.styleFrom(minimumSize: const Size(90, 44)), child: const Text('تفعيل')),
        ],
      ),
    );
    if (code == null || code.trim().isEmpty) return;
    final s = ref.read(sessionProvider);
    try {
      await s.api.redeemCode(code);
      s.subscription = await s.api.currentSubscription(s.session!.storeId);
      s.kick();
      if (context.mounted) showOk(context, 'تم تفعيل الاشتراك');
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  Future<void> _changePassword(BuildContext context, WidgetRef ref) async {
    final c = TextEditingController();
    final pw = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('كلمة مرور جديدة'),
        content: TextField(controller: c, obscureText: true, decoration: const InputDecoration(helperText: '8 أحرف على الأقل')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('رجوع')),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text), style: FilledButton.styleFrom(minimumSize: const Size(90, 44)), child: const Text('حفظ')),
        ],
      ),
    );
    if (pw == null) return;
    try {
      await ref.read(sessionProvider).api.changeMyPassword(pw);
      if (context.mounted) showOk(context, 'تم تغيير كلمة المرور');
    } catch (e) {
      if (context.mounted) showError(context, e);
    }
  }

  Future<void> _storeSheet(BuildContext context, WidgetRef ref) async {
    final s = ref.read(sessionProvider);
    final w = s.session!;
    final selected = {...w.enabledCurrencies};
    final branch = TextEditingController();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.viewInsetsOf(ctx).bottom + 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('العملات المفعلة', style: TextStyle(fontWeight: FontWeight.w600)),
            Wrap(spacing: 8, children: [
              for (final c in Currency.all)
                FilterChip(
                  label: Text(c.nameAr),
                  selected: selected.contains(c.code),
                  onSelected: c.code == w.defaultCurrency ? null : (v) => set(() => v ? selected.add(c.code) : selected.remove(c.code)),
                ),
            ]),
            FilledButton.tonal(
              onPressed: () async {
                try {
                  await s.api.updateStore(w.storeId, {'enabled_currencies': selected.toList()});
                  if (ctx.mounted) showOk(ctx, 'تم الحفظ — سجّل الخروج والدخول لتطبيقها');
                } catch (e) {
                  if (ctx.mounted) showError(ctx, e);
                }
              },
              child: const Text('حفظ العملات'),
            ),
            const Divider(height: 32),
            const Text('إضافة فرع', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(controller: branch, decoration: const InputDecoration(labelText: 'اسم الفرع')),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () async {
                if (branch.text.trim().isEmpty) return;
                try {
                  final b = await s.api.addBranch(branch.text.trim());
                  if (ctx.mounted) showOk(ctx, 'أُضيف ${b.name} — يظهر في شاشة الدخول');
                  branch.clear();
                } catch (e) {
                  if (ctx.mounted) showError(ctx, e);
                }
              },
              child: const Text('إضافة الفرع'),
            ),
          ]),
        ),
      ),
    );
  }
}
