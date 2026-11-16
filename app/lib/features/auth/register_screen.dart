import 'package:ajil_core/ajil_core.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';

/// إنشاء بقالة: الرقم ← رمز التحقق ← اسم البقالة واسمك وكلمة المرور (تجربة 30 يوماً)
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _phone = TextEditingController();
  final _code = TextEditingController();
  final _store = TextEditingController();
  final _owner = TextEditingController();
  final _password = TextEditingController();
  String _currency = 'YER';
  bool _codeSent = false;
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

  Future<void> _sendCode() => _run(() async {
        final s = ref.read(sessionProvider);
        final dev = await s.api.sendOtp(Identity.normalizePhone(_phone.text), 'register');
        setState(() => _codeSent = true);
        if (dev != null && kDebugMode) _code.text = dev;
        if (mounted) showDevOtp(context, dev);
      });

  Future<void> _create() => _run(() async {
        final s = ref.read(sessionProvider);
        final phone = Identity.normalizePhone(_phone.text);
        await s.api.registerStore(
          phone: phone,
          code: _code.text.trim(),
          storeName: _store.text,
          ownerName: _owner.text,
          password: _password.text,
          currency: _currency,
        );
        await s.login(storePhone: phone, userNo: 1, password: _password.text);
      });

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const AjilHeader(title: 'إنشاء بقالة جديدة'),
        body: ListView(padding: const EdgeInsets.all(20), children: [
          const Text('رقم جوالك هو رقم البقالة، وأنت المستخدم رقم 1.', style: TextStyle(color: AjilColors.textMuted)),
          const SizedBox(height: 16),
          TextField(
            controller: _phone,
            enabled: !_codeSent,
            keyboardType: TextInputType.phone,
            textDirection: TextDirection.ltr,
            decoration: const InputDecoration(labelText: 'رقم جوالك'),
          ),
          const SizedBox(height: 12),
          if (!_codeSent)
            FilledButton(onPressed: _busy ? null : _sendCode, child: const Text('إرسال رمز التحقق'))
          else ...[
            TextField(
              controller: _code,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(labelText: 'رمز التحقق (6 أرقام)'),
            ),
            TextField(controller: _store, decoration: const InputDecoration(labelText: 'اسم البقالة')),
            const SizedBox(height: 12),
            TextField(controller: _owner, decoration: const InputDecoration(labelText: 'اسمك')),
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'كلمة المرور', helperText: '8 أحرف على الأقل'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _currency,
              decoration: const InputDecoration(labelText: 'العملة الأساسية'),
              items: [for (final c in Currency.all) DropdownMenuItem(value: c.code, child: Text(c.nameAr))],
              onChanged: (v) => setState(() => _currency = v!),
            ),
            const SizedBox(height: 20),
            FilledButton(onPressed: _busy ? null : _create, child: const Text('إنشاء البقالة — تجربة 30 يوماً مجاناً')),
            TextButton(onPressed: _busy ? null : _sendCode, child: const Text('إعادة إرسال الرمز')),
          ],
        ]),
      );
}
