import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';
import 'pin_pad.dart';

/// شاشة القفل: PIN أو البصمة. بعد 5 أخطاء ← الدخول بكلمة المرور.
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});
  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  String _pin = '';
  bool _bio = false;
  bool _checking = false;
  int _len = 4;

  @override
  void initState() {
    super.initState();
    final lock = ref.read(sessionProvider).lock;
    lock.pinLength().then((n) => mounted ? setState(() => _len = n) : null);
    lock.biometricEnabled().then((on) {
      if (!mounted) return;
      setState(() => _bio = on);
      if (on) lock.unlockWithBiometric();
    });
  }

  Future<void> _onKey(String k) async {
    if (_checking) return;
    setState(() {
      if (k == 'del') {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      } else if (_pin.length < _len) {
        _pin += k;
      }
    });
    if (_pin.length == _len) {
      final s = ref.read(sessionProvider);
      _checking = true;
      final ok = await s.lock.unlockWithPin(_pin);
      _checking = false;
      if (!mounted) return;
      if (!ok) {
        setState(() => _pin = '');
        if (s.lock.mustUsePassword) {
          showError(context, 'x: محاولات كثيرة — ادخل بكلمة المرور');
          await s.logout();
        } else {
          showError(context, 'x: الرمز غير صحيح');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(sessionProvider);
    final w = s.session;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AjilColors.primary, borderRadius: BorderRadius.circular(16)),
              child: const Text('آ', style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 18),
            Text('أهلاً ${w?.displayName ?? ''}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
            Text('المستخدم ${w?.userNo ?? ''} · ${w?.branch.name ?? ''}', style: const TextStyle(color: AjilColors.textMuted)),
            const SizedBox(height: 22),
            const Text('أدخل رمز PIN'),
            const SizedBox(height: 14),
            PinDots(length: _pin.length, max: _len),
            const Spacer(),
            PinPad(
              onKey: _onKey,
              leading: _bio
                  ? IconButton.filledTonal(
                      onPressed: () => s.lock.unlockWithBiometric(),
                      icon: const Icon(Icons.fingerprint, size: 32),
                      tooltip: 'الدخول بالبصمة',
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            TextButton(onPressed: () => s.logout(), child: const Text('الدخول بكلمة المرور / تبديل المستخدم')),
          ]),
        ),
      ),
    );
  }
}
