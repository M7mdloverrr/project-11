// Teacher code format: "TCH-" + 6 characters from a 32-symbol alphabet that
// leaves out look-alikes (0/O, 1/I). 32^6 ≈ 1.07 billion possible codes.
export const CODE_PREFIX = "TCH-";
export const CODE_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
export const CODE_LENGTH = 6;
export const CODE_PATTERN = /^TCH-[ABCDEFGHJKLMNPQRSTUVWXYZ23456789]{6}$/;

/** Crypto-random code. 256 is a multiple of 32, so `byte % 32` is unbiased. */
export function generateTeacherCode(
  random: (bytes: Uint8Array) => Uint8Array = (b) => crypto.getRandomValues(b),
): string {
  const bytes = random(new Uint8Array(CODE_LENGTH));
  let body = "";
  for (const byte of bytes) body += CODE_ALPHABET[byte % CODE_ALPHABET.length];
  return CODE_PREFIX + body;
}

/** Accepts "tch-abc234", " TCH ABC234 ", "abc234"; returns canonical form or null. */
export function normalizeTeacherCode(input: unknown): string | null {
  if (typeof input !== "string") return null;
  let s = input.toUpperCase().replace(/[\s_]/g, "");
  if (s.startsWith("TCH-")) s = s.slice(4);
  else if (s.startsWith("TCH")) s = s.slice(3);
  s = s.replace(/-/g, "");
  const code = CODE_PREFIX + s;
  return CODE_PATTERN.test(code) ? code : null;
}
