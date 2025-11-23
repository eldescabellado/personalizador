# Script de Compilación para LicenseTester
# Este script ayuda a compilar el proyecto desde la línea de comandos

param(
    [string]$DelphiPath = "C:\Program Files (x86)\Embarcadero\Studio\20.0\bin",
    [string]$Configuration = "Debug",
    [string]$Platform = "Win32"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "LicenseGuard - License Tester Builder" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Verificar que existe el compilador de Delphi
$MSBuildPath = Join-Path $DelphiPath "rsvars.bat"
if (-not (Test-Path $MSBuildPath)) {
    Write-Host "ERROR: No se encontró rsvars.bat en: $DelphiPath" -ForegroundColor Red
    Write-Host "Por favor, especifique la ruta correcta de Delphi usando el parámetro -DelphiPath" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Ejemplo:" -ForegroundColor Yellow
    Write-Host '  .\Build.ps1 -DelphiPath "C:\Program Files (x86)\Embarcadero\Studio\20.0\bin"' -ForegroundColor Gray
    exit 1
}

# Verificar que existe el archivo de proyecto
$ProjectFile = "LicenseTester.dproj"
if (-not (Test-Path $ProjectFile)) {
    Write-Host "ERROR: No se encontró el archivo de proyecto: $ProjectFile" -ForegroundColor Red
    Write-Host "Asegúrese de ejecutar este script desde el directorio TestApp" -ForegroundColor Yellow
    exit 1
}

Write-Host "Configuración:" -ForegroundColor Green
Write-Host "  Delphi Path: $DelphiPath" -ForegroundColor Gray
Write-Host "  Configuration: $Configuration" -ForegroundColor Gray
Write-Host "  Platform: $Platform" -ForegroundColor Gray
Write-Host "  Project: $ProjectFile" -ForegroundColor Gray
Write-Host ""

# Limpiar archivos anteriores
Write-Host "Limpiando archivos de compilación anteriores..." -ForegroundColor Yellow
$filesToClean = @("*.dcu", "*.exe", "*.map", "*.drc")
foreach ($pattern in $filesToClean) {
    Get-ChildItem -Filter $pattern -ErrorAction SilentlyContinue | Remove-Item -Force
}
Write-Host "Limpieza completada." -ForegroundColor Green
Write-Host ""

# Compilar el proyecto
Write-Host "Compilando proyecto..." -ForegroundColor Yellow
Write-Host ""

try {
    # Configurar variables de entorno de Delphi
    cmd /c "`"$MSBuildPath`" && msbuild `"$ProjectFile`" /t:Build /p:Config=$Configuration /p:Platform=$Platform"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "Compilación exitosa!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        
        $exePath = "LicenseTester.exe"
        if (Test-Path $exePath) {
            $exeInfo = Get-Item $exePath
            Write-Host "Ejecutable generado:" -ForegroundColor Cyan
            Write-Host "  Ubicación: $($exeInfo.FullName)" -ForegroundColor Gray
            Write-Host "  Tamaño: $([math]::Round($exeInfo.Length / 1KB, 2)) KB" -ForegroundColor Gray
            Write-Host "  Fecha: $($exeInfo.LastWriteTime)" -ForegroundColor Gray
        }
        
        Write-Host ""
        Write-Host "Para ejecutar la aplicación:" -ForegroundColor Yellow
        Write-Host "  .\LicenseTester.exe" -ForegroundColor Gray
    }
    else {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Red
        Write-Host "Error en la compilación" -ForegroundColor Red
        Write-Host "========================================" -ForegroundColor Red
        Write-Host ""
        Write-Host "Revise los mensajes de error anteriores." -ForegroundColor Yellow
        exit 1
    }
}
catch {
    Write-Host ""
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
