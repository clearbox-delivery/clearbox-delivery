import { assertEquals } from "jsr:@std/assert@1";

Deno.test("[unit] sanity", () => {
  assertEquals(1 + 1, 2);
});
