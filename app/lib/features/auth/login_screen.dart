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
    final last = branches.where((b) => b.id == _branchId).firstOrNull;
    final label = TextStyle(fontSize: 14, color: context.ajil.textSoft);
    const big = TextStyle(fontSize: 17);
    const pad = EdgeInsets.symmetric(horizontal: 14, vertical: 15);
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: box.maxHeight - 64),
              child: IntrinsicHeight(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const _Logo(),
                  const SizedBox(height: 28),
                  LabeledField(
                    label: 'رقم جوال البقالة',
                    labelStyle: label,
                    gap: 6,
                    child: TextField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.right,
                      style: big,
                      decoration: const InputDecoration(contentPadding: pad, hintText: '7XX XXX XXX'),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(
                      child: LabeledField(
                        label: 'رقم المستخدم',
                        labelStyle: label,
                        gap: 6,
                        helper: 'المالك = 1',
                        child: TextField(
                          controller: _userNo,
                          keyboardType: TextInputType.number,
                          style: big,
                          decoration: const InputDecoration(contentPadding: pad),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ),
                    if (branches.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: LabeledField(
                          label: 'الفرع',
                          labelStyle: label,
                          gap: 6,
                          child: DropdownButtonFormField<String>(
                            value: _branchId ?? branches.first.id,
                            isExpanded: true,
                            style: TextStyle(fontFamily: ajilFont, fontSize: 16, color: context.ajil.text),
                            icon: const Icon(Icons.keyboard_arrow_down_rounded),
                            decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14)),
                            items: [for (final b in branches) DropdownMenuItem(value: b.id, child: Text(b.name, overflow: TextOverflow.ellipsis))],
                            onChanged: (v) => setState(() => _branchId = v),
                          ),
                        ),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 16),
                  LabeledField(
                    label: 'كلمة المرور',
                    labelStyle: label,
                    gap: 6,
                    child: TextField(
                      controller: _password,
                      obscureText: _obscure,
                      style: big,
                      decoration: InputDecoration(
                        contentPadding: pad,
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: context.ajil.textMuted),
                          onPressed: () => setState(() => _obscure = !_obscure),
                          tooltip: 'إظهار',
                        ),
                      ),
                      onSubmitted: (_) => _submit(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    last != null
                        ? 'آخر دخول: ${last.name} — يُحفظ تلقائياً'
                        : (branches.isEmpty ? 'أول دخول على هذا الجوال: ستختار الفرع بعد التحقق' : 'الفرع يُحفظ تلقائياً'),
                    style: TextStyle(color: context.ajil.textMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    style: FilledButton.styleFrom(textStyle: const TextStyle(fontFamily: ajilFont, fontSize: 18, fontWeight: FontWeight.w600)),
                    child: _busy
                        ? SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: context.ajil.onPrimary))
                        : const Text('دخول'),
                  ),
                  const Spacer(),
                  const SizedBox(height: 28),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    LinkText('نسيت كلمة المرور؟', onTap: () => context.push('/reset')),
                    LinkText('إنشاء بقالة جديدة', onTap: () => context.push('/register')),
                  ]),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();
  @override
  Widget build(BuildContext context) => Column(children: [
        AjilLogo(size: 72),
        SizedBox(height: 12),
        Text('آجِل', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600)),
        SizedBox(height: 4),
        Text('دفتر ديون البقالة', style: TextStyle(fontSize: 15, color: context.ajil.textMuted)),
      ]);
}
