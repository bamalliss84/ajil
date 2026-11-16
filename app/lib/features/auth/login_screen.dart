import 'package:ajil_core/ajil_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';

/// الدخول: رقم جوال البقالة + رقم المستخدم + الفرع + كلمة المرور
/// الفرع يُختار هنا فقط، وآخر فرع يكون مختاراً مسبقاً
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phone = TextEditingController();
  final _userNo = TextEditingController(text: '1');
  final _password = TextEditingController();
  String? _branchId;
  bool _busy = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    final m = ref.read(sessionProvider).memory;
    if (m != null) {
      _phone.text = m.storePhone;
      _userNo.text = '${m.userNo}';
      _branchId = m.lastBranchId;
    }
  }

  List<Branch> get _branches {
    final no = int.tryParse(_userNo.text) ?? 0;
    try {
      final phone = Identity.normalizePhone(_phone.text);
      return ref.read(sessionProvider).rememberedBranches(phone, no);
    } catch (_) {
      return const [];
    }
  }

  Future<void> _submit() async {
    final no = int.tryParse(_userNo.text);
    if (no == null || no < 1) return showError(context, const AjilError('x', 'رقم المستخدم غير صحيح'));
    if (_password.text.isEmpty) return showError(context, const AjilError('x', 'اكتب كلمة المرور'));
    setState(() => _busy = true);
    try {
      await ref.read(sessionProvider).login(storePhone: _phone.text, userNo: no, password: _password.text, branchId: _branchId);
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final branches = _branches;
    if (_branchId != null && !branches.any((b) => b.id == _branchId)) _branchId = null;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
          children: [
            const _Logo(),
            const SizedBox(height: 28),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(labelText: 'رقم جوال البقالة'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _userNo,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'رقم المستخدم', helperText: 'المالك = 1'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              if (branches.length > 1) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _branchId ?? branches.first.id,
                    decoration: const InputDecoration(labelText: 'الفرع'),
                    items: [for (final b in branches) DropdownMenuItem(value: b.id, child: Text(b.name))],
                    onChanged: (v) => setState(() => _branchId = v),
                  ),
                ),
              ],
            ]),
            const SizedBox(height: 14),
            TextField(
              controller: _password,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'كلمة المرور',
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscure = !_obscure),
                  tooltip: 'إظهار',
                ),
              ),
              onSubmitted: (_) => _submit(),
            ),
            if (branches.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('أول دخول على هذا الجوال: ستختار الفرع بعد التحقق', style: TextStyle(color: AjilColors.textMuted, fontSize: 13)),
              ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white)) : const Text('دخول'),
            ),
            const SizedBox(height: 24),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              TextButton(onPressed: () => context.push('/reset'), child: const Text('نسيت كلمة المرور؟')),
              TextButton(onPressed: () => context.push('/register'), child: const Text('إنشاء بقالة جديدة')),
            ]),
          ],
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();
  @override
  Widget build(BuildContext context) => Column(children: [
        Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: AjilColors.primary, borderRadius: BorderRadius.circular(20)),
          child: const Text('آ', style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 10),
        const Text('آجِل', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600)),
        const Text('دفتر ديون البقالة', style: TextStyle(color: AjilColors.textMuted)),
      ]);
}
