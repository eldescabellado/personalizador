unit LG.DataManager;

{
  LicenseGuard - Data Manager
  Manages applications, distributors, and license records
  Uses JSON file-based storage
}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.JSON,
  System.IOUtils, LG.LicenseData;

type
  // License record for history
  TLicenseRecord = record
    LicenseSerial: string;
    ClientName: string;
    ClientCompany: string;
    ApplicationName: string;
    DistributorName: string;
    CreatedDate: TDateTime;
    ExpirationDate: TDateTime;
    LicenseType: TLicenseType;
    FilePath: string;

    function ToJSON: TJSONObject;
    procedure FromJSON(AJSON: TJSONObject);
  end;

  TDataManager = class
  private
    FDataPath: string;
    FApplications: TList<TApplicationInfo>;
    FDistributors: TList<TDistributorInfo>;
    FLicenseRecords: TList<TLicenseRecord>;

    function GetApplicationsFile: string;
    function GetDistributorsFile: string;
    function GetLicenseRecordsFile: string;

    procedure LoadApplications;
    procedure LoadDistributors;
    procedure LoadLicenseRecords;

    procedure SaveApplications;
    procedure SaveDistributors;
    procedure SaveLicenseRecords;
  public
    constructor Create(const ADataPath: string);
    destructor Destroy; override;

    // Application management
    function AddApplication(const AName, ADescription, AVersion: string): Integer;
    procedure UpdateApplication(const AApp: TApplicationInfo);
    procedure DeleteApplication(AID: Integer);
    function GetApplication(AID: Integer): TApplicationInfo;
    function GetApplicationByName(const AName: string): TApplicationInfo;
    function GetAllApplications: TArray<TApplicationInfo>;

    // Distributor management
    function AddDistributor(const AName, AEmail, APhone, AAddress: string): Integer;
    procedure UpdateDistributor(const ADist: TDistributorInfo);
    procedure DeleteDistributor(AID: Integer);
    function GetDistributor(AID: Integer): TDistributorInfo;
    function GetDistributorBySerial(const ASerial: string): TDistributorInfo;
    function GetAllDistributors: TArray<TDistributorInfo>;
    function GenerateDistributorSerial: string;

    // License record management
    procedure AddLicenseRecord(const ARecord: TLicenseRecord);
    function GetLicenseRecord(const ASerial: string): TLicenseRecord;
    function GetAllLicenseRecords: TArray<TLicenseRecord>;
    function GetLicenseRecordsByClient(const AClientName: string): TArray<TLicenseRecord>;

    // Utility
    procedure RefreshData;

    property DataPath: string read FDataPath;
  end;

implementation

uses
  LG.Encryption;

{ TLicenseRecord }

function TLicenseRecord.ToJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('LicenseSerial', LicenseSerial);
  Result.AddPair('ClientName', ClientName);
  Result.AddPair('ClientCompany', ClientCompany);
  Result.AddPair('ApplicationName', ApplicationName);
  Result.AddPair('DistributorName', DistributorName);
  Result.AddPair('CreatedDate', DateTimeToStr(CreatedDate));
  Result.AddPair('ExpirationDate', DateTimeToStr(ExpirationDate));
  Result.AddPair('LicenseType', TJSONNumber.Create(Ord(LicenseType)));
  Result.AddPair('FilePath', FilePath);
end;

procedure TLicenseRecord.FromJSON(AJSON: TJSONObject);
begin
  LicenseSerial := AJSON.GetValue<string>('LicenseSerial');
  ClientName := AJSON.GetValue<string>('ClientName');
  ClientCompany := AJSON.GetValue<string>('ClientCompany');
  ApplicationName := AJSON.GetValue<string>('ApplicationName');
  DistributorName := AJSON.GetValue<string>('DistributorName');
  CreatedDate := StrToDateTime(AJSON.GetValue<string>('CreatedDate'));

  if AJSON.TryGetValue<string>('ExpirationDate') <> '' then
    ExpirationDate := StrToDateTime(AJSON.GetValue<string>('ExpirationDate'))
  else
    ExpirationDate := 0;

  LicenseType := TLicenseType(AJSON.GetValue<Integer>('LicenseType'));
  FilePath := AJSON.GetValue<string>('FilePath');
