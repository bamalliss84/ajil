import 'package:ajil_admin/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('شاشة الدخول تعرض الحقول وزر الدخول', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Directionality(textDirection: TextDirection.rtl, child: LoginPage()),
    ));
    expect(find.text('آجِل — إدارة المنصة'), findsOneWidget);
    expect(find.text('البريد'), findsOneWidget);
    expect(find.text('كلمة المرور'), findsOneWidget);
    expect(find.text('دخول'), findsOneWidget);
  });
}
