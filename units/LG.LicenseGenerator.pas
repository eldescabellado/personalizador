unit LG.LicenseGenerator;

{
  LicenseGuard - License Generator
  Generates encrypted license files (.sis) and packages them in ZIP containers

  UPDATED: Added File Verification support
}

interface

uses
  System.SysUtils, System.Classes, System.Zip, System.IOUtils,
  LG.LicenseData, LG.Encryption, LG.FileVerification;

type
  TLicenseGenerator = class
  private
    FMasterKey: string;
    FOutputPath: string;
    FControlFileHash: string;

    function GetControlFilePath: string;
    procedure GenerateControlFile;
    function CalculateControlFileHash: string;
  public
    constructor Create(const AMasterKey: string);

    // Generate license file
    function GenerateLicense(var ALicenseData: TLicenseData;
      const ACompanyName: string): string;

    // Generate control file (premium.sis)
    procedure CreateControlFile(const AOutputPath: string);

    // Verify control file
    function VerifyControlFile(const AFilePath: string): Boolean;

    // Generate demo license
    function GenerateDemoLicense(const AClientName, AAppName: string;
      ADays: Integer): string;

    // NEW: Set file verification for license
    procedure SetFileVerification(var ALicenseData: TLicenseData;
      const AFilePath: string; const ADescription: string = '');

    // Properties
    property OutputPath: string read FOutputPath write FOutputPath;
    property ControlFileHash: string read FControlFileHash;
  end;

  ELicenseGeneratorError = class(Exception);

const
  LICENSE_FILE_NAME = 'license.sis';
  CONTROL_FILE_NAME = 'premium.sis';
  CONTROL_FILE_MAGIC = 'LICENSEGUARD-CONTROL-FILE-V1.0';

implementation

uses
  System.Hash, System.DateUtils;

{ TLicenseGenerator }

constructor TLicenseGenerator.Create(const AMasterKey: string);
begin
  inherited Create;
  FMasterKey := AMasterKey;
  FOutputPath := TPath.Combine(TPath.GetDocumentsPath, 'LicenseGuard');

  if not TDirectory.Exists(FOutputPath) then
    TDirectory.CreateDirectory(FOutputPath);
end;

function TLicenseGenerator.GetControlFilePath: string;
begin
  Result := TPath.Combine(FOutputPath, CONTROL_FILE_NAME);
end;

procedure TLicenseGenerator.GenerateControlFile;
var
  ControlData: string;
  EncryptedData: string;
  Stream: TFileStream;
begin
  // Generate unique control file data
  ControlData := Format('%s|%s|%s',
    [CONTROL_FILE_MAGIC,
     TLGEncryption.GenerateUniqueID,
     DateTimeToStr(Now)]);

  // Encrypt control data
  EncryptedData := TLGEncryption.Encrypt(ControlData, FMasterKey);

  // Save to file
  Stream := TFileStream.Create(GetControlFilePath, fmCreate);
  try
    Stream.WriteData(EncryptedData);
  finally
    Stream.Free;
  end;

  // Calculate and store hash
  FControlFileHash := CalculateControlFileHash;
end;

function TLicenseGenerator.CalculateControlFileHash: string;
var
  Stream: TFileStream;
  Hash: THashSHA2;
  Bytes: TBytes;
begin
  if not TFile.Exists(GetControlFilePath) then
    raise ELicenseGeneratorError.Create('Control file does not exist');

  Stream := TFileStream.Create(GetControlFilePath, fmOpenRead);
  try
    SetLength(Bytes, Stream.Size);
    Stream.Read(Bytes[0], Stream.Size);

    Hash := THashSHA2.Create(THashSHA2.TSHA2Version.SHA256);
    Hash.Update(Bytes);
    Result := Hash.HashAsString;
  finally
    Stream.Free;
  end;
end;

procedure TLicenseGenerator.CreateControlFile(const AOutputPath: string);
var
  OldPath: string;
begin
  OldPath := FOutputPath;
  try
    FOutputPath := AOutputPath;
    GenerateControlFile;
  finally
    FOutputPath := OldPath;
  end;
end;

function TLicenseGenerator.VerifyControlFile(const AFilePath: string): Boolean;
var
  Stream: TFileStream;
  Hash: THashSHA2;
  Bytes: TBytes;
  FileHash: string;
begin
  Result := False;

  if not TFile.Exists(AFilePath) then
    Exit;

  try
    Stream := TFileStream.Create(AFilePath, fmOpenRead);
    try
      SetLength(Bytes, Stream.Size);
      Stream.Read(Bytes[0], Stream.Size);

      Hash := THashSHA2.Create(THashSHA2.TSHA2Version.SHA256);
      Hash.Update(Bytes);
      FileHash := Hash.HashAsString;

      Result := SameText(FileHash, FControlFileHash);
    finally
      Stream.Free;
    end;
  except
    Result := False;
  end;