end;

{ TDataManager }

constructor TDataManager.Create(const ADataPath: string);
begin
  inherited Create;
  FDataPath := ADataPath;

  if not TDirectory.Exists(FDataPath) then
    TDirectory.CreateDirectory(FDataPath);

  FApplications := TList<TApplicationInfo>.Create;
  FDistributors := TList<TDistributorInfo>.Create;
  FLicenseRecords := TList<TLicenseRecord>.Create;

  LoadApplications;
  LoadDistributors;
  LoadLicenseRecords;
end;

destructor TDataManager.Destroy;
begin
  SaveApplications;
  SaveDistributors;
  SaveLicenseRecords;

  FApplications.Free;
  FDistributors.Free;
  FLicenseRecords.Free;

  inherited;
end;

function TDataManager.GetApplicationsFile: string;
begin
  Result := TPath.Combine(FDataPath, 'applications.json');
end;

function TDataManager.GetDistributorsFile: string;
begin
  Result := TPath.Combine(FDataPath, 'distributors.json');
end;

function TDataManager.GetLicenseRecordsFile: string;
begin
  Result := TPath.Combine(FDataPath, 'license_records.json');
end;

procedure TDataManager.LoadApplications;
var
  JSONText: string;
  JSONArray: TJSONArray;
  JSONObj: TJSONObject;
  I: Integer;
  App: TApplicationInfo;
begin
  FApplications.Clear;

  if not TFile.Exists(GetApplicationsFile) then
    Exit;

  JSONText := TFile.ReadAllText(GetApplicationsFile, TEncoding.UTF8);
  JSONArray := TJSONObject.ParseJSONValue(JSONText) as TJSONArray;

  if Assigned(JSONArray) then
  try
    for I := 0 to JSONArray.Count - 1 do
    begin
      JSONObj := JSONArray.Items[I] as TJSONObject;
      App.FromJSON(JSONObj);
      FApplications.Add(App);
    end;
  finally
    JSONArray.Free;
  end;
end;

procedure TDataManager.LoadDistributors;
var
  JSONText: string;
  JSONArray: TJSONArray;
  JSONObj: TJSONObject;
  I: Integer;
  Dist: TDistributorInfo;
begin
  FDistributors.Clear;

  if not TFile.Exists(GetDistributorsFile) then
    Exit;

  JSONText := TFile.ReadAllText(GetDistributorsFile, TEncoding.UTF8);
  JSONArray := TJSONObject.ParseJSONValue(JSONText) as TJSONArray;

  if Assigned(JSONArray) then
  try
    for I := 0 to JSONArray.Count - 1 do
    begin
      JSONObj := JSONArray.Items[I] as TJSONObject;
      Dist.FromJSON(JSONObj);
      FDistributors.Add(Dist);
    end;
  finally
    JSONArray.Free;
  end;
end;

procedure TDataManager.LoadLicenseRecords;
var
  JSONText: string;
  JSONArray: TJSONArray;
  JSONObj: TJSONObject;
  I: Integer;
  Rec: TLicenseRecord;
begin
  FLicenseRecords.Clear;

  if not TFile.Exists(GetLicenseRecordsFile) then
    Exit;

  JSONText := TFile.ReadAllText(GetLicenseRecordsFile, TEncoding.UTF8);
  JSONArray := TJSONObject.ParseJSONValue(JSONText) as TJSONArray;

  if Assigned(JSONArray) then
  try
    for I := 0 to JSONArray.Count - 1 do
    begin
      JSONObj := JSONArray.Items[I] as TJSONObject;
      Rec.FromJSON(JSONObj);
      FLicenseRecords.Add(Rec);
    end;
  finally
    JSONArray.Free;
  end;
