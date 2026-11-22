// POST /functions/v1/resolve-teacher-code  { "code": "TCH-XXXXXX" }
// Caller: a signed-in student. Validates the code and creates (or returns)
// a pending link request. Runs with the caller's JWT, so RLS and the
// request_teacher_link() checks apply; no service-role key is used.
import { createClient } from "jsr:@supabase/supabase-js@2";
import { normalizeTeacherCode } from "../_shared/teacher_code.ts";
import { corsHeaders, errorResponse, json, requireEnv, statusForPgCode } from "../_shared/http.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return errorResponse(405, "method_not_allowed", "Use POST");

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return errorResponse(401, "unauthorized", "Missing Authorization header");

  let body: { code?: unknown };
  try {
    body = await req.json();
  } catch {
    return errorResponse(400, "bad_request", "Body must be JSON");
  }

  const code = normalizeTeacherCode(body.code);
  if (!code) return errorResponse(400, "invalid_format", "Code must look like TCH-XXXXXX");

  const client = createClient(requireEnv("SUPABASE_URL"), requireEnv("SUPABASE_ANON_KEY"), {
    global: { headers: { Authorization: authHeader } },
    auth: { persistSession: false },
  });

  const { data, error } = await client.rpc("request_teacher_link", { p_code: code });
  if (error) {
    const status = statusForPgCode(error.code);
    const kind = {
      403: "forbidden",
      404: "code_not_found",
      409: "already_linked",
      429: "rate_limited",
      400: "invalid_request",
    }[status] ?? "server_error";
    return errorResponse(status, kind, error.message);
  }
  return json(data);
});