end;

procedure TLicenseGenerator.SetFileVerification(var ALicenseData: TLicenseData;
  const AFilePath: string; const ADescription: string = '');
begin
  if not FileExists(AFilePath) then
    raise ELicenseGeneratorError.CreateFmt('Verification file not found: %s', [AFilePath]);

  ALicenseData.FileVerification := TFileVerificationHelper.GetFileInfo(AFilePath);
  ALicenseData.FileVerification.Description := ADescription;
end;

function TLicenseGenerator.GenerateLicense(var ALicenseData: TLicenseData;
  const ACompanyName: string): string;
var
  LicenseJSON: string;
  EncryptedLicense: string;
  TempPath: string;
  LicenseFilePath: string;
  ZipFilePath: string;
  ZipFile: TZipFile;
  SafeCompanyName: string;
begin
  // Validate input
  if ACompanyName.Trim.IsEmpty then
    raise ELicenseGeneratorError.Create('Company name cannot be empty');

  // Create safe company name for file system
  SafeCompanyName := ACompanyName.Trim;
  SafeCompanyName := SafeCompanyName.Replace(' ', '_');
  SafeCompanyName := SafeCompanyName.Replace('\', '');
  SafeCompanyName := SafeCompanyName.Replace('/', '');
  SafeCompanyName := SafeCompanyName.Replace(':', '');
  SafeCompanyName := SafeCompanyName.Replace('*', '');
  SafeCompanyName := SafeCompanyName.Replace('?', '');
  SafeCompanyName := SafeCompanyName.Replace('"', '');
  SafeCompanyName := SafeCompanyName.Replace('<', '');
  SafeCompanyName := SafeCompanyName.Replace('>', '');
  SafeCompanyName := SafeCompanyName.Replace('|', '');

  // Ensure control file exists and is up to date
  if not TFile.Exists(GetControlFilePath) then
    GenerateControlFile;

  // Update license data with control file hash
  ALicenseData.ControlFileHash := CalculateControlFileHash;

  // Convert license data to JSON
  LicenseJSON := ALicenseData.ToJSON.ToString;

  // Encrypt license data
  EncryptedLicense := TLGEncryption.Encrypt(LicenseJSON, FMasterKey);

  // Create temporary directory for license file
  TempPath := TPath.Combine(TPath.GetTempPath, 'LG_' + TLGEncryption.GenerateUniqueID);
  TDirectory.CreateDirectory(TempPath);
  try
    // Save encrypted license to .sis file
    LicenseFilePath := TPath.Combine(TempPath, LICENSE_FILE_NAME);
    TFile.WriteAllText(LicenseFilePath, EncryptedLicense, TEncoding.UTF8);

    // Create ZIP file with company name
    ZipFilePath := TPath.Combine(FOutputPath, SafeCompanyName + '.zip');

    // Delete existing ZIP if it exists
    if TFile.Exists(ZipFilePath) then
      TFile.Delete(ZipFilePath);

    // Create new ZIP file
    ZipFile := TZipFile.Create;
    try
      ZipFile.Open(ZipFilePath, zmWrite);
      ZipFile.Add(LicenseFilePath, LICENSE_FILE_NAME);
      ZipFile.Close;
    finally
      ZipFile.Free;
    end;

    Result := ZipFilePath;
  finally
    // Clean up temporary directory
    if TDirectory.Exists(TempPath) then
      TDirectory.Delete(TempPath, True);
  end;
end;

function TLicenseGenerator.GenerateDemoLicense(const AClientName,
  AAppName: string; ADays: Integer): string;
var
  LicenseData: TLicenseData;
begin
  // Initialize license data
  LicenseData.Initialize;
  try
    // Set demo parameters
    LicenseData.LicenseType := ltDemo;
    LicenseData.ClientName := AClientName;
    LicenseData.ClientCompany := AClientName;
    LicenseData.ApplicationName := AAppName;
    LicenseData.ApplicationID := TLGEncryption.HashSHA256(AAppName);

    // Set expiration
    LicenseData.Expiration.HasExpiration := True;
    LicenseData.Expiration.ExpirationDate := IncDay(Now, ADays);
    LicenseData.Expiration.GracePeriodDays := 0;

    // Allow any version for demo
    LicenseData.VersionTolerance.AllowAnyVersion := True;

    // No hardware binding for demo
    LicenseData.HardwareBinding.Enabled := False;

    // No file verification for demo
    LicenseData.FileVerification := TFileVerificationInfo.Empty;

    // Set distributor info
    LicenseData.DistributorName := 'DEMO';
    LicenseData.DistributorSerial := 'DEMO-0000-0000-0000';

    // Add demo note
    LicenseData.Notes := Format('Demo license valid for %d days', [ADays]);

    // Generate license
    Result := GenerateLicense(LicenseData, AClientName + '_DEMO');
  finally
    LicenseData.Free;
  end;
end;

end.
