import 'package:ajil/core/theme.dart';
import 'package:ajil/state/theme_controller.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FlutterSecureStorage storage;
  late List<String> pushed;
  late bool offline;

  ThemeController make() => ThemeController(storage, push: (t) async {
        if (offline) throw Exception('offline');
        pushed.add(t);
      });

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    storage = const FlutterSecureStorage();
    pushed = [];
    offline = false;
  });

  test('الافتراضي classic، والاختيار فوري ويُرفع للخادم', () async {
    final c = make();
    await c.attach('u1');
    expect(c.theme, AjilTheme.classic);
    await c.select('ocean');
    expect(c.theme, AjilTheme.ocean);
    await c.flush();
    expect(pushed, ['ocean']);
  });

  test('المظهر لكل مستخدم: مستخدم آخر على نفس الجوال لا يتأثر', () async {
    final c = make();
    await c.attach('u1');
    await c.select('ocean');
    await c.attach('u2');
    expect(c.theme, AjilTheme.classic);
    await c.attach('u1');
    expect(c.theme, AjilTheme.ocean);
  });

  test('بدون نت: يبقى الاختيار معلّقاً ولا تطغى عليه قيمة الخادم، ثم يُرفع عند الاتصال', () async {
    offline = true;
    final c = make();
    await c.attach('u1');
    await c.select('ocean');
    await c.flush();
    expect(pushed, isEmpty);
    // قيمة الخادم القديمة لا تلغي التغيير المحلي غير المرفوع
    await c.adoptServer('u1', 'classic');
    expect(c.theme, AjilTheme.ocean);
    offline = false;
    await c.flush();
    expect(pushed, ['ocean']);
    // بعد الرفع: الخادم هو المرجع (مثلاً غيّره من جهاز آخر)
    await c.adoptServer('u1', 'classic');
    expect(c.theme, AjilTheme.classic);
  });

  test('يُطبَّق فور الفتح من التخزين المحلي (آخر مستخدم)', () async {
    final a = make();
    await a.attach('u1');
    await a.select('ocean');
    final b = make();
    await b.init();
    expect(b.userId, 'u1');
    expect(b.theme, AjilTheme.ocean);
  });

  test('قيمة خادم لمستخدم غير الحالي تُحفظ له فقط', () async {
    final c = make();
    await c.attach('u1');
    await c.adoptServer('u2', 'ocean');
    expect(c.theme, AjilTheme.classic);
    await c.attach('u2');
    expect(c.theme, AjilTheme.ocean);
  });
}
