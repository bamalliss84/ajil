# يشغّل الخادم المحلي كاملاً: Supabase (Docker) ← سر البوابة ← Edge Functions ← adb reverse
# الاستخدام: powershell -ExecutionPolicy Bypass -File scripts\dev-up.ps1  [-Phone 192.168.0.100:34279]  [-Reset]
#   -Phone  عنوان Wireless debugging من الجوال (اتركه إن كان الجوال موصولاً بـ USB)
#   -Reset  يمسح القاعدة ويعيد الـ migrations
param([switch]$Reset, [string]$Phone)
. "$PSScriptRoot\_common.ps1"
Set-Location $Root

docker info *> $null
if ($LASTEXITCODE -ne 0) { throw 'Docker متوقف — شغّل Docker Desktop ثم أعد المحاولة' }

Write-Host '== Supabase start' -ForegroundColor Cyan
npx supabase start | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'فشل supabase start' }
if ($Reset) { npx supabase db reset; if ($LASTEXITCODE -ne 0) { throw 'فشل db reset' } }

# ملف أسرار الدوال
$envFile = Join-Path $Root 'supabase\functions\.env'
if (-not (Test-Path $envFile)) {
  $bytes = New-Object byte[] 48; [Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
  $secret = [Convert]::ToBase64String($bytes) -replace '[+/=]', ''
  (Get-Content (Join-Path $Root 'supabase\functions\.env.example')) -replace '^AJIL_GATEWAY_SECRET=.*', "AJIL_GATEWAY_SECRET=$secret" |
    Set-Content -Encoding ascii $envFile
  Write-Host 'أُنشئ supabase\functions\.env' -ForegroundColor Green
}
$secret = ((Get-Content $envFile | Where-Object { $_ -match '^AJIL_GATEWAY_SECRET=' }) -split '=', 2)[1].Trim()

# بصمة السر في القاعدة (تُمسح مع كل db reset، فنعيد ضبطها دائماً)
$sql = "update app.platform_config set value = encode(sha256(convert_to('$secret','UTF8')),'hex') where key='gateway_secret_sha256';"
docker exec $DbContainer psql -U postgres -d postgres -q -c $sql | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'تعذّر ضبط بصمة سر البوابة' }
Write-Host 'بصمة سر البوابة مضبوطة في platform_config' -ForegroundColor Green

# Edge Functions في نافذة مستقلة (تبقى تعمل وتعرض السجلات)
$running = Get-CimInstance Win32_Process -Filter "Name='node.exe'" | Where-Object { $_.CommandLine -match 'functions serve' }
if ($running) {
  Write-Host 'functions serve يعمل مسبقاً' -ForegroundColor Yellow
} else {
  Start-Process powershell -ArgumentList '-NoExit', '-Command', "Set-Location '$Root'; `$host.UI.RawUI.WindowTitle='ajil functions'; npx supabase functions serve --env-file supabase\functions\.env"
  Write-Host 'functions serve بدأ في نافذة جديدة' -ForegroundColor Green
}

Connect-WirelessPhone $Phone
Set-AdbReverse | Out-Null

$st = Get-SupabaseStatus
Write-Host ''
Write-Host "API:     $($st.API_URL)"
Write-Host "Studio:  $($st.STUDIO_URL)"
Write-Host "DB:      $($st.DB_URL)"
Write-Host 'التالي: scripts\run-phone.ps1' -ForegroundColor Cyan
