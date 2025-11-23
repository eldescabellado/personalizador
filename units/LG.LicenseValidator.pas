unit LG.LicenseValidator;

{
  LicenseGuard - License Validator (Simplified)
  Validates license files in client applications

  USO SIMPLE EN APLICACIONES CLIENTE:
  =====================================

  1. Agregar unidades al proyecto:
     - LG.LicenseValidator
     - LG.LicenseData
     - LG.Encryption
     - LG.HardwareInfo (si usa vinculación de hardware)

  2. Código mínimo de integración:

     var
       Validator: TLicenseValidator;
     begin
       Validator := TLicenseValidator.Create('TU-MASTER-KEY');
       try
         if Validator.LoadLicense('ruta/al/archivo.lic') then
         begin
           if Validator.IsValid then
             // Licencia válida, continuar
           else
             ShowMessage('Licencia inválida: ' + Validator.ErrorMessage);
         end
         else
           ShowMessage('No se pudo cargar la licencia');
       finally
         Validator.Free;
       end;
     end;

  3. Con archivo de control (OPCIONAL):

     Validator.SetControlFile('ruta/a/premium.sis');
     if Validator.LoadLicense('license.lic') then
       // La validación incluirá verificación del archivo de control
}

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.JSON,
  LG.LicenseData, LG.Encryption, LG.HardwareInfo;

type
  TLicenseValidator = class
  private
    FMasterKey: string;
    FLicenseData: TLicenseData;
    FApplicationVersion: string;
    FApplicationName: string;
    FIsValid: Boolean;
    FIsLoaded: Boolean;
    FErrorMessage: string;
    FWarningMessage: string;
    FControlFilePath: string;
    FControlFileHash: string;
    FUseControlFile: Boolean;

    function ValidateInternal: Boolean;
    function ValidateControlFile: Boolean;
  public
    constructor Create(const AMasterKey: string);
    destructor Destroy; override;

    // Cargar licencia desde archivo
    function LoadLicense(const ALicensePath: string): Boolean;

    // Cargar licencia desde contenido encriptado
    function LoadLicenseFromContent(const AEncryptedContent: string): Boolean;

    // Archivo de control (OPCIONAL)
    procedure SetControlFile(const AControlFilePath: string);
    procedure ClearControlFile;

    // Validar licencia cargada
    function Validate: Boolean;

    // Verificar si es válida para aplicación específica
    function IsValidFor(const AAppName: string): Boolean; overload;
    function IsValidFor(const AAppName, AAppVersion: string): Boolean; overload;

    // Obtener días restantes
    function GetDaysRemaining: Integer;

    // Obtener información de licencia como texto
    function GetLicenseInfo: string;

    // Propiedades de estado
    property IsValid: Boolean read FIsValid;
    property IsLoaded: Boolean read FIsLoaded;
    property ErrorMessage: string read FErrorMessage;
    property WarningMessage: string read FWarningMessage;

    // Propiedades de configuración
    property ApplicationVersion: string read FApplicationVersion write FApplicationVersion;
    property ApplicationName: string read FApplicationName write FApplicationName;
    property ControlFilePath: string read FControlFilePath;
    property UseControlFile: Boolean read FUseControlFile;

    // Acceso a datos de licencia
    property LicenseData: TLicenseData read FLicenseData;

    // Propiedades útiles directas
    property ClientName: string read FLicenseData.ClientName;
    property ClientCompany: string read FLicenseData.ClientCompany;
    property LicenseType: TLicenseType read FLicenseData.LicenseType;
    property ExpirationDate: TDateTime read FLicenseData.Expiration.ExpirationDate;
  end;

  ELicenseValidationError = class(Exception);

implementation

uses
  System.Hash, System.DateUtils;

{ TLicenseValidator }

constructor TLicenseValidator.Create(const AMasterKey: string);
begin
  inherited Create;
  FMasterKey := AMasterKey;
  FLicenseData.Initialize;
  FIsValid := False;
  FIsLoaded := False;
  FErrorMessage := '';
  FWarningMessage := '';
  FControlFilePath := '';
  FControlFileHash := '';
  FUseControlFile := False;
end;

destructor TLicenseValidator.Destroy;
begin
  FLicenseData.Free;
  inherited;
end;

procedure TLicenseValidator.SetControlFile(const AControlFilePath: string);
var
  FileContent: string;
  Hash: THashSHA2;
  Bytes: TBytes;
