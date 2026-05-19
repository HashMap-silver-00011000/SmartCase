# Ejecutable Windows apuntando al backend en casa (puerto 8080).
# Uso: .\scripts\build_windows_casa.ps1
# Opcional: .\scripts\build_windows_casa.ps1 -ApiBaseUrl "http://192.168.1.50:8080"

param(
    [string]$ApiBaseUrl = "http://192.168.56.1:8080"
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot\..

Write-Host "Compilando metro_gps para Windows -> $ApiBaseUrl" -ForegroundColor Cyan

flutter build windows --release --dart-define=API_BASE_URL=$ApiBaseUrl

$out = Resolve-Path "build\windows\x64\runner\Release"
Write-Host ""
Write-Host "Listo. Ejecutable:" -ForegroundColor Green
Write-Host "  $out\metro_gps.exe"
Write-Host ""
Write-Host "Copia toda la carpeta Release si la mueves a otro PC." -ForegroundColor Yellow
