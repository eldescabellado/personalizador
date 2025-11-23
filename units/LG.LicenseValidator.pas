unit LG.LicenseValidator;

{
  LicenseGuard - License Validator
  Validates and loads license files in client applications

  INTEGRATION GUIDE:
  1. Include this unit and dependent units in your application
  2. Create a TLicenseValidator instance with your master key
  3. Call LoadLicenseFromZip with the path to the license ZIP file
  4. Check the validation result
  5. Access license data through the LicenseData property

  VERSION: 1.1.0 - Fixed file reading and encoding issues
}

interface

uses
  System.SysUtils, System.Classes, System.Zip, System.IOUtils, System.JSON,
  System.TypInfo, System.StrUtils,
  LG.LicenseData, LG.Encryption, LG.HardwareInfo;

type
  TLicenseValidator = class
  private
    FMasterKey: string;
    FLicenseData: TLicenseData;
    FControlFileHash: string;
    FApplicationVersion: string;
    FValidationResult: TValidationResult;

    function ExtractLicenseFromZip(const AZipPath: string): string;
    function ValidateControlFile: Boolean;
    function ValidateVersion: Boolean;
    function ValidateExpiration: Boolean;
    function ValidateHardware: Boolean;
    function ValidateDistributor: Boolean;

    // NEW: Helper to read license file safely
    function ReadLicenseFileSafe(const AFilePath: string): string;
  public
    constructor Create(const AMasterKey: string);
    destructor Destroy; override;

    // Load and validate license from ZIP file
    function LoadLicenseFromZip(const AZipPath: string;
      const AControlFilePath: string): TValidationResult;

    // Load and validate license from SIS file directly
    function LoadLicenseFromSIS(const ASISPath: string;
      const AControlFilePath: string): TValidationResult;

    // Validate current license
    function Validate: TValidationResult;

    // Check if license is valid for specific application
    function IsValidForApplication(const AAppName, AAppVersion: string): Boolean;

    // Get license information
    function GetLicenseInfo: string;

    // Properties
    property LicenseData: TLicenseData read FLicenseData;
    property ApplicationVersion: string read FApplicationVersion write FApplicationVersion;
    property ValidationResult: TValidationResult read FValidationResult;
  end;

  ELicenseValidationError = class(Exception);

const
  LICENSE_FILE_NAME = 'license.sis';

implementation

uses
  System.Hash, System.DateUtils;

{ TLicenseValidator }

constructor TLicenseValidator.Create(const AMasterKey: string);
begin
  inherited Create;
  FMasterKey := AMasterKey;
  FLicenseData.Initialize;
  FValidationResult := TValidationResult.Failure('No license loaded');
end;

destructor TLicenseValidator.Destroy;
begin
  FLicenseData.Free;
  inherited;
end;

function TLicenseValidator.ReadLicenseFileSafe(const AFilePath: string): string;
var
  FileBytes: TBytes;
  FileStream: TFileStream;
  I: Integer;
  IsBase64: Boolean;
