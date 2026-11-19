# المهام القادمة

اعمل بالترتيب. بعد كل مهمة: شغّل الاختبارات، أشّر عليها هنا (✅)، وحدّث «الحالة الحالية» في `CLAUDE.md`.

> **مهم:** كود Flutter و Dart كُتب كاملاً **بدون مترجم** (لم يكن Flutter متاحاً في بيئة الكتابة).
> قاعدة البيانات مختبرة فعلياً (97 اختباراً)، ومنطق Edge Functions المشترك مختبر (6 اختبارات).
> أول مهمة لك: تشغيل `flutter analyze` وإصلاح أي أخطاء ترجمة أو اختلاف في إصدارات الحزم — **بدون تغيير القواعد في CLAUDE.md**.

## ✅ رابط كشف الحساب العام للزبون (2026-11-19)
- **القاعدة:** `migrations/…13_statement_links.sql` — جدول `app.statement_links` (رابط واحد لكل زبون: customer_id PK، token فريد 128 بت base64url، revoked_at، last_viewed_at، view_count). القراءة بـ RLS لمن له `has_branch`، ولا insert/update مباشر.
  - `app.statement_link(p_customer, p_regenerate)`: يرجع الـ token أو ينشئه؛ التجديد (وإعادة تفعيل رابط ملغى) للمالك أو للموظف إن كان `employees_can_send_notices`. `app.revoke_statement_link(p_customer)` للإلغاء بدون بديل (غير مستخدمة في التطبيق بعد).
  - `app.public_statement(p_token)`: لـ anon فقط (`grant usage on schema app to anon`، بلا أي صلاحية على الجداول). ترجع اسم البقالة والفرع والزبون، الأرصدة لكل عملة (الإجماليات بدون الملغاة وقيودها)، آخر 50 حركة بدون الملغاة، الوعود المفتوحة (تاريخ ومبلغ فقط)، ووقت الاستعلام — بلا جوال ولا ملاحظات ولا سقف ولا معرّفات. `null` موحّد لأي رابط غير صالح/ملغى/زبون مؤرشف/بقالة موقوفة. تحدّث المشاهدات.
  - `statement_link_test.sql` (33) + تحديث `isolation_test.sql` (anon مسموح له `public_statement` فقط، ولا صلاحية لـ anon/public على جداول app) ← **166 ✓**. `_helpers.sql` يمنح anon مخطط `test` (للاختبارات فقط).
- **الصفحة:** `web/statement/index.html` ملف واحد بلا framework (RTL، خط Tajawal، ألوان DESIGN.md، للجوال أولاً). الـ token في `location.hash` فلا يصل للخادم. `noindex` و `referrer=no-referrer` و CSP. عند النشر استبدل `__SUPABASE_URL__` و `__SUPABASE_ANON_KEY__` و `__LANDING_URL__`، وأضف ترويستي `Referrer-Policy: no-referrer` و `X-Robots-Tag: noindex` في الاستضافة.
  - محلياً: `scripts/run-statement.ps1` (أو preview «statement») ← http://localhost:8092/statement/#token. جُرّبت: الكشف، و«الرابط غير صالح»، وبعرض 375px.
- **التطبيق:** `services/statement_links.dart` (الـ token يُحفظ في `KeyValues` بعد أول جلب)، `features/customers/statement_link_sheet.dart` (نسخ، مشاركة، تجديد بتأكيد؛ رسالة واضحة بدون نت)، المدخل: شاشة الزبون ← «الكشف والمزيد» ← «رابط كشف الحساب».
  - `Whatsapp.remind` يستخدم الآن قالب البقالة `reminder_template` ويملأ `{الرابط}`؛ بدون رابط تُحذف جملة الرابط كاملة (`whatsapp_fill_test.dart`، 3 اختبارات).
  - `balance_notices_screen`: شريحة `{الرابط}` مفعّلة، والرابط يُجلب لكل زبون قبل المعاينة/الإرسال (المحفوظ أو من الخادم، وإلا بدون سطر الرابط).
  - `STATEMENT_BASE_URL`: `run-web.ps1` يضبطه على http://localhost:8092/statement/، و `run-phone.ps1` على http://127.0.0.1:8092/statement/ مع `adb reverse tcp:8092` (أو `-StatementUrl`).
  - جُرّب في الويب (بناء منفصل): القائمة ← الرابط يُنشأ ← التجديد يبطل القديم ← الرابط الجديد يفتح الكشف. `flutter analyze` بلا أخطاء، `flutter test` 12/12.
