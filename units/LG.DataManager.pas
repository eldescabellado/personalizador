unit LG.DataManager;

{
  LicenseGuard - Data Manager
  Manages applications, distributors, and license records
  Uses database storage (SQLite/PostgreSQL) with logging
}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  FireDAC.Comp.Client, LG.LicenseData, LG.Database, LG.DatabaseLogger;

type
  // License record for history
  TLicenseRecord = record
    ID: Integer;
    LicenseSerial: string;
    ClientName: string;
    ClientCompany: string;
    ContactEmail: string;
    ApplicationName: string;
    ApplicationVersion: string;
    DistributorName: string;
    DistributorSerial: string;
    CreatedDate: TDateTime;
    ExpirationDate: TDateTime;
    LicenseType: TLicenseType;
    HardwareBindingType: THardwareBindingType;
    HardwareID: string;
    DemoExpiresDate: TDateTime;
    ControlFileHash: string;
    FilePath: string;
  end;

  TDataManager = class
  private
    FDatabase: TLGDatabase;
    FLogger: TLGDatabaseLogger;
    FOwnDatabase: Boolean; // Si creamos la base de datos, la destruimos

    function LicenseTypeToString(ALicenseType: TLicenseType): string;
    function StringToLicenseType(const AStr: string): TLicenseType;
    function HardwareBindingTypeToString(ABindingType: THardwareBindingType): string;
    function StringToHardwareBindingType(const AStr: string): THardwareBindingType;
  public
    constructor Create(ADatabase: TLGDatabase; ALogger: TLGDatabaseLogger); overload;
    constructor Create; overload; // Crea su propia base de datos
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
    procedure RefreshData; // Mantener compatibilidad, pero no hace nada con DB

    property Database: TLGDatabase read FDatabase;
    property Logger: TLGDatabaseLogger read FLogger;
  end;

implementation

uses
  LG.Encryption, System.DateUtils;

{ TDataManager }

constructor TDataManager.Create(ADatabase: TLGDatabase; ALogger: TLGDatabaseLogger);
begin
  inherited Create;
  FDatabase := ADatabase;
  FLogger := ALogger;
  FOwnDatabase := False;
end;

constructor TDataManager.Create;
begin
  inherited Create;
  FDatabase := TLGDatabase.Create;
  FDatabase.Connect(FDatabase.GetDefaultConfig);
  FLogger := TLGDatabaseLogger.Create(FDatabase);
  FOwnDatabase := True;

  FLogger.LogInfo(lcSystem, 'DataManager initialized with own database');
end;

destructor TDataManager.Destroy;
begin
  if FOwnDatabase then
  begin
    FLogger.Free;
    FDatabase.Free;
  end;
  inherited;
end;

function TDataManager.LicenseTypeToString(ALicenseType: TLicenseType): string;
begin
  case ALicenseType of
    ltFull: Result := 'Full';
    ltDemo: Result := 'Demo';
    ltTrial: Result := 'Trial';
  else
    Result := 'Unknown';
  end;
end;

function TDataManager.StringToLicenseType(const AStr: string): TLicenseType;
begin
  if SameText(AStr, 'Full') then
    Result := ltFull
  else if SameText(AStr, 'Demo') then
    Result := ltDemo
  else if SameText(AStr, 'Trial') then
    Result := ltTrial
  else
    Result := ltFull; // Default
end;

function TDataManager.HardwareBindingTypeToString(ABindingType: THardwareBindingType): string;
begin
  case ABindingType of
    hbtNone: Result := 'None';
    hbtMAC: Result := 'MAC';
    hbtCPU: Result := 'CPU';
    hbtDisk: Result := 'Disk';
    hbtCombined: Result := 'Combined';
  else
    Result := 'None';
  end;
end;

function TDataManager.StringToHardwareBindingType(const AStr: string): THardwareBindingType;
begin
  if SameText(AStr, 'MAC') then
    Result := hbtMAC
  else if SameText(AStr, 'CPU') then
    Result := hbtCPU
  else if SameText(AStr, 'Disk') then
    Result := hbtDisk
  else if SameText(AStr, 'Combined') then
    Result := hbtCombined
  else
    Result := hbtNone;
