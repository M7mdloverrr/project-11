// POST /functions/v1/admin-users  { "action": "...", ...params }
// Caller: a signed-in admin. Performs the account operations that need the
// Supabase Auth admin API (create, block, delete, password reset, e-mail
// confirmation) plus issuing a teacher code on a teacher's behalf.
// The service-role key stays here on the server.
import { createClient, type SupabaseClient } from "jsr:@supabase/supabase-js@2";
import { generateTeacherCode } from "../_shared/teacher_code.ts";
import { corsHeaders, errorResponse, json, requireEnv, statusForPgCode } from "../_shared/http.ts";
import { parseAdminRequest, redirectForRole, type AdminRequest } from "./actions.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return errorResponse(405, "method_not_allowed", "Use POST");

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return errorResponse(401, "unauthorized", "Missing Authorization header");

  let parsed: AdminRequest | string;
  try {
    parsed = parseAdminRequest(await req.json());
  } catch {
    return errorResponse(400, "bad_request", "Body must be JSON");
  }
  if (typeof parsed === "string") return errorResponse(400, "bad_request", parsed);

  const url = requireEnv("SUPABASE_URL");
  const anonKey = requireEnv("SUPABASE_ANON_KEY");
  const userClient = createClient(url, anonKey, {
    global: { headers: { Authorization: authHeader } },
    auth: { persistSession: false },
  });
  const { data: userData, error: userError } = await userClient.auth.getUser();
  if (userError || !userData.user) return errorResponse(401, "unauthorized", "Invalid session");
  const { data: isAdmin, error: adminError } = await userClient.rpc("is_admin");
  if (adminError || isAdmin !== true) return errorResponse(403, "forbidden", "Admins only");

  const adminId = userData.user.id;
  const admin = createClient(url, requireEnv("SUPABASE_SERVICE_ROLE_KEY"), {
    auth: { persistSession: false },
  });

  try {
    return await handle(parsed, adminId, admin, createClient(url, anonKey, { auth: { persistSession: false } }));
  } catch (e) {
    const err = e as { status?: number; code?: string; message?: string };
    return errorResponse(err.status ?? statusForPgCode(err.code), err.code ?? "failed", err.message ?? String(e));
  }
});

class HttpError extends Error {
  constructor(readonly status: number, readonly code: string, message: string) {
    super(message);
  }
}

async function log(admin: SupabaseClient, adminId: string, action: string, targetType: string, targetId: string | null, details: Record<string, unknown> = {}) {
  const { error } = await admin.rpc("log_admin_action_as", {
    p_admin_id: adminId,
    p_action: action,
    p_target_type: targetType,
    p_target_id: targetId,
    p_details: details,
  });
  if (error) console.error("audit log failed", error);
}

async function profileOf(admin: SupabaseClient, userId: string) {
  const { data, error } = await admin.from("profiles").select("id, role, display_name").eq("id", userId).maybeSingle();
  if (error) throw error;
  if (!data) throw new HttpError(404, "user_not_found", "User not found");
  return data as { id: string; role: string; display_name: string };
}

async function emailOf(admin: SupabaseClient, userId: string): Promise<string> {
  const { data, error } = await admin.auth.admin.getUserById(userId);
  if (error) throw error;
  const email = data.user?.email;
  if (!email) throw new HttpError(404, "user_not_found", "User has no e-mail");
  return email;
}

function notSelf(adminId: string, userId: string) {
  if (adminId === userId) throw new HttpError(400, "self_action", "You cannot do this to your own account");
}

