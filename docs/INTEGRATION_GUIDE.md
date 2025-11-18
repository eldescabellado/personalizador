# LicenseGuard - Guía de Integración

## Introducción

Esta guía explica cómo integrar el sistema de validación de licencias LicenseGuard en sus aplicaciones Delphi.

## Tabla de Contenidos

1. [Preparación](#preparación)
2. [Integración Básica](#integración-básica)
3. [Validación Avanzada](#validación-avanzada)
4. [Ejemplos Completos](#ejemplos-completos)
5. [Mejores Prácticas](#mejores-prácticas)
6. [Solución de Problemas](#solución-de-problemas)

## Preparación

### Paso 1: Copiar Archivos Necesarios

Copie las siguientes unidades desde `units/` a su proyecto:

```
YourProject/
├── Units/
│   ├── LG.Encryption.pas
│   ├── LG.LicenseData.pas
│   ├── LG.LicenseValidator.pas
│   └── LG.HardwareInfo.pas
```

### Paso 2: Configurar Rutas del Proyecto

En Delphi:
1. Project → Options → Delphi Compiler → Search Path
2. Agregue la ruta donde copiaron las unidades

### Paso 3: Distribuir Archivo de Control

1. Genere `premium.sis` desde LicenseGuard (Settings → Generate Control File)
2. Incluya este archivo en la instalación de su aplicación
3. Colóquelo en la misma carpeta que su ejecutable o en una ubicación conocida

### Paso 4: Definir la Clave Maestra

Debe usar la **misma clave maestra** que usó para generar las licencias.

```pascal
const
  MASTER_KEY = 'YourSecureMasterKey-ChangeThis-InProduction-32Chars';
```

**IMPORTANTE**: No hardcodee la clave directamente. Considere:
- Ofuscar la clave en el código
- Cargarla desde un recurso encriptado
- Usar técnicas anti-debugging

## Integración Básica

### Ejemplo 1: Validación Simple al Inicio

```pascal
unit MainUnit;

interface

uses
  Winapi.Windows, System.SysUtils, Vcl.Forms, Vcl.Dialogs,
  LG.LicenseValidator, LG.LicenseData;

type
  TMainForm = class(TForm)
    procedure FormCreate(Sender: TObject);
  private
    FLicenseValidator: TLicenseValidator;
    function ValidateLicense: Boolean;
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

const
  MASTER_KEY = 'YourSecureMasterKey';  // Cambie esto
  APP_NAME = 'MiAplicacion';
  APP_VERSION = '1.0.0';

function TMainForm.ValidateLicense: Boolean;
var
  LicensePath: string;
  ControlFilePath: string;
  ValidationResult: TValidationResult;
begin
  Result := False;

  // Crear validador
  FLicenseValidator := TLicenseValidator.Create(MASTER_KEY);
  FLicenseValidator.ApplicationVersion := APP_VERSION;

  // Definir rutas
  LicensePath := ExtractFilePath(Application.ExeName) + 'license.zip';
  ControlFilePath := ExtractFilePath(Application.ExeName) + 'premium.sis';

  // Validar que existen los archivos
  if not FileExists(LicensePath) then
  begin
    ShowMessage('License file not found. Please contact support.');
    Exit;
  end;

  if not FileExists(ControlFilePath) then
  begin
    ShowMessage('Control file missing. Please reinstall the application.');
    Exit;
  end;

  // Cargar y validar licencia
  ValidationResult := FLicenseValidator.LoadLicenseFromZip(
    LicensePath,
    ControlFilePath
  );

  // Verificar resultado
  if ValidationResult.IsValid then
  begin
    // Mostrar advertencia si está por vencer
    if ValidationResult.WarningMessage <> '' then
      ShowMessage(ValidationResult.WarningMessage);

    Result := True;
  end
  else
  begin
    ShowMessage('License Error: ' + ValidationResult.ErrorMessage);
    Result := False;
  end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  // Validar licencia al iniciar
  if not ValidateLicense then
  begin
    Application.MessageBox(
      'This application requires a valid license to run.',
      'License Required',
      MB_OK or MB_ICONERROR
    );
    Application.Terminate;
  end
  else
  begin
    // Mostrar información de licencia
    Caption := Format('%s - Licensed to: %s',
      [Caption, FLicenseValidator.LicenseData.ClientName]);
  end;
end;

end.
```

### Ejemplo 2: Validación con Diálogo de Selección

```pascal
procedure TMainForm.LoadLicenseClick(Sender: TObject);
var
  OpenDialog: TOpenDialog;
  Validator: TLicenseValidator;
  Result: TValidationResult;
  ControlPath: string;
begin
  OpenDialog := TOpenDialog.Create(nil);
  try
    OpenDialog.Title := 'Select License File';
    OpenDialog.Filter := 'License Files (*.zip)|*.zip';
    OpenDialog.InitialDir := ExtractFilePath(Application.ExeName);

    if OpenDialog.Execute then
    begin
      Validator := TLicenseValidator.Create(MASTER_KEY);
      try
        Validator.ApplicationVersion := APP_VERSION;
        ControlPath := ExtractFilePath(Application.ExeName) + 'premium.sis';

        Result := Validator.LoadLicenseFromZip(
          OpenDialog.FileName,
          ControlPath
        );

        if Result.IsValid then
        begin
          ShowMessage('License loaded successfully!' + #13#10 +
                      'Licensed to: ' + Validator.LicenseData.ClientCompany);

          // Guardar ruta para próxima ejecución
          SaveLicensePath(OpenDialog.FileName);

          // Habilitar aplicación
          EnableApplication;
        end
        else
        begin
          ShowMessage('Invalid license: ' + Result.ErrorMessage);
        end;
      finally
        Validator.Free;
      end;
    end;
  finally
    OpenDialog.Free;
  end;
end;
```

## Validación Avanzada

### Validación Periódica

```pascal
type
  TMainForm = class(TForm)
    TimerLicenseCheck: TTimer;
    procedure TimerLicenseCheckTimer(Sender: TObject);
  private
    FLicenseValidator: TLicenseValidator;
    procedure CheckLicenseValidity;
  end;

procedure TMainForm.CheckLicenseValidity;
var
  Result: TValidationResult;
begin
  if not Assigned(FLicenseValidator) then
    Exit;

  // Re-validar licencia
  Result := FLicenseValidator.Validate;

  if not Result.IsValid then
  begin
    ShowMessage('License is no longer valid: ' + Result.ErrorMessage);
    Application.Terminate;
  end
  else if Result.WarningMessage <> '' then
  begin
    // Mostrar advertencia solo una vez al día
    if ShouldShowWarning then
      ShowMessage(Result.WarningMessage);
  end;
end;

procedure TMainForm.TimerLicenseCheckTimer(Sender: TObject);
begin
  CheckLicenseValidity;
end;

// Configurar timer para verificar cada hora
procedure TMainForm.FormCreate(Sender: TObject);
begin
  // ... validación inicial ...

  TimerLicenseCheck.Interval := 3600000; // 1 hora
  TimerLicenseCheck.Enabled := True;
end;
```

### Obtener Información de Hardware para Activación

```pascal
uses LG.HardwareInfo;

procedure TMainForm.ShowHardwareInfoClick(Sender: TObject);
var
  HwInfo: string;
begin
  HwInfo := THardwareInfo.GetHardwareInfoString;
  ShowMessage(HwInfo);
end;

procedure TMainForm.GetHardwareIDClick(Sender: TObject);
var
  HardwareID: string;
begin
  // Obtener ID combinado (más seguro)
  HardwareID := THardwareInfo.GetCombinedHardwareID;

  // Mostrar para que el usuario lo envíe al soporte
  ShowMessage('Hardware ID:' + #13#10 + HardwareID + #13#10#13#10 +
              'Please send this ID to support to receive your license.');

  // Copiar al portapapeles
  Clipboard.AsText := HardwareID;
end;
```

### Validar Características Específicas

```pascal
function TMainForm.CheckFeatureAccess(const FeatureName: string): Boolean;
begin
  Result := False;

  if not Assigned(FLicenseValidator) then
    Exit;

  // Verificar licencia válida
  if not FLicenseValidator.ValidationResult.IsValid then
    Exit;

  // Verificar tipo de licencia
  if FLicenseValidator.LicenseData.LicenseType = ltDemo then
  begin
    ShowMessage('This feature is not available in demo version.');
    Exit;
  end;

  // Verificar campos personalizados
  if FLicenseValidator.LicenseData.CustomFields.ContainsKey(FeatureName) then
  begin
    Result := FLicenseValidator.LicenseData.CustomFields[FeatureName] = 'enabled';
  end
  else
    Result := True; // Por defecto habilitado
end;

procedure TMainForm.AdvancedFeatureClick(Sender: TObject);
begin
  if CheckFeatureAccess('AdvancedReports') then
  begin
    // Ejecutar función avanzada
    ShowAdvancedReports;
  end
  else
  begin
    ShowMessage('Your license does not include this feature.');
  end;
end;
```

## Ejemplos Completos

### Sistema Completo de Gestión de Licencias

```pascal
unit LicenseManager;

interface

uses
  System.SysUtils, System.Classes, System.IniFiles,
  LG.LicenseValidator, LG.LicenseData;

type
  TLicenseManager = class
  private
    FValidator: TLicenseValidator;
    FLicensePath: string;
    FControlPath: string;
    FIsValid: Boolean;
    FLastCheckTime: TDateTime;

    procedure LoadPaths;
    procedure SavePaths;
    function GetLicenseInfo: string;
  public
    constructor Create(const AMasterKey: string);
    destructor Destroy; override;

    function LoadLicense(const ALicensePath: string = ''): Boolean;
    function IsValid: Boolean;
    function GetClientName: string;
    function GetExpirationDate: TDateTime;
    function IsFeatureEnabled(const AFeatureName: string): Boolean;

    property LicenseInfo: string read GetLicenseInfo;
  end;

implementation

uses
  System.IOUtils;

{ TLicenseManager }

constructor TLicenseManager.Create(const AMasterKey: string);
begin
  inherited Create;
  FValidator := TLicenseValidator.Create(AMasterKey);
  FIsValid := False;
  FLastCheckTime := 0;

  LoadPaths;

  // Intentar cargar licencia automáticamente
  if FLicensePath <> '' then
    LoadLicense(FLicensePath);
end;

destructor TLicenseManager.Destroy;
begin
  FValidator.Free;
  inherited;
end;

procedure TLicenseManager.LoadPaths;
var
  IniFile: TIniFile;
  IniPath: string;
begin
  IniPath := TPath.Combine(
    ExtractFilePath(ParamStr(0)),
    'license.ini'
  );

  if not TFile.Exists(IniPath) then
  begin
    FControlPath := TPath.Combine(
      ExtractFilePath(ParamStr(0)),
      'premium.sis'
    );
    Exit;
  end;

  IniFile := TIniFile.Create(IniPath);
  try
    FLicensePath := IniFile.ReadString('License', 'Path', '');
    FControlPath := IniFile.ReadString('License', 'ControlPath',
      TPath.Combine(ExtractFilePath(ParamStr(0)), 'premium.sis'));
  finally
    IniFile.Free;
  end;
end;

procedure TLicenseManager.SavePaths;
var
  IniFile: TIniFile;
  IniPath: string;
begin
  IniPath := TPath.Combine(
    ExtractFilePath(ParamStr(0)),
    'license.ini'
  );

  IniFile := TIniFile.Create(IniPath);
  try
    IniFile.WriteString('License', 'Path', FLicensePath);
    IniFile.WriteString('License', 'ControlPath', FControlPath);
  finally
    IniFile.Free;
  end;
end;

function TLicenseManager.LoadLicense(const ALicensePath: string): Boolean;
var
  Result: TValidationResult;
  LicPath: string;
begin
  LicPath := ALicensePath;
  if LicPath = '' then
    LicPath := FLicensePath;

  if not TFile.Exists(LicPath) then
    Exit(False);

  if not TFile.Exists(FControlPath) then
    Exit(False);

  Result := FValidator.LoadLicenseFromZip(LicPath, FControlPath);

  FIsValid := Result.IsValid;
  FLastCheckTime := Now;

  if FIsValid then
  begin
    FLicensePath := LicPath;
    SavePaths;
  end;

  Result := FIsValid;
end;

function TLicenseManager.IsValid: Boolean;
begin
  // Re-validar si ha pasado más de 1 hora
  if (Now - FLastCheckTime) > (1/24) then
  begin
    if Assigned(FValidator) then
    begin
      FIsValid := FValidator.Validate.IsValid;
      FLastCheckTime := Now;
    end;
  end;

  Result := FIsValid;
end;

function TLicenseManager.GetClientName: string;
begin
  if FIsValid and Assigned(FValidator) then
    Result := FValidator.LicenseData.ClientName
  else
    Result := 'Unlicensed';
end;

function TLicenseManager.GetExpirationDate: TDateTime;
begin
  if FIsValid and Assigned(FValidator) then
  begin
    if FValidator.LicenseData.Expiration.HasExpiration then
      Result := FValidator.LicenseData.Expiration.ExpirationDate
    else
      Result := 0;
  end
  else
    Result := 0;
end;

function TLicenseManager.IsFeatureEnabled(const AFeatureName: string): Boolean;
begin
  Result := False;

  if not FIsValid then
    Exit;

  // Demo licenses have limited features
  if FValidator.LicenseData.LicenseType = ltDemo then
  begin
    // Only basic features in demo
    Result := (AFeatureName = 'Basic') or (AFeatureName = 'View');
    Exit;
  end;

  // Full license - check custom fields
  if FValidator.LicenseData.CustomFields.ContainsKey(AFeatureName) then
    Result := FValidator.LicenseData.CustomFields[AFeatureName] = 'true'
  else
    Result := True; // Default: enabled
end;

function TLicenseManager.GetLicenseInfo: string;
begin
  if FIsValid and Assigned(FValidator) then
    Result := FValidator.GetLicenseInfo
  else
    Result := 'No valid license loaded';
end;

end.
```

### Uso del LicenseManager

```pascal
unit MainUnit;

interface

uses
  Winapi.Windows, System.SysUtils, Vcl.Forms,
  LicenseManager;

type
  TMainForm = class(TForm)
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FLicenseManager: TLicenseManager;
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

const
  MASTER_KEY = 'YourMasterKeyHere';

procedure TMainForm.FormCreate(Sender: TObject);
begin
  // Crear gestor de licencias
  FLicenseManager := TLicenseManager.Create(MASTER_KEY);

  // Verificar validez
  if not FLicenseManager.IsValid then
  begin
    // Mostrar diálogo para cargar licencia
    if not ShowLicenseDialog(FLicenseManager) then
    begin
      Application.Terminate;
      Exit;
    end;
  end;

  // Actualizar UI con información de licencia
  Caption := Format('%s - %s',
    [Caption, FLicenseManager.GetClientName]);

  // Habilitar/deshabilitar funciones según licencia
  UpdateFeatureAccess;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  FLicenseManager.Free;
end;

end.
```

## Mejores Prácticas

### 1. Seguridad de la Clave Maestra

```pascal
// MAL - Hardcoded visible
const
  MASTER_KEY = 'MySecretKey123';

// MEJOR - Ofuscado
function GetMasterKey: string;
var
  Bytes: TBytes;
begin
  // Key encoded in bytes (basic obfuscation)
  Bytes := TBytes.Create($4D, $79, $53, $65, $63, $72, $65, $74, $4B, $65, $79);
  Result := TEncoding.ASCII.GetString(Bytes);
end;

// AÚN MEJOR - Usar recursos o DLL externa
```

### 2. Manejo de Errores

```pascal
function LoadAndValidateLicense: Boolean;
begin
  Result := False;
  try
    // ... código de validación ...
  except
    on E: ELicenseValidationError do
    begin
      LogError('License validation error: ' + E.Message);
      ShowMessage('License error. Please contact support.');
    end;
    on E: Exception do
    begin
      LogError('Unexpected error: ' + E.Message);
      ShowMessage('An error occurred. Please contact support.');
    end;
  end;
end;
```

### 3. Registro de Eventos

```pascal
procedure LogLicenseEvent(const AEvent: string);
var
  LogFile: TextFile;
  LogPath: string;
begin
  LogPath := TPath.Combine(
    ExtractFilePath(Application.ExeName),
    'license.log'
  );

  AssignFile(LogFile, LogPath);
  try
    if FileExists(LogPath) then
      Append(LogFile)
    else
      Rewrite(LogFile);

    WriteLn(LogFile, Format('[%s] %s',
      [FormatDateTime('yyyy-mm-dd hh:nn:ss', Now), AEvent]));
  finally
    CloseFile(LogFile);
  end;
end;
```

### 4. Validación al Guardar/Exportar

```pascal
procedure TMainForm.SaveDocumentClick(Sender: TObject);
begin
  // Verificar licencia antes de operaciones importantes
  if not FLicenseManager.IsValid then
  begin
    ShowMessage('Your license has expired. Please renew to continue using this feature.');
    Exit;
  end;

  // Continuar con la operación
  DoSaveDocument;
end;
```

## Solución de Problemas

### Problema: "Invalid encrypted data format"

**Causa**: Clave maestra incorrecta o archivo corrupto

**Solución**:
```pascal
try
  Result := Validator.LoadLicenseFromZip(LicPath, CtrlPath);
except
  on E: EEncryptionError do
  begin
    ShowMessage('Invalid license file or wrong decryption key.');
    // Log error
  end;
end;
```

### Problema: "Control file mismatch"

**Causa**: El archivo premium.sis no coincide

**Solución**:
1. Verifique que distribuyó el premium.sis correcto
2. Regenere la licencia si es necesario
3. Verifique que el archivo no se ha modificado

### Problema: Falsa detección de expiración

**Causa**: Reloj del sistema alterado

**Solución**:
```pascal
// Verificar sincronización con servidor NTP
function IsSystemTimeValid: Boolean;
var
  ServerTime: TDateTime;
begin
  ServerTime := GetNTPTime('pool.ntp.org');
  Result := Abs(Now - ServerTime) < (1/24/60); // < 1 minuto diferencia
end;
```

## Recursos Adicionales

- Ver `examples/IntegrationExample.pas` para código completo
- Ver `docs/SECURITY.md` para información de seguridad
- Ver README.md para información general

---

**Versión de Documento**: 1.0
**Última Actualización**: 2025
