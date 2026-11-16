import 'package:ajil_core/ajil_core.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme.dart';
import '../state/providers.dart';

/// مبلغ منسق بلون حسب الإشارة (الأحمر للدين فقط)
class MoneyText extends ConsumerWidget {
  const MoneyText(this.value, this.currency,
      {super.key, this.size = 16, this.symbol = true, this.signed = false, this.color, this.weight = FontWeight.w600});
  final Decimal value;
  final String currency;
  final double size;
  final bool symbol;
  final bool signed;
  final Color? color;
  final FontWeight weight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = ref.watch(moneyFormatProvider);
    final c = color ??
        (value > Decimal.zero ? AjilColors.debt : (value < Decimal.zero ? AjilColors.paid : AjilColors.textMuted));
    return Text(
      f.amount(value, currency, withSymbol: symbol, signed: signed),
      style: TextStyle(fontSize: size, fontWeight: weight, color: c),
      textDirection: TextDirection.rtl,
    );
  }
}

/// أيقونة حالة المزامنة أمام كل حركة
class SyncBadge extends StatelessWidget {
  const SyncBadge(this.state, {super.key, this.compact = false});
  final SyncState state;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = switch (state) {
      SyncState.synced => (Icons.check_rounded, AjilColors.paid, 'متزامن'),
      SyncState.pending => (Icons.schedule_rounded, const Color(0xFFA15C07), 'بانتظار'),
      SyncState.failed => (Icons.warning_amber_rounded, AjilColors.debt, 'مرفوضة'),
    };
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 14, color: color, semanticLabel: label),
      if (!compact) ...[const SizedBox(width: 3), Text(label, style: TextStyle(fontSize: 12, color: color))],
    ]);
  }
}

/// شريط علوي: غير متصل / حركات بانتظار المزامنة / اشتراك منتهٍ
class StatusBanner extends ConsumerWidget {
  const StatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sessionProvider);
    if (s.mustChangePassword) {
      return _Banner(
        icon: Icons.password_outlined,
        text: 'كلمة مرورك مؤقتة — غيّرها الآن',
        bg: AjilColors.infoBg,
        fg: AjilColors.infoText,
        action: ('تغيير', () => context.push('/settings')),
      );
    }
    if (s.subscriptionExpired) {
      return _Banner(
        icon: Icons.lock_clock_outlined,
        text: 'الاشتراك منتهٍ — البيانات للقراءة فقط',
        bg: AjilColors.debtBg,
        fg: const Color(0xFF7A2318),
        action: s.session?.isOwner == true ? ('تجديد', () => context.push('/settings')) : null,
      );
    }
    if (!s.online || s.pending > 0) {
      return _Banner(
        icon: s.online ? Icons.sync_rounded : Icons.cloud_off_rounded,
        text: s.online
            ? '${s.pending} حركات بانتظار المزامنة'
            : (s.pending > 0 ? 'غير متصل — ${s.pending} حركات بانتظار المزامنة' : 'غير متصل — تعمل البيانات من الجوال'),
        bg: AjilColors.pendingBg,
        fg: AjilColors.pendingText,
        action: s.pending > 0 ? ('عرض', () => context.push('/unsynced')) : null,
      );
    }
    return const SizedBox.shrink();
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.text, required this.bg, required this.fg, this.action});
  final IconData icon;
  final String text;
  final Color bg;
  final Color fg;
  final (String, VoidCallback)? action;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Icon(icon, size: 20, color: fg),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: fg, fontSize: 14))),
          if (action != null)
            TextButton(onPressed: action!.$2, child: Text(action!.$1, style: TextStyle(color: fg, fontWeight: FontWeight.w600))),
        ]),
      );
}

class Initials extends StatelessWidget {
  const Initials(this.text, {super.key, this.size = 42});
  final String text;
  final double size;
  @override
  Widget build(BuildContext context) => CircleAvatar(
        radius: size / 2,
        backgroundColor: AjilColors.primaryLight,
        child: Text(text, style: TextStyle(color: AjilColors.primaryDark, fontWeight: FontWeight.w600, fontSize: size * .34)),
      );
}

class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.child, this.padding = const EdgeInsets.all(14), this.margin});
  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets? margin;
  @override
  Widget build(BuildContext context) => Container(
        margin: margin ?? const EdgeInsets.fromLTRB(16, 14, 16, 0),
        padding: padding,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: child,
      );
}

/// اختيار العملة (ر.ي | ر.س …)
class CurrencyToggle extends StatelessWidget {
  const CurrencyToggle({super.key, required this.currencies, required this.value, required this.onChanged});
  final List<String> currencies;
  final String value;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) {
    if (currencies.length < 2) return const SizedBox.shrink();
    return SegmentedButton<String>(
      segments: [for (final c in currencies) ButtonSegment(value: c, label: Text(Currency.of(c).symbolAr))],
      selected: {value},
      showSelectedIcon: false,
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

/// لوحة أرقام كبيرة لإدخال المبلغ بسرعة
class AmountKeypad extends StatelessWidget {
  const AmountKeypad({super.key, required this.onKey});
  final ValueChanged<String> onKey; // '0'..'9' ، '000' ، '.' ، 'del'

  @override
  Widget build(BuildContext context) {
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '000', '0', 'del'];
    return Directionality(
      textDirection: TextDirection.ltr,
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 2.6,
        children: [
          for (final k in keys)
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  HapticFeedback.selectionClick();
                  onKey(k);
                },
                child: Center(
                  child: k == 'del'
                      ? const Icon(Icons.backspace_outlined, semanticLabel: 'حذف')
                      : Text(k, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// زر الدين (حدود حمراء) وزر السداد (أخضر ممتلئ)
class DebtPayButtons extends StatelessWidget {
  const DebtPayButtons({super.key, required this.onDebt, required this.onPay});
  final VoidCallback onDebt;
  final VoidCallback onPay;
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onDebt,
            icon: const Icon(Icons.add_rounded),
            label: const Text('تسجيل دين'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AjilColors.debt,
              side: const BorderSide(color: AjilColors.debtBorder, width: 1.5),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(onPressed: onPay, icon: const Icon(Icons.check_rounded), label: const Text('تسجيل سداد')),
        ),
      ]);
}

void showError(BuildContext context, Object e) {
  final err = AjilError.parse(e);
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err.message), backgroundColor: AjilColors.debt));
}

void showOk(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AjilColors.primary));
}

/// شريط التنقل السفلي
class AjilNavBar extends StatelessWidget {
  const AjilNavBar({super.key, required this.index});
  final int index;
  static const _routes = ['/', '/customers', '/reports', '/settings'];
  @override
  Widget build(BuildContext context) => NavigationBar(
        selectedIndex: index,
        backgroundColor: Colors.white,
        indicatorColor: AjilColors.primaryLight,
        onDestinationSelected: (i) {
          if (i != index) context.go(_routes[i]);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'الرئيسية'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'الزبائن'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart), label: 'التقارير'),
          NavigationDestination(icon: Icon(Icons.menu), label: 'المزيد'),
        ],
      );
}

/// اسم الفرع ثابت أعلى الشاشات
class BranchChip extends ConsumerWidget {
  const BranchChip({super.key, this.light = false});
  final bool light;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sessionProvider).session;
    if (s == null) return const SizedBox.shrink();
    return Text('${s.branch.name} · ${s.displayName}${s.isOwner ? ' (المالك)' : ''}',
        style: TextStyle(fontSize: 13, color: light ? const Color(0xFFCFEDE3) : AjilColors.textMuted));
  }
}
