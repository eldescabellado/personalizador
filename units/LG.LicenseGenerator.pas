unit LG.LicenseGenerator;

{
  LicenseGuard - License Generator (Simplified)
  Generates encrypted license files (.lic) directly

  CARACTERÍSTICAS:
  - Genera un único archivo .lic encriptado
  - Archivo de control OPCIONAL (premium.sis)
  - Si existe archivo de control, se vincula a la licencia
  - Si no existe, la licencia funciona independientemente
}

interface

uses
  System.SysUtils, System.Classes, System.IOUtils,
  LG.LicenseData, LG.Encryption;

type
  TLicenseGenerator = class
  private
    FMasterKey: string;
    FOutputPath: string;
    FLicenseExtension: string;
    FControlFileHash: string;
    FControlFileName: string;

    function GetControlFilePath: string;
  public
    constructor Create(const AMasterKey: string);

    // Generar archivo de licencia
    function GenerateLicense(var ALicenseData: TLicenseData;
      const AFileName: string): string;

    // Generar licencia demo
    function GenerateDemoLicense(const AClientName, AAppName: string;
      ADays: Integer): string;

    // Archivo de control (OPCIONAL)
    function CreateControlFile: string;
    function CreateControlFileAt(const APath: string): string;
    function LoadControlFile(const APath: string): Boolean;
    function ControlFileExists: Boolean;

    // Propiedades
    property OutputPath: string read FOutputPath write FOutputPath;
    property LicenseExtension: string read FLicenseExtension write FLicenseExtension;
    property MasterKey: string read FMasterKey;
    property ControlFileHash: string read FControlFileHash;
    property ControlFileName: string read FControlFileName write FControlFileName;
  end;

  ELicenseGeneratorError = class(Exception);

const
  DEFAULT_CONTROL_FILE_NAME = 'premium.sis';
  CONTROL_FILE_MAGIC = 'LICENSEGUARD-CONTROL-V1';

implementation

uses
  System.Hash, System.DateUtils;

{ TLicenseGenerator }

constructor TLicenseGenerator.Create(const AMasterKey: string);
begin
  inherited Create;
  FMasterKey := AMasterKey;
  FLicenseExtension := '.lic';
  FControlFileName := DEFAULT_CONTROL_FILE_NAME;
  FControlFileHash := '';
  FOutputPath := TPath.Combine(TPath.GetDocumentsPath, 'LicenseGuard');

  if not TDirectory.Exists(FOutputPath) then
    TDirectory.CreateDirectory(FOutputPath);
end;

function TLicenseGenerator.GetControlFilePath: string;
begin
  Result := TPath.Combine(FOutputPath, FControlFileName);
end;

function TLicenseGenerator.ControlFileExists: Boolean;
begin
  Result := TFile.Exists(GetControlFilePath);
end;

function TLicenseGenerator.CreateControlFile: string;
begin
  Result := CreateControlFileAt(GetControlFilePath);
end;

function TLicenseGenerator.CreateControlFileAt(const APath: string): string;
var
  ControlData: string;
  EncryptedData: string;
  Hash: THashSHA2;
  Bytes: TBytes;
  DirPath: string;
begin
  // Asegurar que el directorio existe
  DirPath := ExtractFilePath(APath);
  if (DirPath <> '') and (not TDirectory.Exists(DirPath)) then
    TDirectory.CreateDirectory(DirPath);

  // Generar datos del archivo de control
  ControlData := Format('%s|%s|%s',
    [CONTROL_FILE_MAGIC,
     TLGEncryption.GenerateUniqueID,
     DateTimeToStr(Now)]);

  // Encriptar datos de control
  EncryptedData := TLGEncryption.Encrypt(ControlData, FMasterKey);

  // Guardar archivo
  TFile.WriteAllText(APath, EncryptedData, TEncoding.UTF8);

  // Calcular y guardar hash
  Bytes := TEncoding.UTF8.GetBytes(EncryptedData);
  Hash := THashSHA2.Create(THashSHA2.TSHA2Version.SHA256);
  Hash.Update(Bytes);
  FControlFileHash := Hash.HashAsString;

  Result := APath;
end;

function TLicenseGenerator.LoadControlFile(const APath: string): Boolean;
var
  FileContent: string;
  Hash: THashSHA2;
  Bytes: TBytes;
