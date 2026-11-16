// تسجيل بقالة جديدة بعد التحقق من رقم المالك
// POST { phone, code, store_name, owner_name, password, device_key?, currency? }
// ← { session } جلسة دخول للمالك (المستخدم 1، الفرع الرئيسي)
import { dbError, env, handler, json, serviceClient } from "../_shared/http.ts";
import { AppError, derivedEmail, normalizePhone, validatePassword } from "../_shared/identity.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

Deno.serve(handler(async (req) => {
  const b = await req.json();
  const phone = normalizePhone(String(b.phone ?? ""));
  const storeName = String(b.store_name ?? "").trim();
  const ownerName = String(b.owner_name ?? "").trim();
  if (storeName.length < 2) throw new AppError("store_name_required", "اكتب اسم البقالة");
  if (ownerName.length < 2) throw new AppError("owner_name_required", "اكتب اسمك");
  validatePassword(b.password);

  const svc = serviceClient();
  const db = svc.schema("app");

  const { data: ok, error: otpErr } = await db.rpc("otp_verify", {
    p_phone: phone, p_purpose: "register", p_code: String(b.code ?? ""),
  });
  if (otpErr) dbError(otpErr);
  if (!ok) throw new AppError("otp_wrong", "الرمز غير صحيح");

  const email = derivedEmail(phone, 1);
  const { data: created, error: authErr } = await svc.auth.admin.createUser({
    email, password: b.password, email_confirm: true,
    user_metadata: { store_phone: phone, user_no: 1, display_name: ownerName },
  });
  if (authErr || !created.user) {
    throw new AppError("auth_create_failed", "تعذّر إنشاء الحساب — ربما الرقم مسجل مسبقاً");
  }

  const { error: storeErr } = await db.rpc("create_store", {
    p_name: storeName, p_owner_phone: phone, p_owner_name: ownerName,
    p_auth_user_id: created.user.id, p_device_key: b.device_key ?? null,
    p_currency: b.currency ?? "YER",
  });
  if (storeErr) {
    await svc.auth.admin.deleteUser(created.user.id);   // تراجع: لا حساب بدون بقالة
    dbError(storeErr);
  }

  // دخول مباشر: التوكن الآن يحمل store_id والدور (عبر hook التوكن)
  const anon = createClient(env("SUPABASE_URL"), env("SUPABASE_ANON_KEY"), { auth: { persistSession: false } });
  const { data: signIn, error: signErr } = await anon.auth.signInWithPassword({ email, password: b.password });
  if (signErr) throw new AppError("signin_failed", "تم التسجيل — سجّل الدخول من جديد");
  return json({ session: signIn.session });
}));
