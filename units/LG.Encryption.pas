unit LG.Encryption;

{
  LicenseGuard - Encryption Module
  Implements AES-256 encryption with PBKDF2 key derivation

  Requirements:
  - Delphi 10.2 Tokyo or later (for System.Hash)
  - For production, consider using DCPcrypt or System.Crypto (Delphi 11+)

  This implementation uses:
  - AES-256 in CBC mode (simplified XOR for demo)
  - PBKDF2 for key derivation from master password
  - Random IV for each encryption
  - Random Salt for key derivation

  VERSION: 1.1.0 - Fixed encoding issues in Decrypt method
}

interface

uses
  System.SysUtils, System.Classes, System.Hash, System.NetEncoding;

type
  TLGEncryption = class
  private
    class function PBKDF2(const Password, Salt: TBytes; Iterations: Integer;
      KeyLength: Integer): TBytes;
    class function GenerateRandomBytes(Count: Integer): TBytes;
    class function XORBytes(const A, B: TBytes): TBytes;
  public
    // Main encryption/decryption methods
    class function Encrypt(const PlainText, MasterKey: string): string;
    class function Decrypt(const EncryptedText, MasterKey: string): string;

    // Encrypt/Decrypt with custom parameters
    class function EncryptBytes(const Data: TBytes; const Key: TBytes): TBytes;
    class function DecryptBytes(const Data: TBytes; const Key: TBytes): TBytes;

    // Utility methods
    class function GenerateSalt: TBytes;
    class function GenerateIV: TBytes;
    class function DeriveKey(const Password: string; const Salt: TBytes): TBytes;
    class function HashSHA256(const Data: string): string;
    class function GenerateUniqueID: string;

    // NEW: Validation helper
    class function IsValidBase64(const Text: string): Boolean;
  end;

  EEncryptionError = class(Exception);

const
  SALT_SIZE = 32;      // 256 bits
  IV_SIZE = 16;        // 128 bits (AES block size)
  KEY_SIZE = 32;       // 256 bits (AES-256)
  PBKDF2_ITERATIONS = 100000;

implementation

uses
  System.DateUtils;

{ TLGEncryption }

class function TLGEncryption.GenerateRandomBytes(Count: Integer): TBytes;
var
  I: Integer;
begin
  SetLength(Result, Count);
  Randomize;
  for I := 0 to Count - 1 do
    Result[I] := Random(256);
end;

class function TLGEncryption.GenerateSalt: TBytes;
begin
  Result := GenerateRandomBytes(SALT_SIZE);
end;

class function TLGEncryption.GenerateIV: TBytes;
begin
  Result := GenerateRandomBytes(IV_SIZE);
end;

class function TLGEncryption.PBKDF2(const Password, Salt: TBytes;
  Iterations: Integer; KeyLength: Integer): TBytes;
var
  I, J, K: Integer;
  U, F: TBytes;
  Hash: THashSHA2;
  Block: TBytes;
  BlockCount: Integer;
begin
  // Simple PBKDF2-HMAC-SHA256 implementation
  // For production, use a proper crypto library

  SetLength(Result, KeyLength);
  BlockCount := (KeyLength + 31) div 32;

  for I := 1 to BlockCount do
  begin
    // Initial U = PRF(Password, Salt || INT(i))
    SetLength(Block, Length(Salt) + 4);
    Move(Salt[0], Block[0], Length(Salt));
    Block[Length(Salt)] := (I shr 24) and $FF;
    Block[Length(Salt) + 1] := (I shr 16) and $FF;
    Block[Length(Salt) + 2] := (I shr 8) and $FF;
    Block[Length(Salt) + 3] := I and $FF;

    Hash := THashSHA2.Create(THashSHA2.TSHA2Version.SHA256);
    Hash.Update(Password);
    Hash.Update(Block);
    U := Hash.HashAsBytes;
    F := Copy(U);

    // Iterate
    for J := 2 to Iterations do
    begin
      Hash := THashSHA2.Create(THashSHA2.TSHA2Version.SHA256);
      Hash.Update(Password);
      Hash.Update(U);
      U := Hash.HashAsBytes;

      // XOR with F
      for K := 0 to Length(U) - 1 do
        F[K] := F[K] xor U[K];
    end;

    // Copy to result
    K := (I - 1) * 32;
    if K + 32 <= KeyLength then
      Move(F[0], Result[K], 32)
    else
      Move(F[0], Result[K], KeyLength - K);
  end;
end;

class function TLGEncryption.DeriveKey(const Password: string;
  const Salt: TBytes): TBytes;
var
  PasswordBytes: TBytes;
begin
  PasswordBytes := TEncoding.UTF8.GetBytes(Password);
  Result := PBKDF2(PasswordBytes, Salt, PBKDF2_ITERATIONS, KEY_SIZE);
end;

class function TLGEncryption.XORBytes(const A, B: TBytes): TBytes;
var
  I: Integer;
begin
  SetLength(Result, Length(A));
  for I := 0 to Length(A) - 1 do
    Result[I] := A[I] xor B[I mod Length(B)];
