unit LG.Database;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils,
  FireDAC.Comp.Client, FireDAC.Stan.Def, FireDAC.Stan.Async,
  FireDAC.Phys, FireDAC.Phys.SQLite, FireDAC.Phys.PG,
  FireDAC.Stan.Param, FireDAC.DatS, FireDAC.DApt;

type
  TDatabaseType = (dtSQLite, dtPostgreSQL);

  TDatabaseConfig = record
    DatabaseType: TDatabaseType;
    // SQLite
    SQLiteFilePath: string;
    // PostgreSQL
    PGHost: string;
    PGPort: Integer;
    PGDatabase: string;
    PGUsername: string;
    PGPassword: string;
  end;

  TLGDatabase = class
  private
    FConnection: TFDConnection;
    FConfig: TDatabaseConfig;
    FConnected: Boolean;
    procedure ConfigureSQLite;
    procedure ConfigurePostgreSQL;
    procedure InitializeSchema;
    function GetSchemaSQL: string;
  public
    constructor Create;
    destructor Destroy; override;

    // Conexión
    procedure Connect(const AConfig: TDatabaseConfig);
    procedure Disconnect;
    function IsConnected: Boolean;

    // Configuración
    procedure SaveConfig(const AConfig: TDatabaseConfig);
    function LoadConfig: TDatabaseConfig;
    function GetDefaultConfig: TDatabaseConfig;

    // Operaciones de base de datos
    function ExecuteSQL(const ASQL: string): Integer;
    function ExecuteQuery(const ASQL: string): TFDQuery;
    procedure BeginTransaction;
    procedure Commit;
    procedure Rollback;
    function InTransaction: Boolean;

    // Propiedades
    property Connection: TFDConnection read FConnection;
    property Config: TDatabaseConfig read FConfig;
    property Connected: Boolean read FConnected;
  end;

implementation

uses
  System.IniFiles;

{ TLGDatabase }

constructor TLGDatabase.Create;
begin
  inherited;
  FConnection := TFDConnection.Create(nil);
  FConnected := False;
end;

destructor TLGDatabase.Destroy;
begin
  if FConnected then
    Disconnect;
  FConnection.Free;
  inherited;
end;

procedure TLGDatabase.Connect(const AConfig: TDatabaseConfig);
begin
  if FConnected then
    Disconnect;

  FConfig := AConfig;

  case FConfig.DatabaseType of
    dtSQLite: ConfigureSQLite;
    dtPostgreSQL: ConfigurePostgreSQL;
  end;

  try
    FConnection.Connected := True;
    FConnected := True;
    InitializeSchema;
  except
    on E: Exception do
    begin
      FConnected := False;
      raise Exception.Create('Error al conectar a la base de datos: ' + E.Message);
    end;
  end;
end;

procedure TLGDatabase.Disconnect;
begin
  if FConnected then
  begin
    if InTransaction then
      Rollback;
    FConnection.Connected := False;
    FConnected := False;
  end;
end;

function TLGDatabase.IsConnected: Boolean;
begin
  Result := FConnected and FConnection.Connected;
end;

procedure TLGDatabase.ConfigureSQLite;
var
  DBPath: string;
begin
  FConnection.DriverName := 'SQLite';

  // Asegurar que el directorio existe
  if FConfig.SQLiteFilePath = '' then
    FConfig.SQLiteFilePath := TPath.Combine(ExtractFilePath(ParamStr(0)), 'licenseguard.db');

  DBPath := ExtractFilePath(FConfig.SQLiteFilePath);
  if not TDirectory.Exists(DBPath) then
    TDirectory.CreateDirectory(DBPath);

  FConnection.Params.Clear;
  FConnection.Params.Add('Database=' + FConfig.SQLiteFilePath);
  FConnection.Params.Add('LockingMode=Normal');
  FConnection.Params.Add('Synchronous=FULL');
  FConnection.Params.Add('JournalMode=WAL');
  FConnection.Params.Add('ForeignKeys=ON');
end;

