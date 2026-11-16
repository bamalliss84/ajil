# ملفات Android تُنسخ بعد `flutter create`

```bash
cd app
flutter create --org app.ajil --project-name ajil --platforms android,web .
cp android-overrides/app/src/main/kotlin/app/ajil/ajil/MainActivity.kt android/app/src/main/kotlin/app/ajil/ajil/MainActivity.kt
```

ثم أضف إلى `android/app/src/main/AndroidManifest.xml` داخل `<manifest>`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.USE_BIOMETRIC"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
```

وداخل `<application>` (لإعادة جدولة التنبيهات بعد إعادة تشغيل الجوال):

```xml
<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
  <intent-filter>
    <action android:name="android.intent.action.BOOT_COMPLETED"/>
    <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
  </intent-filter>
</receiver>
<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"/>
```

وفي `android/app/build.gradle`: `minSdk = 23` و `compileOptions { coreLibraryDesugaringEnabled true }` مع
`dependencies { coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4' }` (مطلوب لـ flutter_local_notifications).

## الويب (drift)
انسخ `sqlite3.wasm` و `drift_worker.js` إلى `app/web/` — من صفحة إصدارات drift و sqlite3.dart على GitHub
(الإصدار المطابق لـ pubspec.lock). التفاصيل: https://drift.simonbinder.eu/platforms/web/
