unit LG.LicenseData;

{
  LicenseGuard - License Data Management
  Defines all data structures for license management

  UPDATED: Added File Verification support
}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.JSON,
  LG.FileVerification;

type
  // License type enumeration
  TLicenseType = (ltFull, ltDemo, ltTrial);

  // Application information
  TApplicationInfo = record
    ID: Integer;
    Name: string;
    Description: string;
    CurrentVersion: string;
    CreatedDate: TDateTime;
    function ToJSON: TJSONObject;
    procedure FromJSON(AJSON: TJSONObject);
  end;

  // Distributor information
  TDistributorInfo = record
    ID: Integer;
    Name: string;
    SerialNumber: string;
    ContactEmail: string;
    ContactPhone: string;
    Address: string;
    Active: Boolean;
    CreatedDate: TDateTime;
    function ToJSON: TJSONObject;
    procedure FromJSON(AJSON: TJSONObject);
  end;

  // Version tolerance specification
  TVersionTolerance = record
    AllowedVersions: TArray<string>;
    AllowAnyVersion: Boolean;
    MinVersion: string;
    MaxVersion: string;
    function ToJSON: TJSONObject;
    procedure FromJSON(AJSON: TJSONObject);
    function IsVersionAllowed(const Version: string): Boolean;
  end;

  // Hardware binding information
  THardwareBinding = record
    Enabled: Boolean;
    HardwareID: string;
    BindingType: string; // 'MAC', 'CPU', 'DISK', 'COMBINED'
    function ToJSON: TJSONObject;
    procedure FromJSON(AJSON: TJSONObject);
  end;

  // Expiration settings
  TExpirationInfo = record
    HasExpiration: Boolean;
    ExpirationDate: TDateTime;
    GracePeriodDays: Integer;
    function ToJSON: TJSONObject;
    procedure FromJSON(AJSON: TJSONObject);
    function IsExpired: Boolean;
    function DaysUntilExpiration: Integer;
  end;

  // Complete license data structure
  TLicenseData = record
    // Identification
    LicenseSerial: string;
    LicenseType: TLicenseType;
    CreatedDate: TDateTime;

    // Client information
    ClientName: string;
    ClientCompany: string;

    // Application information
    ApplicationName: string;
    ApplicationID: string;

    // Version control
    VersionTolerance: TVersionTolerance;

    // Expiration
    Expiration: TExpirationInfo;

    // Distributor
    DistributorName: string;
    DistributorSerial: string;

    // Hardware binding
    HardwareBinding: THardwareBinding;

    // Control file association
    ControlFileHash: string; // SHA-256 hash of premium.sis

    // NEW: File verification
    FileVerification: TFileVerificationInfo;

    // Additional metadata
    Notes: string;
    CustomFields: TDictionary<string, string>;

    // Methods
    function ToJSON: TJSONObject;
    procedure FromJSON(AJSON: TJSONObject);
    function ToString: string;
    procedure Initialize;
    procedure Free;
  end;

  // License validation result
  TValidationResult = record
    IsValid: Boolean;
    ErrorMessage: string;
    WarningMessage: string;
    DaysUntilExpiration: Integer;

    class function Success: TValidationResult; static;
    class function Failure(const AMessage: string): TValidationResult; static;
    class function Warning(const AMessage: string): TValidationResult; static;
  end;

implementation

uses
  System.DateUtils, LG.Encryption;

{ TApplicationInfo }

function TApplicationInfo.ToJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('ID', TJSONNumber.Create(ID));
  Result.AddPair('Name', Name);
  Result.AddPair('Description', Description);
  Result.AddPair('CurrentVersion', CurrentVersion);
  Result.AddPair('CreatedDate', DateTimeToStr(CreatedDate));
end;

procedure TApplicationInfo.FromJSON(AJSON: TJSONObject);
begin
  ID := AJSON.GetValue<Integer>('ID');
  Name := AJSON.GetValue<string>('Name');
  Description := AJSON.GetValue<string>('Description');
  CurrentVersion := AJSON.GetValue<string>('CurrentVersion');
  CreatedDate := StrToDateTime(AJSON.GetValue<string>('CreatedDate'));
end;

{ TDistributorInfo }

function TDistributorInfo.ToJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('ID', TJSONNumber.Create(ID));
  Result.AddPair('Name', Name);
  Result.AddPair('SerialNumber', SerialNumber);
  Result.AddPair('ContactEmail', ContactEmail);
  Result.AddPair('ContactPhone', ContactPhone);
  Result.AddPair('Address', Address);
  Result.AddPair('Active', TJSONBool.Create(Active));
  Result.AddPair('CreatedDate', DateTimeToStr(CreatedDate));
end;

