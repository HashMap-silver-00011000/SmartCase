# APK Android apuntando al backend en red local.
# Uso: .\scripts\build_apk_casa.ps1
#      .\scripts\build_apk_casa.ps1 -ApiBaseUrl "http://192.168.1.50:8080"

param(
    [string]$ApiBaseUrl = "http://192.168.56.1:8080"
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..

Write-Host "Compilando APK -> $ApiBaseUrl" -ForegroundColor Cyan
flutter build apk --release --dart-define=API_BASE_URL=$ApiBaseUrl

$apk = Resolve-Path "build\app\outputs\flutter-apk\app-release.apk"
Write-Host ""
Write-Host "APK:" -ForegroundColor Green
Write-Host "  $apk"