async function handle(r: AdminRequest, adminId: string, admin: SupabaseClient, anon: SupabaseClient): Promise<Response> {
  switch (r.action) {
    case "create_user": {
      const metadata = { role: r.role === "admin" ? "student" : r.role, display_name: r.display_name, locale: r.locale };
      let userId: string;
      let inviteSent = false;
      if (r.password) {
        const { data, error } = await admin.auth.admin.createUser({
          email: r.email,
          password: r.password,
          email_confirm: true,
          user_metadata: metadata,
        });
        if (error) throw new HttpError(error.status ?? 400, error.code ?? "create_failed", error.message);
        userId = data.user.id;
      } else {
        const { data, error } = await admin.auth.admin.inviteUserByEmail(r.email, {
          data: metadata,
          redirectTo: redirectForRole(r.role),
        });
        if (error) throw new HttpError(error.status ?? 400, error.code ?? "invite_failed", error.message);
        userId = data.user.id;
        inviteSent = true;
      }
      if (r.role === "admin") {
        const { error } = await admin.from("profiles").update({ role: "admin" }).eq("id", userId);
        if (error) throw error;
      }
      await log(admin, adminId, "create_user", "user", userId, { email: r.email, role: r.role, invite: inviteSent });
      return json({ user_id: userId, invite_sent: inviteSent });
    }

    case "set_blocked": {
      notSelf(adminId, r.user_id);
      await profileOf(admin, r.user_id);
      const { error } = await admin.auth.admin.updateUserById(r.user_id, {
        ban_duration: r.blocked ? "876000h" : "none",
      });
      if (error) throw new HttpError(error.status ?? 400, error.code ?? "update_failed", error.message);
      await log(admin, adminId, r.blocked ? "block_user" : "unblock_user", "user", r.user_id);
      return json({ user_id: r.user_id, blocked: r.blocked });
    }

    case "delete_user": {
      notSelf(adminId, r.user_id);
      const profile = await profileOf(admin, r.user_id);
      const email = await emailOf(admin, r.user_id);
      const { error } = await admin.auth.admin.deleteUser(r.user_id);
      if (error) throw new HttpError(error.status ?? 400, error.code ?? "delete_failed", error.message);
      await log(admin, adminId, "delete_user", "user", r.user_id, { email, role: profile.role, display_name: profile.display_name });
      return json({ user_id: r.user_id, deleted: true });
    }

    case "confirm_email": {
      await profileOf(admin, r.user_id);
      const { error } = await admin.auth.admin.updateUserById(r.user_id, { email_confirm: true });
      if (error) throw new HttpError(error.status ?? 400, error.code ?? "update_failed", error.message);
      await log(admin, adminId, "confirm_email", "user", r.user_id);
      return json({ user_id: r.user_id, confirmed: true });
    }

    case "password_reset": {
      const profile = await profileOf(admin, r.user_id);
      const email = await emailOf(admin, r.user_id);
      const redirectTo = redirectForRole(profile.role);
      if (r.mode === "email") {
        const { error } = await anon.auth.resetPasswordForEmail(email, { redirectTo });
        if (error) throw new HttpError(error.status ?? 400, error.code ?? "reset_failed", error.message);
        await log(admin, adminId, "send_password_reset", "user", r.user_id);
        return json({ user_id: r.user_id, email_sent: true });
      }
      const { data, error } = await admin.auth.admin.generateLink({ type: "recovery", email, options: { redirectTo } });
      if (error) throw new HttpError(error.status ?? 400, error.code ?? "reset_failed", error.message);
      await log(admin, adminId, "create_password_reset_link", "user", r.user_id);
      return json({ user_id: r.user_id, link: data.properties.action_link });
    }

    case "issue_code": {
      const profile = await profileOf(admin, r.teacher_id);
      if (profile.role !== "teacher") throw new HttpError(400, "not_teacher", "Only teachers can have a teacher code");
      for (let attempt = 0; attempt < 5; attempt++) {
        const { data, error } = await admin.rpc("issue_teacher_code", {
          p_teacher_id: r.teacher_id,
          p_code: generateTeacherCode(),
        });
        if (!error) {
          await log(admin, adminId, "issue_code", "teacher_code", data.id, { code: data.code, teacher_id: r.teacher_id });
          return json({ id: data.id, code: data.code, revoked: data.revoked, created_at: data.created_at });
        }
        if (error.code !== "23505") throw error;
      }
      throw new HttpError(503, "collision", "Could not issue a unique code, try again");
    }
  }
}
