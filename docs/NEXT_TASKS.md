# المهام القادمة

اعمل بالترتيب. بعد كل مهمة: شغّل الاختبارات، أشّر عليها هنا (✅)، وحدّث «الحالة الحالية» في `CLAUDE.md`.

> **مهم:** كود Flutter و Dart كُتب كاملاً **بدون مترجم** (لم يكن Flutter متاحاً في بيئة الكتابة).
> قاعدة البيانات مختبرة فعلياً (97 اختباراً)، ومنطق Edge Functions المشترك مختبر (6 اختبارات).
> أول مهمة لك: تشغيل `flutter analyze` وإصلاح أي أخطاء ترجمة أو اختلاف في إصدارات الحزم — **بدون تغيير القواعد في CLAUDE.md**.

## 1. الخادم محلياً
- [ ] `npx supabase init` ثم انسخ محتوى `supabase/config.additions.toml` إلى `supabase/config.toml`
- [ ] `npx supabase start && npx supabase db reset` — يجب أن تُطبَّق 10 migrations بلا خطأ
- [ ] شغّل الاختبارات على قاعدة Supabase المحلية:
  `for f in supabase/tests/*_test.sql; do psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" -v ON_ERROR_STOP=1 -f $f; done`
  ← 97 ✓ (ثم `npx supabase db reset` للتنظيف). بديل بدون Supabase: `bash supabase/tests/run_local.sh`
- [ ] فعّل pg_cron من لوحة Supabase (Database → Extensions) ثم `npx supabase db reset` لجدولة الفحص اليومي

## 2. Edge Functions
- [ ] `cp supabase/functions/.env.example supabase/functions/.env` واضبط `AJIL_GATEWAY_SECRET` بقيمة عشوائية طويلة
- [ ] خزّن بصمة السر في القاعدة (وفي الإنتاج فعّل البوابة):
  ```sql
  update app.platform_config set value = encode(sha256(convert_to('<السر>', 'UTF8')), 'hex') where key = 'gateway_secret_sha256';
  update app.platform_config set value = 'true' where key = 'require_gateway';  -- في الإنتاج
  ```
- [ ] `npx supabase functions serve --env-file supabase/functions/.env`
- [ ] `deno test supabase/functions/_shared/deno_test.ts` (أو `bash supabase/functions/_shared/run_node_tests.sh`)
- [ ] جرّب بالترتيب بـ curl: `send-otp` (الرمز يظهر في الرد لأن OTP_DEV_ECHO=true) ← `register-store` ← الدخول ← `add-employee`

## 3. الحزمة المشتركة
- [ ] `cd packages/ajil_core && dart pub get && dart test` — كل الاختبارات يجب أن تنجح (أرقامها مطابقة لاختبارات الخادم)

## 4. تطبيق Flutter
- [ ] `cd app && flutter create --org app.ajil --project-name ajil --platforms android,web .`
- [ ] اتبع `app/android-overrides/README.md` (MainActivity بـ FLAG_SECURE + الصلاحيات + desugaring)
- [ ] ضع ملفات خط IBM Plex Sans Arabic في `app/assets/fonts/` (Regular, Medium, SemiBold)
- [ ] `flutter pub get && dart run build_runner build --delete-conflicting-outputs` (يولّد `db.g.dart`)
- [ ] `flutter analyze` ← أصلح كل الأخطاء
- [ ] `flutter test` ← اختبارات محرك المزامنة (8) يجب أن تنجح
- [ ] شغّل على المحاكي:
  `flutter run --dart-define=SUPABASE_URL=http://10.0.2.2:54321 --dart-define=SUPABASE_ANON_KEY=<من supabase status>`
- [ ] سيناريو كامل يدوياً: تسجيل بقالة ← PIN ← زبون برصيد افتتاحي ← دين بموعد ← اقطع النت وسجّل ← أرجعه وتأكد من ✓ ← وعد ← كشف PDF ← واتساب ← موظف بجهاز ثانٍ (اعتماد) ← إلغاء من الموظف بعد المهلة يُرفض

## 5. الويب
- [ ] صفحة المشترك: `cd app && flutter run -d chrome ...` (انسخ `sqlite3.wasm` و `drift_worker.js` إلى `app/web/` — راجع android-overrides/README.md)
- [ ] لوحة الإدارة: `cd web/admin && flutter create --platforms web . && flutter run -d chrome ...` — أنشئ مدير المنصة كما في `web/README.md`
- [ ] صفحة التعريف: `web/landing/index.html` — ضع رابط المتجر ورقم الدعم

## 6. ميزات لم تُنفّذ بعد (حسب الأولوية)
- [ ] **رابط كشف الحساب العام للزبون**: جدول `statement_links` (token عشوائي طويل، يُلغى) + Edge Function `public-statement` تعرض صفحة HTML للقراءة فقط. الإعداد `STATEMENT_BASE_URL` جاهز في التطبيق
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
- **لاحقاً (غير منفّذ):** `{الرابط}` لكشف الحساب العام (ينتظر ميزة الرابط العام)، وقنوات مدفوعة SMS/WhatsApp API للباقة الأعلى.
- **تحقق يدوي على جهاز حقيقي:** الرجوع من واتساب يُظهر «هل وصلت الرسالة؟»، والضغط على تنبيه المطالبة وهو مقفل يفتح الشاشة بعد إدخال PIN.
