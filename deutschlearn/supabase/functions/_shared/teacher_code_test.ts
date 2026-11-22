import { assert, assertEquals } from "jsr:@std/assert@1";
import {
  CODE_ALPHABET,
  CODE_PATTERN,
  generateTeacherCode,
  normalizeTeacherCode,
} from "./teacher_code.ts";

Deno.test("generated codes match the format", () => {
  for (let i = 0; i < 2000; i++) assert(CODE_PATTERN.test(generateTeacherCode()));
});

Deno.test("generated codes are not repeated in a large sample", () => {
  const seen = new Set<string>();
  for (let i = 0; i < 20000; i++) seen.add(generateTeacherCode());
  assert(seen.size > 19990);
});

Deno.test("every alphabet symbol is reachable", () => {
  let n = 0;
  const code = generateTeacherCode((b) => b.map(() => n++));
  assertEquals(code, "TCH-ABCDEF");
  assertEquals(CODE_ALPHABET.length, 32);
});

Deno.test("normalization", () => {
  assertEquals(normalizeTeacherCode("tch-abc234"), "TCH-ABC234");
  assertEquals(normalizeTeacherCode(" TCH ABC 234 "), "TCH-ABC234");
  assertEquals(normalizeTeacherCode("abc234"), "TCH-ABC234");
  assertEquals(normalizeTeacherCode("TCH-ABC23"), null);
  assertEquals(normalizeTeacherCode("TCH-ABC0O1"), null);
  assertEquals(normalizeTeacherCode(42), null);
});
