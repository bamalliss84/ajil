// اختبارات المنطق المشترك — تعمل في Deno (deno test) وفي Node عبر tsc
import { canonicalString, checkTimestamp, derToRaw, sha256Hex, verifySignature } from "./signature.ts";
import { derivedEmail, normalizePhone, parseDbError } from "./identity.ts";

type T = { name: string; fn: () => void | Promise<void> };
export const tests: T[] = [];
const test = (name: string, fn: T["fn"]) => tests.push({ name, fn });
function eq(a: unknown, b: unknown, msg = "") {
  if (JSON.stringify(a) !== JSON.stringify(b)) throw new Error(`${msg} expected ${JSON.stringify(b)} got ${JSON.stringify(a)}`);
}
function throws(fn: () => unknown, code: string) {
  try { fn(); } catch (e) { if (String((e as Error).message).startsWith(code)) return; throw e; }
  throw new Error(`expected ${code}`);
}

test("توحيد رقم الجوال اليمني بكل الصيغ", () => {
  eq(normalizePhone("777 123 456"), "777123456");
  eq(normalizePhone("+967777123456"), "777123456");
  eq(normalizePhone("00967 777-123-456"), "777123456");
  eq(normalizePhone("٧٧٧١٢٣٤٥٦"), "777123456");
  eq(normalizePhone("0777123456"), "777123456");
  throws(() => normalizePhone("123"), "phone_invalid");
});

test("البريد الداخلي من رقم البقالة ورقم المستخدم", () => {
  eq(derivedEmail("777123456", 1), "u1.777123456@users.ajil.app");
  eq(derivedEmail("777123456", 3), "u3.777123456@users.ajil.app");
  throws(() => derivedEmail("777123456", 0), "user_no_invalid");
});

test("قراءة أخطاء قاعدة البيانات العربية", () => {
  eq(parseDbError("plan_customer_limit: وصلت لحد الباقة (200 زبون)"),
    { code: "plan_customer_limit", message: "وصلت لحد الباقة (200 زبون)" });
  eq(parseDbError("some random error").code, "server_error");
});

test("التوقيع الصحيح يُقبل والمعدَّل يُرفض (P-256، DER و raw)", async () => {
  const kp = await crypto.subtle.generateKey({ name: "ECDSA", namedCurve: "P-256" }, true, ["sign", "verify"]);
  const spki = new Uint8Array(await crypto.subtle.exportKey("spki", kp.publicKey));
  const pub = btoa(String.fromCharCode(...spki));
  const msg = await canonicalString({ method: "post", path: "/sync-push", deviceId: "d1", timestamp: "1", nonce: "n1", body: '{"rows":[]}' });
  const raw = new Uint8Array(await crypto.subtle.sign({ name: "ECDSA", hash: "SHA-256" }, kp.privateKey, new TextEncoder().encode(msg)));
  eq(await verifySignature(pub, msg, btoa(String.fromCharCode(...raw))), true, "raw");

  // نحوّل raw إلى DER كما يخرجه Android
  const int = (b: Uint8Array) => { let v = b; while (v.length > 1 && v[0] === 0 && !(v[1] & 0x80)) v = v.slice(1); if (v[0] & 0x80) v = Uint8Array.from([0, ...v]); return [0x02, v.length, ...v]; };
  const body = [...int(raw.slice(0, 32)), ...int(raw.slice(32))];
  const der = Uint8Array.from([0x30, body.length, ...body]);
  eq(derToRaw(der), raw, "der->raw");
  eq(await verifySignature(pub, msg, btoa(String.fromCharCode(...der))), true, "der");

  const tampered = msg.replace("n1", "n2");
  eq(await verifySignature(pub, tampered, btoa(String.fromCharCode(...raw))), false, "tampered");
  eq(await verifySignature(pub, msg, "AAAA"), false, "garbage");
});

test("النص الموقَّع يتضمن بصمة الجسم", async () => {
  const a = await canonicalString({ method: "POST", path: "/p", deviceId: "d", timestamp: "1", nonce: "n", body: "x" });
  eq(a.split("\n").length, 6);
  eq(a.split("\n")[5], await sha256Hex("x"));
});

test("ساعة الجوال: فرق أكثر من 5 دقائق يُرفض", () => {
  const now = 1_000_000_000;
  checkTimestamp(String(now - 60_000), now);
  throws(() => checkTimestamp(String(now - 6 * 60_000), now), "timestamp_skew");
  throws(() => checkTimestamp("abc", now), "timestamp_skew");
});