end;

procedure TDataManager.SaveApplications;
var
  JSONArray: TJSONArray;
  App: TApplicationInfo;
begin
  JSONArray := TJSONArray.Create;
  try
    for App in FApplications do
      JSONArray.AddElement(App.ToJSON);

    TFile.WriteAllText(GetApplicationsFile, JSONArray.ToString, TEncoding.UTF8);
  finally
    JSONArray.Free;
  end;
end;

procedure TDataManager.SaveDistributors;
var
  JSONArray: TJSONArray;
  Dist: TDistributorInfo;
begin
  JSONArray := TJSONArray.Create;
  try
    for Dist in FDistributors do
      JSONArray.AddElement(Dist.ToJSON);

    TFile.WriteAllText(GetDistributorsFile, JSONArray.ToString, TEncoding.UTF8);
  finally
    JSONArray.Free;
  end;
end;

procedure TDataManager.SaveLicenseRecords;
var
  JSONArray: TJSONArray;
  Rec: TLicenseRecord;
begin
  JSONArray := TJSONArray.Create;
  try
    for Rec in FLicenseRecords do
      JSONArray.AddElement(Rec.ToJSON);

    TFile.WriteAllText(GetLicenseRecordsFile, JSONArray.ToString, TEncoding.UTF8);
  finally
    JSONArray.Free;
  end;
end;

function TDataManager.AddApplication(const AName, ADescription,
  AVersion: string): Integer;
var
  App: TApplicationInfo;
  MaxID: Integer;
  ExistingApp: TApplicationInfo;
begin
  MaxID := 0;
  for ExistingApp in FApplications do
    if ExistingApp.ID > MaxID then
      MaxID := ExistingApp.ID;

  App.ID := MaxID + 1;
  App.Name := AName;
  App.Description := ADescription;
  App.CurrentVersion := AVersion;
  App.CreatedDate := Now;

  FApplications.Add(App);
  SaveApplications;

  Result := App.ID;
end;

procedure TDataManager.UpdateApplication(const AApp: TApplicationInfo);
var
  I: Integer;
begin
  for I := 0 to FApplications.Count - 1 do
  begin
    if FApplications[I].ID = AApp.ID then
    begin
      FApplications[I] := AApp;
      SaveApplications;
      Exit;
    end;
  end;
end;

procedure TDataManager.DeleteApplication(AID: Integer);
var
  I: Integer;
begin
  for I := FApplications.Count - 1 downto 0 do
  begin
    if FApplications[I].ID = AID then
    begin
      FApplications.Delete(I);
      SaveApplications;
      Exit;
    end;
  end;
end;

function TDataManager.GetApplication(AID: Integer): TApplicationInfo;
var
  App: TApplicationInfo;
begin
  for App in FApplications do
  begin
    if App.ID = AID then
      Exit(App);
  end;

  raise Exception.CreateFmt('Application with ID %d not found', [AID]);
end;

function TDataManager.GetApplicationByName(const AName: string): TApplicationInfo;
var
  App: TApplicationInfo;
begin
  for App in FApplications do
  begin
    if SameText(App.Name, AName) then
      Exit(App);
  end;

  raise Exception.CreateFmt('Application "%s" not found', [AName]);
end;

function TDataManager.GetAllApplications: TArray<TApplicationInfo>;
begin
  Result := FApplications.ToArray;
end;

function TDataManager.AddDistributor(const AName, AEmail, APhone,
  AAddress: string): Integer;
var
  Dist: TDistributorInfo;
  MaxID: Integer;
  ExistingDist: TDistributorInfo;
