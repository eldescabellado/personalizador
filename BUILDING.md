# LicenseGuard - Instrucciones de Compilación y Despliegue

## Requisitos Previos

### Software Necesario
- **Delphi**: 10.2 Tokyo o superior (10.4 Sydney o 11 Alexandria recomendados)
- **Windows**: XP o superior (para compilación y ejecución)
- **Espacio en disco**: ~100 MB para el proyecto y compilación

### Componentes VCL (Incluidos en Delphi)
- `System.SysUtils`
- `System.Classes`
- `System.Hash` (Delphi 10.2+)
- `System.JSON`
- `System.Zip`
- `Vcl.Forms`, `Vcl.Controls`, `Vcl.StdCtrls`, etc.

## Estructura del Proyecto

```
personalizador/
├── src/
│   └── LicenseGuard.dpr           # Proyecto principal
├── forms/
│   ├── MainForm.pas               # Formulario principal
│   └── MainForm.dfm
├── units/
│   ├── LG.Encryption.pas          # Encriptación
│   ├── LG.LicenseData.pas         # Datos
│   ├── LG.LicenseGenerator.pas    # Generador
│   ├── LG.LicenseValidator.pas    # Validador
│   ├── LG.HardwareInfo.pas        # Hardware
│   └── LG.DataManager.pas         # Gestión de datos
├── examples/
│   └── IntegrationExample.pas     # Ejemplo
├── docs/
│   ├── INTEGRATION_GUIDE.md
│   └── SECURITY.md
├── data/                          # Creado en runtime
├── output/                        # Licencias generadas
└── README.md
```

## Compilación Paso a Paso

### Opción 1: Compilar desde Delphi IDE

1. **Abrir el Proyecto**:
   ```
   Delphi IDE → File → Open Project
   Navegar a: personalizador/src/LicenseGuard.dpr
   ```

2. **Verificar Rutas**:
   ```
   Project → Options → Delphi Compiler → Search Path

   Agregar si es necesario:
   ..\units
   ..\forms
   ```

3. **Configurar Opciones de Compilación**:
   ```
   Project → Options → Building → Delphi Compiler

   Debug:
   - Optimization: OFF
   - Debug Information: ON
   - Range Checking: ON

   Release:
   - Optimization: ON
   - Debug Information: OFF
   - Range Checking: OFF
   ```

4. **Compilar**:
   ```
   Debug: Project → Build LicenseGuard (Shift+F9)
   Release: Project → Options → Set Release, luego Build
   ```

5. **Ubicación del Ejecutable**:
   ```
   Debug: personalizador/src/Win32/Debug/LicenseGuard.exe
   Release: personalizador/src/Win32/Release/LicenseGuard.exe
   ```

### Opción 2: Compilar desde Línea de Comandos

Usando MSBuild (incluido con Delphi):

```batch
@echo off
REM Configurar ruta de Delphi (ajustar según versión)
set DELPHI_PATH=C:\Program Files (x86)\Embarcadero\Studio\21.0
set MSBUILD=%DELPHI_PATH%\bin\msbuild.exe

REM Compilar Debug
"%MSBUILD%" LicenseGuard.dproj /t:Build /p:Config=Debug /p:Platform=Win32

REM Compilar Release
"%MSBUILD%" LicenseGuard.dproj /t:Build /p:Config=Release /p:Platform=Win32
```

Guardar como `build.bat` en la carpeta `src/` y ejecutar.

### Opción 3: Script de Compilación Automatizado

```batch
@echo off
echo ========================================
echo LicenseGuard Build Script
echo ========================================
echo.

REM Configurar variables
set PROJECT_ROOT=%~dp0
set SRC_DIR=%PROJECT_ROOT%src
set OUTPUT_DIR=%PROJECT_ROOT%build
set DELPHI_BIN=C:\Program Files (x86)\Embarcadero\Studio\21.0\bin

REM Crear directorio de salida
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

REM Compilar
echo Building Release version...
"%DELPHI_BIN%\msbuild.exe" "%SRC_DIR%\LicenseGuard.dproj" ^
    /t:Build ^
    /p:Config=Release ^
    /p:Platform=Win32

if %ERRORLEVEL% NEQ 0 (
    echo Build FAILED!
    pause
    exit /b 1
)

REM Copiar ejecutable
echo Copying executable...
copy "%SRC_DIR%\Win32\Release\LicenseGuard.exe" "%OUTPUT_DIR%\"

echo.
echo Build completed successfully!
echo Output: %OUTPUT_DIR%\LicenseGuard.exe
pause
```

