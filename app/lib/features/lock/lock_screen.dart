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
        child: LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: box.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(32, 48, 32, 24),
                  child: Column(children: [
                    const AjilLogo(size: 56),
                    const SizedBox(height: 24),
                    Text('أهلاً ${w?.displayName ?? ''}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('المستخدم ${w?.userNo ?? ''} · ${w?.branch.name ?? ''}', style: const TextStyle(fontSize: 14, color: AjilColors.textMuted)),
                    const SizedBox(height: 24),
                    const Text('أدخل رمز PIN', style: TextStyle(fontSize: 15, color: AjilColors.textSoft)),
                    const SizedBox(height: 24),
                    PinDots(length: _pin.length, max: _len),
                    const SizedBox(height: 36),
                    PinPad(
                      onKey: _onKey,
                      leading: _bio
                          ? Material(
                              color: AjilColors.primaryLight,
                              shape: const CircleBorder(),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () => s.lock.unlockWithBiometric(),
                                child: const Icon(Icons.fingerprint_rounded, size: 30, color: AjilColors.primary, semanticLabel: 'الدخول بالبصمة'),
                              ),
                            )
                          : null,
                    ),
                    const Spacer(),
                    const SizedBox(height: 24),
                    LinkText('الدخول بكلمة المرور', onTap: () => s.logout()),
                    LinkText('تبديل المستخدم', onTap: () => s.logout()),
                    const SizedBox(height: 4),
                    const Text('يُقفل التطبيق بعد 5 دقائق بدون استخدام', style: TextStyle(fontSize: 13, color: AjilColors.textMuted)),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
