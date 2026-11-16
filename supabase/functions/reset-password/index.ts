// إعادة تعيين كلمة المرور
//  1) المالك لموظف:   POST { mode: "employee", user_id } (بتوكن المالك) ← { temp_password }
//  2) المالك لنفسه:   POST { mode: "owner", phone, code, new_password } (برمز OTP)
//  3) تغيير كلمة المؤقتة: POST { mode: "self", new_password } (بتوكن المستخدم)
import { claimsOf, dbError, handler, json, serviceClient, userClient } from "../_shared/http.ts";
import { AppError, normalizePhone, validatePassword } from "../_shared/identity.ts";

function tempPassword(): string {
  const chars = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789";
  return [...crypto.getRandomValues(new Uint8Array(10))].map((b) => chars[b % chars.length]).join("");
}

Deno.serve(handler(async (req) => {
  const b = await req.json();
  const svc = serviceClient();

  if (b.mode === "employee") {
    const claims = await claimsOf(req);
    if (claims.app_role !== "owner") throw new AppError("owner_only", "للمالك فقط", 403);
    // RLS: المالك يرى مستخدمي بقالته فقط
    const { data: u, error } = await userClient(req).schema("app").from("app_users")
      .select("auth_user_id, role").eq("id", b.user_id).single();
    if (error || !u) throw new AppError("user_not_found", "المستخدم غير موجود");
    if (u.role !== "employee") throw new AppError("not_employee", "استخدم استعادة كلمة مرور المالك");
    const pw = tempPassword();
    await svc.auth.admin.updateUserById(u.auth_user_id, {
      password: pw, user_metadata: { must_change_password: true },
    });
    return json({ temp_password: pw });
  }

  if (b.mode === "owner") {
    const phone = normalizePhone(String(b.phone ?? ""));
    validatePassword(b.new_password);
    const db = svc.schema("app");
    const { data: ok, error } = await db.rpc("otp_verify", { p_phone: phone, p_purpose: "reset_owner", p_code: String(b.code ?? "") });
    if (error) dbError(error);
    if (!ok) throw new AppError("otp_wrong", "الرمز غير صحيح");
    const { data: owner, error: oErr } = await db.from("app_users")
      .select("auth_user_id, stores!inner(owner_phone)").eq("role", "owner").eq("stores.owner_phone", phone).single();
    if (oErr || !owner) throw new AppError("phone_unknown", "لا توجد بقالة بهذا الرقم");
    await svc.auth.admin.updateUserById(owner.auth_user_id, { password: b.new_password });
    return json({ ok: true });
  }

  if (b.mode === "self") {
    validatePassword(b.new_password);
    const jwt = (req.headers.get("authorization") ?? "").replace(/^Bearer\s+/i, "");
    const { data, error } = await svc.auth.getUser(jwt);
    if (error || !data.user) throw new AppError("not_authenticated", "سجّل الدخول أولاً", 401);
    await svc.auth.admin.updateUserById(data.user.id, {
      password: b.new_password, user_metadata: { must_change_password: false },
    });
    return json({ ok: true });
  }

  throw new AppError("mode_invalid", "نوع الطلب غير صحيح");
}));
