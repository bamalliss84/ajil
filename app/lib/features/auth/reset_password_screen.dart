import 'package:ajil_core/ajil_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';

/// استعادة كلمة مرور المالك برمز OTP. الموظف يطلبها من المالك.
class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});
  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  final _password = TextEditingController();
  bool _sent = false;
  bool _busy = false;

  Future<void> _run(Future<void> Function() f) async {
    setState(() => _busy = true);
    try {
      await f();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final api = ref.read(sessionProvider).api;
    return Scaffold(
      appBar: AppBar(title: const Text('استعادة كلمة المرور')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        const Text('للمالك فقط. إذا كنت موظفاً اطلب من المالك إعادة تعيين كلمة مرورك.',
            style: TextStyle(color: AjilColors.textMuted)),
        const SizedBox(height: 16),
        TextField(
          controller: _phone,
          enabled: !_sent,
          keyboardType: TextInputType.phone,
          textDirection: TextDirection.ltr,
          decoration: const InputDecoration(labelText: 'رقم جوال البقالة'),
        ),
        const SizedBox(height: 12),
        if (!_sent)
          FilledButton(
            onPressed: _busy
                ? null
                : () => _run(() async {
                      final dev = await api.sendOtp(Identity.normalizePhone(_phone.text), 'reset_owner');
                      setState(() => _sent = true);
                      if (dev != null && mounted) showOk(context, 'رمز التطوير: $dev');
                    }),
            child: const Text('إرسال رمز التحقق'),
          )
        else ...[
          TextField(controller: _code, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'الرمز')),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'كلمة المرور الجديدة', helperText: '8 أحرف على الأقل'),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy
                ? null
                : () => _run(() async {
                      await api.resetOwnerPassword(Identity.normalizePhone(_phone.text), _code.text.trim(), _password.text);
                      if (!mounted) return;
                      showOk(context, 'تم تغيير كلمة المرور — سجّل الدخول');
                      context.go('/login');
                    }),
            child: const Text('حفظ كلمة المرور'),
          ),
        ],
      ]),
    );
  }
}