end;

// Application management

function TDataManager.AddApplication(const AName, ADescription, AVersion: string): Integer;
var
  SQL: string;
  Query: TFDQuery;
  Timestamp: string;
  SafeName, SafeDesc, SafeVersion: string;
begin
  // Escapar comillas simples
  SafeName := StringReplace(AName, '''', '''''', [rfReplaceAll]);
  SafeDesc := StringReplace(ADescription, '''', '''''', [rfReplaceAll]);
  SafeVersion := StringReplace(AVersion, '''', '''''', [rfReplaceAll]);
  Timestamp := FormatDateTime('yyyy-mm-dd hh:nn:ss', Now);

  SQL := Format(
    'INSERT INTO applications (name, current_version, created_at, updated_at) ' +
    'VALUES (''%s'', ''%s'', ''%s'', ''%s'')',
    [SafeName, SafeVersion, Timestamp, Timestamp]
  );

  try
    FDatabase.ExecuteSQL(SQL);

    // Obtener el ID generado
    Query := FDatabase.ExecuteQuery('SELECT last_insert_rowid() as id');
    try
      if not Query.Eof then
        Result := Query.FieldByName('id').AsInteger
      else
        Result := -1;
    finally
      Query.Free;
    end;

    FLogger.LogInfo(lcApplication, Format('Application "%s" added with ID %d', [AName, Result]),
      'User added new application');
  except
    on E: Exception do
    begin
      FLogger.LogError(lcApplication, Format('Failed to add application "%s"', [AName]), E,
        'User attempted to add application');
      raise;
    end;
  end;
end;

procedure TDataManager.UpdateApplication(const AApp: TApplicationInfo);
var
  SQL: string;
  Timestamp: string;
  SafeName, SafeVersion: string;
begin
  SafeName := StringReplace(AApp.Name, '''', '''''', [rfReplaceAll]);
  SafeVersion := StringReplace(AApp.CurrentVersion, '''', '''''', [rfReplaceAll]);
  Timestamp := FormatDateTime('yyyy-mm-dd hh:nn:ss', Now);

  SQL := Format(
    'UPDATE applications SET name = ''%s'', current_version = ''%s'', updated_at = ''%s'' ' +
    'WHERE id = %d',
    [SafeName, SafeVersion, Timestamp, AApp.ID]
  );

  try
    FDatabase.ExecuteSQL(SQL);
    FLogger.LogInfo(lcApplication, Format('Application ID %d updated', [AApp.ID]),
      'User updated application');
  except
    on E: Exception do
    begin
      FLogger.LogError(lcApplication, Format('Failed to update application ID %d', [AApp.ID]), E);
      raise;
    end;
  end;
end;

procedure TDataManager.DeleteApplication(AID: Integer);
var
  SQL: string;
begin
  SQL := Format('DELETE FROM applications WHERE id = %d', [AID]);

  try
    FDatabase.ExecuteSQL(SQL);
    FLogger.LogInfo(lcApplication, Format('Application ID %d deleted', [AID]),
      'User deleted application');
  except
    on E: Exception do
    begin
      FLogger.LogError(lcApplication, Format('Failed to delete application ID %d', [AID]), E);
      raise;
    end;
  end;
end;

function TDataManager.GetApplication(AID: Integer): TApplicationInfo;
var
  SQL: string;
  Query: TFDQuery;
begin
  SQL := Format('SELECT * FROM applications WHERE id = %d', [AID]);
  Query := FDatabase.ExecuteQuery(SQL);
  try
    if Query.Eof then
      raise Exception.CreateFmt('Application with ID %d not found', [AID]);

    Result.ID := Query.FieldByName('id').AsInteger;
    Result.Name := Query.FieldByName('name').AsString;
    Result.CurrentVersion := Query.FieldByName('current_version').AsString;
    Result.Description := ''; // No guardado en DB por ahora
    Result.CreatedDate := StrToDateTime(Query.FieldByName('created_at').AsString);
  finally
    Query.Free;
  end;
end;

function TDataManager.GetApplicationByName(const AName: string): TApplicationInfo;
var
  SQL: string;
  Query: TFDQuery;
  SafeName: string;
begin
  SafeName := StringReplace(AName, '''', '''''', [rfReplaceAll]);
  SQL := Format('SELECT * FROM applications WHERE name = ''%s''', [SafeName]);
  Query := FDatabase.ExecuteQuery(SQL);
  try
    if Query.Eof then
      raise Exception.CreateFmt('Application "%s" not found', [AName]);

    Result.ID := Query.FieldByName('id').AsInteger;
    Result.Name := Query.FieldByName('name').AsString;
    Result.CurrentVersion := Query.FieldByName('current_version').AsString;
    Result.Description := '';
    Result.CreatedDate := StrToDateTime(Query.FieldByName('created_at').AsString);
  finally
    Query.Free;
  end;