begin
  if not TFile.Exists(AFilePath) then
    raise ELicenseValidationError.CreateFmt('License file not found: %s', [AFilePath]);

  try
    // Read file as raw bytes
    FileStream := TFileStream.Create(AFilePath, fmOpenRead or fmShareDenyWrite);
    try
      SetLength(FileBytes, FileStream.Size);
      if FileStream.Size > 0 then
        FileStream.ReadBuffer(FileBytes[0], FileStream.Size);
    finally
      FileStream.Free;
    end;

    // Check if it's valid Base64 (should only contain Base64 characters)
    IsBase64 := True;
    for I := 0 to Length(FileBytes) - 1 do
    begin
      // Base64 chars: A-Z, a-z, 0-9, +, /, =, and whitespace (CR, LF, space)
      if not (
        ((FileBytes[I] >= Ord('A')) and (FileBytes[I] <= Ord('Z'))) or
        ((FileBytes[I] >= Ord('a')) and (FileBytes[I] <= Ord('z'))) or
        ((FileBytes[I] >= Ord('0')) and (FileBytes[I] <= Ord('9'))) or
        (FileBytes[I] = Ord('+')) or
        (FileBytes[I] = Ord('/')) or
        (FileBytes[I] = Ord('=')) or
        (FileBytes[I] = 13) or  // CR
        (FileBytes[I] = 10) or  // LF
        (FileBytes[I] = 32)     // Space
      ) then
      begin
        IsBase64 := False;
        Break;
      end;
    end;

    if not IsBase64 then
      raise ELicenseValidationError.Create('License file is corrupted or not a valid license file');

    // Convert to string using ASCII (Base64 is pure ASCII)
    Result := TEncoding.ASCII.GetString(FileBytes);

    // Remove any whitespace
    Result := StringReplace(Result, #13, '', [rfReplaceAll]);
    Result := StringReplace(Result, #10, '', [rfReplaceAll]);
    Result := StringReplace(Result, ' ', '', [rfReplaceAll]);

    if Result = '' then
      raise ELicenseValidationError.Create('License file is empty');

  except
    on E: ELicenseValidationError do
      raise;
    on E: Exception do
      raise ELicenseValidationError.Create('Failed to read license file: ' + E.Message);
  end;
end;

function TLicenseValidator.ExtractLicenseFromZip(const AZipPath: string): string;
var
  ZipFile: TZipFile;
  TempPath: string;
  LicenseFilePath: string;
  I: Integer;
  Found: Boolean;
  Bytes: TBytes;
begin
  Result := '';

  if not TFile.Exists(AZipPath) then
    raise ELicenseValidationError.CreateFmt('License ZIP file not found: %s', [AZipPath]);

  // Create temporary directory
  TempPath := TPath.Combine(TPath.GetTempPath, 'LG_Validate_' + TLGEncryption.GenerateUniqueID);
  TDirectory.CreateDirectory(TempPath);

  ZipFile := TZipFile.Create;
  try
    try
      ZipFile.Open(AZipPath, zmRead);
    except
      on E: Exception do
        raise ELicenseValidationError.Create('Failed to open ZIP file: ' + E.Message);
    end;

    // Find license.sis in ZIP
    Found := False;
    for I := 0 to ZipFile.FileCount - 1 do
    begin
      if SameText(ZipFile.FileNames[I], LICENSE_FILE_NAME) or
         SameText(TPath.GetFileName(ZipFile.FileNames[I]), LICENSE_FILE_NAME) then
      begin
        try
          // Extract to temp directory
          ZipFile.Extract(ZipFile.FileNames[I], TempPath);
          LicenseFilePath := TPath.Combine(TempPath, LICENSE_FILE_NAME);
          Found := True;
          Break;
        except
          on E: Exception do
            raise ELicenseValidationError.Create('Failed to extract license from ZIP: ' + E.Message);
        end;
      end;
    end;

    ZipFile.Close;

    if not Found then
      raise ELicenseValidationError.Create('License file (license.sis) not found in ZIP archive');

    // Read license content safely
    Result := ReadLicenseFileSafe(LicenseFilePath);

    // Clean up
    try
      if TDirectory.Exists(TempPath) then
        TDirectory.Delete(TempPath, True);
    except
      // Ignore cleanup errors
    end;
  finally
    ZipFile.Free;
  end;
end;

function TLicenseValidator.LoadLicenseFromZip(const AZipPath: string;
  const AControlFilePath: string): TValidationResult;
var
  EncryptedLicense: string;
begin
  try
    // Extract license from ZIP
    EncryptedLicense := ExtractLicenseFromZip(AZipPath);

    // Load from encrypted content (pass content, not path)
    Result := LoadLicenseFromSIS(EncryptedLicense, AControlFilePath);
  except
    on E: ELicenseValidationError do
      Result := TValidationResult.Failure(E.Message);
    on E: Exception do
      Result := TValidationResult.Failure('Failed to load license: ' + E.Message);
  end;

  FValidationResult := Result;
end;

function TLicenseValidator.LoadLicenseFromSIS(const ASISPath: string;
  const AControlFilePath: string): TValidationResult;
var
  EncryptedLicense: string;
  DecryptedLicense: string;
  LJSON: TJSONObject;
  ControlFileHash: string;
  Stream: TFileStream;
  Hash: THashSHA2;
  Bytes: TBytes;
begin
  try
    // Determine if ASISPath is a file path or the content itself
    if TFile.Exists(ASISPath) then
    begin
      // It's a file path - read it safely
      EncryptedLicense := ReadLicenseFileSafe(ASISPath);
    end
    else
    begin
      // Assume it's the encrypted content itself
      EncryptedLicense := ASISPath;

      // Validate it looks like Base64
      if not TLGEncryption.IsValidBase64(EncryptedLicense) then
        Exit(TValidationResult.Failure('Invalid license data format'));
    end;

    // Decrypt license
    try
      DecryptedLicense := TLGEncryption.Decrypt(EncryptedLicense, FMasterKey);
    except
      on E: EEncryptionError do
        Exit(TValidationResult.Failure('License decryption failed: ' + E.Message));
      on E: Exception do
        Exit(TValidationResult.Failure('Failed to decrypt license: ' + E.Message));
    end;

    // Parse JSON
    try
      LJSON := TJSONObject.ParseJSONValue(DecryptedLicense) as TJSONObject;
      if not Assigned(LJSON) then
        Exit(TValidationResult.Failure('Invalid license format: not valid JSON'));

      try
        FLicenseData.FromJSON(LJSON);
      finally
        LJSON.Free;
      end;
    except
      on E: Exception do
        Exit(TValidationResult.Failure('Failed to parse license data: ' + E.Message));
    end;

    // Verify control file if provided
    if AControlFilePath <> '' then
    begin
      if not TFile.Exists(AControlFilePath) then
        Exit(TValidationResult.Failure('Control file not found: ' + AControlFilePath));

      try
        // Calculate control file hash
        Stream := TFileStream.Create(AControlFilePath, fmOpenRead or fmShareDenyWrite);
        try
          SetLength(Bytes, Stream.Size);
          if Stream.Size > 0 then
            Stream.Read(Bytes[0], Stream.Size);

          Hash := THashSHA2.Create(THashSHA2.TSHA2Version.SHA256);
          Hash.Update(Bytes);
          ControlFileHash := Hash.HashAsString;
        finally
          Stream.Free;
        end;

        // Compare with license's control file hash
        if not SameText(ControlFileHash, FLicenseData.ControlFileHash) then
          Exit(TValidationResult.Failure('Control file mismatch: Invalid or tampered license'));
      except
        on E: Exception do
          Exit(TValidationResult.Failure('Failed to verify control file: ' + E.Message));
      end;
    end;

    // Validate license
    Result := Validate;
  except
    on E: ELicenseValidationError do
      Result := TValidationResult.Failure(E.Message);
    on E: Exception do
      Result := TValidationResult.Failure('Unexpected error: ' + E.Message);
  end;

  FValidationResult := Result;
end;

function TLicenseValidator.ValidateControlFile: Boolean;
begin
  // Control file validation is done in LoadLicenseFromSIS
  Result := True;
end;

function TLicenseValidator.ValidateVersion: Boolean;
begin
  if FApplicationVersion = '' then
    Exit(True); // No version specified, skip validation

  Result := FLicenseData.VersionTolerance.IsVersionAllowed(FApplicationVersion);
end;

function TLicenseValidator.ValidateExpiration: Boolean;
begin
  Result := not FLicenseData.Expiration.IsExpired;
end;

function TLicenseValidator.ValidateHardware: Boolean;
var
  CurrentHardwareID: string;
begin
  if not FLicenseData.HardwareBinding.Enabled then
    Exit(True);

  CurrentHardwareID := THardwareInfo.GetHardwareID(FLicenseData.HardwareBinding.BindingType);

  Result := SameText(CurrentHardwareID, FLicenseData.HardwareBinding.HardwareID);
end;

function TLicenseValidator.ValidateDistributor: Boolean;
begin
  // Basic validation - check if distributor serial is not empty
  Result := FLicenseData.DistributorSerial <> '';
end;

function TLicenseValidator.Validate: TValidationResult;
begin
  // Check version
  if not ValidateVersion then
    Exit(TValidationResult.Failure(
      Format('Application version %s is not allowed by this license', [FApplicationVersion])));

  // Check expiration
  if not ValidateExpiration then
    Exit(TValidationResult.Failure(
      Format('License expired on %s', [DateToStr(FLicenseData.Expiration.ExpirationDate)])));

  // Check hardware binding
  if not ValidateHardware then
    Exit(TValidationResult.Failure('Hardware mismatch: License is bound to different hardware'));

  // Check distributor
  if not ValidateDistributor then
    Exit(TValidationResult.Failure('Invalid distributor information'));

  // Check for expiration warning (within 30 days)
  if FLicenseData.Expiration.HasExpiration then
  begin
    if FLicenseData.Expiration.DaysUntilExpiration <= 30 then
    begin
      Result := TValidationResult.Warning(
        Format('License will expire in %d days', [FLicenseData.Expiration.DaysUntilExpiration]));
      Result.IsValid := True;
      Result.DaysUntilExpiration := FLicenseData.Expiration.DaysUntilExpiration;
      Exit;
    end;
  end;

  // All validations passed
  Result := TValidationResult.Success;
  if FLicenseData.Expiration.HasExpiration then
    Result.DaysUntilExpiration := FLicenseData.Expiration.DaysUntilExpiration
  else
    Result.DaysUntilExpiration := MaxInt;
end;

function TLicenseValidator.IsValidForApplication(const AAppName,
  AAppVersion: string): Boolean;
begin
  FApplicationVersion := AAppVersion;

  Result := (FLicenseData.ApplicationName = AAppName) and
            Validate.IsValid;
end;

function TLicenseValidator.GetLicenseInfo: string;
var
  LicenseTypeStr: string;
  ExpiresStr: string;
  HardwareBindingStr: string;
  StatusStr: string;
begin
  // Determinar tipo de licencia
  case FLicenseData.LicenseType of
    ltFull: LicenseTypeStr := 'Full';
    ltDemo: LicenseTypeStr := 'Demo';
    ltTrial: LicenseTypeStr := 'Trial';
  else
    LicenseTypeStr := 'Unknown';
  end;

  // Determinar fecha de expiración
  if FLicenseData.Expiration.HasExpiration then
    ExpiresStr := DateToStr(FLicenseData.Expiration.ExpirationDate)
  else
    ExpiresStr := 'Never';

  // Determinar vinculación de hardware
  if FLicenseData.HardwareBinding.Enabled then
    HardwareBindingStr := FLicenseData.HardwareBinding.BindingType
  else
    HardwareBindingStr := 'None';

  // Determinar estado
  if FValidationResult.IsValid then
    StatusStr := 'VALID'
  else
    StatusStr := 'INVALID';

  Result := Format(
    'License Information:' + sLineBreak +
    '===================' + sLineBreak +
    'License Serial: %s' + sLineBreak +
    'License Type: %s' + sLineBreak +
    'Client: %s' + sLineBreak +
    'Company: %s' + sLineBreak +
    'Application: %s' + sLineBreak +
    'Distributor: %s (%s)' + sLineBreak +
    'Created: %s' + sLineBreak +
    'Expires: %s' + sLineBreak +
    'Hardware Binding: %s' + sLineBreak +
    'Status: %s',
    [
      FLicenseData.LicenseSerial,
      LicenseTypeStr,
      FLicenseData.ClientName,
      FLicenseData.ClientCompany,
      FLicenseData.ApplicationName,
      FLicenseData.DistributorName,
      FLicenseData.DistributorSerial,
      DateTimeToStr(FLicenseData.CreatedDate),
      ExpiresStr,
      HardwareBindingStr,
      StatusStr
    ]);
end;

end.