## Mejoras para Producción

### 1. Reemplazar Implementación AES

**Ubicación**: `units/LG.Encryption.pas`

**Usando DCPcrypt**:

```pascal
// 1. Descargar DCPcrypt de:
// https://sourceforge.net/projects/dcpcrypt/

// 2. Agregar a Search Path:
// Project → Options → Search Path → Agregar carpeta DCPcrypt

// 3. Modificar LG.Encryption.pas:

uses
  DCPcrypt2, DCPrijndael, DCPsha256;

class function TLGEncryption.EncryptBytes(const Data: TBytes;
  const Key: TBytes): TBytes;
var
  Cipher: TDCP_rijndael;
  IV: array[0..15] of Byte;
begin
  // Generar IV aleatorio
  FillChar(IV, SizeOf(IV), 0);
  // TODO: Usar generador aleatorio fuerte

  Cipher := TDCP_rijndael.Create(nil);
  try
    Cipher.Init(Key[0], 256, @IV[0]);
    SetLength(Result, Length(Data));
    Cipher.EncryptCBC(Data[0], Result[0], Length(Data));
  finally
    Cipher.Free;
  end;
end;
```

**Usando System.Crypto (Delphi 11+)**:

```pascal
uses
  System.Crypto;

class function TLGEncryption.EncryptBytes(const Data: TBytes;
  const Key: TBytes): TBytes;
var
  Cipher: ISymmetricCipher;
begin
  Cipher := TCipherFactory.CreateCipher(
    TAlgorithm.AES,
    TMode.CBC,
    TPadding.PKCS7,
    Key
  );

  Result := Cipher.Encrypt(Data);
end;
```

### 2. Protección del Ejecutable

**Usando Enigma Protector**:

1. Descargar Enigma Protector de https://enigmaprotector.com/
2. Crear proyecto de protección:
   ```
   Input File: LicenseGuard.exe
   Output File: LicenseGuard_Protected.exe

   Options:
   - Enable Virtualization
   - Enable Anti-Debugging
   - Enable Code Obfuscation
   - Add Resources Protection
   ```

3. Automatizar con línea de comandos:
   ```batch
   enigma_protector.exe /project:protection.enigma /input:LicenseGuard.exe
   ```

### 3. Firma Digital del Ejecutable

**Usando SignTool (Windows SDK)**:

```batch
REM Obtener certificado de Code Signing
REM Firmar el ejecutable

signtool sign /f "MyCertificate.pfx" /p "password" ^
    /t http://timestamp.digicert.com ^
    /fd SHA256 ^
    LicenseGuard.exe
```

## Crear Instalador

### Usando Inno Setup

1. **Instalar Inno Setup**: https://jrsoftware.org/isinfo.php

2. **Crear Script** (`installer.iss`):

```inno
[Setup]
AppName=LicenseGuard
AppVersion=1.0
DefaultDirName={pf}\LicenseGuard
DefaultGroupName=LicenseGuard
OutputDir=installer_output
OutputBaseFilename=LicenseGuard_Setup
Compression=lzma2
SolidCompression=yes

[Files]
Source: "build\LicenseGuard.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "README.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "docs\*"; DestDir: "{app}\docs"; Flags: ignoreversion recursesubdirs

[Dirs]
Name: "{app}\data"
Name: "{app}\output"

[Icons]
Name: "{group}\LicenseGuard"; Filename: "{app}\LicenseGuard.exe"
Name: "{group}\Uninstall"; Filename: "{uninstallexe}"

[Run]
Filename: "{app}\LicenseGuard.exe"; Description: "Launch LicenseGuard"; Flags: nowait postinstall skipifsilent
```

