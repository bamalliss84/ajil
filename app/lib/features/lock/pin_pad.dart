import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';

class PinDots extends StatelessWidget {
  const PinDots({super.key, required this.length, this.max = 4});
  final int length;
  final int max;
  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < (length > max ? length : max); i++)
              Container(
                width: 16,
                height: 16,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < length ? AjilColors.primary : Colors.transparent,
                  border: Border.all(color: i < length ? AjilColors.primary : const Color(0xFF9FB3AD), width: 2),
                ),
              ),
          ],
        ),
      );
}

/// لوحة PIN دائرية؛ trailing = زر البصمة (اختياري)
class PinPad extends StatelessWidget {
  const PinPad({super.key, required this.onKey, this.leading});
  final ValueChanged<String> onKey;
  final Widget? leading;

  Widget _key(String k) => SizedBox(
        width: 72,
        height: 72,
        child: Material(
          color: const Color(0xFFF1F5F4),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              HapticFeedback.selectionClick();
              onKey(k);
            },
            child: Center(child: Text(k, style: const TextStyle(fontSize: 26))),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.ltr,
        child: Column(children: [
          for (final row in const [
            ['1', '2', '3'],
            ['4', '5', '6'],
            ['7', '8', '9'],
          ])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [for (final k in row) _key(k)]),
            ),
          Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            SizedBox(width: 72, height: 72, child: leading),
            _key('0'),
            SizedBox(
              width: 72,
              height: 72,
              child: IconButton(
                onPressed: () => onKey('del'),
                icon: const Icon(Icons.backspace_outlined),
                tooltip: 'حذف',
              ),
            ),
          ]),
        ]),
      );
}
