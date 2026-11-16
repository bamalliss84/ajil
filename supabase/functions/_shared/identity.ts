// هوية المستخدم: رقم البقالة + رقم المستخدم ← بريد داخلي في Supabase Auth
// منطق خالص بدون اعتماد على Deno — يُختبر بـ Node

/** يوحّد رقم الجوال: أرقام فقط، يحوّل الأرقام العربية/الفارسية، ويحذف 00 ومفتاح اليمن */
export function normalizePhone(input: string, countryCode = "967"): string {
  const western = input
    .replace(/[٠-٩]/g, (d) => String(d.charCodeAt(0) - 0x0660))
    .replace(/[۰-۹]/g, (d) => String(d.charCodeAt(0) - 0x06f0))
    .replace(/\D/g, "");
  let p = western.replace(/^00/, "");
  if (p.startsWith(countryCode)) p = p.slice(countryCode.length);
  p = p.replace(/^0+/, "");
  if (p.length < 7 || p.length > 12) {
    throw new AppError("phone_invalid", "رقم الجوال غير صحيح");
  }
  return p;
}

/** البريد الداخلي: لا يراه المستخدم أبداً */
export function derivedEmail(storePhone: string, userNo: number): string {
  if (!Number.isInteger(userNo) || userNo < 1) {
    throw new AppError("user_no_invalid", "رقم المستخدم غير صحيح");
  }
  return `u${userNo}.${storePhone}@users.ajil.app`;
}

export function validatePassword(pw: string): void {
  if (typeof pw !== "string" || pw.length < 8) {
    throw new AppError("password_weak", "كلمة المرور 8 أحرف على الأقل");
  }
}

export class AppError extends Error {
  constructor(public code: string, public messageAr: string, public status = 400) {
    super(`${code}: ${messageAr}`);
  }
}

/** يستخرج «رمز: رسالة» من أخطاء PostgreSQL (raise exception 'code: رسالة') */
export function parseDbError(message: string | undefined): { code: string; message: string } {
  const m = /^([a-z_]+):\s*(.+)$/s.exec(message ?? "");
  if (m) return { code: m[1], message: m[2] };
  return { code: "server_error", message: "حدث خطأ غير متوقع — حاول مرة أخرى" };
}
