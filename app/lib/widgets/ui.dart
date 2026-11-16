import 'package:flutter/material.dart';

import '../core/theme.dart';

/// مكوّنات الواجهة حسب docs/design/*.dc.html

/// مقطّع: مسار رمادي #EEF2F1 وعنصر مختار أبيض (زوايا 12 / 9، ارتفاع 38)
class AjilSegmented<T> extends StatelessWidget {
  const AjilSegmented({super.key, required this.options, required this.value, required this.onChanged, this.fontSize = 14});
  final List<(T, String)> options;
  final T value;
  final ValueChanged<T> onChanged;
  final double fontSize;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: AjilColors.track, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          for (final (v, label) in options)
            Expanded(
              child: Semantics(
                button: true,
                selected: v == value,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(v),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: v == value ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Text(label,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: v == value ? FontWeight.w600 : FontWeight.w400,
                          color: v == value ? AjilColors.text : AjilColors.textSoft,
                        )),
                  ),
                ),
              ),
            ),
        ]),
      );
}

/// شريحة دائرية (Pill): المختار داكن (أو أخضر في فلاتر الزبائن)
class PillChip extends StatelessWidget {
  const PillChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.selectedColor = AjilColors.chipSelected,
    this.height = 34,
    this.fontSize = 13,
    this.icon,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color selectedColor;
  final double height;
  final double fontSize;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => Material(
        color: selected ? selectedColor : Colors.white,
        shape: StadiumBorder(side: selected ? BorderSide.none : const BorderSide(color: AjilColors.border)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Container(
            height: height,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: selected ? Colors.white : AjilColors.textSoft),
                const SizedBox(width: 4),
              ],
              Text(label, style: TextStyle(fontSize: fontSize, color: selected ? Colors.white : AjilColors.textSoft)),
            ]),
          ),
        ),
      );
}

/// خيار مربع (شاشة الوعد): المختار حدود خضراء 2 وخلفية خضراء فاتحة
class OptionTile extends StatelessWidget {
  const OptionTile({super.key, required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
        color: selected ? AjilColors.primaryLight : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: selected ? AjilColors.primary : AjilColors.border, width: selected ? 2 : 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: SizedBox(
            height: 46,
            child: Center(
              child: Text(label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    color: selected ? AjilColors.primaryDark : AjilColors.textSoft,
                  )),
            ),
          ),
        ),
      );
}

/// عنوان فوق الحقل (التصميم يضع التسميات فوق الحقول لا داخلها)
class LabeledField extends StatelessWidget {
  const LabeledField({super.key, required this.label, required this.child, this.helper, this.labelStyle, this.gap = 4});
  final String label;
  final Widget child;
  final String? helper;
  final TextStyle? labelStyle;
  final double gap;
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: labelStyle ?? const TextStyle(fontSize: 13, color: AjilColors.textSoft)),
          SizedBox(height: gap),
          child,
          if (helper != null) ...[
            const SizedBox(height: 4),
            Text(helper!, style: const TextStyle(fontSize: 12, color: AjilColors.textMuted)),
          ],
        ],
      );
}

/// مربع الوحدة الرمادي بجانب حقل المبلغ (ر.ي)
class UnitBox extends StatelessWidget {
  const UnitBox(this.text, {super.key, this.height = 46});
  final String text;
  final double height;
  @override
  Widget build(BuildContext context) => Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: AjilColors.track, borderRadius: BorderRadius.circular(12)),
        child: Text(text, style: const TextStyle(fontSize: 15)),
      );
}

/// صف بخانة اختيار: النص يميناً والخانة يساراً، فاصل سفلي
class CheckRow extends StatelessWidget {
  const CheckRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.bold = false,
    this.divider = true,
    this.minHeight = 52,
    this.subtitle,
  });
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool bold;
  final bool divider;
  final double minHeight;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: Container(
          constraints: BoxConstraints(minHeight: minHeight),
          decoration: divider ? const BoxDecoration(border: Border(bottom: BorderSide(color: AjilColors.divider))) : null,
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(label, style: TextStyle(fontSize: bold ? 16 : 15, fontWeight: bold ? FontWeight.w600 : FontWeight.w400)),
                if (subtitle != null) Text(subtitle!, style: const TextStyle(fontSize: 12, color: AjilColors.textMuted)),
              ]),
            ),
            Transform.scale(
              scale: 1.15,
              child: Checkbox(value: value, onChanged: onChanged == null ? null : (v) => onChanged!(v ?? false)),
            ),
          ]),
        ),
      );
}

/// زر أيقونة مربع 44 بحدود (هيدر الزبون، الاتصال وواتساب)
class SquareIconButton extends StatelessWidget {
  const SquareIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.color = AjilColors.textSoft,
    this.bg = Colors.white,
    this.borderColor = AjilColors.border,
    this.size = 44,
    this.iconSize = 20,
    this.radius = 12,
    this.badge,
  });
  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final Color color;
  final Color bg;
  final Color? borderColor;
  final double size;
  final double iconSize;
  final double radius;
  final int? badge;
  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: Stack(clipBehavior: Clip.none, children: [
          Material(
            color: bg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius),
              side: borderColor == null ? BorderSide.none : BorderSide(color: borderColor!),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(radius),
              onTap: onPressed,
              child: SizedBox(width: size, height: size, child: Icon(icon, size: iconSize, color: color, semanticLabel: tooltip)),
            ),
          ),
          if (badge != null && badge! > 0)
            Positioned(
              top: 6,
              left: 6,
              child: IgnorePointer(
                child: Container(
                  constraints: const BoxConstraints(minWidth: 18),
                  height: 18,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: AjilColors.pendingDot, borderRadius: BorderRadius.circular(9)),
                  child: Text('$badge', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AjilColors.badgeText, height: 1.1)),
                ),
              ),
            ),
        ]),
      );
}

