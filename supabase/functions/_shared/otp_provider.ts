// مزوّد إرسال رمز التحقق — خلف واجهة لأن المزوّد لم يُختر بعد
// للتطوير: ConsoleProvider يطبع الرمز في سجل الدالة

export interface OtpProvider {
  send(phoneE164: string, message: string): Promise<void>;
}

export class ConsoleProvider implements OtpProvider {
  async send(phone: string, message: string): Promise<void> {
    console.log(`[OTP] ${phone}: ${message}`);
  }
}

/**
 * قالب لمزوّد HTTP عام (واتساب Business API أو بوابة SMS).
 * يُضبط بمتغيرات البيئة: OTP_HTTP_URL و OTP_HTTP_TOKEN
 * والجسم: { to, message } — عدّل الشكل حسب المزوّد المختار.
 */
export class HttpProvider implements OtpProvider {
  constructor(private url: string, private token: string) {}
  async send(phone: string, message: string): Promise<void> {
    const res = await fetch(this.url, {
      method: "POST",
      headers: { "content-type": "application/json", authorization: `Bearer ${this.token}` },
      body: JSON.stringify({ to: phone, message }),
    });
    if (!res.ok) throw new Error(`otp_send_failed: ${res.status}`);
  }
}

export function otpMessage(code: string, purpose: string): string {
  const what = purpose === "register" ? "تسجيل بقالتك في آجِل" : "استعادة كلمة المرور في آجِل";
  return `رمز ${what}: ${code}\nصالح 5 دقائق. لا تشاركه مع أحد.`;
}

export function providerFromEnv(get: (k: string) => string | undefined): OtpProvider {
  const url = get("OTP_HTTP_URL");
  const token = get("OTP_HTTP_TOKEN");
  if (url && token) return new HttpProvider(url, token);
  return new ConsoleProvider();
}
