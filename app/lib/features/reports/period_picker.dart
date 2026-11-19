import 'package:ajil_core/ajil_core.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../widgets/common.dart';
import 'report_state.dart';

/// نافذة «اختر الفترة»: يوم / شهر / سنة / من – إلى
Future<ReportPeriod?> showPeriodPicker(
  BuildContext context, {
  required ReportPeriod current,
  required List<LedgerTx> txs,
  required String currency,
  required MoneyFormat f,
}) =>
    showModalBottomSheet<ReportPeriod>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.ajil.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (_) => _Picker(current: current, txs: txs, currency: currency, f: f),
    );

class _Picker extends StatefulWidget {
  const _Picker({required this.current, required this.txs, required this.currency, required this.f});
  final ReportPeriod current;
  final List<LedgerTx> txs;
  final String currency;
  final MoneyFormat f;
  @override
  State<_Picker> createState() => _PickerState();
}

class _PickerState extends State<_Picker> {
  final today = DateTime.now();
  late PeriodKind _kind = widget.current.kind;
  late int _year = widget.current.start.year;
  late int _month = widget.current.kind == PeriodKind.month ? widget.current.start.month : today.month;
  late DateTime _day = widget.current.kind == PeriodKind.day ? widget.current.start : today;
  late DateTime _from = widget.current.start;
  late DateTime _to = widget.current.effectiveEnd(today);
  late final List<int> _years = PeriodReport.years(widget.txs, today);
  late int _windowEnd = _years.indexOf(_year).clamp(0, _years.length - 1);
  final _paidCache = <int, List<Decimal>>{};

  MoneyFormat get f => widget.f;
  List<Decimal> _paid(int y) => _paidCache[y] ??= PeriodReport.monthlyCollected(widget.txs, y, widget.currency);

  ReportPeriod get _result => switch (_kind) {
        PeriodKind.day => ReportPeriod.day(_day),
        PeriodKind.month => ReportPeriod.month(_year, _month),
        PeriodKind.year => ReportPeriod.year(_year),
        PeriodKind.range => ReportPeriod.range(_from, _to),
      };

