import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../state/providers.dart';
import '../../widgets/common.dart';
import '../lock/pin_pad.dart';

/// تهيئة PIN بعد أول دخول على الجوال (+ البصمة اختيارياً)
class SetPinScreen extends ConsumerStatefulWidget {
  const SetPinScreen({super.key});
  @override
  ConsumerState<SetPinScreen> createState() => _SetPinScreenState();
}

class _SetPinScreenState extends ConsumerState<SetPinScreen> {
  String _first = '';
  String _entry = '';
  bool _confirming = false;
  bool _bio = false;
  bool _bioAvailable = false;

  @override
  void initState() {
    super.initState();
    ref.read(sessionProvider).lock.biometricAvailable().then((v) => mounted ? setState(() => _bioAvailable = v) : null);
  }

  Future<void> _onKey(String k) async {
    setState(() {
      if (k == 'del') {
        if (_entry.isNotEmpty) _entry = _entry.substring(0, _entry.length - 1);
      } else if (_entry.length < 6) {
        _entry += k;
      }
    });
  }

  Future<void> _next() async {
    if (_entry.length < 4) return showError(context, 'x: PIN من 4 إلى 6 أرقام');
    if (!_confirming) {
      setState(() {
        _first = _entry;
        _entry = '';
        _confirming = true;
      });
      return;
    }
    if (_entry != _first) {
      setState(() {
        _entry = '';
        _first = '';
        _confirming = false;
      });
      return showError(context, 'x: الرمزان غير متطابقين — أعد المحاولة');
    }
    await ref.read(sessionProvider).setPin(_entry, biometric: _bio);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: context.ajil.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(children: [
              const SizedBox(height: 24),
              Text(_confirming ? 'أعد إدخال رمز PIN' : 'اختر رمز PIN لفتح التطبيق',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Text('4 إلى 6 أرقام، خاص بك على هذا الجوال', style: TextStyle(color: context.ajil.textMuted)),
              const SizedBox(height: 24),
              PinDots(length: _entry.length, max: 6),
              const Spacer(),
              PinPad(onKey: _onKey),
              if (_bioAvailable)
                SwitchListTile(
                  value: _bio,
                  onChanged: (v) => setState(() => _bio = v),
                  title: const Text('الفتح بالبصمة أيضاً'),
                ),
              const SizedBox(height: 8),
              FilledButton(onPressed: _next, child: Text(_confirming ? 'تأكيد' : 'التالي')),
            ]),
          ),
        ),
      );
}