- [ ] لم يُجرَّب على الجوال: المشاركة الأصلية، ورسالة «لا يوجد اتصال» في نافذة الرابط، ورسالة واتساب بالرابط من جوال حقيقي.
- [ ] الدومين النهائي لـ STATEMENT_BASE_URL والاستضافة (قرار معلّق مع اسم الشركة والدومين).
- [ ] زر «إلغاء الرابط» في التطبيق (الدالة جاهزة)، وعرض عدد المشاهدات وآخرها للمالك.

## ✅ تقوية العزل بين البقالات (2026-11-18) — `supabase/migrations/20261118000012_isolation_hardening.sql`
- `app.promises`: trigger `promises_customer_check` يرفض `customer_mismatch` إن لم يتبع الزبون نفس البقالة والفرع.
- `created_by` في `customers` و `promises` يفرضه الخادم `:= app.app_user_id()` لطلبات API (authenticated/anon)؛ مفتاح الخدمة والاتصال المباشر يحتفظان بالقيمة.
- `app.has_branch` تشترط أن المستخدم الحالي `is_active` في نفس البقالة ← إيقاف الموظف يقطع وصوله فوراً رغم أن توكنه ساري.
- فحص المالك `is distinct from 'owner'` في redeem_code / add_employee / add_branch / set_device_state / set_employee (توكن بلا `app_role` كان يمر).
- EXECUTE: مسحوبة من public و anon لكل دوال `app`، و authenticated يأخذ قائمة صريحة (دوال RLS + التطبيق + الإدارة)، و service_role كل الدوال (+ صلاحية افتراضية للقادمة). خطّاف التوكن لـ supabase_auth_admin فقط.
  **مهم:** PostgreSQL يمنح public تنفيذ كل دالة جديدة؛ أي migration تضيف دالة في `app` يجب أن تسحبها (`revoke execute on function app.x(...) from public, anon`) وإلا يفشل `isolation_test.sql`.
- `app.current_subscription` صارت security invoker وترفض `store_mismatch` لبقالة أخرى، إلا لمدير المنصة و service_role والاتصال المباشر (والاستدعاء من دوال security definer مثل الـ triggers).
- `otp_issue` و `generate_codes` بـ `gen_random_bytes` (pgcrypto في مخطط `extensions`).
- الاختبارات: `isolation_test.sql` (34) ← المجموع **132 ✓** (ledger 43، services 54، cron 1، isolation 34). جُرّب حياً: send-otp ← register-store ← الدخول (claims من الخطّاف) ← RLS و `pull_changes`، و authenticated مرفوض من `otp_issue`، و anon مرفوض من مخطط app.
- تشغيل كل الاختبارات (بعد `npx supabase db reset`، لأن إعادة الضبط تعيد تشغيل الحاوية وتمسح /tmp):
  `docker cp supabase/tests supabase_db_ajil:/tmp/ajtests && for t in ledger services cron isolation statement_link; do docker exec supabase_db_ajil psql -U postgres -v ON_ERROR_STOP=1 -f /tmp/ajtests/${t}_test.sql; done`

## ✅ شاشة التقارير الجديدة (2026-11-17) — `docs/REPORTS_SPEC.md`
- المنطق في `packages/ajil_core/lib/src/reports.dart` (`ReportPeriod`، `PeriodReport.build`) + 19 اختباراً (ajil_core: 44/44). الشاشة عرض فقط.
- الشاشة: `app/lib/features/reports/` (reports_screen، report_sections، report_views، period_picker، report_state). الافتراضي الشهر الحالي، يوم/شهر/سنة/من–إلى، الفترة تبقى طوال الجلسة. السنة أو >3000 حركة تُحسب في isolate.
- التصدير PDF و Excel (`services/report_export.dart`، حزمة `excel`) ومشاركة ملخص اليوم نصاً.
- قورنت لقطات الجوال بـ Reports / ReportsDay / ReportsYear / ReportsPicker.
- أيقونات الأسهم (chevron) كانت معكوسة في RTL في كل التطبيق — صُحّحت.
- [ ] شريط «إغلاق السنة» في تصميم السنة غير منفّذ (لا توجد ميزة إغلاق سنة بعد).
- [ ] «حسب المستخدم» بدون اتصال يعرض اسم المستخدم الحالي فقط (الأسماء من الخادم).

