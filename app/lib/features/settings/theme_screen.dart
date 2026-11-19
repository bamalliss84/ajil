import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../state/providers.dart';

/// «مظهر التطبيق» — اختيار كل مستخدم لنفسه (docs/design/SettingsTheme.dc.html)
class ThemeScreen extends ConsumerWidget {
  const ThemeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctl = ref.watch(themeProvider);
    final isOwner = ref.watch(sessionProvider).session?.isOwner ?? false;
    final c = context.ajil;
    return Scaffold(
      backgroundColor: c.background,
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Material(
          color: c.header,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
              child: Row(children: [
                Semantics(
                  button: true,
                  label: 'رجوع',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(11),
                    onTap: () => Navigator.of(context).maybePop(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(color: c.onPrimary.withOpacity(.14), borderRadius: BorderRadius.circular(11)),
                      child: Icon(Icons.arrow_back_rounded, size: 18, color: c.onPrimary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text('مظهر التطبيق', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: c.onPrimary)),
              ]),
            ),
          ),
        ),
        Expanded(
          child: ListView(padding: const EdgeInsets.all(14), children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
              child: Text('اختيارك أنت وحدك — لكل موظف مظهره، ويتبعك على أي جهاز تدخل منه.',
                  style: TextStyle(fontSize: 13, color: c.textMuted)),
            ),
            for (final t in AjilTheme.all) _ThemeCard(t, selected: ctl.theme.id == t.id, onTap: () => ctl.select(t.id)),
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(color: c.infoBg, borderRadius: BorderRadius.circular(14)),
              child: Text(
                'التبديل فوري ولا يحتاج إعادة تشغيل، ويعمل بدون إنترنت.'
                '${isOwner ? '\nوبما أنك المالك، فمظهرك هذا يراه زبائنك في صفحة كشف الحساب.' : ''}',
                style: TextStyle(fontSize: 13, color: c.infoText, height: 1.5),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
              child: Text('معاينة', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500, color: c.textMuted)),
            ),
            Row(children: [
              for (final t in AjilTheme.all) ...[
                if (t != AjilTheme.all.first) const SizedBox(width: 11),
                Expanded(child: _Preview(t)),
              ],
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard(this.t, {required this.selected, required this.onTap});
  final AjilTheme t;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ajil;
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Semantics(
        button: true,
        selected: selected,
        label: t.nameAr,
        child: Material(
          type: MaterialType.transparency,
          child: Ink(
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: selected ? c.primary : c.surface, width: 2),
              boxShadow: [BoxShadow(color: c.shadow, blurRadius: 2, offset: const Offset(0, 1))],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Row(children: [
                  for (final s in t.swatches) ...[Swatch(s, size: 34, radius: 10), const SizedBox(width: 6)],
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(t.nameAr, style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: c.text)),
                      Text(t.descriptionAr, style: TextStyle(fontSize: 12.5, color: c.textMuted)),
                    ]),
                  ),
                  if (selected)
                    Icon(Icons.check_rounded, size: 22, color: c.primary)
                  else
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: c.border, width: 1.8)),
                    ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// بطاقة معاينة مصغّرة بألوان المظهر نفسه (وليس المظهر الحالي)
class _Preview extends StatelessWidget {
  const _Preview(this.t);
  final AjilTheme t;

  @override
  Widget build(BuildContext context) => Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: t.shadow, blurRadius: 2, offset: const Offset(0, 1))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(
            color: t.header,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Text('بقالة الأمانة', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: t.onPrimary)),
          ),
          Container(
            color: t.surface,
            padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('عليه', style: TextStyle(fontSize: 11.5, color: t.textMuted)),
              Text('20,000', textDirection: TextDirection.ltr, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: t.debt)),
              const SizedBox(height: 9),
              Container(
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: t.primary, borderRadius: BorderRadius.circular(10)),
                child: Text('سداد', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: t.onPrimary)),
              ),
            ]),
          ),
        ]),
      );
}

/// مربع لون صغير بحدّ داخلي خفيف
class Swatch extends StatelessWidget {
  const Swatch(this.color, {super.key, this.size = 18, this.radius = 6});
  final Color color;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: context.ajil.shadow, width: 1),
        ),
      );
}
