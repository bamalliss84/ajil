// بوابة رفع الحركات: تتحقق من توقيع الجهاز ثم تمرر الدفعة لقاعدة البيانات
// الرؤوس: Authorization, x-ajil-device, x-ajil-ts (ms), x-ajil-nonce, x-ajil-sig (base64)
// الجسم: { rows: [...] } ← { results: [{id,status,server_seq,error}], gaps: [seq...] }
import { dbError, env, handler, json, userClient } from "../_shared/http.ts";
import { AppError } from "../_shared/identity.ts";
import { canonicalString, checkTimestamp, verifySignature } from "../_shared/signature.ts";

const MAX_ROWS = 500;

Deno.serve(handler(async (req) => {
  const deviceId = req.headers.get("x-ajil-device") ?? "";
  const ts = req.headers.get("x-ajil-ts") ?? "";
  const nonce = req.headers.get("x-ajil-nonce") ?? "";
  const sig = req.headers.get("x-ajil-sig") ?? "";
  if (!deviceId || !nonce || !sig) throw new AppError("signature_missing", "طلب غير موقّع", 401);
  try {
    checkTimestamp(ts);
  } catch {
    throw new AppError("timestamp_skew", "ساعة الجوال غير مضبوطة — صحّح التاريخ والوقت", 401);
  }

  const body = await req.text();
  const db = userClient(req).schema("app");

  // يرجع المفتاح العام للجهاز المعتمد في بقالة المستخدم، ويسجل الـ nonce (منع الإعادة)
  const { data: publicKey, error: kErr } = await db.rpc("gateway_device_key", { p_device: deviceId, p_nonce: nonce });
  if (kErr) dbError(kErr);

  // المسار ثابت (لا نعتمد على req.url لأن بوابة Supabase قد تغيّره)
  const message = await canonicalString({ method: "POST", path: "sync-push", deviceId, timestamp: ts, nonce, body });
  if (!(await verifySignature(publicKey as string, message, sig))) {
    throw new AppError("signature_invalid", "توقيع الجهاز غير صحيح", 401);
  }

  const { rows } = JSON.parse(body);
  if (!Array.isArray(rows) || rows.length > MAX_ROWS) {
    throw new AppError("batch_invalid", `الدفعة يجب أن تكون قائمة حتى ${MAX_ROWS} حركة`);
  }

  // نفس توكن المستخدم + سر البوابة: RLS تطبَّق، والقاعدة تعرف أن الطلب مرّ من هنا
  const gw = userClient(req, { "x-ajil-gateway": env("AJIL_GATEWAY_SECRET") }).schema("app");
  const { data: results, error: pErr } = await gw.rpc("push_transactions", { p_device: deviceId, p_rows: rows });
  if (pErr) dbError(pErr);
  const { data: gaps } = await gw.rpc("device_gaps", { p_device: deviceId });

  return json({ results, gaps: (gaps ?? []).map((g: { missing_seq: number }) => g.missing_seq) });
}));
