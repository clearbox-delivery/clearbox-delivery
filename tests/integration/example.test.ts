import { assert } from "jsr:@std/assert@1";

Deno.test("[integration] supabase env binding", () => {
  // Ensures CI/local integration tests load .env.test correctly
  const url = Deno.env.get("SUPABASE_URL");
  assert(url && url.startsWith("http://127.0.0.1:"));
});
