# CLAUDE.md — مشروع «آجِل» (Ajil)

هذا الملف يقرؤه Claude Code تلقائياً عند فتح المشروع. اقرأه كاملاً قبل أي عمل، ثم `docs/NEXT_TASKS.md`.

## ما هو المشروع
منصة اشتراكات (Multi-Tenant SaaS) لإدارة البيع الآجل والديون في البقالات. السوق الأول اليمن (المكلا مدينة التجربة)، والنظام مبني ليعمل في أي دولة.
- تطبيق Android لصاحب البقالة وموظفيه — **يعمل بدون إنترنت** ويتزامن لاحقاً
- صفحة ويب للمشترك (نفس محتوى التطبيق، تحتاج اتصالاً)
- لوحة إدارة المنصة (الاشتراكات والتفعيل)
- صفحة تعريف تسويقية (HTML بسيط)

التحليل الكامل: `docs/SPEC.md` — التصميم: `docs/DESIGN.md` و `docs/design/*.dc.html`

## التقنيات
| الجزء | التقنية |
| --- | --- |
| الخادم | Supabase (PostgreSQL 15 + Auth + Realtime + Edge Functions). محلياً: Supabase CLI + Docker |
| التطبيق | Flutter (Android + Web)، قاعدة محلية drift (SQLite) — التشفير بـ SQLCipher مهمة قادمة |
| الويب | صفحة المشترك = تطبيق `app/` مبنياً للويب (متصل فقط). لوحة الإدارة مشروع منفصل `web/admin`. يشتركان في `packages/ajil_core` |
| الحالة | Riverpod |
| التنبيهات | flutter_local_notifications (محلية، تعمل بدون نت) |

## الهيكل
```
supabase/migrations/   مخطط قاعدة البيانات — لا تعدّل ملفاً قديماً، أضف migration جديدة دائماً
supabase/functions/    Edge Functions (Deno/TypeScript)
supabase/tests/        اختبارات SQL — يجب أن تبقى كلها ناجحة
app/                   تطبيق Flutter
web/admin/             لوحة إدارة المنصة (Flutter Web)
web/landing/           صفحة التعريف (HTML)
packages/ajil_core/    النماذج، الاتصال بالخادم، منطق المزامنة المشترك
docs/                  التحليل والتصميم والمهام
```

## قواعد لا تُكسر
1. **العزل:** كل جدول فيه `store_id`، والتشغيلية فيها `branch_id`. الحماية بـ RLS في قاعدة البيانات، لا في التطبيق فقط. المطالبات من JWT: `store_id`, `app_user_id`, `app_role` (يضيفها `public.ajil_access_token_hook`).
2. **السجل المالي يُضاف فقط:** لا UPDATE ولا DELETE على `app.transactions` أبداً. التصحيح بحركة `void` (قيد عكسي) بسبب إلزامي.
3. **الإشارة والرصيد يحسبهما الخادم:** `signed_amount` و `customer_balances` من الـ triggers. التطبيق يحسب محلياً للعرض فقط ويعتمد قيمة الخادم بعد المزامنة.
4. **المبالغ `numeric` في PostgreSQL و `Decimal` في Dart** — ممنوع `double` للمال.
5. **كل حركة تُنشأ في الجوال بـ UUID + `device_seq` متزايد** (عدّاد واحد للجهاز)، تُحفظ محلياً بحالة `pending`، وتُرفع عبر `sync-push` الموقّعة فقط، ولا تصبح `synced` إلا بعد تأكيد الخادم.
6. **عملة لكل حركة**، والرصيد منفصل لكل (زبون، عملة)، بدون تحويل تلقائي.
7. **الحذف ممنوع للزبائن** — أرشفة فقط. والبيانات لا تُحذف عند انتهاء الاشتراك (قراءة فقط بعد 7 أيام).
8. **الفرع يُختار في شاشة الدخول** ولا يُبدَّل من داخل التطبيق (خروج ثم دخول).
9. **رسائل واتساب لا تُرسل آلياً** — تُفتح من جوال صاحب البقالة بضغطة (wa.me).

