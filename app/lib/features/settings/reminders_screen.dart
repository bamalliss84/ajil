import 'package:ajil_core/ajil_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';

/// إعدادات التنبيهات والتحصيل (للمالك): المطالبة الشهرية، الديون المتأخرة، قالب الرسالة
class RemindersScreen extends ConsumerStatefulWidget {
  const RemindersScreen({super.key});
  @override
  ConsumerState<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends ConsumerState<RemindersScreen> {
  Map<String, dynamic>? _s;
  final _min = TextEditingController();
  final _tpl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final s = ref.read(sessionProvider);
    s.api.settings(s.session!.storeId).then((v) {
      if (!mounted) return;
      setState(() {
        _s = Map.of(v);
        _min.text = '${v['monthly_claim_min']}'.replaceFirst(RegExp(r'\.0+$'), '');
        _tpl.text = v['reminder_template'];
      });
    }).catchError((e) {
      if (mounted) showError(context, e);
    });
  }

  Future<void> _save() async {
    final s = ref.read(sessionProvider);
    try {
      await s.api.updateSettings(s.session!.storeId, {
        'monthly_claim_enabled': _s!['monthly_claim_enabled'],
        'monthly_claim_day': _s!['monthly_claim_day'],
        'monthly_claim_time': _s!['monthly_claim_time'],
        'monthly_claim_min': _min.text.trim(),
        'overdue_days': _s!['overdue_days'],
        'employee_void_hours': _s!['employee_void_hours'],
        'reminder_template': _tpl.text.trim(),
        'employees_can_send_notices': _s!['employees_can_send_notices'] == true,
      });
      s.settings?['employees_can_send_notices'] = _s!['employees_can_send_notices'] == true;
      s.settings?['reminder_template'] = _tpl.text.trim(); // يستخدمه زر التذكير بواتساب فوراً
      if (mounted) showOk(context, 'تم حفظ الإعدادات');
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _s;
    final owner = sessionOf(ref).isOwner;
    final cur = Currency.of(sessionOf(ref).defaultCurrency).symbolAr;
    final dd = TextStyle(fontFamily: ajilFont, fontSize: 15, color: context.ajil.text);
    const ddPad = EdgeInsets.symmetric(horizontal: 10, vertical: 12);
    Widget compactDrop(int value, List<(int, String)> items, ValueChanged<int?>? onChanged) => SizedBox(
          width: 124,
          child: DropdownButtonFormField<int>(
            value: value,
            isExpanded: true,
            style: TextStyle(fontFamily: ajilFont, fontSize: 14, color: context.ajil.text),
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
            decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 9)),
            items: [for (final (v, l) in items) DropdownMenuItem(value: v, child: Text(l))],
            onChanged: onChanged,
          ),
        );
    Widget inlineRow(String label, Widget trailing, {bool divider = true}) => Container(
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: divider ? BoxDecoration(border: Border(bottom: BorderSide(color: context.ajil.divider))) : null,
          child: Row(children: [
            Expanded(child: Text(label, style: const TextStyle(fontSize: 15))),
            const SizedBox(width: 8),
            trailing,
          ]),
        );

    return Scaffold(
      appBar: const AjilHeader(title: 'التنبيهات والتحصيل', titleSize: 19),
      body: s == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.only(bottom: 24), children: [
              AjilCard(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  CheckRow(
                    label: 'المطالبة الشهرية',
                    bold: true,
                    minHeight: 56,
                    value: s['monthly_claim_enabled'] == true,
                    onChanged: owner ? (v) => setState(() => s['monthly_claim_enabled'] = v) : null,
                  ),
                  const SizedBox(height: 12),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                      child: LabeledField(
                        label: 'يوم المطالبة من كل شهر',
                        child: DropdownButtonFormField<int>(
                          value: s['monthly_claim_day'] as int,
                          isExpanded: true,
                          style: dd,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          decoration: const InputDecoration(contentPadding: ddPad),
                          items: [
                            for (final d in [1, 5, 10, 15, 20, 25, 28]) DropdownMenuItem(value: d, child: Text('يوم $d')),
                            const DropdownMenuItem(value: 0, child: Text('آخر يوم في الشهر')),
                          ],
                          onChanged: owner ? (v) => setState(() => s['monthly_claim_day'] = v) : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: LabeledField(
                        label: 'الوقت',
                        child: DropdownButtonFormField<String>(
                          value: (s['monthly_claim_time'] as String).substring(0, 5),
                          isExpanded: true,
                          style: dd,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded),
                          decoration: const InputDecoration(contentPadding: ddPad),
                          items: const [
                            DropdownMenuItem(value: '09:00', child: Text('9:00 ص')),
                            DropdownMenuItem(value: '16:00', child: Text('4:00 م')),
                            DropdownMenuItem(value: '20:00', child: Text('8:00 م')),
                          ],
                          onChanged: owner ? (v) => setState(() => s['monthly_claim_time'] = v) : null,
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  LabeledField(
                    label: 'تشمل الزبائن الذين عليهم أكثر من',
                    child: Row(children: [
                      Expanded(
                        child: TextField(controller: _min, enabled: owner, style: const TextStyle(fontSize: 15), keyboardType: TextInputType.number),
                      ),
                      const SizedBox(width: 8),
                      UnitBox(cur),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(color: context.ajil.background, borderRadius: BorderRadius.circular(12)),
                    child: Text('في يوم المطالبة يجهّز التطبيق قائمة تحصيل مع رسالة واتساب جاهزة لكل زبون.',
                        style: TextStyle(fontSize: 13, color: context.ajil.textMuted)),
                  ),
                ]),
              ),
              AjilCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const CardTitle('الديون المتأخرة والمهلة'),
                  inlineRow(
                    'نبّهني إذا لم يسدد الزبون منذ',
                    compactDrop(s['overdue_days'] as int, const [(30, '30 يوماً'), (60, '60 يوماً'), (90, '90 يوماً')],
                        owner ? (v) => setState(() => s['overdue_days'] = v) : null),
                  ),
                  inlineRow(
                    'مهلة الموظف لإلغاء حركاته',
                    compactDrop(s['employee_void_hours'] as int, const [(1, 'ساعة'), (24, '24 ساعة'), (72, '3 أيام')],
                        owner ? (v) => setState(() => s['employee_void_hours'] = v) : null),
                    divider: false,
                  ),
                ]),
              ),
              AjilCard(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const CardTitle('رسالة التذكير للزبون', divider: false),
                  TextField(controller: _tpl, enabled: owner, maxLines: 4, style: const TextStyle(fontSize: 14, height: 1.7)),
                  const SizedBox(height: 8),
                  Text('{الاسم} {البقالة} {المبلغ} {الرابط} — تُرسل من واتساب جوالك بضغطة، ولا تُرسل تلقائياً.',
                      style: TextStyle(fontSize: 12, color: context.ajil.textMuted)),
                ]),
              ),
              AjilCard(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const CardTitle('إرسال الأرصدة للزبائن', divider: false),
                  CheckRow(
                    label: 'السماح للموظفين بإرسال الأرصدة',
                    subtitle: 'المالك يستطيع دائماً',
                    value: s['employees_can_send_notices'] == true,
                    onChanged: owner ? (v) => setState(() => s['employees_can_send_notices'] = v) : null,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/notices'),
                    icon: const Icon(Icons.campaign_outlined),
                    label: const Text('افتح إرسال الأرصدة'),
                  ),
                ]),
              ),
              if (owner)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                  child: FilledButton(onPressed: _save, child: const Text('حفظ الإعدادات')),
                ),
            ]),
    );
  }
}