end;

function TDataManager.GetAllApplications: TArray<TApplicationInfo>;
var
  SQL: string;
  Query: TFDQuery;
  List: TList<TApplicationInfo>;
  App: TApplicationInfo;
begin
  SQL := 'SELECT * FROM applications ORDER BY name';
  Query := FDatabase.ExecuteQuery(SQL);
  List := TList<TApplicationInfo>.Create;
  try
    while not Query.Eof do
    begin
      App.ID := Query.FieldByName('id').AsInteger;
      App.Name := Query.FieldByName('name').AsString;
      App.CurrentVersion := Query.FieldByName('current_version').AsString;
      App.Description := '';
      App.CreatedDate := StrToDateTime(Query.FieldByName('created_at').AsString);

      List.Add(App);
      Query.Next;
    end;

    Result := List.ToArray;
  finally
    List.Free;
    Query.Free;
  end;
end;

// Distributor management

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

function TDataManager.AddDistributor(const AName, AEmail, APhone, AAddress: string): Integer;
var
  SQL: string;
  Query: TFDQuery;
  Timestamp: string;
  Serial: string;
  SafeName, SafeEmail, SafePhone, SafeAddress, SafeSerial: string;
  ContactInfo: string;
begin
  Serial := GenerateDistributorSerial;

  // Escapar comillas simples
  SafeName := StringReplace(AName, '''', '''''', [rfReplaceAll]);
  SafeSerial := StringReplace(Serial, '''', '''''', [rfReplaceAll]);
  SafeEmail := StringReplace(AEmail, '''', '''''', [rfReplaceAll]);
  SafePhone := StringReplace(APhone, '''', '''''', [rfReplaceAll]);
  SafeAddress := StringReplace(AAddress, '''', '''''', [rfReplaceAll]);

  ContactInfo := Format('Email: %s, Phone: %s, Address: %s', [SafeEmail, SafePhone, SafeAddress]);
  Timestamp := FormatDateTime('yyyy-mm-dd hh:nn:ss', Now);

  SQL := Format(
    'INSERT INTO distributors (name, serial_number, contact_info, active, created_at, updated_at) ' +
    'VALUES (''%s'', ''%s'', ''%s'', 1, ''%s'', ''%s'')',
    [SafeName, SafeSerial, ContactInfo, Timestamp, Timestamp]
  );

  try
    FDatabase.ExecuteSQL(SQL);

    // Obtener el ID generado
    Query := FDatabase.ExecuteQuery('SELECT last_insert_rowid() as id');
    try
      if not Query.Eof then
        Result := Query.FieldByName('id').AsInteger
      else
        Result := -1;
    finally
      Query.Free;
    end;

    FLogger.LogInfo(lcDistributor,
      Format('Distributor "%s" added with serial %s', [AName, Serial]),
      'User added new distributor');
  except
    on E: Exception do
    begin
      FLogger.LogError(lcDistributor, Format('Failed to add distributor "%s"', [AName]), E);
      raise;
    end;
  end;
end;

procedure TDataManager.UpdateDistributor(const ADist: TDistributorInfo);
var
  SQL: string;
  Timestamp: string;
  SafeName, SafeSerial: string;
  ActiveInt: Integer;
  ContactInfo: string;
begin
  SafeName := StringReplace(ADist.Name, '''', '''''', [rfReplaceAll]);
  SafeSerial := StringReplace(ADist.SerialNumber, '''', '''''', [rfReplaceAll]);
  ContactInfo := Format('Email: %s, Phone: %s, Address: %s',
    [StringReplace(ADist.ContactEmail, '''', '''''', [rfReplaceAll]),
     StringReplace(ADist.ContactPhone, '''', '''''', [rfReplaceAll]),
     StringReplace(ADist.Address, '''', '''''', [rfReplaceAll])]);
  Timestamp := FormatDateTime('yyyy-mm-dd hh:nn:ss', Now);

  if ADist.Active then
    ActiveInt := 1
  else
    ActiveInt := 0;

  SQL := Format(
    'UPDATE distributors SET name = ''%s'', serial_number = ''%s'', ' +
    'contact_info = ''%s'', active = %d, updated_at = ''%s'' ' +
    'WHERE id = %d',
    [SafeName, SafeSerial, ContactInfo, ActiveInt, Timestamp, ADist.ID]
  );

  try
    FDatabase.ExecuteSQL(SQL);
    FLogger.LogInfo(lcDistributor, Format('Distributor ID %d updated', [ADist.ID]));
  except
    on E: Exception do
    begin
      FLogger.LogError(lcDistributor, Format('Failed to update distributor ID %d', [ADist.ID]), E);
      raise;
    end;
  end;
end;

procedure TDataManager.DeleteDistributor(AID: Integer);
var
  SQL: string;
begin
  SQL := Format('DELETE FROM distributors WHERE id = %d', [AID]);

  try
    FDatabase.ExecuteSQL(SQL);
    FLogger.LogInfo(lcDistributor, Format('Distributor ID %d deleted', [AID]));
  except
    on E: Exception do
    begin
      FLogger.LogError(lcDistributor, Format('Failed to delete distributor ID %d', [AID]), E);
      raise;
    end;
  end;
end;

function TDataManager.GetDistributor(AID: Integer): TDistributorInfo;
var
  SQL: string;
  Query: TFDQuery;
begin
  SQL := Format('SELECT * FROM distributors WHERE id = %d', [AID]);
  Query := FDatabase.ExecuteQuery(SQL);
  try
    if Query.Eof then
      raise Exception.CreateFmt('Distributor with ID %d not found', [AID]);

    Result.ID := Query.FieldByName('id').AsInteger;
    Result.Name := Query.FieldByName('name').AsString;
    Result.SerialNumber := Query.FieldByName('serial_number').AsString;
    Result.Active := Query.FieldByName('active').AsInteger = 1;
    Result.CreatedDate := StrToDateTime(Query.FieldByName('created_at').AsString);
    // contact_info está en formato texto, por ahora lo dejamos vacío
    Result.ContactEmail := '';
    Result.ContactPhone := '';
    Result.Address := '';
  finally
    Query.Free;
  end;
end;

function TDataManager.GetDistributorBySerial(const ASerial: string): TDistributorInfo;
var
  SQL: string;
  Query: TFDQuery;
  SafeSerial: string;
begin
  SafeSerial := StringReplace(ASerial, '''', '''''', [rfReplaceAll]);
  SQL := Format('SELECT * FROM distributors WHERE serial_number = ''%s''', [SafeSerial]);
  Query := FDatabase.ExecuteQuery(SQL);
  try
    if Query.Eof then
      raise Exception.CreateFmt('Distributor with serial "%s" not found', [ASerial]);

    Result.ID := Query.FieldByName('id').AsInteger;
    Result.Name := Query.FieldByName('name').AsString;
    Result.SerialNumber := Query.FieldByName('serial_number').AsString;
    Result.Active := Query.FieldByName('active').AsInteger = 1;
    Result.CreatedDate := StrToDateTime(Query.FieldByName('created_at').AsString);
    Result.ContactEmail := '';
    Result.ContactPhone := '';
    Result.Address := '';
  finally
    Query.Free;
  end;
