unit ClientIntegration;

{
  EJEMPLO DE INTEGRACIÓN DE LICENSEGUARD EN APLICACIÓN CLIENTE
  =============================================================

  Este archivo muestra cómo integrar el validador de licencias
  en tu aplicación Delphi de forma simple y directa.

  ARCHIVOS NECESARIOS EN TU PROYECTO:
  -----------------------------------
  1. LG.LicenseValidator.pas  - Validador principal
  2. LG.LicenseData.pas       - Estructuras de datos
  3. LG.Encryption.pas        - Funciones de encriptación
  4. LG.HardwareInfo.pas      - Info de hardware (opcional)

  CONFIGURACIÓN:
  --------------
  - Usa la misma MasterKey que usaste para generar las licencias
  - El archivo de licencia debe tener extensión .lic
}

interface

uses
  System.SysUtils, Vcl.Forms, Vcl.Dialogs,
  LG.LicenseValidator;

type
  TLicenseManager = class
  private
    FValidator: TLicenseValidator;
    FAppName: string;
    FAppVersion: string;
    FLicensePath: string;
  public
    constructor Create(const AMasterKey, AAppName, AAppVersion: string);
    destructor Destroy; override;

    // Verificar licencia al iniciar la aplicación
    function CheckLicense: Boolean;

    // Mostrar información de licencia
    procedure ShowLicenseInfo;

    // Propiedades
    property LicensePath: string read FLicensePath write FLicensePath;
    property Validator: TLicenseValidator read FValidator;
  end;

// Función global simple para verificar licencia
function VerifyLicense(const ALicensePath, AMasterKey, AAppName: string): Boolean;

implementation

uses
  System.IOUtils;

{ Función global simple }

function VerifyLicense(const ALicensePath, AMasterKey, AAppName: string): Boolean;
var
  Validator: TLicenseValidator;
begin
  Validator := TLicenseValidator.Create(AMasterKey);
  try
    if Validator.LoadLicense(ALicensePath) then
      Result := Validator.IsValidFor(AAppName)
    else
      Result := False;

    if not Result then
      ShowMessage('Licencia inválida: ' + Validator.ErrorMessage);
  finally
    Validator.Free;
  end;
end;

{ TLicenseManager }

constructor TLicenseManager.Create(const AMasterKey, AAppName, AAppVersion: string);
begin
  inherited Create;
  FValidator := TLicenseValidator.Create(AMasterKey);
  FAppName := AAppName;
  FAppVersion := AAppVersion;

  // Buscar licencia en ubicación por defecto
  FLicensePath := TPath.Combine(ExtractFilePath(Application.ExeName), 'license.lic');
end;

destructor TLicenseManager.Destroy;
begin
  FValidator.Free;
  inherited;
end;

function TLicenseManager.CheckLicense: Boolean;
begin
  // Verificar que existe el archivo
  if not TFile.Exists(FLicensePath) then
  begin
    ShowMessage('No se encontró archivo de licencia.' + sLineBreak +
                'Por favor coloque el archivo license.lic en la carpeta de la aplicación.');
    Result := False;
    Exit;
  end;

  // Cargar y validar licencia
  if not FValidator.LoadLicense(FLicensePath) then
  begin
    ShowMessage('Error al cargar licencia: ' + FValidator.ErrorMessage);
    Result := False;
    Exit;
  end;

  // Verificar para esta aplicación
  if not FValidator.IsValidFor(FAppName, FAppVersion) then
  begin
    ShowMessage('Licencia inválida: ' + FValidator.ErrorMessage);
    Result := False;
    Exit;
  end;

  // Mostrar advertencia si expira pronto
  if FValidator.WarningMessage <> '' then
    ShowMessage('Advertencia: ' + FValidator.WarningMessage);

  Result := True;
end;

procedure TLicenseManager.ShowLicenseInfo;
begin
  ShowMessage(FValidator.GetLicenseInfo);
end;

end.