procedure TLGDatabase.ConfigurePostgreSQL;
begin
  FConnection.DriverName := 'PG';

  FConnection.Params.Clear;
  FConnection.Params.Add('Server=' + FConfig.PGHost);
  FConnection.Params.Add('Port=' + IntToStr(FConfig.PGPort));
  FConnection.Params.Add('Database=' + FConfig.PGDatabase);
  FConnection.Params.Add('User_Name=' + FConfig.PGUsername);
  FConnection.Params.Add('Password=' + FConfig.PGPassword);
  FConnection.Params.Add('CharacterSet=UTF8');
end;

function TLGDatabase.GetSchemaSQL: string;
begin
  // Usar el esquema compatible con ambas bases de datos
  Result :=
    'CREATE TABLE IF NOT EXISTS applications (' +
    '  id INTEGER PRIMARY KEY AUTOINCREMENT,' +
    '  name TEXT NOT NULL UNIQUE,' +
    '  current_version TEXT NOT NULL,' +
    '  created_at TEXT NOT NULL,' +
    '  updated_at TEXT NOT NULL' +
    ');' + sLineBreak +

    'CREATE TABLE IF NOT EXISTS distributors (' +
    '  id INTEGER PRIMARY KEY AUTOINCREMENT,' +
    '  name TEXT NOT NULL,' +
    '  serial_number TEXT NOT NULL UNIQUE,' +
    '  contact_info TEXT,' +
    '  active INTEGER NOT NULL DEFAULT 1,' +
    '  created_at TEXT NOT NULL,' +
    '  updated_at TEXT NOT NULL' +
    ');' + sLineBreak +

    'CREATE TABLE IF NOT EXISTS licenses (' +
    '  id INTEGER PRIMARY KEY AUTOINCREMENT,' +
    '  company_name TEXT NOT NULL,' +
    '  contact_name TEXT,' +
    '  contact_email TEXT,' +
    '  application_name TEXT NOT NULL,' +
    '  application_version TEXT NOT NULL,' +
    '  license_type TEXT NOT NULL,' +
    '  distributor_serial TEXT,' +
    '  expiration_date TEXT,' +
    '  hardware_binding_type TEXT,' +
    '  hardware_id TEXT,' +
    '  demo_expires_date TEXT,' +
    '  control_file_hash TEXT,' +
    '  zip_file_path TEXT,' +
    '  created_at TEXT NOT NULL,' +
    '  FOREIGN KEY (distributor_serial) REFERENCES distributors(serial_number)' +
    ');' + sLineBreak +

    'CREATE TABLE IF NOT EXISTS activity_log (' +
    '  id INTEGER PRIMARY KEY AUTOINCREMENT,' +
    '  timestamp TEXT NOT NULL,' +
    '  log_level TEXT NOT NULL,' +
    '  category TEXT NOT NULL,' +
    '  message TEXT NOT NULL,' +
    '  details TEXT,' +
    '  user_action TEXT,' +
    '  error_code TEXT,' +
    '  stack_trace TEXT' +
    ');' + sLineBreak +

    'CREATE INDEX IF NOT EXISTS idx_licenses_company ON licenses(company_name);' + sLineBreak +
    'CREATE INDEX IF NOT EXISTS idx_licenses_app ON licenses(application_name);' + sLineBreak +
    'CREATE INDEX IF NOT EXISTS idx_licenses_created ON licenses(created_at);' + sLineBreak +
    'CREATE INDEX IF NOT EXISTS idx_activity_log_timestamp ON activity_log(timestamp);' + sLineBreak +
    'CREATE INDEX IF NOT EXISTS idx_activity_log_level ON activity_log(log_level);' + sLineBreak +
    'CREATE INDEX IF NOT EXISTS idx_activity_log_category ON activity_log(category);';
end;

procedure TLGDatabase.InitializeSchema;
var
  SQL: string;
  SQLList: TStringList;
  I: Integer;
begin
  if not FConnected then
    Exit;

  SQL := GetSchemaSQL;
  SQLList := TStringList.Create;
  try
    SQLList.Text := StringReplace(SQL, ';', sLineBreak, [rfReplaceAll]);

    BeginTransaction;
    try
      for I := 0 to SQLList.Count - 1 do
      begin
        if Trim(SQLList[I]) <> '' then
          ExecuteSQL(Trim(SQLList[I]));
      end;
      Commit;
    except
      Rollback;
      raise;
    end;
  finally
    SQLList.Free;
  end;