end;

class function TLGEncryption.EncryptBytes(const Data: TBytes;
  const Key: TBytes): TBytes;
var
  I, BlockCount: Integer;
  IV, Block, EncBlock, PrevBlock: TBytes;
  Padding: Byte;
  PaddedData: TBytes;
begin
  {
    NOTE: This is a SIMPLIFIED implementation for demonstration.
    For PRODUCTION use, please integrate a proper AES library such as:
    - DCPcrypt: https://sourceforge.net/projects/dcpcrypt/
    - LockBox3: https://github.com/TurboPack/LockBox3
    - System.Crypto (Delphi 11+)

    This implementation uses XOR as a placeholder.
    Replace with actual AES-256-CBC implementation.
  }

  // Generate random IV
  IV := GenerateIV;

  // Add PKCS7 padding
  Padding := 16 - (Length(Data) mod 16);
  if Padding = 0 then Padding := 16;

  SetLength(PaddedData, Length(Data) + Padding);
  if Length(Data) > 0 then
    Move(Data[0], PaddedData[0], Length(Data));
  for I := Length(Data) to Length(PaddedData) - 1 do
    PaddedData[I] := Padding;

  BlockCount := Length(PaddedData) div 16;
  SetLength(Result, IV_SIZE + Length(PaddedData));

  // Store IV at the beginning
  Move(IV[0], Result[0], IV_SIZE);

  PrevBlock := Copy(IV);

  // Encrypt each block (simplified - replace with real AES)
  for I := 0 to BlockCount - 1 do
  begin
    SetLength(Block, 16);
    Move(PaddedData[I * 16], Block[0], 16);

    // CBC mode: XOR with previous ciphertext block
    Block := XORBytes(Block, PrevBlock);

    // "Encrypt" with key (THIS SHOULD BE REAL AES-256)
    EncBlock := XORBytes(Block, Key);

    // Store encrypted block
    Move(EncBlock[0], Result[IV_SIZE + I * 16], 16);
    PrevBlock := Copy(EncBlock);
  end;
end;

class function TLGEncryption.DecryptBytes(const Data: TBytes;
  const Key: TBytes): TBytes;
var
  I, BlockCount: Integer;
  IV, Block, DecBlock, PrevBlock, CipherBlock: TBytes;
  Padding: Byte;
begin
  {
    NOTE: Simplified decryption - replace with real AES-256-CBC
  }

  if Length(Data) < IV_SIZE then
    raise EEncryptionError.Create('Invalid encrypted data: too short');

  if (Length(Data) - IV_SIZE) mod 16 <> 0 then
    raise EEncryptionError.Create('Invalid encrypted data: incorrect block size');

  // Extract IV
  SetLength(IV, IV_SIZE);
  Move(Data[0], IV[0], IV_SIZE);

  BlockCount := (Length(Data) - IV_SIZE) div 16;
  SetLength(Result, BlockCount * 16);

  PrevBlock := Copy(IV);

  // Decrypt each block
  for I := 0 to BlockCount - 1 do
  begin
    SetLength(CipherBlock, 16);
    Move(Data[IV_SIZE + I * 16], CipherBlock[0], 16);

    // "Decrypt" with key (THIS SHOULD BE REAL AES-256)
    DecBlock := XORBytes(CipherBlock, Key);

    // CBC mode: XOR with previous ciphertext block
    Block := XORBytes(DecBlock, PrevBlock);

    Move(Block[0], Result[I * 16], 16);
    PrevBlock := Copy(CipherBlock);
  end;

  // Remove PKCS7 padding
  if Length(Result) > 0 then
  begin
    Padding := Result[Length(Result) - 1];
    if (Padding > 0) and (Padding <= 16) then
    begin
      // Validate padding
      for I := Length(Result) - Integer(Padding) to Length(Result) - 1 do
      begin
        if Result[I] <> Padding then
          raise EEncryptionError.Create('Invalid padding detected - possible wrong key or corrupted data');
      end;
      SetLength(Result, Length(Result) - Padding);
    end;
  end;
end;

class function TLGEncryption.Encrypt(const PlainText, MasterKey: string): string;
var
  PlainBytes, Salt, Key, EncryptedBytes: TBytes;
  Output: TMemoryStream;
  Base64: TBase64Encoding;
begin
  if PlainText = '' then
    raise EEncryptionError.Create('PlainText cannot be empty');

  if MasterKey = '' then
    raise EEncryptionError.Create('MasterKey cannot be empty');

  // Generate random salt
  Salt := GenerateSalt;

  // Derive key from master password using PBKDF2
  Key := DeriveKey(MasterKey, Salt);

  // Convert plaintext to bytes
  PlainBytes := TEncoding.UTF8.GetBytes(PlainText);

  // Encrypt
  EncryptedBytes := EncryptBytes(PlainBytes, Key);

  // Format: [SALT][ENCRYPTED_DATA]
  Output := TMemoryStream.Create;
  try
    Output.Write(Salt[0], Length(Salt));
    Output.Write(EncryptedBytes[0], Length(EncryptedBytes));

    SetLength(EncryptedBytes, Output.Size);
    Output.Position := 0;
    Output.Read(EncryptedBytes[0], Output.Size);

    // Encode as Base64
    Base64 := TBase64Encoding.Create(0);
    try
      Result := Base64.EncodeBytesToString(EncryptedBytes);
    finally
      Base64.Free;
    end;
  finally
    Output.Free;
  end;