end;

function TDataManager.GetAllDistributors: TArray<TDistributorInfo>;
var
  SQL: string;
  Query: TFDQuery;
  List: TList<TDistributorInfo>;
  Dist: TDistributorInfo;
begin
  SQL := 'SELECT * FROM distributors ORDER BY name';
  Query := FDatabase.ExecuteQuery(SQL);
  List := TList<TDistributorInfo>.Create;
  try
    while not Query.Eof do
    begin
      Dist.ID := Query.FieldByName('id').AsInteger;
      Dist.Name := Query.FieldByName('name').AsString;
      Dist.SerialNumber := Query.FieldByName('serial_number').AsString;
      Dist.Active := Query.FieldByName('active').AsInteger = 1;
      Dist.CreatedDate := StrToDateTime(Query.FieldByName('created_at').AsString);
      Dist.ContactEmail := '';
      Dist.ContactPhone := '';
      Dist.Address := '';

      List.Add(Dist);
      Query.Next;
    end;

    Result := List.ToArray;
  finally
    List.Free;
    Query.Free;
  end;
end;

// License record management

procedure TDataManager.AddLicenseRecord(const ARecord: TLicenseRecord);
var
  SQL: string;
  Timestamp: string;
  SafeCompany, SafeContact, SafeEmail, SafeApp, SafeAppVer, SafeDistSerial: string;
  SafeHardwareID, SafeHash, SafePath: string;
  LicenseTypeStr, HardwareTypeStr: string;
  ExpiresStr, DemoExpiresStr: string;
