# Local API server (double-click or: powershell -File serve-local.ps1).
# Serves backend-app on http://127.0.0.1:8000 in its own window so it
# survives IDE/tool shells. Stop with Ctrl+C in that window.
$php = (Get-Command php -ErrorAction SilentlyContinue).Source
if (-not $php) {
  $php = 'C:\Users\Acer\AppData\Local\Microsoft\WinGet\Packages\PHP.PHP.8.3_Microsoft.Winget.Source_8wekyb3d8bbwe\php.exe'
}
Set-Location (Join-Path $PSScriptRoot 'backend-app')
& $php artisan serve --host=127.0.0.1 --port=8000