## 🟡 جلسة مطابقة التصميم (2026-11-17)
- الخط IBM Plex Sans Arabic مضمّن كأصل (`fonts:` في pubspec، أُزيل google_fonts) و`core/theme.dart` يحوي كل رموز `docs/DESIGN.md`.
- مكوّنات مشتركة في `app/lib/widgets/ui.dart` (هيدر، مقطّع، شرائح، خيارات، صفوف اختيار، بطاقات) مطابقة لـ `docs/design/*.dc.html`.
- أُعيد بناء واجهات: الرئيسية (مع حالة فارغة)، الزبون، تسجيل الحركة، الزبائن، القفل، الدخول، الوعد، التنبيهات — وبنفس الهوية: إضافة زبون، التقارير، الإعدادات، الإشعار، إرسال الأرصدة، وبقية الشاشات (هيدر موحّد).
- لوحة الأرقام في تسجيل الحركة تختفي عند فتح لوحة المفاتيح (حقل الوصف).
- debug فقط: لا FLAG_SECURE ← `adb exec-out screencap -p` يعمل للمقارنة.
- المزامنة العالقة سببها انقطاع adb اللاسلكي (يضيع `adb reverse`)، لا منطق التطبيق. الحل: `scripts/open-firewall.ps1` مرة واحدة كمسؤول ← `run-phone.ps1` يستخدم IP الكمبيوتر تلقائياً.
- [x] لقطات من الجوال (Infinix) قورنت بـ `docs/design/png/`: الرئيسية، الزبائن، الزبون، تسجيل الدين، الوعد، التنبيهات، القفل + التقارير والإعدادات وإضافة زبون. أُصلحت: شرائح موعد السداد كانت بعرض كامل، التواريخ كانت بأرقام هندية رغم إعداد 123، عنوان/زر شاشة الحركة، عرض الحد الأدنى 1000.0.
- [ ] شاشة الدخول (Main) لم تُصوَّر على الجوال (تتطلب خروجاً وإدخال كلمة المرور). قسم «مواعيد ووعود السداد» في تصميم التنبيهات بلا إعدادات خلفية — غير منفّذ.
- [ ] زر البصمة في شاشة الدخول (موجود في التصميم) يحتاج منطق دخول بالبصمة — غير منفّذ.

## ✅ جلسة التجهيز (2026-11-16)
- البيئة: Flutter 3.24.5 (Dart 3.5.4)، Supabase CLI 3.2، Docker. git + `.gitignore` + `.gitattributes`.
- سكربتان: `scripts/dev-up.ps1` (Supabase + بصمة سر البوابة + functions serve + adb reverse) و`scripts/run-phone.ps1` (`-Apk` للتثبيت فقط، `-Lan` لاستخدام IP الشبكة بدل adb reverse).
- القاعدة: 11 migration (الجديدة `…11_enable_pg_cron.sql` تفعّل pg_cron وتجدول الفحص اليومي) و**98 اختبار SQL ناجح** (أضيف `cron_test.sql`). psql غير مثبت على Windows ← الاختبارات تُشغَّل داخل الحاوية:
  `docker cp supabase/tests/. supabase_db_ajil:/tmp/tests/ && docker exec supabase_db_ajil psql -U postgres -v ON_ERROR_STOP=1 -f /tmp/tests/ledger_test.sql`
