# يشغّل لوحة إدارة المنصة (web/admin) على Supabase المحلي
#   powershell -ExecutionPolicy Bypass -File scripts/run-admin.ps1           # يبني release ويخدمه على http://localhost:8090
#   powershell -ExecutionPolicy Bypass -File scripts/run-admin.ps1 -Chrome   # تطوير: flutter run في Chrome (hot reload)
param([int]$Port = 8090, [switch]$Chrome)
Set-Location (Split-Path $PSScriptRoot -Parent)

$raw = (cmd /c "npx supabase status -o json 2>nul") -join "`n"
$st = $raw.Substring($raw.IndexOf('{')) | ConvertFrom-Json
if (-not $st.API_URL -or -not $st.ANON_KEY) { Write-Error 'Supabase غير مكتمل التشغيل (API_URL فارغ) — شغّل: npx supabase start'; exit 1 }
$defines = @("--dart-define=SUPABASE_URL=$($st.API_URL)", "--dart-define=SUPABASE_ANON_KEY=$($st.ANON_KEY)")

Set-Location web/admin
if ($Chrome) {
  flutter run -d chrome --web-port $Port @defines
} else {
  flutter build web --release @defines
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
  python -m http.server $Port --bind 127.0.0.1 --directory build/web
}