begin
  Result := False;
  FControlFileHash := '';

  if not TFile.Exists(APath) then
    Exit;

  try
    FileContent := TFile.ReadAllText(APath, TEncoding.UTF8);
    Bytes := TEncoding.UTF8.GetBytes(FileContent);

    Hash := THashSHA2.Create(THashSHA2.TSHA2Version.SHA256);
    Hash.Update(Bytes);
    FControlFileHash := Hash.HashAsString;

    Result := True;
  except
    FControlFileHash := '';
    Result := False;
  end;
end;

function TLicenseGenerator.GenerateLicense(var ALicenseData: TLicenseData;
  const AFileName: string): string;
var
  LicenseJSON: string;
  EncryptedLicense: string;
  LicenseFilePath: string;
  SafeFileName: string;
  Hash: THashSHA2;
  LicenseHash: string;
begin
  // Validar entrada
  if Trim(AFileName) = '' then
    raise ELicenseGeneratorError.Create('El nombre de archivo no puede estar vacío');

  // Crear nombre de archivo seguro
  SafeFileName := Trim(AFileName);
  SafeFileName := StringReplace(SafeFileName, ' ', '_', [rfReplaceAll]);
  SafeFileName := StringReplace(SafeFileName, '\', '', [rfReplaceAll]);
  SafeFileName := StringReplace(SafeFileName, '/', '', [rfReplaceAll]);
  SafeFileName := StringReplace(SafeFileName, ':', '', [rfReplaceAll]);
  SafeFileName := StringReplace(SafeFileName, '*', '', [rfReplaceAll]);
  SafeFileName := StringReplace(SafeFileName, '?', '', [rfReplaceAll]);
  SafeFileName := StringReplace(SafeFileName, '"', '', [rfReplaceAll]);
  SafeFileName := StringReplace(SafeFileName, '<', '', [rfReplaceAll]);
  SafeFileName := StringReplace(SafeFileName, '>', '', [rfReplaceAll]);
  SafeFileName := StringReplace(SafeFileName, '|', '', [rfReplaceAll]);

  // Determinar el hash a usar
  if FControlFileHash <> '' then
  begin
    // Usar hash del archivo de control si existe
    ALicenseData.ControlFileHash := FControlFileHash;
  end
  else
  begin
    // Generar hash interno basado en datos de la licencia
    Hash := THashSHA2.Create(THashSHA2.TSHA2Version.SHA256);
    Hash.Update(ALicenseData.LicenseSerial + FMasterKey + ALicenseData.ApplicationID);
    LicenseHash := Hash.HashAsString;
    ALicenseData.ControlFileHash := LicenseHash;
  end;

  // Convertir datos de licencia a JSON
  LicenseJSON := ALicenseData.ToJSON.ToString;

  // Encriptar datos de licencia
  EncryptedLicense := TLGEncryption.Encrypt(LicenseJSON, FMasterKey);

  // Ruta del archivo de licencia
  LicenseFilePath := TPath.Combine(FOutputPath, SafeFileName + FLicenseExtension);

  // Eliminar archivo existente si existe
  if TFile.Exists(LicenseFilePath) then
    TFile.Delete(LicenseFilePath);

  // Guardar licencia encriptada
  TFile.WriteAllText(LicenseFilePath, EncryptedLicense, TEncoding.UTF8);

  Result := LicenseFilePath;
end;

function TLicenseGenerator.GenerateDemoLicense(const AClientName,
  AAppName: string; ADays: Integer): string;
var
  LicenseData: TLicenseData;
begin
  // Inicializar datos de licencia
  LicenseData.Initialize;
  try
    // Configurar parámetros demo
    LicenseData.LicenseType := ltDemo;
    LicenseData.ClientName := AClientName;
    LicenseData.ClientCompany := AClientName;
    LicenseData.ApplicationName := AAppName;
    LicenseData.ApplicationID := TLGEncryption.HashSHA256(AAppName);

    // Configurar expiración
    LicenseData.Expiration.HasExpiration := True;
    LicenseData.Expiration.ExpirationDate := IncDay(Now, ADays);
    LicenseData.Expiration.GracePeriodDays := 0;

    // Permitir cualquier versión para demo
    LicenseData.VersionTolerance.AllowAnyVersion := True;

    // Sin vinculación de hardware para demo
    LicenseData.HardwareBinding.Enabled := False;

    // Información de distribuidor
    LicenseData.DistributorName := 'DEMO';
    LicenseData.DistributorSerial := 'DEMO-0000-0000-0000';

    // Nota demo
    LicenseData.Notes := Format('Licencia demo válida por %d días', [ADays]);

    // Generar licencia
    Result := GenerateLicense(LicenseData, AClientName + '_DEMO');
  finally
    LicenseData.Free;
  end;
end;

end.
