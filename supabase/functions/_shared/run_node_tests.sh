#!/usr/bin/env bash
# تشغيل اختبارات المنطق المشترك بـ Node (بديل deno test)
set -euo pipefail
cd "$(dirname "$0")"
OUT="$(mktemp -d)"
TSC="$(command -v tsc || echo "npx -y -p typescript tsc")"
$TSC --target es2022 --module es2022 --moduleResolution bundler --allowImportingTsExtensions \
  --rewriteRelativeImportExtensions --strict --lib es2022,dom --outDir "$OUT" identity.ts signature.ts shared.test.ts
echo '{"type":"module"}' > "$OUT/package.json"
cat > "$OUT/run.mjs" <<'JS'
import { tests } from "./shared.test.js";
let fail = 0;
for (const t of tests) { try { await t.fn(); console.log("✓", t.name); } catch (e) { fail++; console.log("✗", t.name, e.message); } }
process.exit(fail ? 1 : 0);
JS
node "$OUT/run.mjs"