procedure TDistributorInfo.FromJSON(AJSON: TJSONObject);
begin
  ID := AJSON.GetValue<Integer>('ID');
  Name := AJSON.GetValue<string>('Name');
  SerialNumber := AJSON.GetValue<string>('SerialNumber');
  ContactEmail := AJSON.GetValue<string>('ContactEmail');
  ContactPhone := AJSON.GetValue<string>('ContactPhone');
  Address := AJSON.GetValue<string>('Address');
  Active := AJSON.GetValue<Boolean>('Active');
  CreatedDate := StrToDateTime(AJSON.GetValue<string>('CreatedDate'));
end;

{ TVersionTolerance }

function TVersionTolerance.ToJSON: TJSONObject;
var
  VersionsArray: TJSONArray;
  Version: string;
begin
  Result := TJSONObject.Create;
  Result.AddPair('AllowAnyVersion', TJSONBool.Create(AllowAnyVersion));
  Result.AddPair('MinVersion', MinVersion);
  Result.AddPair('MaxVersion', MaxVersion);

  VersionsArray := TJSONArray.Create;
  for Version in AllowedVersions do
    VersionsArray.Add(Version);
  Result.AddPair('AllowedVersions', VersionsArray);
end;

procedure TVersionTolerance.FromJSON(AJSON: TJSONObject);
var
  VersionsArray: TJSONArray;
  I: Integer;
begin
  AllowAnyVersion := AJSON.GetValue<Boolean>('AllowAnyVersion');
  MinVersion := AJSON.GetValue<string>('MinVersion');
  MaxVersion := AJSON.GetValue<string>('MaxVersion');

  VersionsArray := AJSON.GetValue<TJSONArray>('AllowedVersions');
  SetLength(AllowedVersions, VersionsArray.Count);
  for I := 0 to VersionsArray.Count - 1 do
    AllowedVersions[I] := VersionsArray.Items[I].Value;
end;

function TVersionTolerance.IsVersionAllowed(const Version: string): Boolean;
var
  AllowedVersion: string;
begin
  if AllowAnyVersion then
    Exit(True);

  // Check if version is in allowed list
  for AllowedVersion in AllowedVersions do
    if SameText(Version, AllowedVersion) then
      Exit(True);

  // Check version range (simplified - in production, use proper version comparison)
  if (MinVersion <> '') and (Version < MinVersion) then
    Exit(False);

  if (MaxVersion <> '') and (Version > MaxVersion) then
    Exit(False);

  Result := (MinVersion <> '') or (MaxVersion <> '');
end;

{ THardwareBinding }

function THardwareBinding.ToJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('Enabled', TJSONBool.Create(Enabled));
  Result.AddPair('HardwareID', HardwareID);
  Result.AddPair('BindingType', BindingType);
end;

procedure THardwareBinding.FromJSON(AJSON: TJSONObject);
begin
  Enabled := AJSON.GetValue<Boolean>('Enabled');
  HardwareID := AJSON.GetValue<string>('HardwareID');
  BindingType := AJSON.GetValue<string>('BindingType');
end;

{ TExpirationInfo }

function TExpirationInfo.ToJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('HasExpiration', TJSONBool.Create(HasExpiration));
  Result.AddPair('ExpirationDate', DateTimeToStr(ExpirationDate));
  Result.AddPair('GracePeriodDays', TJSONNumber.Create(GracePeriodDays));
end;

procedure TExpirationInfo.FromJSON(AJSON: TJSONObject);
begin
  HasExpiration := AJSON.GetValue<Boolean>('HasExpiration');
  ExpirationDate := StrToDateTime(AJSON.GetValue<string>('ExpirationDate'));
  GracePeriodDays := AJSON.GetValue<Integer>('GracePeriodDays');
end;

function TExpirationInfo.IsExpired: Boolean;
begin
  if not HasExpiration then
    Exit(False);

  Result := Now > IncDay(ExpirationDate, GracePeriodDays);
end;

function TExpirationInfo.DaysUntilExpiration: Integer;
begin
  if not HasExpiration then
    Exit(MaxInt);

  Result := DaysBetween(Now, ExpirationDate);
  if Now > ExpirationDate then
    Result := -Result;
end;

{ TLicenseData }

procedure TLicenseData.Initialize;
begin
  CustomFields := TDictionary<string, string>.Create;
  LicenseSerial := TLGEncryption.GenerateUniqueID;
  CreatedDate := Now;
  LicenseType := ltFull;

  // Initialize sub-structures
  VersionTolerance.AllowAnyVersion := False;
  SetLength(VersionTolerance.AllowedVersions, 0);
  VersionTolerance.MinVersion := '';
  VersionTolerance.MaxVersion := '';

  Expiration.HasExpiration := False;
  Expiration.ExpirationDate := 0;
  Expiration.GracePeriodDays := 0;

  HardwareBinding.Enabled := False;
  HardwareBinding.HardwareID := '';
  HardwareBinding.BindingType := '';

  // Initialize file verification
  FileVerification := TFileVerificationInfo.Empty;
