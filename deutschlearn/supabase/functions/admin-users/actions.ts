// Request validation for the admin-users edge function (kept pure for tests).

export type Role = "student" | "teacher" | "admin";

export type AdminRequest =
  | { action: "create_user"; email: string; role: Role; display_name: string; locale: string; password?: string }
  | { action: "set_blocked"; user_id: string; blocked: boolean }
  | { action: "delete_user"; user_id: string }
  | { action: "confirm_email"; user_id: string }
  | { action: "password_reset"; user_id: string; mode: "email" | "link" }
  | { action: "issue_code"; teacher_id: string };

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const ROLES: readonly Role[] = ["student", "teacher", "admin"];
const LOCALES = ["ar", "de", "en"];

export const ADMIN_PANEL_URL = Deno.env.get("ADMIN_PANEL_URL") ??
  "https://m7mdloverrr.github.io/project-11/deutschlearn/admin-web/";

/** Where auth e-mails for a user of [role] should land. */
export function redirectForRole(role: string): string {
  switch (role) {
    case "teacher": return "com.deutschlearn.teacher://auth-callback";
    case "admin": return ADMIN_PANEL_URL;
    default: return "com.deutschlearn.student://auth-callback";
  }
}

/** Returns the validated request, or an error message. */
export function parseAdminRequest(body: unknown): AdminRequest | string {
  if (typeof body !== "object" || body === null) return "Body must be an object";
  const b = body as Record<string, unknown>;
  const uuid = (key: string): string | null => {
    const v = b[key];
    return typeof v === "string" && UUID.test(v) ? v.toLowerCase() : null;
  };

  switch (b.action) {
    case "create_user": {
      const email = typeof b.email === "string" ? b.email.trim().toLowerCase() : "";
      if (!EMAIL.test(email)) return "Invalid e-mail";
      const role = b.role as Role;
      if (!ROLES.includes(role)) return "Invalid role";
      const displayName = typeof b.display_name === "string" ? b.display_name.trim().slice(0, 80) : "";
      const locale = typeof b.locale === "string" && LOCALES.includes(b.locale) ? b.locale : "ar";
      let password: string | undefined;
      if (b.password !== undefined && b.password !== null && b.password !== "") {
        if (typeof b.password !== "string" || b.password.length < 8) return "Password must have at least 8 characters";
        password = b.password;
      }
      return { action: "create_user", email, role, display_name: displayName, locale, password };
    }
    case "set_blocked": {
      const id = uuid("user_id");
      if (!id || typeof b.blocked !== "boolean") return "user_id and blocked are required";
      return { action: "set_blocked", user_id: id, blocked: b.blocked };
    }
    case "delete_user":
    case "confirm_email": {
      const id = uuid("user_id");
      if (!id) return "user_id is required";
      return { action: b.action, user_id: id };
    }
    case "password_reset": {
      const id = uuid("user_id");
      if (!id) return "user_id is required";
      const mode = b.mode === "email" ? "email" : "link";
      return { action: "password_reset", user_id: id, mode };
    }
    case "issue_code": {
      const id = uuid("teacher_id");
      if (!id) return "teacher_id is required";
      return { action: "issue_code", teacher_id: id };
    }
    default:
      return "Unknown action";
  }
}
