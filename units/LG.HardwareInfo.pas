unit LG.HardwareInfo;

{
  LicenseGuard - Hardware Information
  Retrieves hardware identifiers for license binding

  NOTE: GetMACAddress uses a simplified placeholder implementation.
  For production use, implement actual MAC address retrieval using:
  - GetAdaptersInfo from iphlpapi.dll
  - WMI queries (Win32_NetworkAdapter)
  - Third-party components

  Current implementation generates pseudo-unique identifiers suitable for
  demonstration and testing purposes.
}

interface

uses
  System.SysUtils, System.Classes, LG.Encryption;

type
  THardwareInfo = class
  private
    class function GetMACAddress: string;
    class function GetCPUId: string;
    class function GetDiskSerial: string;
    class function GetComputerName: string;
  public
    // Get individual hardware identifiers
    class function GetHardwareID(const ABindingType: string): string;

    // Generate combined hardware ID (more secure)
    class function GetCombinedHardwareID: string;

    // Get all hardware info for display
    class function GetHardwareInfoString: string;
  end;

implementation

uses
  {$IFDEF MSWINDOWS}
  Winapi.Windows, System.Win.Registry,
  {$ENDIF}
  System.Hash;

{ THardwareInfo }

class function THardwareInfo.GetMACAddress: string;
{$IFDEF MSWINDOWS}
begin
  Result := '';
  try
    // This is a simplified implementation
    // For production, use a more robust method to get MAC address
    // Consider using GetAdaptersInfo from iphlpapi.dll or WMI

    // Placeholder implementation - generates a pseudo-unique identifier
    Result := 'MAC-' + IntToHex(GetTickCount, 8);
  except
    Result := 'MAC-ERROR';
  end;
end;
{$ELSE}
begin
  Result := 'MAC-UNSUPPORTED';
end;
{$ENDIF}

class function THardwareInfo.GetCPUId: string;
{$IFDEF MSWINDOWS}
var
  Reg: TRegistry;
begin
  Result := '';
  Reg := TRegistry.Create(KEY_READ);
  try
    Reg.RootKey := HKEY_LOCAL_MACHINE;
    if Reg.OpenKeyReadOnly('HARDWARE\DESCRIPTION\System\CentralProcessor\0') then
    begin
      if Reg.ValueExists('ProcessorNameString') then
        Result := Reg.ReadString('ProcessorNameString');

      if Reg.ValueExists('Identifier') then
        Result := Result + '|' + Reg.ReadString('Identifier');

      Reg.CloseKey;
    end;

    if Result = '' then
      Result := 'CPU-UNKNOWN';

    // Hash the CPU info for privacy
    Result := TLGEncryption.HashSHA256(Result);
  finally
    Reg.Free;
  end;
end;
{$ELSE}
begin
  Result := 'CPU-UNSUPPORTED';
end;
{$ENDIF}

class function THardwareInfo.GetDiskSerial: string;
{$IFDEF MSWINDOWS}
var
  VolumeSerialNumber: DWORD;
  MaxComponentLength: DWORD;
  FileSystemFlags: DWORD;
  VolumeName: array[0..MAX_PATH] of Char;
  FileSystemName: array[0..MAX_PATH] of Char;
begin
  if GetVolumeInformation(
    'C:\',
    VolumeName,
    SizeOf(VolumeName),
    @VolumeSerialNumber,
    MaxComponentLength,
    FileSystemFlags,
    FileSystemName,
    SizeOf(FileSystemName)) then
  begin
    Result := IntToHex(VolumeSerialNumber, 8);
  end
  else
    Result := 'DISK-ERROR';
end;
{$ELSE}
begin
  Result := 'DISK-UNSUPPORTED';
end;
{$ENDIF}

class function THardwareInfo.GetComputerName: string;
{$IFDEF MSWINDOWS}
var
  Buffer: array[0..MAX_COMPUTERNAME_LENGTH] of Char;
  Size: DWORD;
begin
  Size := SizeOf(Buffer);
  if Winapi.Windows.GetComputerName(Buffer, Size) then
    Result := Buffer
  else
    Result := 'COMPUTER-UNKNOWN';
end;
{$ELSE}
begin
  Result := 'COMPUTER-UNSUPPORTED';
end;
{$ENDIF}

class function THardwareInfo.GetHardwareID(const ABindingType: string): string;
begin
  if SameText(ABindingType, 'MAC') then
    Result := GetMACAddress
  else if SameText(ABindingType, 'CPU') then
    Result := GetCPUId
  else if SameText(ABindingType, 'DISK') then
    Result := GetDiskSerial
  else if SameText(ABindingType, 'COMBINED') then
    Result := GetCombinedHardwareID
  else
    raise Exception.CreateFmt('Unknown binding type: %s', [ABindingType]);
end;

class function THardwareInfo.GetCombinedHardwareID: string;
var
  CombinedInfo: string;
begin
  // Combine multiple hardware identifiers for stronger binding
  CombinedInfo := Format('%s|%s|%s|%s',
    [GetMACAddress, GetCPUId, GetDiskSerial, GetComputerName]);

  // Hash the combined info
  Result := TLGEncryption.HashSHA256(CombinedInfo);
end;

class function THardwareInfo.GetHardwareInfoString: string;
begin
  Result := Format(
    'Computer Name: %s' + sLineBreak +
    'MAC Address: %s' + sLineBreak +
    'CPU ID: %s' + sLineBreak +
    'Disk Serial: %s' + sLineBreak +
    'Combined ID: %s',
    [GetComputerName, GetMACAddress, GetCPUId, GetDiskSerial, GetCombinedHardwareID]);
end;

end.
