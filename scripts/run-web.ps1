# يشغّل صفحة المشترك (تطبيق app/ مبنياً للويب) على Supabase المحلي
#   powershell -ExecutionPolicy Bypass -File scripts/run-web.ps1           # يبني release ويخدمه على http://localhost:8091
#   powershell -ExecutionPolicy Bypass -File scripts/run-web.ps1 -Chrome   # تطوير: flutter run في Chrome
# يحتاج: supabase start + functions serve (scripts/dev-up.ps1)، و app/web/sqlite3.wasm و drift_worker.js
param([int]$Port = 8091, [switch]$Chrome)
Set-Location (Split-Path $PSScriptRoot -Parent)

$raw = (cmd /c "npx supabase status -o json 2>nul") -join "`n"
$st = $raw.Substring($raw.IndexOf('{')) | ConvertFrom-Json
$defines = @("--dart-define=SUPABASE_URL=$($st.API_URL)", "--dart-define=SUPABASE_ANON_KEY=$($st.ANON_KEY)")

Set-Location app
if ($Chrome) {
  flutter run -d chrome --web-port $Port @defines
} else {
  flutter build web --release @defines
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  python -m http.server $Port --bind 127.0.0.1 --directory build/web
}
