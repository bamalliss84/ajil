import 'package:ajil_core/ajil_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';

/// الموظفون (للمالك): إضافة برقم مستخدم وكلمة مرور مؤقتة، الفروع، الإيقاف، إعادة تعيين كلمة المرور
class EmployeesScreen extends ConsumerStatefulWidget {
  const EmployeesScreen({super.key});
  @override
  ConsumerState<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends ConsumerState<EmployeesScreen> {
  List<Map<String, dynamic>>? _users;
  List<Branch> _branches = const [];

  Future<void> _load() async {
    final api = ref.read(sessionProvider).api;
    try {
      final u = await api.users();
      final b = await api.myBranches();
      if (!mounted) return;
      setState(() {
        _users = u;
        _branches = b;
      });
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _showCredentials(int userNo, String password) => showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('بيانات دخول الموظف'),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('رقم البقالة: ${sessionOf(ref).storePhone}'),
            Text('رقم المستخدم: $userNo'),
            SelectableText('كلمة المرور المؤقتة: $password', style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('سيُطلب منه تغييرها، وجهازه يحتاج اعتمادك من «الأجهزة».',
                style: TextStyle(fontSize: 13, color: context.ajil.textMuted)),
          ]),
          actions: [
            TextButton(
              onPressed: () => Clipboard.setData(ClipboardData(
                  text: 'آجِل\nرقم البقالة: ${sessionOf(ref).storePhone}\nرقم المستخدم: $userNo\nكلمة المرور: $password')),
              child: const Text('نسخ'),
            ),
            FilledButton(onPressed: () => Navigator.pop(ctx), style: FilledButton.styleFrom(minimumSize: const Size(80, 44)), child: const Text('تم')),
          ],
        ),
      );

  Future<void> _add() async {
    final name = TextEditingController();
    final chosen = <String>{if (_branches.isNotEmpty) sessionOf(ref).branch.id};
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => AlertDialog(
          title: const Text('موظف جديد'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: name, autofocus: true, decoration: const InputDecoration(labelText: 'الاسم')),
            const SizedBox(height: 8),
            for (final b in _branches)
              CheckboxListTile(
                value: chosen.contains(b.id),
                title: Text(b.name),
                onChanged: (v) => set(() => v == true ? chosen.add(b.id) : chosen.remove(b.id)),
              ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('رجوع')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(minimumSize: const Size(80, 44)), child: const Text('إضافة')),
          ],
        ),
      ),
    );
    if (ok != true) return;
    try {
      final r = await ref.read(sessionProvider).api.addEmployee(name.text.trim(), chosen.toList());
      await _load();
      await _showCredentials(r.userNo, r.tempPassword);
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final users = _users;
    final branchName = {for (final b in _branches) b.id: b.name};
    return Scaffold(
      appBar: const AjilHeader(title: 'الموظفون'),
      floatingActionButton: FloatingActionButton.extended(onPressed: _add, icon: const Icon(Icons.person_add_alt), label: const Text('موظف')),
      body: users == null
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              itemCount: users.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (_, i) {
                final u = users[i];
                final isOwner = u['role'] == 'owner';
                final active = u['is_active'] == true;
                final branches = ((u['user_branches'] as List?) ?? const []).map((b) => branchName[b['branch_id']] ?? '').join('، ');
                return ListTile(
                  tileColor: context.ajil.surface,
                  leading: CircleAvatar(backgroundColor: context.ajil.primaryLight, child: Text('${u['user_no']}')),
                  title: Text('${u['display_name']}${isOwner ? ' (المالك)' : ''}'),
                  subtitle: Text(isOwner ? 'كل الفروع' : '${active ? '' : 'موقوف · '}$branches'),
                  trailing: isOwner
                      ? null
                      : PopupMenuButton<String>(
                          onSelected: (v) async {
                            final api = ref.read(sessionProvider).api;
                            try {
                              if (v == 'reset') {
                                final pw = await api.resetEmployeePassword(u['id']);
                                await _showCredentials(u['user_no'], pw);
                              } else {
                                await api.setEmployee(u['id'], !active);
                                await _load();
                              }
                            } catch (e) {
                              if (context.mounted) showError(context, e);
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'reset', child: Text('كلمة مرور مؤقتة جديدة')),
                            PopupMenuItem(value: 'toggle', child: Text(active ? 'إيقاف' : 'إعادة تفعيل')),
                          ],
                        ),
                );
              },
            ),
    );
  }
}