begin
  FControlFilePath := '';
  FControlFileHash := '';
  FUseControlFile := False;

  if not TFile.Exists(AControlFilePath) then
    Exit;

  try
    FileContent := TFile.ReadAllText(AControlFilePath, TEncoding.UTF8);
    Bytes := TEncoding.UTF8.GetBytes(FileContent);

    Hash := THashSHA2.Create(THashSHA2.TSHA2Version.SHA256);
    Hash.Update(Bytes);
    FControlFileHash := Hash.HashAsString;

    FControlFilePath := AControlFilePath;
    FUseControlFile := True;
  except
    FControlFilePath := '';
    FControlFileHash := '';
    FUseControlFile := False;
  end;
end;

procedure TLicenseValidator.ClearControlFile;
begin
  FControlFilePath := '';
  FControlFileHash := '';
  FUseControlFile := False;
end;

function TLicenseValidator.ValidateControlFile: Boolean;
begin
  Result := True;

  // Si no se está usando archivo de control, siempre es válido
  if not FUseControlFile then
    Exit;

  // Verificar que el hash coincida
  if not SameText(FControlFileHash, FLicenseData.ControlFileHash) then
  begin
    FErrorMessage := 'Archivo de control no coincide con la licencia';
    Result := False;
  end;
end;

function TLicenseValidator.LoadLicense(const ALicensePath: string): Boolean;
var
  EncryptedContent: string;
begin
  FIsLoaded := False;
  FIsValid := False;
  FErrorMessage := '';
  FWarningMessage := '';

  // Verificar que el archivo existe
  if not TFile.Exists(ALicensePath) then
  begin
    FErrorMessage := 'Archivo de licencia no encontrado: ' + ALicensePath;
    Result := False;
    Exit;
  end;

  try
    // Leer contenido encriptado
    EncryptedContent := TFile.ReadAllText(ALicensePath, TEncoding.UTF8);
    Result := LoadLicenseFromContent(EncryptedContent);
  except
    on E: Exception do
    begin
      FErrorMessage := 'Error al leer archivo de licencia: ' + E.Message;
      Result := False;
    end;
  end;
end;

function TLicenseValidator.LoadLicenseFromContent(const AEncryptedContent: string): Boolean;
var
  DecryptedLicense: string;
  LJSON: TJSONObject;
begin
  FIsLoaded := False;
  FIsValid := False;
  FErrorMessage := '';

  try
    // Desencriptar licencia
    try
      DecryptedLicense := TLGEncryption.Decrypt(AEncryptedContent, FMasterKey);
    except
      on E: Exception do
      begin
        FErrorMessage := 'Error al desencriptar licencia: Clave inválida o archivo corrupto';
        Result := False;
        Exit;
      end;
    end;

    // Parsear JSON
    LJSON := TJSONObject.ParseJSONValue(DecryptedLicense) as TJSONObject;
    if not Assigned(LJSON) then
    begin
      FErrorMessage := 'Formato de licencia inválido';
      Result := False;
      Exit;
    end;

    try
      FLicenseData.FromJSON(LJSON);
    finally
      LJSON.Free;
    end;

    FIsLoaded := True;

    // Validar automáticamente
    FIsValid := ValidateInternal;
    Result := True;
  except
    on E: Exception do
    begin
      FErrorMessage := 'Error al procesar licencia: ' + E.Message;
      Result := False;
    end;
  end;
end;

function TLicenseValidator.ValidateInternal: Boolean;
var
  CurrentHardwareID: string;
