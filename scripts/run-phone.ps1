# يبني التطبيق ويثبّته على الجوال الموصول (debug) ويتصل بالخادم المحلي
# الاستخدام:
#   powershell -ExecutionPolicy Bypass -File scripts\run-phone.ps1          # flutter run (سجلات + hot reload)
#   ... run-phone.ps1 -Apk                                                   # يبني apk debug ويثبّته فقط
#   ... run-phone.ps1 -Phone 192.168.0.100:34279                            # جوال لاسلكي (Wireless debugging)
#   ... run-phone.ps1 -Lan                                                   # بدل adb reverse: IP الكمبيوتر على الشبكة
param([switch]$Apk, [switch]$Lan, [string]$Device, [string]$Phone)
. "$PSScriptRoot\_common.ps1"
Connect-WirelessPhone $Phone
if ($Phone -and -not $Device) { $Device = $Phone }

$st = Get-SupabaseStatus
$anon = $st.ANON_KEY
$devs = @(Get-AndroidDevices)
if ($devs.Count -eq 0) { throw 'لا يوجد جوال موصول — وصّل الجوال بـ USB وفعّل USB debugging ووافق على نافذة السماح' }
if (-not $Device) { $Device = $devs[0] }

if ($Lan) {
  $ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.PrefixOrigin -eq 'Dhcp' -and $_.IPAddress -notlike '169.*' } | Select-Object -First 1).IPAddress
  if (-not $ip) { throw 'تعذّر معرفة IP الكمبيوتر' }
  $url = "http://${ip}:54321"
  Write-Host "يستخدم $url — إن لم يتصل افتح المنفذ (مرة واحدة، PowerShell كمسؤول):" -ForegroundColor Yellow
  Write-Host "  New-NetFirewallRule -DisplayName 'Ajil Supabase 54321' -Direction Inbound -Protocol TCP -LocalPort 54321 -Action Allow -Profile Private"
} else {
  & (Get-Adb) -s $Device reverse tcp:54321 tcp:54321 | Out-Null
  $url = 'http://127.0.0.1:54321'
}

$defines = @("--dart-define=SUPABASE_URL=$url", "--dart-define=SUPABASE_ANON_KEY=$anon")
Set-Location (Join-Path $Root 'app')
Write-Host "الجهاز: $Device   الخادم: $url" -ForegroundColor Cyan

if ($Apk) {
  flutter build apk --debug --target-platform android-arm64 @defines
  if ($LASTEXITCODE -ne 0) { throw 'فشل البناء' }
  & (Get-Adb) -s $Device install -r build\app\outputs\flutter-apk\app-debug.apk
  & (Get-Adb) -s $Device shell am start -n app.ajil.ajil/.MainActivity | Out-Null
  Write-Host 'تم التثبيت والتشغيل. السجلات: flutter logs' -ForegroundColor Green
} else {
  flutter run -d $Device --debug @defines
}
