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
        _min.text = '${v['monthly_claim_min']}';
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
      if (mounted) showOk(context, 'تم حفظ الإعدادات');
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _s;
    final owner = sessionOf(ref).isOwner;
    return Scaffold(
      appBar: AppBar(title: const Text('التنبيهات والتحصيل')),
      body: s == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(padding: const EdgeInsets.only(bottom: 24), children: [
              SectionCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('المطالبة الشهرية', style: TextStyle(fontWeight: FontWeight.w600)),
                    value: s['monthly_claim_enabled'] == true,
                    onChanged: owner ? (v) => setState(() => s['monthly_claim_enabled'] = v) : null,
                  ),
                  Row(children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: s['monthly_claim_day'] as int,
                        decoration: const InputDecoration(labelText: 'يوم المطالبة من كل شهر'),
                        items: [
                          for (final d in [1, 5, 10, 15, 20, 25, 28]) DropdownMenuItem(value: d, child: Text('يوم $d')),
                          const DropdownMenuItem(value: 0, child: Text('آخر يوم في الشهر')),
                        ],
                        onChanged: owner ? (v) => setState(() => s['monthly_claim_day'] = v) : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: (s['monthly_claim_time'] as String).substring(0, 5),
                        decoration: const InputDecoration(labelText: 'الوقت'),
                        items: const [
                          DropdownMenuItem(value: '09:00', child: Text('9:00 ص')),
                          DropdownMenuItem(value: '16:00', child: Text('4:00 م')),
                          DropdownMenuItem(value: '20:00', child: Text('8:00 م')),
                        ],
                        onChanged: owner ? (v) => setState(() => s['monthly_claim_time'] = v) : null,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _min,
                    enabled: owner,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'تشمل الزبائن الذين عليهم أكثر من'),
                  ),
                  const SizedBox(height: 8),
                  const Text('في يوم المطالبة يجهّز التطبيق قائمة تحصيل مع رسالة واتساب جاهزة لكل زبون.',
                      style: TextStyle(fontSize: 13, color: AjilColors.textMuted)),
                ]),
              ),
              SectionCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const Text('الديون المتأخرة', style: TextStyle(fontWeight: FontWeight.w600)),
                  DropdownButtonFormField<int>(
                    value: s['overdue_days'] as int,
                    decoration: const InputDecoration(labelText: 'نبّهني إذا لم يسدد الزبون منذ'),
                    items: const [
                      DropdownMenuItem(value: 30, child: Text('30 يوماً')),
                      DropdownMenuItem(value: 60, child: Text('60 يوماً')),
                      DropdownMenuItem(value: 90, child: Text('90 يوماً')),
                    ],
                    onChanged: owner ? (v) => setState(() => s['overdue_days'] = v) : null,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    value: s['employee_void_hours'] as int,
                    decoration: const InputDecoration(labelText: 'مهلة الموظف لإلغاء حركاته'),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('ساعة')),
                      DropdownMenuItem(value: 24, child: Text('24 ساعة')),
                      DropdownMenuItem(value: 72, child: Text('3 أيام')),
                    ],
                    onChanged: owner ? (v) => setState(() => s['employee_void_hours'] = v) : null,
                  ),
                ]),
              ),
              SectionCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const Text('رسالة التذكير للزبون', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(controller: _tpl, enabled: owner, maxLines: 4),
                  const SizedBox(height: 6),
                  const Text('{الاسم} {البقالة} {المبلغ} {الرابط} — تُرسل من واتساب جوالك بضغطة، ولا تُرسل تلقائياً.',
                      style: TextStyle(fontSize: 12, color: AjilColors.textMuted)),
                ]),
              ),
              SectionCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const Text('إرسال الأرصدة للزبائن', style: TextStyle(fontWeight: FontWeight.w600)),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('السماح للموظفين بإرسال الأرصدة'),
                    subtitle: const Text('المالك يستطيع دائماً'),
                    value: s['employees_can_send_notices'] == true,
                    onChanged: owner ? (v) => setState(() => s['employees_can_send_notices'] = v) : null,
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/notices'),
                    icon: const Icon(Icons.campaign_outlined),
                    label: const Text('افتح إرسال الأرصدة'),
                  ),
                ]),
              ),
              if (owner) Padding(padding: const EdgeInsets.all(16), child: FilledButton(onPressed: _save, child: const Text('حفظ'))),
            ]),
    );
  }
}
