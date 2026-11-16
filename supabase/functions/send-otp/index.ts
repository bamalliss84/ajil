// إرسال رمز تحقق لرقم المالك: للتسجيل أو لاستعادة كلمة المرور
// POST { phone, purpose: "register" | "reset_owner" }
import { dbError, handler, json, serviceClient } from "../_shared/http.ts";
import { AppError, normalizePhone } from "../_shared/identity.ts";
import { otpMessage, providerFromEnv } from "../_shared/otp_provider.ts";

Deno.serve(handler(async (req) => {
  const { phone, purpose } = await req.json();
  if (!["register", "reset_owner"].includes(purpose)) {
    throw new AppError("purpose_invalid", "نوع الطلب غير صحيح");
  }
  const p = normalizePhone(String(phone ?? ""));
  const db = serviceClient().schema("app");
  const { data: code, error } = await db.rpc("otp_issue", { p_phone: p, p_purpose: purpose });
  if (error) dbError(error);

  const cc = Deno.env.get("PHONE_COUNTRY_CODE") ?? "967";
  await providerFromEnv((k) => Deno.env.get(k)).send(`+${cc}${p}`, otpMessage(code as string, purpose));

  // للتطوير فقط: يرجع الرمز في الرد لتسهيل التجربة
  const echo = Deno.env.get("OTP_DEV_ECHO") === "true";
  return json({ ok: true, ...(echo ? { dev_code: code } : {}) });
}));
