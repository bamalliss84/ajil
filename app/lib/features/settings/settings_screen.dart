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
      appBar: AjilHeader(
        title: 'الإعدادات',
        titleSize: 22,
        showLeading: false,
        subtitle: '${w.storeName} · ${w.branch.name} · ${w.displayName}${w.isOwner ? ' (المالك)' : ''}',
      ),
      bottomNavigationBar: const AjilNavBar(index: 3),
      body: ListView(padding: const EdgeInsets.only(bottom: 24), children: [
        SectionCard(
          child: Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: AjilColors.primaryLight, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.workspace_premium_outlined, color: AjilColors.primaryDark),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('الباقة: $plan', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                if (exp != null)
                  Text('تنتهي: ${intl.DateFormat('d MMMM y', 'ar').format(exp)}',
                      style: TextStyle(fontSize: 13, color: s.subscriptionExpired ? AjilColors.debt : AjilColors.textMuted)),
              ]),
            ),
            if (w.isOwner)
              LinkText('تفعيل بكود', onTap: () => _redeem(context, ref), size: 14, weight: FontWeight.w500),
          ]),
        ),
        if (w.isOwner)
          _group([
            _tile(Icons.notifications_active_outlined, 'التنبيهات والتحصيل', () => context.push('/settings/reminders')),
            _tile(Icons.people_alt_outlined, 'الموظفون', () => context.push('/settings/employees')),
            _tile(Icons.phonelink_setup_outlined, 'الأجهزة', () => context.push('/settings/devices')),
            _tile(Icons.store_outlined, 'الفروع والعملات', () => _storeSheet(context, ref)),
          ]),
        _group([
          _tile(Icons.sync_outlined, 'حركات غير متزامنة', () => context.push('/unsynced'), trailing: s.pending > 0 ? '${s.pending}' : null),
          _row(
            Icons.translate_outlined,
            'الأرقام الهندية (١٢٣)',
            null,
            trailingWidget: Switch(
              value: f.arabicIndicDigits,
              onChanged: (v) => ref.read(moneyFormatProvider.notifier).state = MoneyFormat(arabicIndicDigits: v),
            ),
          ),
          _tile(Icons.password_outlined, 'تغيير كلمة المرور', () => _changePassword(context, ref)),
          if (AppConfig.supportWhatsapp.isNotEmpty)
            _tile(Icons.support_agent_outlined, 'الدعم الفني (واتساب)',
                () => launchUrl(Uri.parse('https://wa.me/${AppConfig.supportWhatsapp}'), mode: LaunchMode.externalApplication)),
        ]),
        _group([_tile(Icons.logout, 'خروج (لتبديل الفرع أو المستخدم)', () => s.logout(), color: AjilColors.debt)]),
      ]),
    );
  }

  Widget _group(List<Widget> rows) => SectionCard(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Column(children: [
          for (var i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i < rows.length - 1) const Divider(height: 1, color: AjilColors.divider),
          ],
        ]),
      );

  Widget _tile(IconData icon, String title, VoidCallback onTap, {String? trailing, Color? color}) => _row(
        icon,
        title,
        onTap,
        color: color,
        trailingWidget: trailing != null
            ? Container(
                constraints: const BoxConstraints(minWidth: 22),
                height: 22,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AjilColors.pendingDot, borderRadius: BorderRadius.circular(11)),
                child: Text(trailing, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AjilColors.badgeText)),
              )
            : (color == null ? const Icon(Icons.chevron_left_rounded, color: AjilColors.textMuted) : null),
      );

  Widget _row(IconData icon, String title, VoidCallback? onTap, {Widget? trailingWidget, Color? color}) => InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Row(children: [
            Icon(icon, size: 22, color: color ?? AjilColors.textSoft),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: TextStyle(fontSize: 15, color: color ?? AjilColors.text))),
            if (trailingWidget != null) trailingWidget,
          ]),
        ),
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
