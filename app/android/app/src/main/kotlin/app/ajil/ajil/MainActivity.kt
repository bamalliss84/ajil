package app.ajil.ajil

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity

// FlutterFragmentActivity مطلوب لـ local_auth (البصمة)
// FLAG_SECURE: يمنع لقطات الشاشة ويخفي المحتوى في قائمة التطبيقات الأخيرة
class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.setFlags(WindowManager.LayoutParams.FLAG_SECURE, WindowManager.LayoutParams.FLAG_SECURE)
    }
}
