import { assertEquals } from "jsr:@std/assert@1";
import { parseAdminRequest, redirectForRole } from "./actions.ts";

const id = "1be43774-8152-4c54-ac66-d8ee7991736e";

Deno.test("create_user normalizes e-mail and defaults locale", () => {
  assertEquals(parseAdminRequest({ action: "create_user", email: " A@B.de ", role: "teacher", display_name: " Frau W " }), {
    action: "create_user", email: "a@b.de", role: "teacher", display_name: "Frau W", locale: "ar", password: undefined,
  });
});

Deno.test("create_user rejects bad input", () => {
  assertEquals(parseAdminRequest({ action: "create_user", email: "nope", role: "teacher" }), "Invalid e-mail");
  assertEquals(parseAdminRequest({ action: "create_user", email: "a@b.de", role: "root" }), "Invalid role");
  assertEquals(parseAdminRequest({ action: "create_user", email: "a@b.de", role: "student", password: "short" }),
    "Password must have at least 8 characters");
});

Deno.test("user actions require a UUID", () => {
  assertEquals(parseAdminRequest({ action: "delete_user", user_id: "x" }), "user_id is required");
  assertEquals(parseAdminRequest({ action: "delete_user", user_id: id }), { action: "delete_user", user_id: id });
  assertEquals(parseAdminRequest({ action: "set_blocked", user_id: id }), "user_id and blocked are required");
  assertEquals(parseAdminRequest({ action: "set_blocked", user_id: id, blocked: true }), { action: "set_blocked", user_id: id, blocked: true });
  assertEquals(parseAdminRequest({ action: "password_reset", user_id: id }), { action: "password_reset", user_id: id, mode: "link" });
  assertEquals(parseAdminRequest({ action: "issue_code", teacher_id: id }), { action: "issue_code", teacher_id: id });
  assertEquals(parseAdminRequest({ action: "drop_tables" }), "Unknown action");
  assertEquals(parseAdminRequest(null), "Body must be an object");
});

Deno.test("auth e-mails land in the right app", () => {
  assertEquals(redirectForRole("student"), "com.deutschlearn.student://auth-callback");
  assertEquals(redirectForRole("teacher"), "com.deutschlearn.teacher://auth-callback");
  assertEquals(redirectForRole("admin").startsWith("https://"), true);
});