begin
  Result := False;
  FErrorMessage := '';
  FWarningMessage := '';

  if not FIsLoaded then
  begin
    FErrorMessage := 'No hay licencia cargada';
    Exit;
  end;

  // Verificar archivo de control (OPCIONAL)
  if not ValidateControlFile then
    Exit;

  // Verificar aplicación si está especificada
  if (FApplicationName <> '') and (not SameText(FApplicationName, FLicenseData.ApplicationName)) then
  begin
    FErrorMessage := Format('Licencia no válida para esta aplicación. ' +
      'Esperado: %s, Encontrado: %s', [FApplicationName, FLicenseData.ApplicationName]);
    Exit;
  end;

  // Verificar versión
  if (FApplicationVersion <> '') and (not FLicenseData.VersionTolerance.AllowAnyVersion) then
  begin
    if not FLicenseData.VersionTolerance.IsVersionAllowed(FApplicationVersion) then
    begin
      FErrorMessage := Format('Versión %s no permitida por esta licencia', [FApplicationVersion]);
      Exit;
    end;
  end;

  // Verificar expiración
  if FLicenseData.Expiration.HasExpiration then
  begin
    if FLicenseData.Expiration.IsExpired then
    begin
      FErrorMessage := Format('Licencia expirada el %s',
        [DateToStr(FLicenseData.Expiration.ExpirationDate)]);
      Exit;
    end;

    // Advertencia si expira pronto
    if FLicenseData.Expiration.DaysUntilExpiration <= 30 then
    begin
      FWarningMessage := Format('La licencia expira en %d días',
        [FLicenseData.Expiration.DaysUntilExpiration]);
    end;
  end;

  // Verificar vinculación de hardware
  if FLicenseData.HardwareBinding.Enabled then
  begin
    CurrentHardwareID := THardwareInfo.GetHardwareID(FLicenseData.HardwareBinding.BindingType);

    if not SameText(CurrentHardwareID, FLicenseData.HardwareBinding.HardwareID) then
    begin
      FErrorMessage := 'Licencia vinculada a otro hardware';
      Exit;
    end;
  end;

  // Verificar distribuidor
  if FLicenseData.DistributorSerial = '' then
  begin
    FErrorMessage := 'Información de distribuidor inválida';
    Exit;
  end;

  // Todo OK
  Result := True;
end;

function TLicenseValidator.Validate: Boolean;
begin
  FIsValid := ValidateInternal;
  Result := FIsValid;
end;

function TLicenseValidator.IsValidFor(const AAppName: string): Boolean;
begin
  FApplicationName := AAppName;
  Result := Validate;
end;

function TLicenseValidator.IsValidFor(const AAppName, AAppVersion: string): Boolean;
begin
  FApplicationName := AAppName;
  FApplicationVersion := AAppVersion;
  Result := Validate;
end;

function TLicenseValidator.GetDaysRemaining: Integer;
begin
  if not FIsLoaded then
    Result := 0
  else if not FLicenseData.Expiration.HasExpiration then
    Result := MaxInt // Sin expiración
  else
    Result := FLicenseData.Expiration.DaysUntilExpiration;
end;

function TLicenseValidator.GetLicenseInfo: string;
var
  LicenseTypeStr: string;
  ExpiresStr: string;
  HardwareStr: string;
  StatusStr: string;
  ControlStr: string;
begin
  if not FIsLoaded then
  begin
    Result := 'No hay licencia cargada';
    Exit;
  end;

  // Tipo de licencia
  case FLicenseData.LicenseType of
    ltFull: LicenseTypeStr := 'Completa';
    ltDemo: LicenseTypeStr := 'Demo';
    ltTrial: LicenseTypeStr := 'Prueba';
  else
    LicenseTypeStr := 'Desconocido';
  end;

  // Expiración
  if FLicenseData.Expiration.HasExpiration then
    ExpiresStr := DateToStr(FLicenseData.Expiration.ExpirationDate) +
      Format(' (%d días restantes)', [GetDaysRemaining])
  else
    ExpiresStr := 'Sin expiración';

  // Hardware
  if FLicenseData.HardwareBinding.Enabled then
    HardwareStr := FLicenseData.HardwareBinding.BindingType
  else
    HardwareStr := 'Sin vinculación';

  // Archivo de control
  if FUseControlFile then
    ControlStr := 'Sí (verificado)'
  else
    ControlStr := 'No';

  // Estado
  if FIsValid then
    StatusStr := 'VÁLIDA'
  else
    StatusStr := 'INVÁLIDA - ' + FErrorMessage;

  Result := Format(
    'Información de Licencia' + sLineBreak +
    '======================' + sLineBreak +
    'Serial: %s' + sLineBreak +
    'Tipo: %s' + sLineBreak +
    'Cliente: %s' + sLineBreak +
    'Empresa: %s' + sLineBreak +
    'Aplicación: %s' + sLineBreak +
    'Distribuidor: %s' + sLineBreak +
    'Expira: %s' + sLineBreak +
    'Hardware: %s' + sLineBreak +
    'Archivo de Control: %s' + sLineBreak +
    'Estado: %s',
    [
      FLicenseData.LicenseSerial,
      LicenseTypeStr,
      FLicenseData.ClientName,
      FLicenseData.ClientCompany,
      FLicenseData.ApplicationName,
      FLicenseData.DistributorName,
      ExpiresStr,
      HardwareStr,
      ControlStr,
      StatusStr
    ]);
end;

end.
