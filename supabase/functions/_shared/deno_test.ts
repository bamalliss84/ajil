// deno test supabase/functions/_shared/deno_test.ts
import { tests } from "./shared.test.ts";
for (const t of tests) Deno.test(t.name, t.fn);