begin
  MaxID := 0;
  for ExistingDist in FDistributors do
    if ExistingDist.ID > MaxID then
      MaxID := ExistingDist.ID;

  Dist.ID := MaxID + 1;
  Dist.Name := AName;
  Dist.SerialNumber := GenerateDistributorSerial;
  Dist.ContactEmail := AEmail;
  Dist.ContactPhone := APhone;
  Dist.Address := AAddress;
  Dist.Active := True;
  Dist.CreatedDate := Now;

  FDistributors.Add(Dist);
  SaveDistributors;

  Result := Dist.ID;
end;

procedure TDataManager.UpdateDistributor(const ADist: TDistributorInfo);
var
  I: Integer;
begin
  for I := 0 to FDistributors.Count - 1 do
  begin
    if FDistributors[I].ID = ADist.ID then
    begin
      FDistributors[I] := ADist;
      SaveDistributors;
      Exit;
    end;
  end;
end;

procedure TDataManager.DeleteDistributor(AID: Integer);
var
  I: Integer;
begin
  for I := FDistributors.Count - 1 downto 0 do
  begin
    if FDistributors[I].ID = AID then
    begin
      FDistributors.Delete(I);
      SaveDistributors;
      Exit;
    end;
  end;
end;

function TDataManager.GetDistributor(AID: Integer): TDistributorInfo;
var
  Dist: TDistributorInfo;
begin
  for Dist in FDistributors do
  begin
    if Dist.ID = AID then
      Exit(Dist);
  end;

  raise Exception.CreateFmt('Distributor with ID %d not found', [AID]);
end;

function TDataManager.GetDistributorBySerial(const ASerial: string): TDistributorInfo;
var
  Dist: TDistributorInfo;
begin
  for Dist in FDistributors do
  begin
    if SameText(Dist.SerialNumber, ASerial) then
      Exit(Dist);
  end;

  raise Exception.CreateFmt('Distributor with serial "%s" not found', [ASerial]);
end;

function TDataManager.GetAllDistributors: TArray<TDistributorInfo>;
begin
  Result := FDistributors.ToArray;
end;

function TDataManager.GenerateDistributorSerial: string;
var
  Part1, Part2, Part3, Part4: string;
begin
  // Generate serial in format: XXXX-XXXX-XXXX-XXXX
  Part1 := Copy(TLGEncryption.GenerateUniqueID, 1, 4).ToUpper;
  Part2 := Copy(TLGEncryption.GenerateUniqueID, 1, 4).ToUpper;
  Part3 := Copy(TLGEncryption.GenerateUniqueID, 1, 4).ToUpper;
  Part4 := Copy(TLGEncryption.GenerateUniqueID, 1, 4).ToUpper;

  Result := Format('%s-%s-%s-%s', [Part1, Part2, Part3, Part4]);
end;

procedure TDataManager.AddLicenseRecord(const ARecord: TLicenseRecord);
begin
  FLicenseRecords.Add(ARecord);
  SaveLicenseRecords;
end;

function TDataManager.GetLicenseRecord(const ASerial: string): TLicenseRecord;
var
  Rec: TLicenseRecord;
begin
  for Rec in FLicenseRecords do
  begin
    if SameText(Rec.LicenseSerial, ASerial) then
      Exit(Rec);
  end;

  raise Exception.CreateFmt('License record with serial "%s" not found', [ASerial]);
end;

function TDataManager.GetAllLicenseRecords: TArray<TLicenseRecord>;
begin
  Result := FLicenseRecords.ToArray;
end;

function TDataManager.GetLicenseRecordsByClient(
  const AClientName: string): TArray<TLicenseRecord>;
var
  List: TList<TLicenseRecord>;
  Rec: TLicenseRecord;
begin
  List := TList<TLicenseRecord>.Create;
  try
    for Rec in FLicenseRecords do
    begin
      if SameText(Rec.ClientName, AClientName) or
         SameText(Rec.ClientCompany, AClientName) then
        List.Add(Rec);
    end;

    Result := List.ToArray;
  finally
    List.Free;
  end;
end;

procedure TDataManager.RefreshData;
begin
  LoadApplications;
  LoadDistributors;
  LoadLicenseRecords;
end;

end.