{
================================================================================
EJEMPLOS DE USO
================================================================================

--------------------------------------------------------------------------------
EJEMPLO 1: Verificación Simple (mínimo código)
--------------------------------------------------------------------------------

procedure TFormMain.FormCreate(Sender: TObject);
const
  MASTER_KEY = 'TU-MASTER-KEY-AQUI';  // Misma key usada para generar
  APP_NAME = 'MiAplicacion';
var
  LicensePath: string;
begin
  LicensePath := ExtractFilePath(Application.ExeName) + 'license.lic';

  if not VerifyLicense(LicensePath, MASTER_KEY, APP_NAME) then
  begin
    Application.Terminate;
    Exit;
  end;

  // Continuar con la aplicación...
end;

--------------------------------------------------------------------------------
EJEMPLO 2: Usando TLicenseManager (más control)
--------------------------------------------------------------------------------

var
  LicenseManager: TLicenseManager;

procedure TFormMain.FormCreate(Sender: TObject);
const
  MASTER_KEY = 'TU-MASTER-KEY-AQUI';
  APP_NAME = 'MiAplicacion';
  APP_VERSION = '1.0.0';
begin
  LicenseManager := TLicenseManager.Create(MASTER_KEY, APP_NAME, APP_VERSION);

  // Opcionalmente especificar otra ubicación
  // LicenseManager.LicensePath := 'C:\Licencias\mi_licencia.lic';

  if not LicenseManager.CheckLicense then
  begin
    Application.Terminate;
    Exit;
  end;

  // Mostrar días restantes en StatusBar
  StatusBar1.SimpleText := Format('Licencia: %s - %d días restantes',
    [LicenseManager.Validator.ClientCompany,
     LicenseManager.Validator.GetDaysRemaining]);
end;

procedure TFormMain.FormDestroy(Sender: TObject);
begin
  LicenseManager.Free;
end;

procedure TFormMain.mnuLicenseInfoClick(Sender: TObject);
begin
  LicenseManager.ShowLicenseInfo;
end;

--------------------------------------------------------------------------------
EJEMPLO 3: Control Total con TLicenseValidator
--------------------------------------------------------------------------------

procedure TFormMain.FormCreate(Sender: TObject);
const
  MASTER_KEY = 'TU-MASTER-KEY-AQUI';
var
  Validator: TLicenseValidator;
  LicensePath: string;
begin
  LicensePath := ExtractFilePath(Application.ExeName) + 'license.lic';

  Validator := TLicenseValidator.Create(MASTER_KEY);
  try
    // Configurar validador
    Validator.ApplicationName := 'MiAplicacion';
    Validator.ApplicationVersion := '2.0.0';

    // Cargar licencia
    if not Validator.LoadLicense(LicensePath) then
    begin
      ShowMessage('Error: ' + Validator.ErrorMessage);
      Application.Terminate;
      Exit;
    end;

    // Verificar validez
    if not Validator.IsValid then
    begin
      ShowMessage('Licencia inválida: ' + Validator.ErrorMessage);
      Application.Terminate;
      Exit;
    end;

    // Acceder a datos de la licencia
    Caption := 'Mi App - Registrado a: ' + Validator.ClientCompany;

    // Verificar tipo de licencia
    case Validator.LicenseType of
      ltDemo:
        begin
          // Limitar funcionalidad para demo
          mnuAdvancedFeatures.Enabled := False;
          ShowMessage('Modo Demo - Funcionalidad limitada');
        end;
      ltTrial:
        begin
          // Mostrar días restantes de prueba
          ShowMessage(Format('Periodo de prueba: %d días restantes',
            [Validator.GetDaysRemaining]));
        end;
      ltFull:
        begin
          // Acceso completo
        end;
    end;

    // Guardar referencia si necesitas acceder después
    FValidator := Validator;
    Validator := nil; // Evitar Free en finally

  finally
    Validator.Free;
  end;
end;

--------------------------------------------------------------------------------
EJEMPLO 4: Verificación Periódica
--------------------------------------------------------------------------------

procedure TFormMain.Timer1Timer(Sender: TObject);
begin
  // Verificar cada hora si la licencia sigue válida
  if Assigned(FValidator) then
  begin
    if not FValidator.Validate then
    begin
      ShowMessage('La licencia ha expirado: ' + FValidator.ErrorMessage);
      Close;
    end;
  end;
end;

--------------------------------------------------------------------------------
EJEMPLO 5: Buscar Licencia en Varias Ubicaciones
--------------------------------------------------------------------------------

function FindLicenseFile: string;
var
  Paths: array[0..3] of string;
  I: Integer;
begin
  Result := '';

  // Definir ubicaciones de búsqueda
  Paths[0] := ExtractFilePath(Application.ExeName) + 'license.lic';
  Paths[1] := ExtractFilePath(Application.ExeName) + 'Licencia\license.lic';
  Paths[2] := TPath.Combine(TPath.GetDocumentsPath, 'MiApp\license.lic');
  Paths[3] := 'C:\ProgramData\MiApp\license.lic';

  // Buscar en orden
  for I := 0 to High(Paths) do
  begin
    if TFile.Exists(Paths[I]) then
    begin
      Result := Paths[I];
      Exit;
    end;
  end;
end;

procedure TFormMain.FormCreate(Sender: TObject);
var
  LicensePath: string;
begin
  LicensePath := FindLicenseFile;

  if LicensePath = '' then
  begin
    ShowMessage('No se encontró archivo de licencia');
    Application.Terminate;
    Exit;
  end;

  // Continuar con validación...
end;

================================================================================
}
