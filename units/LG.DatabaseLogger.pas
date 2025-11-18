unit LG.DatabaseLogger;

interface

uses
  System.SysUtils, System.Classes, System.JSON,
  LG.Database;

type
  TLogLevel = (llDebug, llInfo, llWarning, llError);
  TLogCategory = (lcLicense, lcApplication, lcDistributor, lcValidation, lcSystem);

  TLGDatabaseLogger = class
  private
    FDatabase: TLGDatabase;
    FMinLogLevel: TLogLevel;
    function LogLevelToString(ALevel: TLogLevel): string;
    function LogCategoryToString(ACategory: TLogCategory): string;
    function GetCurrentTimestamp: string;
  public
    constructor Create(ADatabase: TLGDatabase);

    // Métodos de logging
    procedure Log(ALevel: TLogLevel; ACategory: TLogCategory; const AMessage: string); overload;
    procedure Log(ALevel: TLogLevel; ACategory: TLogCategory; const AMessage: string;
      const ADetails: TJSONObject); overload;
    procedure Log(ALevel: TLogLevel; ACategory: TLogCategory; const AMessage: string;
      const ADetails: TJSONObject; const AUserAction: string); overload;
    procedure LogError(ACategory: TLogCategory; const AMessage: string;
      E: Exception); overload;
    procedure LogError(ACategory: TLogCategory; const AMessage: string;
      E: Exception; const AUserAction: string); overload;

    // Métodos de conveniencia
    procedure LogInfo(ACategory: TLogCategory; const AMessage: string); overload;
    procedure LogInfo(ACategory: TLogCategory; const AMessage: string;
      const AUserAction: string); overload;
    procedure LogWarning(ACategory: TLogCategory; const AMessage: string); overload;
    procedure LogWarning(ACategory: TLogCategory; const AMessage: string;
      const AUserAction: string); overload;
    procedure LogDebug(ACategory: TLogCategory; const AMessage: string);

    // Configuración
    property MinLogLevel: TLogLevel read FMinLogLevel write FMinLogLevel;
  end;

implementation

uses
  System.DateUtils;

{ TLGDatabaseLogger }

constructor TLGDatabaseLogger.Create(ADatabase: TLGDatabase);
begin
  inherited Create;
  FDatabase := ADatabase;
  FMinLogLevel := llInfo; // Por defecto, no loguear debug
end;

function TLGDatabaseLogger.LogLevelToString(ALevel: TLogLevel): string;
begin
  case ALevel of
    llDebug: Result := 'DEBUG';
    llInfo: Result := 'INFO';
    llWarning: Result := 'WARNING';
    llError: Result := 'ERROR';
  else
    Result := 'UNKNOWN';
  end;
end;

function TLGDatabaseLogger.LogCategoryToString(ACategory: TLogCategory): string;
begin
  case ACategory of
    lcLicense: Result := 'LICENSE';
    lcApplication: Result := 'APPLICATION';
    lcDistributor: Result := 'DISTRIBUTOR';
    lcValidation: Result := 'VALIDATION';
    lcSystem: Result := 'SYSTEM';
  else
    Result := 'UNKNOWN';
  end;
end;

function TLGDatabaseLogger.GetCurrentTimestamp: string;
begin
  Result := FormatDateTime('yyyy-mm-dd hh:nn:ss', Now);
end;

procedure TLGDatabaseLogger.Log(ALevel: TLogLevel; ACategory: TLogCategory;
  const AMessage: string);
begin
  Log(ALevel, ACategory, AMessage, nil, '');
end;

procedure TLGDatabaseLogger.Log(ALevel: TLogLevel; ACategory: TLogCategory;
  const AMessage: string; const ADetails: TJSONObject);
begin
  Log(ALevel, ACategory, AMessage, ADetails, '');
end;

procedure TLGDatabaseLogger.Log(ALevel: TLogLevel; ACategory: TLogCategory;
  const AMessage: string; const ADetails: TJSONObject; const AUserAction: string);
