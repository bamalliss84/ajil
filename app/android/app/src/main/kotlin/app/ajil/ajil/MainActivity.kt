package app.ajil.ajil

import android.content.pm.ApplicationInfo
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity

// FlutterFragmentActivity مطلوب لـ local_auth (البصمة)
// FLAG_SECURE: يمنع لقطات الشاشة ويخفي المحتوى في قائمة التطبيقات الأخيرة
// (في نسخة debug فقط يُترك بدونه لأخذ لقطات المطابقة مع التصميم عبر adb)
class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val debuggable = (applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
        if (!debuggable) {
            window.setFlags(WindowManager.LayoutParams.FLAG_SECURE, WindowManager.LayoutParams.FLAG_SECURE)
        }
    }
}