  String get _cta => switch (_kind) {
        PeriodKind.day => 'عرض ${f.digits('${_day.day} ${monthNames[_day.month - 1]}')}',
        PeriodKind.month => 'عرض ${monthNames[_month - 1]} ${f.digits('$_year')}',
        PeriodKind.year => 'عرض سنة ${f.digits('$_year')}',
        PeriodKind.range => 'عرض الفترة',
      };

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(
            child: Container(width: 40, height: 4, decoration: BoxDecoration(color: context.ajil.border, borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 8),
          Row(children: [
            const Expanded(child: Text('اختر الفترة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700))),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.close_rounded, color: context.ajil.textMuted),
              tooltip: 'إغلاق',
            ),
          ]),
          const SizedBox(height: 10),
          AjilSegmented<PeriodKind>(
            options: const [(PeriodKind.day, 'يوم'), (PeriodKind.month, 'شهر'), (PeriodKind.year, 'سنة'), (PeriodKind.range, 'من – إلى')],
            value: _kind,
            selectedFg: context.ajil.primaryDark,
            shadow: true,
            onChanged: (k) => setState(() => _kind = k),
          ),
          const SizedBox(height: 14),
          ...switch (_kind) {
            PeriodKind.month => _monthBody(),
            PeriodKind.year => _yearBody(),
            PeriodKind.day => _dayBody(),
            PeriodKind.range => _rangeBody(),
          },
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  foregroundColor: context.ajil.primary,
                  side: BorderSide(color: context.ajil.borderStrong),
                  textStyle: const TextStyle(fontFamily: ajilFont, fontSize: 15, fontWeight: FontWeight.w500),
                ),
                onPressed: () => Navigator.pop(context, ReportPeriod.currentMonth(today)),
                child: const Text('الشهر الحالي'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  textStyle: const TextStyle(fontFamily: ajilFont, fontSize: 17, fontWeight: FontWeight.w700),
                ),
                onPressed: () => Navigator.pop(context, _result),
                child: Text(_cta),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  /// صف السنوات: 3 سنوات ظاهرة مع سهمين
  Widget _yearsRow() {
    final end = _windowEnd;
    final start = (end - 2).clamp(0, _years.length - 1);
    final visible = _years.sublist(start, end + 1);
    Widget arrow(IconData icon, VoidCallback? onTap, String tip) => SquareIconButton(
          icon: icon,
          tooltip: tip,
          color: onTap == null ? context.ajil.axis : context.ajil.text,
          borderColor: onTap == null ? context.ajil.divider : context.ajil.border,
          onPressed: onTap,
        );
    return Row(children: [
      arrow(Icons.chevron_left_rounded, start > 0 ? () => setState(() => _windowEnd--) : null, 'السنوات السابقة'),
      Expanded(
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (final y in visible)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: PillChip(
                label: f.digits('$y'),
                selected: y == _year,
                selectedColor: context.ajil.primary,
                height: 40,
                fontSize: 15,
                onTap: () => setState(() {
                  _year = y;
                  if (DateTime(_year, _month).isAfter(today)) _month = today.month;
                }),
              ),
            ),
        ]),
      ),
      arrow(Icons.chevron_right_rounded, end < _years.length - 1 ? () => setState(() => _windowEnd++) : null, 'السنوات التالية'),
    ]);
  }

  List<Widget> _monthBody() {
    final paid = _paid(_year);
    final sym = Currency.of(widget.currency).symbolAr;
    return [
      _yearsRow(),
      const SizedBox(height: 14),
      GridView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8, mainAxisExtent: 64),
        children: [
          for (var m = 1; m <= 12; m++) _monthTile(m, paid[m - 1]),
        ],
      ),
      const SizedBox(height: 14),
      Row(children: [
        Icon(Icons.info_outline_rounded, size: 18, color: context.ajil.textMuted),
        const SizedBox(width: 8),
        Expanded(
          child: Text('الرقم تحت كل شهر = التحصيل بالألف $sym · الأشهر القادمة غير متاحة',
              style: TextStyle(fontSize: 12, color: context.ajil.textMuted)),
        ),
      ]),
    ];
  }

  Widget _monthTile(int m, Decimal paid) {
    final future = DateTime(_year, m).isAfter(today);
    final sel = !future && m == _month;
    final isNow = _year == today.year && m == today.month;
    final bg = sel ? context.ajil.primary : (future ? context.ajil.background : context.ajil.surface);
    final fg = sel ? context.ajil.onPrimary : (future ? context.ajil.axis : context.ajil.text);
    final subFg = sel ? context.ajil.onHeaderMuted : (future ? context.ajil.axis : context.ajil.textMuted);
    final border = sel ? context.ajil.primary : (future ? context.ajil.divider : context.ajil.border);
    return Material(
      color: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: border)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: future ? null : () => setState(() => _month = m),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(monthNames[m - 1], style: TextStyle(fontSize: 15, fontWeight: sel ? FontWeight.w700 : FontWeight.w500, color: fg)),
          Text(future ? 'قادم' : '${thousands(f, paid)}${isNow ? ' · حتى الآن' : ''}', style: TextStyle(fontSize: 11, color: subFg)),
        ]),
      ),
    );
  }

  List<Widget> _yearBody() => [
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, mainAxisSpacing: 8, crossAxisSpacing: 8, mainAxisExtent: 64),
          children: [
            for (final y in _years.reversed)
              () {
                final sel = y == _year;
                final total = _paid(y).fold(Decimal.zero, (a, b) => a + b);
                return Material(
                  color: sel ? context.ajil.primary : context.ajil.surface,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14), side: BorderSide(color: sel ? context.ajil.primary : context.ajil.border)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => setState(() => _year = y),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(f.digits('$y'),
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: sel ? context.ajil.onPrimary : context.ajil.text)),
                      Text('${thousands(f, total)} ألف${y == today.year ? ' · حتى الآن' : ''}',
                          style: TextStyle(fontSize: 11, color: sel ? context.ajil.onHeaderMuted : context.ajil.textMuted)),
                    ]),
                  ),
                );
              }(),
          ],
        ),
      ];

  List<Widget> _dayBody() {
    final first = DateTime(_years.first);
    return [
      SizedBox(
        height: 300,
        child: CalendarDatePicker(
          initialDate: _day.isBefore(first) ? first : _day,
          firstDate: first,
          lastDate: today,
          onDateChanged: (d) => setState(() => _day = d),
        ),
      ),
    ];
  }

  List<Widget> _rangeBody() {
    final first = DateTime(_years.first);
    Widget field(String label, DateTime v, ValueChanged<DateTime> set) => Expanded(
          child: LabeledField(
            label: label,
            child: Material(
              color: context.ajil.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: context.ajil.border)),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  final d = await showDatePicker(context: context, initialDate: v, firstDate: first, lastDate: today);
                  if (d != null) setState(() => set(d));
                },
                child: Container(
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(children: [
                    Icon(Icons.event_outlined, size: 18, color: context.ajil.textMuted),
                    const SizedBox(width: 8),
                    Text(f.digits('${v.day} ${monthNames[v.month - 1]} ${v.year}'), style: const TextStyle(fontSize: 15)),
                  ]),
                ),
              ),
            ),
          ),
        );
    final days = _result.days;
    return [
      Row(children: [
        field('من', _from, (d) => _from = d),
        const SizedBox(width: 10),
        field('إلى', _to, (d) => _to = d),
      ]),
      const SizedBox(height: 10),
      Text('${counted(f, days, 'يوم', 'يومان', 'أيام', 'يوماً')} · تُقارن بالفترة السابقة بنفس الطول',
          style: TextStyle(fontSize: 12, color: context.ajil.textMuted)),
    ];
  }
}