- Edge Functions: send-otp ← register-store ← الدخول (JWT فيه store_id/app_user_id/app_role) ← add-employee — كلها تعمل محلياً. اختبارات المنطق المشترك 6/6.
- ajil_core: 25/25 (أصلح `AjilError.parse` — كان «message:» يبتلع رمز الخطأ).
- التطبيق: `flutter analyze` بلا أخطاء، `flutter test` 9/9. إصلاحات توافق Flutter 3.24: `drift_flutter <0.2.5`، و`dependency_overrides: app_links: 6.3.3`.
- debug فقط: رمز OTP الراجع من الخادم يظهر في SnackBar (30 ثانية + نسخ) ويُعبّأ في حقل الرمز (`showDevOtp`). `usesCleartextTraffic` في `src/debug` فقط.
- **جوال حقيقي (Infinix X6840، Android 16) لاسلكياً:** `adb connect` + `adb reverse tcp:54321` يعمل عبر Wireless debugging. التطبيق يفتح ← «إنشاء بقالة جديدة» ← send-otp (الرمز في SnackBar ويُعبّأ تلقائياً) ← register-store ← **شاشة PIN** ✅ (تحقق آلي بـ uiautomator لأن FLAG_SECURE يمنع لقطات الشاشة).
- `compileSdk = 35` في `android/app/build.gradle` (تطلبه الإضافات). أول بناء ينزّل NDK 25.1 (~1.4GB).
- ملاحظة: `npx supabase db reset` يمسح بصمة سر البوابة ← أعد تشغيل `dev-up.ps1` بعده.
- لاحقاً: ترقية Flutter لإصدار حديث ثم رفع الحزم (122 حزمة لها إصدارات أحدث) وإزالة الـ overrides، واستبدال `anonKey` بـ `publishableKey`.

## 1. الخادم محلياً
- [x] ✅ `npx supabase init` ثم انسخ محتوى `supabase/config.additions.toml` إلى `supabase/config.toml`
- [x] ✅ `npx supabase start && npx supabase db reset` — يجب أن تُطبَّق 10 migrations بلا خطأ
- [x] ✅ شغّل الاختبارات على قاعدة Supabase المحلية:
  `for f in supabase/tests/*_test.sql; do psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" -v ON_ERROR_STOP=1 -f $f; done`
  ← 97 ✓ (ثم `npx supabase db reset` للتنظيف). بديل بدون Supabase: `bash supabase/tests/run_local.sh`
- [x] ✅ فعّل pg_cron من لوحة Supabase (Database → Extensions) ثم `npx supabase db reset` لجدولة الفحص اليومي

## 2. Edge Functions
- [x] ✅ `cp supabase/functions/.env.example supabase/functions/.env` واضبط `AJIL_GATEWAY_SECRET` بقيمة عشوائية طويلة
- [x] ✅ خزّن بصمة السر في القاعدة (وفي الإنتاج فعّل البوابة):
  ```sql
  update app.platform_config set value = encode(sha256(convert_to('<السر>', 'UTF8')), 'hex') where key = 'gateway_secret_sha256';
  update app.platform_config set value = 'true' where key = 'require_gateway';  -- في الإنتاج
  ```
- [x] ✅ `npx supabase functions serve --env-file supabase/functions/.env`
- [x] ✅ `deno test supabase/functions/_shared/deno_test.ts` (أو `bash supabase/functions/_shared/run_node_tests.sh`)
- [x] ✅ جرّب بالترتيب بـ curl: `send-otp` (الرمز يظهر في الرد لأن OTP_DEV_ECHO=true) ← `register-store` ← الدخول ← `add-employee`

## 3. الحزمة المشتركة
- [x] ✅ `cd packages/ajil_core && dart pub get && dart test` — كل الاختبارات يجب أن تنجح (أرقامها مطابقة لاختبارات الخادم)

## 4. تطبيق Flutter
- [x] ✅ `cd app && flutter create --org app.ajil --project-name ajil --platforms android,web .`
- [x] ✅ اتبع `app/android-overrides/README.md` (MainActivity بـ FLAG_SECURE + الصلاحيات + desugaring)
- [x] ✅ ضع ملفات خط IBM Plex Sans Arabic في `app/assets/fonts/` (Regular, Medium, SemiBold)
- [x] ✅ `flutter pub get && dart run build_runner build --delete-conflicting-outputs` (يولّد `db.g.dart`)
- [x] ✅ `flutter analyze` ← أصلح كل الأخطاء
- [x] ✅ `flutter test` ← اختبارات محرك المزامنة (8) يجب أن تنجح
- [x] ✅ شغّل على جوال حقيقي: `scripts/run-phone.ps1 -Phone <ip:port>` (أو على المحاكي:
  `flutter run --dart-define=SUPABASE_URL=http://10.0.2.2:54321 --dart-define=SUPABASE_ANON_KEY=<من supabase status>`)