end;

procedure TLicenseData.Free;
begin
  if Assigned(CustomFields) then
    CustomFields.Free;
end;

function TLicenseData.ToJSON: TJSONObject;
var
  CustomFieldsObj: TJSONObject;
  Key: string;
begin
  Result := TJSONObject.Create;

  // Basic info
  Result.AddPair('LicenseSerial', LicenseSerial);
  Result.AddPair('LicenseType', TJSONNumber.Create(Ord(LicenseType)));
  Result.AddPair('CreatedDate', DateTimeToStr(CreatedDate));

  // Client info
  Result.AddPair('ClientName', ClientName);
  Result.AddPair('ClientCompany', ClientCompany);

  // Application info
  Result.AddPair('ApplicationName', ApplicationName);
  Result.AddPair('ApplicationID', ApplicationID);

  // Version tolerance
  Result.AddPair('VersionTolerance', VersionTolerance.ToJSON);

  // Expiration
  Result.AddPair('Expiration', Expiration.ToJSON);

  // Distributor
  Result.AddPair('DistributorName', DistributorName);
  Result.AddPair('DistributorSerial', DistributorSerial);

  // Hardware binding
  Result.AddPair('HardwareBinding', HardwareBinding.ToJSON);

  // Control file
  Result.AddPair('ControlFileHash', ControlFileHash);

  // File verification
  Result.AddPair('FileVerification', FileVerification.ToJSON);

  // Metadata
  Result.AddPair('Notes', Notes);

  // Custom fields
  CustomFieldsObj := TJSONObject.Create;
  if Assigned(CustomFields) then
    for Key in CustomFields.Keys do
      CustomFieldsObj.AddPair(Key, CustomFields[Key]);
  Result.AddPair('CustomFields', CustomFieldsObj);
end;

procedure TLicenseData.FromJSON(AJSON: TJSONObject);
var
  CustomFieldsObj: TJSONObject;
  Pair: TJSONPair;
  FileVerifObj: TJSONValue;
begin
  // Basic info
  LicenseSerial := AJSON.GetValue<string>('LicenseSerial');
  LicenseType := TLicenseType(AJSON.GetValue<Integer>('LicenseType'));
  CreatedDate := StrToDateTime(AJSON.GetValue<string>('CreatedDate'));

  // Client info
  ClientName := AJSON.GetValue<string>('ClientName');
  ClientCompany := AJSON.GetValue<string>('ClientCompany');

  // Application info
  ApplicationName := AJSON.GetValue<string>('ApplicationName');
  ApplicationID := AJSON.GetValue<string>('ApplicationID');

  // Version tolerance
  VersionTolerance.FromJSON(AJSON.GetValue<TJSONObject>('VersionTolerance'));

  // Expiration
  Expiration.FromJSON(AJSON.GetValue<TJSONObject>('Expiration'));

  // Distributor
  DistributorName := AJSON.GetValue<string>('DistributorName');
  DistributorSerial := AJSON.GetValue<string>('DistributorSerial');

  // Hardware binding
  HardwareBinding.FromJSON(AJSON.GetValue<TJSONObject>('HardwareBinding'));

  // Control file
  ControlFileHash := AJSON.GetValue<string>('ControlFileHash');

  // File verification
  FileVerifObj := AJSON.GetValue('FileVerification');
  if Assigned(FileVerifObj) and (FileVerifObj is TJSONObject) then
    FileVerification.FromJSON(TJSONObject(FileVerifObj))
  else
    FileVerification := TFileVerificationInfo.Empty;

  // Metadata
  Notes := AJSON.GetValue<string>('Notes');

  // Custom fields
  if not Assigned(CustomFields) then
    CustomFields := TDictionary<string, string>.Create
  else
    CustomFields.Clear;

  CustomFieldsObj := AJSON.GetValue<TJSONObject>('CustomFields');
  for Pair in CustomFieldsObj do
    CustomFields.Add(Pair.JsonString.Value, Pair.JsonValue.Value);
end;

function TLicenseData.ToString: string;
begin
  Result := ToJSON.ToString;
end;

{ TValidationResult }

class function TValidationResult.Success: TValidationResult;
begin
  Result.IsValid := True;
  Result.ErrorMessage := '';
  Result.WarningMessage := '';
  Result.DaysUntilExpiration := MaxInt;
end;

class function TValidationResult.Failure(const AMessage: string): TValidationResult;
begin
  Result.IsValid := False;
  Result.ErrorMessage := AMessage;
  Result.WarningMessage := '';
  Result.DaysUntilExpiration := 0;
end;

class function TValidationResult.Warning(const AMessage: string): TValidationResult;
begin
  Result.IsValid := True;
  Result.ErrorMessage := '';
  Result.WarningMessage := AMessage;
  Result.DaysUntilExpiration := 0;
end;

end.
