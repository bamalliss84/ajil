# الويب

| المجلد | ما هو | التشغيل |
| --- | --- | --- |
| `../app` | **صفحة المشترك** = نفس تطبيق Flutter مبنياً للويب. يعمل متصلاً فقط: الكتابة تُمنع بدون اتصال، والبيانات المحلية تُمسح عند الخروج | `powershell -ExecutionPolicy Bypass -File scripts/run-web.ps1` ← http://localhost:8091. من الجوال: `adb reverse tcp:8091 tcp:8091` ثم افتحه في Chrome |
| `admin/` | **لوحة إدارة المنصة**: الملخص، البقالات (تفعيل/تجديد/إيقاف)، أكواد التفعيل، تنبيهات السلامة | `powershell -ExecutionPolicy Bypass -File scripts/run-admin.ps1` ← http://localhost:8090 (أو `-Chrome` للتطوير) |
| `landing/` | **صفحة التعريف** HTML ثابتة (سريعة وتظهر في Google). عدّل `[رابط المتجر]` و `[رقم الدعم]` | افتح `index.html` أو انشرها على أي استضافة ثابتة |

## إنشاء مدير المنصة (مرة واحدة)
**محلياً:** `powershell -ExecutionPolicy Bypass -File scripts/create-platform-admin.ps1 -Email admin@ajil.local -Password '...'`
(بيانات مدير التطوير المحلي محفوظة في `web/admin/.env.local` — غير مرفوعة).

**في الإنتاج:**
1. من لوحة Supabase (Authentication → Add user) أنشئ مستخدماً ببريدك وكلمة مرور قوية.
2. في SQL Editor:
```sql
insert into app.platform_admins (auth_user_id, name) values ('<user id>', 'اسمك');
```
3. سجّل الدخول في لوحة الإدارة بالبريد وكلمة المرور.

## ملاحظات لوحة الإدارة
- بعد كل بناء جديد قد يعرض المتصفح النسخة القديمة (service worker): حدّث بـ Ctrl+Shift+R.
- الإيقاف يمنع تسجيل حركات جديدة للبقالة (trigger `tx_store_active`) ولا يحذف شيئاً.
