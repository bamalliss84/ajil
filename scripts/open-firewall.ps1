# يفتح منفذ Supabase المحلي (54321) لأجهزة الشبكة المحلية فقط — مرة واحدة، PowerShell كمسؤول:
#   powershell -ExecutionPolicy Bypass -File scripts\open-firewall.ps1
# بعدها run-phone.ps1 يبني التطبيق على IP الكمبيوتر بدل adb reverse، فلا تتوقف المزامنة عند انقطاع التصحيح اللاسلكي.
. "$PSScriptRoot\_common.ps1"
$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $admin) { throw 'شغّل PowerShell كمسؤول (Run as administrator) ثم أعد الأمر' }
if (Get-NetFirewallRule -DisplayName $FirewallRuleName -ErrorAction SilentlyContinue) {
  Write-Host "القاعدة موجودة مسبقاً: $FirewallRuleName" -ForegroundColor Green
} else {
  # LocalSubnet: يسمح لأجهزة نفس الشبكة فقط (الجوال)، لا للإنترنت
  New-NetFirewallRule -DisplayName $FirewallRuleName -Direction Inbound -Protocol TCP -LocalPort 54321 -RemoteAddress LocalSubnet -Action Allow -Profile Any | Out-Null
  Write-Host "أُضيفت القاعدة: $FirewallRuleName (TCP 54321 من الشبكة المحلية فقط)" -ForegroundColor Green
}