/// هيدر أبيض بخط سفلي: زر إغلاق/رجوع، عنوان، سطر فرعي، أزرار يسار
class AjilHeader extends StatelessWidget implements PreferredSizeWidget {
  const AjilHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.close = false,
    this.actions = const [],
    this.titleSize = 18,
    this.showLeading = true,
    this.subtitleLtr = false,
    this.onBack,
  });
  final String title;
  final String? subtitle;
  final bool close;
  final bool showLeading;
  final bool subtitleLtr;
  final List<Widget> actions;
  final double titleSize;
  final VoidCallback? onBack;
  @override
  Size get preferredSize => const Size.fromHeight(73);
  @override
  Widget build(BuildContext context) {
    final canBack = onBack != null || Navigator.of(context).canPop();
    return Material(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 73,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AjilColors.headerBorder))),
          child: Row(children: [
            if (showLeading && canBack) ...[
              SizedBox(
                width: 44,
                height: 44,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                  icon: Icon(close ? Icons.close_rounded : Icons.chevron_right_rounded, size: close ? 26 : 30),
                  tooltip: close ? 'إغلاق' : 'رجوع',
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: titleSize, fontWeight: FontWeight.w600)),
                if (subtitle != null)
                  Text(subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection: subtitleLtr ? TextDirection.ltr : null,
                      textAlign: subtitleLtr ? TextAlign.right : null,
                      style: const TextStyle(fontSize: 13, color: AjilColors.textMuted)),
              ]),
            ),
            for (final a in actions) ...[const SizedBox(width: 10), a],
          ]),
        ),
      ),
    );
  }
}

/// شعار آجِل: «آ» أبيض على مربع أخضر
class AjilLogo extends StatelessWidget {
  const AjilLogo({super.key, this.size = 72});
  final double size;
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: AjilColors.primary, borderRadius: BorderRadius.circular(size * 0.28)),
        child: Text('آ', style: TextStyle(color: Colors.white, fontSize: size * 0.55, fontWeight: FontWeight.w600, height: 1.25)),
      );
}

/// رابط نصي بخط سفلي
class LinkText extends StatelessWidget {
  const LinkText(this.text, {super.key, required this.onTap, this.color = AjilColors.primary, this.size = 15, this.weight = FontWeight.w400});
  final String text;
  final VoidCallback? onTap;
  final Color color;
  final double size;
  final FontWeight weight;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          child: Text(text,
              style: TextStyle(
                color: color,
                fontSize: size,
                fontWeight: weight,
                decoration: TextDecoration.underline,
                decorationColor: color,
              )),
        ),
      );
}

/// شريط معلومة ملون (يوم المطالبة، الوعد، ملاحظة)
class InfoStrip extends StatelessWidget {
  const InfoStrip({
    super.key,
    required this.text,
    this.icon,
    this.bg = AjilColors.infoBg,
    this.fg = AjilColors.infoText,
    this.action,
    this.margin,
    this.onTap,
  });
  final String text;
  final IconData? icon;
  final Color bg;
  final Color fg;
  final (String, VoidCallback)? action;
  final EdgeInsets? margin;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Padding(
        padding: margin ?? EdgeInsets.zero,
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: action == null ? 12 : 4),
              child: Row(children: [
                if (icon != null) ...[Icon(icon, size: 20, color: fg), const SizedBox(width: 10)],
                Expanded(child: Text(text, style: TextStyle(color: fg, fontSize: 14))),
                if (action != null) ...[const SizedBox(width: 8), LinkText(action!.$1, onTap: action!.$2, color: fg, size: 14, weight: FontWeight.w500)],
              ]),
            ),
          ),
        ),
      );
}

/// بطاقة بيضاء بزوايا 16 وعنوان اختياري
class AjilCard extends StatelessWidget {
  const AjilCard({super.key, required this.child, this.padding = const EdgeInsets.all(14), this.margin = const EdgeInsets.fromLTRB(16, 14, 16, 0)});
  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;
  @override
  Widget build(BuildContext context) => Container(
        margin: margin,
        padding: padding,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: child,
      );
}

/// عنوان قسم داخل البطاقة (16/600) مع فاصل سفلي
class CardTitle extends StatelessWidget {
  const CardTitle(this.text, {super.key, this.trailing, this.divider = true});
  final String text;
  final Widget? trailing;
  final bool divider;
  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: 52),
        decoration: divider ? const BoxDecoration(border: Border(bottom: BorderSide(color: AjilColors.divider))) : null,
        child: Row(children: [
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
          if (trailing != null) trailing!,
        ]),
      );
}

/// شارة نوع الحركة (دين / سداد / إلغاء / افتتاحي)
class TypeBadge extends StatelessWidget {
  const TypeBadge(this.text, {super.key, required this.bg, required this.fg});
  final String text;
  final Color bg;
  final Color fg;
  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minWidth: 52),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
        child: Text(text, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: fg)),
      );
}