3. **Compilar Instalador**:
   ```batch
   "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installer.iss
   ```

## Despliegue

### Distribución de LicenseGuard

**Archivos a distribuir**:
```
LicenseGuard_Setup.exe          # Instalador
o
LicenseGuard.exe                # Ejecutable standalone
README.md                       # Documentación
docs/                           # Documentación completa
```

### Distribución con Aplicaciones Cliente

**Archivos necesarios en aplicaciones cliente**:
```
YourApp.exe                     # Su aplicación
premium.sis                     # Archivo de control (generado por LicenseGuard)
license.zip                     # Licencia del cliente (distribuir al cliente)
```

**Unidades a incluir en proyecto cliente**:
```
LG.Encryption.pas
LG.LicenseData.pas
LG.LicenseValidator.pas
LG.HardwareInfo.pas
```

## Configuración Inicial

### Primera Ejecución

1. **Ejecutar LicenseGuard**:
   - La aplicación creará automáticamente la carpeta `data/` para almacenar configuración

2. **Configurar Settings**:
   ```
   Tab: Settings
   - Master Key: Ingrese clave segura (32+ caracteres)
   - Output Path: Seleccione carpeta para licencias generadas
   - Guardar configuración
   ```

3. **Generar Archivo de Control**:
   ```
   Tab: Settings
   - Click: Generate Control File
   - Se genera: premium.sis en Output Path
   ```

4. **Configurar Aplicaciones**:
   ```
   Tab: Applications
   - Add: MyApp, v1.0.0
   ```

5. **Configurar Distribuidores**:
   ```
   Tab: Distributors
   - Add: MyCompany, email@example.com
   - Serial se genera automáticamente
   ```

## Verificación de Compilación

### Checklist Pre-Release

- [ ] Compilación exitosa sin warnings
- [ ] AES-256 real implementado (DCPcrypt/System.Crypto)
- [ ] Clave maestra configurada
- [ ] Archivo de control generado
- [ ] Probado generación de licencia
- [ ] Probado validación en aplicación de ejemplo
- [ ] Ejecutable firmado digitalmente
- [ ] Protección aplicada (Enigma/Themida)
- [ ] Documentación incluida
- [ ] Instalador creado y probado

### Testing

1. **Test de Generación**:
   ```
   - Generar licencia Full
   - Generar licencia Demo
   - Verificar archivos .zip creados
   ```

2. **Test de Validación**:
   ```
   - Cargar licencia en ejemplo
   - Verificar información correcta
   - Probar vencimiento
   - Probar hardware binding
   ```

3. **Test de Seguridad**:
   ```
   - Intentar abrir .sis sin clave
   - Modificar premium.sis
   - Copiar licencia a otro equipo (con binding)
   ```

## Solución de Problemas

### Error de Compilación: "Unit not found"

**Solución**:
```
Project → Options → Delphi Compiler → Search Path
Agregar:
..\units;..\forms
```

### Error: "Access violation"

**Causa**: Posible problema con memoria

**Solución**:
- Verificar inicialización de objetos
- Usar try-finally para liberar objetos
- Revisar `TLicenseData.Initialize` y `.Free`

### Licencias no se guardan

**Causa**: Permisos de escritura

**Solución**:
- Ejecutar como Administrador (primera vez)
- Configurar Output Path en carpeta con permisos

## Recursos Adicionales

- **Delphi Documentation**: http://docwiki.embarcadero.com/
- **DCPcrypt**: https://sourceforge.net/projects/dcpcrypt/
- **Inno Setup**: https://jrsoftware.org/isinfo.php
- **Enigma Protector**: https://enigmaprotector.com/

## Contacto y Soporte

Para problemas de compilación:
1. Verificar requisitos previos
2. Revisar documentación
3. Consultar logs de compilación

---

**Versión del Documento**: 1.0
**Última Actualización**: 2025
