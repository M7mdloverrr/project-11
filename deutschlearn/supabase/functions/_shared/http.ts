export const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

export function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

export function errorResponse(status: number, error: string, message: string): Response {
  return json({ error, message }, status);
}

/** Maps the SQLSTATE codes raised by our RPCs to HTTP statuses. */
export function statusForPgCode(code: string | undefined): number {
  switch (code) {
    case "42501": return 403;
    case "P0404": return 404;
    case "P0409": return 409;
    case "P0429": return 429;
    case "22023": return 400;
    default: return 500;
  }
}

export function requireEnv(name: string): string {
  const value = Deno.env.get(name);
  if (!value) throw new Error(`missing env ${name}`);
  return value;
}