- [x] ✅ **فتح التطبيق بدون نت بعد إغلاقه** كان يعلق على شاشة البداية (Supabase يعيد تجديد التوكن المنتهي بلا نهاية). الآن: `WorkSession` + الاشتراك + الإعدادات تُحفظ في التخزين الآمن بعد كل فتح ناجح (`ajil.session_cache`)، و `restore()` يفتح منها إن فشل الوصول أو تجاوز `AppConfig.openTimeout` (6 ث)، وأول مزامنة ناجحة تحدّثها. رفض حقيقي من الخادم (لا خطأ اتصال) يبقى ← شاشة الدخول. مُتحقَّق على الجوال: فتح بلا اتصال ← الرئيسية بالبيانات وشريط «غير متصل»، ثم عودة الاتصال تلقائياً. الويب لا يستخدم النسخة المحفوظة
- [ ] سيناريو كامل يدوياً: تسجيل بقالة ← PIN ← زبون برصيد افتتاحي ← دين بموعد ← اقطع النت وسجّل ← أرجعه وتأكد من ✓ ← وعد ← كشف PDF ← واتساب ← موظف بجهاز ثانٍ (اعتماد) ← إلغاء من الموظف بعد المهلة يُرفض

## 5. الويب
- [x] صفحة المشترك: التشغيل `scripts/run-web.ps1` (http://localhost:8091). جُرّب كاملاً: الدخول، إنشاء بقالة برمز OTP التطوير، PIN، الرئيسية، زبون برصيد افتتاحي (متزامن)، تسجيل دين متصل ← الإشعار + الرصيد على الخادم، ثم قطع الخادم: شريط «غير متصل — التسجيل متوقف»، أزرار الدين/السداد وإضافة زبون تختفي، والحفظ المباشر يُرفض برسالة، وعند عودة الاتصال يرجع كل شيء
  - `app/web/sqlite3.wasm` من إصدار sqlite3 2.9.4 الرسمي. أما `drift_worker.js` فيُترجم من حزم التطبيق (الجاهز من drift 2.23.1 بُني بـ sqlite3 أقدم فكان يفشل بـ `Import "dart" "localtime"` عند أول حفظ):
    `cd app && dart compile js -O4 -o web/drift_worker.js tool/drift_worker.dart`
  - عند تحديث الحزم: نزّل `sqlite3.wasm` المطابق لإصدار sqlite3 في pubspec.lock وأعد ترجمة العامل
  - فتح صفحة الويب وهي بلا اتصال يعيدك لشاشة الدخول (الويب متصل فقط — مقبول، لكن الرسالة يمكن تحسينها)
- [x] لوحة الإدارة: تُترجم (analyze 0 أخطاء، اختبار 1/1) وجُرّبت في المتصفح على Supabase المحلي: الدخول، الملخص، تفعيل/تجديد (يمدد من تاريخ الانتهاء)، إيقاف/إعادة تفعيل بتأكيد، توليد أكواد، تنبيهات السلامة. التشغيل `scripts/run-admin.ps1`، ومدير محلي بـ `scripts/create-platform-admin.ps1`
  - [ ] لم يُجرَّب: استخدام كود التفعيل من التطبيق، ودخول مستخدم غير مدير (يُفترض أن ترفضه دوال `platform_admin_only`)
- [ ] صفحة التعريف: `web/landing/index.html` — ضع رابط المتجر ورقم الدعم

## 6. ميزات لم تُنفّذ بعد (حسب الأولوية)
- [x] ✅ **رابط كشف الحساب العام للزبون** — نُفّذ بدالة `app.public_statement` (anon) وصفحة ثابتة `web/statement` بدل Edge Function (انظر القسم أعلاه)
- [ ] **شاشة قائمة التحصيل الشهرية**: في يوم المطالبة، كل زبون عليه أكثر من الحد مع زر واتساب لكل واحد (الإعدادات والتنبيه موجودان)
- [ ] **استيراد الزبائن** من جهات الاتصال أو Excel مع الرصيد الافتتاحي
- [ ] **تشفير القاعدة المحلية** بـ SQLCipher (`sqlcipher_flutter_libs` + مفتاح في التخزين الآمن)
- [ ] **الطابعة الحرارية بلوتوث مباشرة** (حالياً عبر نافذة الطباعة بمقاس 57mm)
- [ ] **التحديث الإجباري**: قيمة `min_app_version` في `platform_config` يقرؤها التطبيق عند الدخول
- [ ] **Play Integrity** + نقل مفتاح الجهاز إلى Android Keystore عبر قناة Kotlin
- [ ] **دمج زبونين مكررين** (نفس رقم الجوال من جوالين أوفلاين)
- [ ] **نقل زبون بين الفروع** (قيد إغلاق + رصيد افتتاحي)
- [ ] **مراقبة الأعطال** Crashlytics أو Sentry
- [ ] **متطلبات Google Play**: سياسة الخصوصية، وحذف الحساب (تصدير ثم حذف بعد مهلة بطلب المالك)
- [ ] **مزوّد OTP حقيقي** (واتساب أو SMS) — نفّذه في `supabase/functions/_shared/otp_provider.ts`

## قرارات معلّقة عند المبرمج
- مزوّد OTP في اليمن
- اسم الشركة والدومين ورقم واتساب الدعم

## إضافة: الإشعار/السند والمشاركة (2026-11-16)
- ملفات جديدة: `app/lib/features/receipt/{receipt_data,receipt_card,receipt_screen}.dart`، `app/lib/services/receipt_pdf.dart`، و`ArabicWords` (التفقيط) في ajil_core.
- تبعيات جديدة: `share_plus` و`qr_flutter` → شغّل `flutter pub get`.
- بعد حفظ أي حركة أو إلغاء قيد ينتقل التطبيق إلى `/customers/:id/receipt/:txId`؛ زر المشاركة يفتح نافذة الجوال الأصلية (واتساب، رسائل، بريد…) بـ PDF أو صورة.
- تحقق: `withOpacity` قد يظهر كتحذير deprecated في Flutter الحديث — استبدله بـ `withValues(alpha:)` إن رغبت.
- اختبر على جهاز حقيقي: مشاركة PDF في واتساب، والصورة (pixelRatio 3)، والطباعة الحرارية 58mm.

## إضافة: إرسال الأرصدة لكل الزبائن حتى تاريخ (2026-11-16)
**الآلية:** شاشة `/notices` ← يختار التاريخ والشروط والنص ← قائمة دور مرتبة (الأكبر ديناً أولاً) ← «إرسال عبر واتساب» يفتح واتساب برقم الزبون والرسالة جاهزة ← عند الرجوع «نعم أُرسلت — التالي» أو «تخطي». الدفعة محفوظة على الجوال وتُستأنف لو أُغلق التطبيق. لا إرسال آلي (مجاني ولا يُحظر الرقم).

- **ajil_core:** `Ledger.balancesAsOf` (الحركات حتى آخر اليوم فقط؛ إلغاء بعد التاريخ لا يؤثر)، و`src/balance_notice.dart`: `NoticeFilter`، `BalanceNotices.select/render`، `NoticeBatch`. + 5 اختبارات.
- **الخادم:** `migrations/…10_balance_notices.sql` — جدول `app.balance_notices` (سجل لا يُعدّل ولا يُحذف)، RLS، `app.can_send_notices()`، وفي `store_settings`: `employees_can_send_notices` و`balance_notice_template`. + 9 اختبارات (الإجمالي 97).
- **التطبيق:**
  - جدول drift جديد `LocalNotices` و**schemaVersion = 2** مع `onUpgrade` ← شغّل `dart run build_runner build --delete-conflicting-outputs`.
  - `repository.dart`: selectForNotices، start/load/save/clearNoticeBatch، markNoticeSent/Skipped، refreshNotices (يجلب ما أرسلته الأجهزة الأخرى خلال 60 يوماً لمنع التكرار)، noticesOf.
  - `sync_engine.dart`: `_pushNotices` يرفع السجل (فشله لا يوقف المزامنة). `RemoteApi` فيه `saveNotice` و`recentNotices`.
  - `features/notices/balance_notices_screen.dart` + المسار `/notices`.
  - المداخل: بطاقة في الرئيسية، زر في «التنبيهات والتحصيل» (مع مفتاح صلاحية الموظفين)، و**تنبيه يوم المطالبة الشهري يفتح الشاشة مباشرة** (payload `/notices` عبر `Notifications.tapRoute`).
  - صفحة الزبون ← القائمة ← «رسائل الرصيد المرسلة» (مرجع عند الخلاف).
  - اختبار مزامنة جديد في `test/sync_engine_test.dart` (استئناف الدفعة + عدم تكرار الإرسال من جوال ثانٍ).
- ✅ `{الرابط}` لكشف الحساب العام مفعّل (2026-11-19). **لاحقاً (غير منفّذ):** قنوات مدفوعة SMS/WhatsApp API للباقة الأعلى.
- **تحقق يدوي على جهاز حقيقي:** الرجوع من واتساب يُظهر «هل وصلت الرسالة؟»، والضغط على تنبيه المطالبة وهو مقفل يفتح الشاشة بعد إدخال PIN.

## 🔤 توحيد الخط على Tajawal (2026-11-19)
اعتُمد **Tajawal** بدل IBM Plex Sans Arabic في كل المنتج. تجوال لا يملك الوزن **600**، فكل 600 يصير **700**.
- ✅ منفَّذ: `docs/DESIGN.md`، `CLAUDE.md`، `docs/DESIGN_FIDELITY.md`، `docs/design/*.dc.html` (12)، `web/statement/index.html`، `web/landing/index.html`
- ⬜ متبقٍ (يحتاج ملفات الخط وتشغيل Flutter):
  1. نزّل Tajawal من https://fonts.google.com/specimen/Tajawal وضع في `app/assets/fonts/` و`web/admin/assets/fonts/`:
     `Tajawal-Regular.ttf` (400) و`Tajawal-Medium.ttf` (500) و`Tajawal-Bold.ttf` (700)، واحذف ملفات IBMPlexSansArabic وحدّث `README.txt` و`OFL.txt`.
  2. `app/pubspec.yaml` و`web/admin/pubspec.yaml`: `family: Tajawal` بأوزان 400/500/**700** (لا تُعلن 600 — وإلا اختار Flutter وزناً أقرب بشكل غير محدَّد).
  3. `app/lib/core/theme.dart`: `ajilFont = 'Tajawal'`، و`web/admin/lib/main.dart`: `fontFamily: 'Tajawal'`.
  4. استبدل كل `FontWeight.w600` بـ `FontWeight.w700` في `app/lib` و`web/admin/lib` (≈88 موضعاً).
  5. ملفات PDF (`statement_pdf.dart`, `receipt_pdf.dart`, `report_export.dart`): مسارات الأصول إلى Tajawal، وتحقّق من اسم الدالة في `PdfGoogleFonts` لتجوال (البديل على الويب) — إن لم تتوفر فاستخدم الأصول في الحالتين.
  6. `flutter analyze` و`flutter test` ثم لقطة شاشة واحدة على الجوال للتأكد أن 700 ليس ثقيلاً أكثر من اللازم.

## 🎨 تصاميم الشاشات المتبقية (2026-11-19)
صُمِّمت ونُشرت في `docs/design/`، واعتُمد **النموذج أ** لكل شاشة بعد مقارنة نموذجين:
- `Payment.dc.html` — تسجيل السداد. المبلغ هو بطل الشاشة بخط 46px، وتحته شريحة حيّة:
  «المتبقي بعده …» وتتحول خضراء «✓ يصير الحساب صافياً» عند تساوي المبلغ مع الدين.
  مبالغ سريعة (كل الدين · النصف · 10,000 · 5,000) ومبدّل العملة في الهيدر.
- `PaymentFx.dc.html` — نفس الشاشة بعملة مختلفة: بطاقة زرقاء بسعر الصرف وما ينقص من الدين.
- `AddCustomer.dc.html` + `AddCustomerOpening.dc.html` — خطوتان مع **معاينة حية** لبطاقة الزبون
  (الحرف الأول والرصيد وشارة «رصيد افتتاحي» تتغير أثناء الإدخال). الرصيد السابق في خطوة مستقلة
  ببطاقة بخطوط دفتر، وتاريخه (اليوم/أمس/تاريخ آخر)، وسطر يشرح أنه يُسجَّل كحركة ويُصحَّح بالإلغاء.
- `Settings.dc.html` — بطاقة الاشتراك أولاً بشريط المدة المتبقية وزر تجديد، ثم البقالة
  (الموظفون/الأجهزة بشارة «1 بانتظار»/الفروع)، ثم العملات والعرض بمفاتيح مباشرة.

**التقارير لم تُعَد تصميمها** — موجودة ومنفّذة (`Reports*.dc.html` + `REPORTS_SPEC.md`).
إضافة مقترحة اختيارية عليها: بطاقة «أكثر المدينين» بشريط نسبي لكل زبون، وإظهار قيمة العمود عند الضغط.

### عند البناء
- الوزن 700 بدل 600 (تجوال)، وكل هدف ضغط ≥ 44px والأزرار الرئيسية 54px.
- لوحة الأرقام في أسفل الشاشة دائماً (استخدام بإبهام واحد)، و`00` مفتاح مستقل.
- سطر «المتبقي بعده» يُحسب محلياً للعرض فقط؛ الرصيد المعتمد من الخادم بعد المزامنة (قاعدة 3).

## 🎨 مظهران قابلان للتبديل (2026-11-19)
رمزان لكل لون (الجدول الكامل في `docs/DESIGN.md`): **أ · الأخضر الكلاسيكي** (الافتراضي) و**ب · فيروزي وكحلي**.
القاعدة: **ممنوع كتابة قيمة لون مباشرة في أي شاشة** — تُستخدم الرموز وإلا لن يتبدّل المظهر.

**قرار تباين مهم:** `#16A085` مع نص أبيض تباينه 3.28:1 (يرسب في WCAG AA)، فهو يبقى لوناً للأيقونات
والتظليل والرسوم (`accent`)، ويُعمَّق إلى `#11856F` (4.56) في الأسطح التي تحمل نصاً أبيض.
الكحلي `#16324F` (13.1) للهيدر والأرقام الكبيرة — وهذا ما يظهر في المرجع الذي أرسله المالك.

- ✅ منفَّذ: `docs/DESIGN.md` (جدول الرمزين)، `docs/design/Settings.dc.html` (صف «مظهر التطبيق»)،
  `docs/design/SettingsTheme.dc.html` (شاشة الاختيار بمعاينة)، `web/statement/index.html`
  (يتبع `theme` القادم من `public_statement`)، `web/landing/index.html` (نفس الرموز، المظهر التسويقي موحّد افتراضياً).
- ⬜ متبقٍ:
  1. **migration جديدة:** `alter table app.store_settings add column theme text not null default 'classic'
     check (theme in ('classic','ocean'));` + `grant update (theme) on app.store_settings to authenticated;`
     ولا تنسَ `revoke execute … from public, anon` لأي دالة جديدة.
  2. **`app.public_statement`**: أضف `'theme', coalesce((select theme from app.store_settings where store_id = l.store_id), 'classic')`
     إلى الـ jsonb المُرجَع (الصفحة تقرؤه الآن وتتجاهله إن غاب).
  3. **اختبارات:** المظهر يرجع في الكشف العام؛ الموظف لا يغيّر المظهر (المالك فقط)؛ القيمة الوحيدة المقبولة `classic`/`ocean`.
  4. **Flutter:** حوّل `AjilColors` من ثوابت إلى `AjilTheme` بحقلين (`classic`/`ocean`) مع `ThemeExtension`،
     و`header` و`accent` رمزان جديدان. استبدل كل قيمة لون مباشرة في `app/lib` و`web/admin/lib` برمز.
     احفظ الاختيار محلياً (يعمل بدون نت) وزامنه مع `store_settings` عند الاتصال، والمالك فقط يغيّره.
  5. **الشاشتان:** صف «مظهر التطبيق» في الإعدادات + شاشة الاختيار حسب `SettingsTheme.dc.html`، والتبديل فوري بلا إعادة تشغيل.
  6. `flutter analyze` و`flutter test`، ولقطة لكل شاشة بالمظهرين للمقارنة مع `docs/design`.
