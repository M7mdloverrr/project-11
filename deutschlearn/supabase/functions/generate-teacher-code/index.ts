// POST /functions/v1/generate-teacher-code
// Caller: a signed-in teacher (JWT in Authorization header).
// Revokes the teacher's current code and issues a new crypto-random one.
// The service-role key is only available here on the server, never in the apps.
import { createClient } from "jsr:@supabase/supabase-js@2";
import { generateTeacherCode } from "../_shared/teacher_code.ts";
import { corsHeaders, errorResponse, json, requireEnv, statusForPgCode } from "../_shared/http.ts";

const MAX_ATTEMPTS = 5;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return errorResponse(405, "method_not_allowed", "Use POST");

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return errorResponse(401, "unauthorized", "Missing Authorization header");

  const url = requireEnv("SUPABASE_URL");
  const userClient = createClient(url, requireEnv("SUPABASE_ANON_KEY"), {
    global: { headers: { Authorization: authHeader } },
    auth: { persistSession: false },
  });

  const { data: userData, error: userError } = await userClient.auth.getUser();
  if (userError || !userData.user) return errorResponse(401, "unauthorized", "Invalid session");

  const { data: profile, error: profileError } = await userClient
    .from("profiles").select("role").eq("id", userData.user.id).single();
  if (profileError || profile?.role !== "teacher") {
    return errorResponse(403, "forbidden", "Only teachers can generate a teacher code");
  }

  const admin = createClient(url, requireEnv("SUPABASE_SERVICE_ROLE_KEY"), {
    auth: { persistSession: false },
  });

  for (let attempt = 0; attempt < MAX_ATTEMPTS; attempt++) {
    const { data, error } = await admin.rpc("issue_teacher_code", {
      p_teacher_id: userData.user.id,
      p_code: generateTeacherCode(),
    });
    if (!error) {
      return json({ id: data.id, code: data.code, revoked: data.revoked, created_at: data.created_at });
    }
    if (error.code !== "23505") {
      return errorResponse(statusForPgCode(error.code), "issue_failed", error.message);
    }
    // 23505 = unique collision with an existing code; draw again.
  }
  return errorResponse(503, "collision", "Could not issue a unique code, try again");
});