end;

class function TLGEncryption.Decrypt(const EncryptedText, MasterKey: string): string;
var
  EncryptedBytes, Salt, Key, CipherData, DecryptedBytes: TBytes;
  Base64: TBase64Encoding;
  TempStr: string;
  I: Integer;
  AllValid: Boolean;
begin
  if EncryptedText = '' then
    raise EEncryptionError.Create('EncryptedText cannot be empty');

  if MasterKey = '' then
    raise EEncryptionError.Create('MasterKey cannot be empty');

  // Validate Base64 format
  if not IsValidBase64(EncryptedText) then
    raise EEncryptionError.Create('Invalid Base64 format in encrypted data');

  // Decode from Base64
  Base64 := TBase64Encoding.Create(0);
  try
    try
      EncryptedBytes := Base64.DecodeStringToBytes(EncryptedText);
    except
      on E: Exception do
        raise EEncryptionError.Create('Failed to decode Base64: ' + E.Message);
    end;
  finally
    Base64.Free;
  end;

  if Length(EncryptedBytes) < SALT_SIZE then
    raise EEncryptionError.CreateFmt('Invalid encrypted data format: expected at least %d bytes, got %d',
      [SALT_SIZE, Length(EncryptedBytes)]);

  // Extract salt
  SetLength(Salt, SALT_SIZE);
  Move(EncryptedBytes[0], Salt[0], SALT_SIZE);

  // Extract cipher data
  SetLength(CipherData, Length(EncryptedBytes) - SALT_SIZE);
  if Length(CipherData) > 0 then
    Move(EncryptedBytes[SALT_SIZE], CipherData[0], Length(CipherData));

  // Derive key
  try
    Key := DeriveKey(MasterKey, Salt);
  except
    on E: Exception do
      raise EEncryptionError.Create('Failed to derive key: ' + E.Message);
  end;

  // Decrypt
  try
    DecryptedBytes := DecryptBytes(CipherData, Key);
  except
    on E: Exception do
      raise EEncryptionError.Create('Decryption failed (wrong key or corrupted data): ' + E.Message);
  end;

  // Convert to string with validation
  try
    // First, try to detect if it's valid UTF-8
    AllValid := True;
    for I := 0 to Length(DecryptedBytes) - 1 do
    begin
      // Check if byte is in printable ASCII range or valid UTF-8 continuation
      if not ((DecryptedBytes[I] >= 32) and (DecryptedBytes[I] <= 126)) and
         not ((DecryptedBytes[I] >= 128) and (DecryptedBytes[I] <= 255)) and
         (DecryptedBytes[I] <> 9) and  // Tab
         (DecryptedBytes[I] <> 10) and // LF
         (DecryptedBytes[I] <> 13) then // CR
      begin
        AllValid := False;
        Break;
      end;
    end;

    if not AllValid then
      raise EEncryptionError.Create('Decrypted data contains invalid characters - wrong master key?');

    Result := TEncoding.UTF8.GetString(DecryptedBytes);

    // Validate that the result looks like JSON (basic check)
    TempStr := Trim(Result);
    if (TempStr = '') or not ((TempStr[1] = '{') or (TempStr[1] = '[')) then
      raise EEncryptionError.Create('Decrypted data is not valid JSON format - wrong master key?');

  except
    on E: EEncodingError do
      raise EEncryptionError.Create('Failed to decode decrypted data as UTF-8 - wrong master key or corrupted data');
    on E: EEncryptionError do
      raise;
    on E: Exception do
      raise EEncryptionError.Create('Unexpected error converting decrypted data: ' + E.Message);
  end;
end;

class function TLGEncryption.IsValidBase64(const Text: string): Boolean;
const
  Base64Chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=';
var
  I: Integer;
begin
  Result := False;

  if Text = '' then
    Exit;

  // Check if all characters are valid Base64
  for I := 1 to Length(Text) do
  begin
    if Pos(Text[I], Base64Chars) = 0 then
      Exit;
  end;

  // Check length is multiple of 4
  if Length(Text) mod 4 <> 0 then
    Exit;

  Result := True;
end;

class function TLGEncryption.HashSHA256(const Data: string): string;
var
  Hash: THashSHA2;
begin
  Hash := THashSHA2.Create(THashSHA2.TSHA2Version.SHA256);
  Hash.Update(TEncoding.UTF8.GetBytes(Data));
  Result := Hash.HashAsString;
end;

class function TLGEncryption.GenerateUniqueID: string;
var
  GUID: TGUID;
begin
  CreateGUID(GUID);
  Result := GUIDToString(GUID).Replace('{', '').Replace('}', '').Replace('-', '');
end;

end.
