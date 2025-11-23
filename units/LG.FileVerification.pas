unit LG.FileVerification;

{
  LicenseGuard - File Verification Module
  Calculates and verifies SHA-256 hash of files for license binding

  Compatible with Delphi 10.3 Rio
}

interface

uses
  System.SysUtils, System.Classes, System.Hash, System.JSON;

type
  TFileVerificationInfo = record
    Enabled: Boolean;
    FileName: string;
    FileHash: string;      // SHA-256 hash of the file
    FileSize: Int64;
    Description: string;   // Optional description

    function ToJSON: TJSONObject;
    procedure FromJSON(AJSON: TJSONObject);
    class function Empty: TFileVerificationInfo; static;
  end;

  TFileVerificationHelper = class
  private
    class function GetFileSize(const AFileName: string): Int64;
  public
    // Calculate SHA-256 hash of a file
    class function CalculateFileHash(const AFileName: string): string;

    // Verify if a file matches expected hash
    class function VerifyFileHash(const AFileName, AExpectedHash: string): Boolean;

    // Get file information for verification
    class function GetFileInfo(const AFileName: string): TFileVerificationInfo;
  end;

implementation

uses
  System.IOUtils;

{ TFileVerificationInfo }

class function TFileVerificationInfo.Empty: TFileVerificationInfo;
begin
  Result.Enabled := False;
  Result.FileName := '';
  Result.FileHash := '';
  Result.FileSize := 0;
  Result.Description := '';
end;

function TFileVerificationInfo.ToJSON: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('Enabled', TJSONBool.Create(Enabled));
  Result.AddPair('FileName', FileName);
  Result.AddPair('FileHash', FileHash);
  Result.AddPair('FileSize', TJSONNumber.Create(FileSize));
  Result.AddPair('Description', Description);
end;

procedure TFileVerificationInfo.FromJSON(AJSON: TJSONObject);
var
  TempValue: TJSONValue;
  TempStr: string;
begin
  // Reset to default values
  Self := Empty;

  // Read Enabled
  TempValue := AJSON.GetValue('Enabled');
  if Assigned(TempValue) and (TempValue is TJSONBool) then
    Enabled := TJSONBool(TempValue).AsBoolean;

  // Read FileName
  TempValue := AJSON.GetValue('FileName');
  if Assigned(TempValue) then
  begin
    TempStr := TempValue.Value;
    if TempStr <> '' then
      FileName := TempStr;
  end;

  // Read FileHash
  TempValue := AJSON.GetValue('FileHash');
  if Assigned(TempValue) then
  begin
    TempStr := TempValue.Value;
    if TempStr <> '' then
      FileHash := TempStr;
  end;

  // Read FileSize
  TempValue := AJSON.GetValue('FileSize');
  if Assigned(TempValue) and (TempValue is TJSONNumber) then
    FileSize := TJSONNumber(TempValue).AsInt64;

  // Read Description
  TempValue := AJSON.GetValue('Description');
  if Assigned(TempValue) then
  begin
    TempStr := TempValue.Value;
    if TempStr <> '' then
      Description := TempStr;
  end;
end;

{ TFileVerificationHelper }

class function TFileVerificationHelper.GetFileSize(const AFileName: string): Int64;
var
  FileStream: TFileStream;
begin
  Result := 0;

  if not FileExists(AFileName) then
    Exit;

  try
    FileStream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
    try
      Result := FileStream.Size;
    finally
      FileStream.Free;
    end;
  except
    Result := 0;
  end;
end;

class function TFileVerificationHelper.CalculateFileHash(const AFileName: string): string;
var
  FileStream: TFileStream;
  HashSHA256: THashSHA2;
begin
  Result := '';

  if not FileExists(AFileName) then
    Exit;

  try
    FileStream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
    try
      HashSHA256 := THashSHA2.Create(THashSHA2.TSHA2Version.SHA256);
      Result := HashSHA256.GetHashString(FileStream);
    finally
      FileStream.Free;
    end;
  except
    on E: Exception do
      raise Exception.CreateFmt('Error calculating file hash: %s', [E.Message]);
  end;
end;

class function TFileVerificationHelper.VerifyFileHash(const AFileName, AExpectedHash: string): Boolean;
var
  CalculatedHash: string;
begin
  Result := False;

  if not FileExists(AFileName) then
    Exit;

  if Trim(AExpectedHash) = '' then
    Exit;

  try
    CalculatedHash := CalculateFileHash(AFileName);
    Result := SameText(CalculatedHash, AExpectedHash);
  except
    Result := False;
  end;
end;

class function TFileVerificationHelper.GetFileInfo(const AFileName: string): TFileVerificationInfo;
begin
  Result := TFileVerificationInfo.Empty;

  if not FileExists(AFileName) then
    Exit;

  try
    Result.Enabled := True;
    Result.FileName := ExtractFileName(AFileName);
    Result.FileHash := CalculateFileHash(AFileName);
    Result.FileSize := GetFileSize(AFileName);
  except
    on E: Exception do
      raise Exception.CreateFmt('Error getting file info: %s', [E.Message]);
  end;
end;

end.
