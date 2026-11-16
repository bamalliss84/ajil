# الويب

| المجلد | ما هو | التشغيل |
| --- | --- | --- |
| `../app` | **صفحة المشترك** = نفس تطبيق Flutter مبنياً للويب. يعمل متصلاً فقط: الكتابة تُمنع بدون اتصال، والبيانات المحلية تُمسح عند الخروج | `cd ../app && flutter run -d chrome --dart-define=SUPABASE_URL=http://127.0.0.1:54321 --dart-define=SUPABASE_ANON_KEY=...` |
| `admin/` | **لوحة إدارة المنصة**: الملخص، البقالات (تفعيل/تجديد/إيقاف)، أكواد التفعيل، تنبيهات السلامة | `cd admin && flutter create --platforms web . && flutter run -d chrome --dart-define=...` |
| `landing/` | **صفحة التعريف** HTML ثابتة (سريعة وتظهر في Google). عدّل `[رابط المتجر]` و `[رقم الدعم]` | افتح `index.html` أو انشرها على أي استضافة ثابتة |

## إنشاء مدير المنصة (مرة واحدة)
1. من لوحة Supabase (Authentication → Add user) أنشئ مستخدماً ببريدك وكلمة مرور قوية.
2. في SQL Editor:
```sql
insert into app.platform_admins (auth_user_id, name) values ('<user id>', 'اسمك');
```
3. سجّل الدخول في لوحة الإدارة بالبريد وكلمة المرور.