## اصطلاحات
- واجهة عربية كاملة RTL، خط IBM Plex Sans Arabic، الألوان في `docs/DESIGN.md`.
- أخطاء قاعدة البيانات: `رمز_إنجليزي: رسالة عربية` (مثل `plan_customer_limit: …`). التطبيق يعرض الجزء العربي ويتصرف حسب الرمز.
- الأرقام: إعداد للاختيار بين الهندية (١٢٣) والعادية (123). أرقام الجوال تُعرض LTR.
- الدخول في Supabase Auth ببريد داخلي مشتق: `u{user_no}.{store_phone}@users.ajil.app` + كلمة المرور.

## الأوامر
```bash
powershell -ExecutionPolicy Bypass -File scripts/dev-up.ps1     # Supabase + الدوال + adb reverse
powershell -ExecutionPolicy Bypass -File scripts/run-phone.ps1  # بناء وتثبيت على الجوال الموصول
npx supabase start && npx supabase db reset           # تشغيل وتطبيق المخطط
psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" -v ON_ERROR_STOP=1 -f supabase/tests/ledger_test.sql
npx supabase db reset                                  # تنظيف بعد الاختبارات
cd app && flutter pub get && flutter test && flutter run
```
**بعد أي تغيير في قاعدة البيانات شغّل الاختبارات، وأضف اختباراً لكل قاعدة جديدة.**

## الحالة الحالية
- ✅ المرحلة 0: التحليل والتصميم (8 شاشات)
- ✅ المرحلة 1: قاعدة البيانات — 11 migrations و **98 اختباراً ناجحاً** (`supabase/tests/`، تُشغَّل داخل حاوية `supabase_db_ajil` لأن psql غير مثبت على Windows)، pg_cron مفعّل ومجدول
- ✅ المرحلة 2.1: Edge Functions — send-otp, register-store, add-employee, reset-password, sync-push — مجرّبة محلياً بـ curl + 6 اختبارات للمنطق المشترك
- ✅ المرحلة 2.2: `packages/ajil_core` — 46 اختباراً ناجحاً
- ✅ المرحلة 2.3–2.4: تطبيق Flutter يُترجم: `flutter analyze` بلا أخطاء، `flutter test` 9/9. البيئة Flutter 3.24.5 (لهذا `drift_flutter <0.2.5` و override لـ `app_links`)
- ✅ التجربة على جوال حقيقي (لاسلكياً): `scripts/dev-up.ps1 -Phone ip:port` ثم `scripts/run-phone.ps1 -Phone ip:port` (adb reverse ← `SUPABASE_URL=http://127.0.0.1:54321`). مُتحقَّق حتى شاشة PIN؛ بقية السيناريو يدوي
- 🟡 مطابقة التصميم: الثيم والخط وكل الشاشات أُعيد بناؤها حسب `docs/design` (`widgets/ui.dart`)، وقورنت لقطات الجوال بالتصميم (عدا شاشة الدخول)
- ✅ شاشة التقارير (يوم/شهر/سنة/فترة + PDF/Excel) حسب `docs/REPORTS_SPEC.md` — منطقها في `ajil_core/src/reports.dart` (ajil_core 46 اختباراً)
- ✅ لوحة الإدارة (`web/admin`): تُترجم وجُرّبت في المتصفح محلياً — `scripts/run-admin.ps1` (http://localhost:8090)، مدير محلي `scripts/create-platform-admin.ps1`
- 🟡 المرحلة 3: صفحة التعريف (`web/landing`) لم تكتمل؛ صفحة المشترك = التطبيق نفسه على الويب — ✅ جُرّبت كاملة (`scripts/run-web.ps1`، http://localhost:8091): زبون، حركة متصلة، ومنع الكتابة بدون اتصال. `drift_worker.js` يُترجم من `app/tool/drift_worker.dart`
- ✅ فتح تطبيق الجوال بدون نت بعد إغلاقه: يفتح من آخر جلسة محفوظة (كان يعلق على شاشة البداية) — مُتحقَّق على الجوال
- ⏭️ التفاصيل والخطوات: `docs/NEXT_TASKS.md`

حدّث هذا القسم و `docs/NEXT_TASKS.md` في نهاية كل جلسة عمل.

## ملاحظة للعمل
المبرمج يعمل على مشاريع أخرى بالتوازي (توصيل السيارات، منصة المدارس). هذا المشروع مستقل تماماً: لا تستورد أو تخلط كوداً أو إعدادات من مجلدات أخرى.