begin
  // Escapar comillas simples
  SafeCompany := StringReplace(ARecord.ClientCompany, '''', '''''', [rfReplaceAll]);
  SafeContact := StringReplace(ARecord.ClientName, '''', '''''', [rfReplaceAll]);
  SafeEmail := StringReplace(ARecord.ContactEmail, '''', '''''', [rfReplaceAll]);
  SafeApp := StringReplace(ARecord.ApplicationName, '''', '''''', [rfReplaceAll]);
  SafeAppVer := StringReplace(ARecord.ApplicationVersion, '''', '''''', [rfReplaceAll]);
  SafeDistSerial := StringReplace(ARecord.DistributorSerial, '''', '''''', [rfReplaceAll]);
  SafeHardwareID := StringReplace(ARecord.HardwareID, '''', '''''', [rfReplaceAll]);
  SafeHash := StringReplace(ARecord.ControlFileHash, '''', '''''', [rfReplaceAll]);
  SafePath := StringReplace(ARecord.FilePath, '''', '''''', [rfReplaceAll]);

  Timestamp := FormatDateTime('yyyy-mm-dd hh:nn:ss', ARecord.CreatedDate);
  LicenseTypeStr := LicenseTypeToString(ARecord.LicenseType);
  HardwareTypeStr := HardwareBindingTypeToString(ARecord.HardwareBindingType);

  if ARecord.ExpirationDate > 0 then
    ExpiresStr := FormatDateTime('yyyy-mm-dd hh:nn:ss', ARecord.ExpirationDate)
  else
    ExpiresStr := '';

  if ARecord.DemoExpiresDate > 0 then
    DemoExpiresStr := FormatDateTime('yyyy-mm-dd hh:nn:ss', ARecord.DemoExpiresDate)
  else
    DemoExpiresStr := '';

  SQL := Format(
    'INSERT INTO licenses (company_name, contact_name, contact_email, application_name, ' +
    'application_version, license_type, distributor_serial, expiration_date, ' +
    'hardware_binding_type, hardware_id, demo_expires_date, control_file_hash, ' +
    'zip_file_path, created_at) ' +
    'VALUES (''%s'', ''%s'', ''%s'', ''%s'', ''%s'', ''%s'', ''%s'', ''%s'', ''%s'', ''%s'', ''%s'', ''%s'', ''%s'', ''%s'')',
    [SafeCompany, SafeContact, SafeEmail, SafeApp, SafeAppVer, LicenseTypeStr, SafeDistSerial,
     ExpiresStr, HardwareTypeStr, SafeHardwareID, DemoExpiresStr, SafeHash, SafePath, Timestamp]
  );

  try
    FDatabase.ExecuteSQL(SQL);
    FLogger.LogInfo(lcLicense,
      Format('License for "%s" (%s) created', [ARecord.ClientCompany, ARecord.ApplicationName]),
      'User generated license');
  except
    on E: Exception do
    begin
      FLogger.LogError(lcLicense, 'Failed to add license record', E);
      raise;
    end;
  end;
end;

function TDataManager.GetLicenseRecord(const ASerial: string): TLicenseRecord;
var
  SQL: string;
  Query: TFDQuery;
  SafeSerial: string;
  TempStr: string;
begin
  SafeSerial := StringReplace(ASerial, '''', '''''', [rfReplaceAll]);
  SQL := Format('SELECT * FROM licenses WHERE company_name = ''%s'' LIMIT 1', [SafeSerial]);
  Query := FDatabase.ExecuteQuery(SQL);
  try
    if Query.Eof then
      raise Exception.CreateFmt('License record with serial "%s" not found', [ASerial]);

    Result.ID := Query.FieldByName('id').AsInteger;
    Result.ClientCompany := Query.FieldByName('company_name').AsString;
    Result.ClientName := Query.FieldByName('contact_name').AsString;
    Result.ContactEmail := Query.FieldByName('contact_email').AsString;
    Result.ApplicationName := Query.FieldByName('application_name').AsString;
    Result.ApplicationVersion := Query.FieldByName('application_version').AsString;
    Result.LicenseType := StringToLicenseType(Query.FieldByName('license_type').AsString);
    Result.DistributorSerial := Query.FieldByName('distributor_serial').AsString;
    Result.HardwareBindingType := StringToHardwareBindingType(
      Query.FieldByName('hardware_binding_type').AsString);
    Result.HardwareID := Query.FieldByName('hardware_id').AsString;
    Result.ControlFileHash := Query.FieldByName('control_file_hash').AsString;
    Result.FilePath := Query.FieldByName('zip_file_path').AsString;
    Result.CreatedDate := StrToDateTime(Query.FieldByName('created_at').AsString);

    TempStr := Query.FieldByName('expiration_date').AsString;
    if TempStr <> '' then
      Result.ExpirationDate := StrToDateTime(TempStr)
    else
      Result.ExpirationDate := 0;

    TempStr := Query.FieldByName('demo_expires_date').AsString;
    if TempStr <> '' then
      Result.DemoExpiresDate := StrToDateTime(TempStr)
    else
      Result.DemoExpiresDate := 0;

    // Usar DistributorSerial para buscar el nombre del distribuidor
    Result.DistributorName := '';
    if Result.DistributorSerial <> '' then
    begin
      try
        Result.DistributorName := GetDistributorBySerial(Result.DistributorSerial).Name;
      except
        // Ignorar si no se encuentra el distribuidor
      end;
    end;

    Result.LicenseSerial := ''; // No se guarda en DB
  finally
    Query.Free;
  end;
end;

function TDataManager.GetAllLicenseRecords: TArray<TLicenseRecord>;
var
  SQL: string;
  Query: TFDQuery;
  List: TList<TLicenseRecord>;
  Rec: TLicenseRecord;
  TempStr: string;
begin
  SQL := 'SELECT * FROM licenses ORDER BY created_at DESC';
  Query := FDatabase.ExecuteQuery(SQL);
  List := TList<TLicenseRecord>.Create;
  try
    while not Query.Eof do
    begin
      Rec.ID := Query.FieldByName('id').AsInteger;
      Rec.ClientCompany := Query.FieldByName('company_name').AsString;
      Rec.ClientName := Query.FieldByName('contact_name').AsString;
      Rec.ContactEmail := Query.FieldByName('contact_email').AsString;
      Rec.ApplicationName := Query.FieldByName('application_name').AsString;
      Rec.ApplicationVersion := Query.FieldByName('application_version').AsString;
      Rec.LicenseType := StringToLicenseType(Query.FieldByName('license_type').AsString);
      Rec.DistributorSerial := Query.FieldByName('distributor_serial').AsString;
      Rec.HardwareBindingType := StringToHardwareBindingType(
        Query.FieldByName('hardware_binding_type').AsString);
      Rec.HardwareID := Query.FieldByName('hardware_id').AsString;
      Rec.ControlFileHash := Query.FieldByName('control_file_hash').AsString;
      Rec.FilePath := Query.FieldByName('zip_file_path').AsString;
      Rec.CreatedDate := StrToDateTime(Query.FieldByName('created_at').AsString);

      TempStr := Query.FieldByName('expiration_date').AsString;
      if TempStr <> '' then
        Rec.ExpirationDate := StrToDateTime(TempStr)
      else
        Rec.ExpirationDate := 0;

      TempStr := Query.FieldByName('demo_expires_date').AsString;
      if TempStr <> '' then
        Rec.DemoExpiresDate := StrToDateTime(TempStr)
      else
        Rec.DemoExpiresDate := 0;

      // Usar DistributorSerial para buscar el nombre
      Rec.DistributorName := '';
      if Rec.DistributorSerial <> '' then
      begin
        try
          Rec.DistributorName := GetDistributorBySerial(Rec.DistributorSerial).Name;
        except
          // Ignorar si no se encuentra
        end;
      end;

      Rec.LicenseSerial := '';

      List.Add(Rec);
      Query.Next;
    end;

    Result := List.ToArray;
  finally
    List.Free;
    Query.Free;
  end;
end;

function TDataManager.GetLicenseRecordsByClient(const AClientName: string): TArray<TLicenseRecord>;
var
  SQL: string;
  Query: TFDQuery;
  List: TList<TLicenseRecord>;
  Rec: TLicenseRecord;
  TempStr: string;
  SafeClient: string;
begin
  SafeClient := StringReplace(AClientName, '''', '''''', [rfReplaceAll]);
  SQL := Format(
    'SELECT * FROM licenses WHERE company_name LIKE ''%%%s%%'' OR contact_name LIKE ''%%%s%%'' ' +
    'ORDER BY created_at DESC',
    [SafeClient, SafeClient]
  );

  Query := FDatabase.ExecuteQuery(SQL);
  List := TList<TLicenseRecord>.Create;
  try
    while not Query.Eof do
    begin
      Rec.ID := Query.FieldByName('id').AsInteger;
      Rec.ClientCompany := Query.FieldByName('company_name').AsString;
      Rec.ClientName := Query.FieldByName('contact_name').AsString;
      Rec.ContactEmail := Query.FieldByName('contact_email').AsString;
      Rec.ApplicationName := Query.FieldByName('application_name').AsString;
      Rec.ApplicationVersion := Query.FieldByName('application_version').AsString;
      Rec.LicenseType := StringToLicenseType(Query.FieldByName('license_type').AsString);
      Rec.DistributorSerial := Query.FieldByName('distributor_serial').AsString;
      Rec.HardwareBindingType := StringToHardwareBindingType(
        Query.FieldByName('hardware_binding_type').AsString);
      Rec.HardwareID := Query.FieldByName('hardware_id').AsString;
      Rec.ControlFileHash := Query.FieldByName('control_file_hash').AsString;
      Rec.FilePath := Query.FieldByName('zip_file_path').AsString;
      Rec.CreatedDate := StrToDateTime(Query.FieldByName('created_at').AsString);

      TempStr := Query.FieldByName('expiration_date').AsString;
      if TempStr <> '' then
        Rec.ExpirationDate := StrToDateTime(TempStr)
      else
        Rec.ExpirationDate := 0;

      TempStr := Query.FieldByName('demo_expires_date').AsString;
      if TempStr <> '' then
        Rec.DemoExpiresDate := StrToDateTime(TempStr)
      else
        Rec.DemoExpiresDate := 0;

      Rec.DistributorName := '';
      if Rec.DistributorSerial <> '' then
      begin
        try
          Rec.DistributorName := GetDistributorBySerial(Rec.DistributorSerial).Name;
        except
        end;
      end;

      Rec.LicenseSerial := '';

      List.Add(Rec);
      Query.Next;
    end;

    Result := List.ToArray;
  finally
    List.Free;
    Query.Free;
  end;
end;

procedure TDataManager.RefreshData;
begin
  // Con base de datos, no es necesario recargar datos
  // Los datos siempre están frescos en las queries
end;

end.