end;

function TLGDatabase.ExecuteSQL(const ASQL: string): Integer;
begin
  Result := FConnection.ExecSQL(ASQL);
end;

function TLGDatabase.ExecuteQuery(const ASQL: string): TFDQuery;
begin
  Result := TFDQuery.Create(nil);
  Result.Connection := FConnection;
  Result.SQL.Text := ASQL;
  Result.Open;
end;

procedure TLGDatabase.BeginTransaction;
begin
  if not InTransaction then
    FConnection.StartTransaction;
end;

procedure TLGDatabase.Commit;
begin
  if InTransaction then
    FConnection.Commit;
end;

procedure TLGDatabase.Rollback;
begin
  if InTransaction then
    FConnection.Rollback;
end;

function TLGDatabase.InTransaction: Boolean;
begin
  Result := FConnection.InTransaction;
end;

procedure TLGDatabase.SaveConfig(const AConfig: TDatabaseConfig);
var
  IniFile: TIniFile;
  ConfigPath: string;
begin
  ConfigPath := TPath.Combine(ExtractFilePath(ParamStr(0)), 'licenseguard.ini');
  IniFile := TIniFile.Create(ConfigPath);
  try
    case AConfig.DatabaseType of
      dtSQLite:
        IniFile.WriteString('Database', 'Type', 'SQLite');
      dtPostgreSQL:
        IniFile.WriteString('Database', 'Type', 'PostgreSQL');
    end;

    // SQLite
    IniFile.WriteString('SQLite', 'FilePath', AConfig.SQLiteFilePath);

    // PostgreSQL
    IniFile.WriteString('PostgreSQL', 'Host', AConfig.PGHost);
    IniFile.WriteInteger('PostgreSQL', 'Port', AConfig.PGPort);
    IniFile.WriteString('PostgreSQL', 'Database', AConfig.PGDatabase);
    IniFile.WriteString('PostgreSQL', 'Username', AConfig.PGUsername);
    IniFile.WriteString('PostgreSQL', 'Password', AConfig.PGPassword); // En producción, encriptar
  finally
    IniFile.Free;
  end;
end;

function TLGDatabase.LoadConfig: TDatabaseConfig;
var
  IniFile: TIniFile;
  ConfigPath: string;
  DBType: string;
begin
  ConfigPath := TPath.Combine(ExtractFilePath(ParamStr(0)), 'licenseguard.ini');

  if not TFile.Exists(ConfigPath) then
  begin
    Result := GetDefaultConfig;
    Exit;
  end;

  IniFile := TIniFile.Create(ConfigPath);
  try
    DBType := IniFile.ReadString('Database', 'Type', 'SQLite');

    if DBType = 'PostgreSQL' then
      Result.DatabaseType := dtPostgreSQL
    else
      Result.DatabaseType := dtSQLite;

    // SQLite
    Result.SQLiteFilePath := IniFile.ReadString('SQLite', 'FilePath',
      TPath.Combine(ExtractFilePath(ParamStr(0)), 'licenseguard.db'));

    // PostgreSQL
    Result.PGHost := IniFile.ReadString('PostgreSQL', 'Host', 'localhost');
    Result.PGPort := IniFile.ReadInteger('PostgreSQL', 'Port', 5432);
    Result.PGDatabase := IniFile.ReadString('PostgreSQL', 'Database', 'licenseguard');
    Result.PGUsername := IniFile.ReadString('PostgreSQL', 'Username', 'postgres');
    Result.PGPassword := IniFile.ReadString('PostgreSQL', 'Password', '');
  finally
    IniFile.Free;
  end;
end;

function TLGDatabase.GetDefaultConfig: TDatabaseConfig;
begin
  Result.DatabaseType := dtSQLite;
  Result.SQLiteFilePath := TPath.Combine(ExtractFilePath(ParamStr(0)), 'licenseguard.db');
  Result.PGHost := 'localhost';
  Result.PGPort := 5432;
  Result.PGDatabase := 'licenseguard';
  Result.PGUsername := 'postgres';
  Result.PGPassword := '';
end;

end.
