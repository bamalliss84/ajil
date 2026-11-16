// التحقق من توقيع طلبات المزامنة بمفتاح الجهاز (ECDSA P-256 / SHA-256)
// الجوال يولّد المفتاح في Android Keystore (لا يخرج منه) ويرسل المفتاح العام عند التسجيل.
// منطق خالص يعمل في Deno و Node 22 (WebCrypto)

const enc = new TextEncoder();

export const MAX_SKEW_MS = 5 * 60 * 1000;

export async function sha256Hex(data: string | Uint8Array): Promise<string> {
  const bytes = typeof data === "string" ? enc.encode(data) : data;
  const digest = await crypto.subtle.digest("SHA-256", bytes as BufferSource);
  return [...new Uint8Array(digest)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

/** النص الموقَّع: يربط التوقيع بالجهاز والوقت والـ nonce ومحتوى الطلب */
export async function canonicalString(p: {
  method: string; path: string; deviceId: string; timestamp: string; nonce: string; body: string;
}): Promise<string> {
  return [p.method.toUpperCase(), p.path, p.deviceId, p.timestamp, p.nonce, await sha256Hex(p.body)].join("\n");
}

export function b64ToBytes(b64: string): Uint8Array {
  const bin = atob(b64.replace(/-/g, "+").replace(/_/g, "/"));
  return Uint8Array.from(bin, (c) => c.charCodeAt(0));
}

/**
 * Android يخرج التوقيع بصيغة DER (ASN.1)، و WebCrypto يتوقع r||s (64 بايت).
 * هذه الدالة تقبل الصيغتين.
 */
export function derToRaw(sig: Uint8Array): Uint8Array {
  if (sig.length === 64) return sig;
  if (sig[0] !== 0x30) throw new Error("bad_signature_format");
  let i = 2;
  if (sig[1] & 0x80) i = 2 + (sig[1] & 0x7f);
  const readInt = (): Uint8Array => {
    if (sig[i] !== 0x02) throw new Error("bad_signature_format");
    const len = sig[i + 1];
    let v = sig.slice(i + 2, i + 2 + len);
    i += 2 + len;
    while (v.length > 32 && v[0] === 0) v = v.slice(1);
    if (v.length > 32) throw new Error("bad_signature_format");
    const out = new Uint8Array(32);
    out.set(v, 32 - v.length);
    return out;
  };
  const r = readInt();
  const s = readInt();
  const raw = new Uint8Array(64);
  raw.set(r, 0);
  raw.set(s, 32);
  return raw;
}

export function checkTimestamp(ts: string, now = Date.now()): void {
  const t = Number(ts);
  if (!Number.isFinite(t) || Math.abs(now - t) > MAX_SKEW_MS) {
    throw new Error("timestamp_skew");
  }
}

export async function verifySignature(publicKeySpkiB64: string, message: string, signatureB64: string): Promise<boolean> {
  const key = await crypto.subtle.importKey(
    "spki", b64ToBytes(publicKeySpkiB64) as BufferSource, { name: "ECDSA", namedCurve: "P-256" }, false, ["verify"],
  );
  let raw: Uint8Array;
  try {
    raw = derToRaw(b64ToBytes(signatureB64));
  } catch {
    return false;
  }
  return crypto.subtle.verify({ name: "ECDSA", hash: "SHA-256" }, key, raw as BufferSource, enc.encode(message));
}
