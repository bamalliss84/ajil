# المهام القادمة

اعمل بالترتيب. بعد كل مهمة: شغّل الاختبارات، أشّر عليها هنا (✅)، وحدّث «الحالة الحالية» في `CLAUDE.md`.

> **مهم:** كود Flutter و Dart كُتب كاملاً **بدون مترجم** (لم يكن Flutter متاحاً في بيئة الكتابة).
> قاعدة البيانات مختبرة فعلياً (97 اختباراً)، ومنطق Edge Functions المشترك مختبر (6 اختبارات).
> أول مهمة لك: تشغيل `flutter analyze` وإصلاح أي أخطاء ترجمة أو اختلاف في إصدارات الحزم — **بدون تغيير القواعد في CLAUDE.md**.

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
- [ ] 🔴 **فتح التطبيق بدون نت بعد إغلاقه يعلق على شاشة البداية** (مُتحقَّق على الجوال 2026-11-18): `restore()` ← `_openSession` يطلب المتجر والمستخدم والفروع والجهاز من الخادم، و Supabase يعيد محاولة تجديد التوكن المنتهي بلا نهاية فتنتظر كل الطلبات. الحل: حفظ `WorkSession` (والاشتراك والإعدادات) محلياً بعد كل فتح ناجح، والفتح منه عند عدم الاتصال مع مهلة قصيرة للطلبات، ثم التحديث في الخلفية عند عودة النت
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
