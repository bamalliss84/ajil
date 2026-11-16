// المالك يضيف موظفاً: يأخذ رقم المستخدم التالي وكلمة مرور مؤقتة
// POST { name, branches: uuid[] } ← { user_no, temp_password }
import { claimsOf, dbError, handler, json, serviceClient, userClient } from "../_shared/http.ts";
import { AppError, derivedEmail } from "../_shared/identity.ts";

function tempPassword(): string {
  const chars = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghjkmnpqrstuvwxyz23456789";
  const bytes = crypto.getRandomValues(new Uint8Array(10));
  return [...bytes].map((b) => chars[b % chars.length]).join("");
}

Deno.serve(handler(async (req) => {
  const claims = await claimsOf(req);
  if (claims.app_role !== "owner") throw new AppError("owner_only", "إضافة الموظفين للمالك فقط", 403);
  const { name, branches } = await req.json();
  if (!name || String(name).trim().length < 2) throw new AppError("name_required", "اكتب اسم الموظف");
  if (!Array.isArray(branches) || branches.length === 0) {
    throw new AppError("branches_required", "اختر فرعاً واحداً على الأقل");
  }

  const user = userClient(req).schema("app");
  const { data: store, error: sErr } = await user.from("stores").select("owner_phone").single();
  if (sErr) dbError(sErr);
  const { data: last } = await user.from("app_users").select("user_no").order("user_no", { ascending: false }).limit(1);
  const predicted = (last?.[0]?.user_no ?? 1) + 1;

  const svc = serviceClient();
  const password = tempPassword();
  const { data: created, error: aErr } = await svc.auth.admin.createUser({
    email: derivedEmail(store.owner_phone, predicted), password, email_confirm: true,
    user_metadata: { store_phone: store.owner_phone, must_change_password: true },
  });
  if (aErr || !created.user) throw new AppError("auth_create_failed", "تعذّر إنشاء حساب الموظف");

  const { data: emp, error: eErr } = await user.rpc("add_employee", {
    p_name: String(name).trim(), p_auth_user_id: created.user.id, p_branches: branches,
  });
  if (eErr) {
    await svc.auth.admin.deleteUser(created.user.id);
    dbError(eErr);
  }
  // لو سبق موظف آخر بنفس اللحظة وأخذ الرقم: نصحح البريد
  if (emp.user_no !== predicted) {
    await svc.auth.admin.updateUserById(created.user.id, { email: derivedEmail(store.owner_phone, emp.user_no) });
  }
  return json({ user_no: emp.user_no, temp_password: password });
}));