var
  SQL: string;
  DetailsStr: string;
  SafeMessage: string;
  SafeUserAction: string;
begin
  // No loguear si el nivel es menor al mínimo configurado
  if ALevel < FMinLogLevel then
    Exit;

  if not FDatabase.IsConnected then
    Exit;

  // Escapar comillas simples para SQL
  SafeMessage := StringReplace(AMessage, '''', '''''', [rfReplaceAll]);
  SafeUserAction := StringReplace(AUserAction, '''', '''''', [rfReplaceAll]);

  if Assigned(ADetails) then
    DetailsStr := StringReplace(ADetails.ToJSON, '''', '''''', [rfReplaceAll])
  else
    DetailsStr := '';

  SQL := Format(
    'INSERT INTO activity_log (timestamp, log_level, category, message, details, user_action) ' +
    'VALUES (''%s'', ''%s'', ''%s'', ''%s'', ''%s'', ''%s'')',
    [GetCurrentTimestamp, LogLevelToString(ALevel), LogCategoryToString(ACategory),
     SafeMessage, DetailsStr, SafeUserAction]
  );

  try
    FDatabase.ExecuteSQL(SQL);
  except
    // Si falla el log, no queremos que afecte la operación principal
    // En producción, podríamos escribir a un archivo de log alternativo
  end;
end;

procedure TLGDatabaseLogger.LogError(ACategory: TLogCategory;
  const AMessage: string; E: Exception);
begin
  LogError(ACategory, AMessage, E, '');
end;

procedure TLGDatabaseLogger.LogError(ACategory: TLogCategory;
  const AMessage: string; E: Exception; const AUserAction: string);
var
  SQL: string;
  SafeMessage: string;
  SafeExceptionMsg: string;
  SafeUserAction: string;
  SafeStackTrace: string;
begin
  if not FDatabase.IsConnected then
    Exit;

  // Escapar comillas simples para SQL
  SafeMessage := StringReplace(AMessage, '''', '''''', [rfReplaceAll]);
  SafeExceptionMsg := StringReplace(E.Message, '''', '''''', [rfReplaceAll]);
  SafeUserAction := StringReplace(AUserAction, '''', '''''', [rfReplaceAll]);
  SafeStackTrace := StringReplace(E.StackTrace, '''', '''''', [rfReplaceAll]);

  SQL := Format(
    'INSERT INTO activity_log (timestamp, log_level, category, message, details, user_action, error_code, stack_trace) ' +
    'VALUES (''%s'', ''ERROR'', ''%s'', ''%s'', ''%s'', ''%s'', ''%s'', ''%s'')',
    [GetCurrentTimestamp, LogCategoryToString(ACategory), SafeMessage,
     SafeExceptionMsg, SafeUserAction, E.ClassName, SafeStackTrace]
  );

  try
    FDatabase.ExecuteSQL(SQL);
  except
    // Si falla el log, no queremos que afecte la operación principal
  end;
end;

procedure TLGDatabaseLogger.LogInfo(ACategory: TLogCategory; const AMessage: string);
begin
  Log(llInfo, ACategory, AMessage);
end;

procedure TLGDatabaseLogger.LogInfo(ACategory: TLogCategory; const AMessage: string;
  const AUserAction: string);
begin
  Log(llInfo, ACategory, AMessage, nil, AUserAction);
end;

procedure TLGDatabaseLogger.LogWarning(ACategory: TLogCategory; const AMessage: string);
begin
  Log(llWarning, ACategory, AMessage);
end;

procedure TLGDatabaseLogger.LogWarning(ACategory: TLogCategory; const AMessage: string;
  const AUserAction: string);
begin
  Log(llWarning, ACategory, AMessage, nil, AUserAction);
end;

procedure TLGDatabaseLogger.LogDebug(ACategory: TLogCategory; const AMessage: string);
begin
  Log(llDebug, ACategory, AMessage);
end;

end.
