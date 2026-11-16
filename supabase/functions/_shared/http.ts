// أدوات HTTP و Supabase المشتركة للدوال (Deno)
import { createClient, type SupabaseClient } from "npm:@supabase/supabase-js@2";
import { AppError, parseDbError } from "./identity.ts";

export const corsHeaders = {
  "access-control-allow-origin": "*",
  "access-control-allow-headers":
    "authorization, x-client-info, apikey, content-type, x-ajil-device, x-ajil-ts, x-ajil-nonce, x-ajil-sig",
  "access-control-allow-methods": "POST, OPTIONS",
};

export const env = (k: string): string => {
  const v = Deno.env.get(k);
  if (!v) throw new Error(`missing env ${k}`);
  return v;
};

export function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "content-type": "application/json; charset=utf-8" },
  });
}

/** يغلّف المعالج: CORS، تحويل الأخطاء إلى { code, message } بالعربي */
export function handler(fn: (req: Request) => Promise<Response>) {
  return async (req: Request): Promise<Response> => {
    if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
    if (req.method !== "POST") return json({ code: "method_not_allowed", message: "POST فقط" }, 405);
    try {
      return await fn(req);
    } catch (e) {
      if (e instanceof AppError) return json({ code: e.code, message: e.messageAr }, e.status);
      const { code, message } = parseDbError((e as { message?: string })?.message);
      console.error(e);
      return json({ code, message }, code === "server_error" ? 500 : 400);
    }
  };
}

/** عميل بصلاحية الخدمة: يتجاوز RLS — لا يُستخدم لعمليات المستخدم */
export function serviceClient(): SupabaseClient {
  return createClient(env("SUPABASE_URL"), env("SUPABASE_SERVICE_ROLE_KEY"), {
    auth: { persistSession: false, autoRefreshToken: false },
  });
}

/** عميل بتوكن المستخدم: RLS تُطبَّق كأن التطبيق يتصل مباشرة */
export function userClient(req: Request, extraHeaders: Record<string, string> = {}): SupabaseClient {
  const auth = req.headers.get("authorization");
  if (!auth) throw new AppError("not_authenticated", "سجّل الدخول أولاً", 401);
  return createClient(env("SUPABASE_URL"), env("SUPABASE_ANON_KEY"), {
    auth: { persistSession: false, autoRefreshToken: false },
    global: { headers: { authorization: auth, ...extraHeaders } },
  });
}

/** يقرأ مطالبات JWT (بعد أن يتحقق منه Supabase عبر getUser) */
export async function claimsOf(req: Request): Promise<Record<string, unknown>> {
  const auth = req.headers.get("authorization") ?? "";
  const jwt = auth.replace(/^Bearer\s+/i, "");
  const { error } = await serviceClient().auth.getUser(jwt);
  if (error) throw new AppError("not_authenticated", "انتهت الجلسة — سجّل الدخول", 401);
  const b64 = jwt.split(".")[1].replace(/-/g, "+").replace(/_/g, "/");
  const padded = b64 + "=".repeat((4 - (b64.length % 4)) % 4);
  const bytes = Uint8Array.from(atob(padded), (c) => c.charCodeAt(0));
  return JSON.parse(new TextDecoder().decode(bytes));
}

export function dbError(error: { message?: string } | null): never {
  const { code, message } = parseDbError(error?.message);
  throw new AppError(code, message);
}
