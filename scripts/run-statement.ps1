# يشغّل صفحة كشف الحساب العام (web/statement) على Supabase المحلي
#   powershell -ExecutionPolicy Bypass -File scripts/run-statement.ps1             # http://localhost:8092/statement/#<token>
#   powershell -ExecutionPolicy Bypass -File scripts/run-statement.ps1 -Token xyz  # يطبع الرابط الكامل
# يستبدل __SUPABASE_URL__ و __SUPABASE_ANON_KEY__ و __LANDING_URL__ في نسخة داخل web/statement/build
# (نفس الاستبدال مطلوب عند النشر)، ويخدم معها صفحة التعريف ليعمل رابط «بواسطة آجِل».
# الـ token: من التطبيق (شاشة الزبون ← رابط الكشف)، أو مباشرة:
#   docker exec supabase_db_ajil psql -U postgres -Atc "select token from app.statement_links limit 1"
param([int]$Port = 8092, [string]$Token = '', [string]$LandingUrl = '/landing/')
. "$PSScriptRoot\_common.ps1"
Set-Location $Root

$st = Get-SupabaseStatus
if (-not $st.API_URL -or -not $st.ANON_KEY) { throw 'Supabase غير مكتمل التشغيل — شغّل: npx supabase start' }

$out = Join-Path $Root 'web\statement\build'
New-Item -ItemType Directory -Force (Join-Path $out 'statement') | Out-Null
New-Item -ItemType Directory -Force (Join-Path $out 'landing') | Out-Null

$html = [IO.File]::ReadAllText((Join-Path $Root 'web\statement\index.html'), [Text.Encoding]::UTF8)
$html = $html.Replace('__SUPABASE_URL__', $st.API_URL).Replace('__SUPABASE_ANON_KEY__', $st.ANON_KEY).Replace('__LANDING_URL__', $LandingUrl)
[IO.File]::WriteAllText((Join-Path $out 'statement\index.html'), $html, (New-Object Text.UTF8Encoding $false))
Copy-Item (Join-Path $Root 'web\landing\index.html') (Join-Path $out 'landing\index.html') -Force

$url = "http://localhost:$Port/statement/#$Token"
Write-Host "كشف الحساب: $url" -ForegroundColor Green
python -m http.server $Port --bind 127.0.0.1 --directory $out
