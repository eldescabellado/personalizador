unit LG.LicenseGenerator;

{
  LicenseGuard - License Generator (Simplified)
  Generates encrypted license files (.lic) directly

  SIMPLIFICADO:
  - Genera un único archivo .lic encriptado
  - No requiere ZIP ni archivo de control separado
  - Todo lo necesario está en el archivo de licencia
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
  public
    constructor Create(const AMasterKey: string);

    // Generar archivo de licencia
    function GenerateLicense(var ALicenseData: TLicenseData;
      const AFileName: string): string;

    // Generar licencia demo
    function GenerateDemoLicense(const AClientName, AAppName: string;
      ADays: Integer): string;

    // Propiedades
    property OutputPath: string read FOutputPath write FOutputPath;
    property LicenseExtension: string read FLicenseExtension write FLicenseExtension;
    property MasterKey: string read FMasterKey;
  end;

  ELicenseGeneratorError = class(Exception);

implementation

uses
  System.Hash, System.DateUtils;

{ TLicenseGenerator }

constructor TLicenseGenerator.Create(const AMasterKey: string);
begin
  inherited Create;
  FMasterKey := AMasterKey;
  FLicenseExtension := '.lic';
  FOutputPath := TPath.Combine(TPath.GetDocumentsPath, 'LicenseGuard');

  if not TDirectory.Exists(FOutputPath) then
    TDirectory.CreateDirectory(FOutputPath);
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

  // Generar hash de verificación interno
  Hash := THashSHA2.Create(THashSHA2.TSHA2Version.SHA256);
  Hash.Update(ALicenseData.LicenseSerial + FMasterKey + ALicenseData.ApplicationID);
  LicenseHash := Hash.HashAsString;
  ALicenseData.ControlFileHash := LicenseHash;

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
