unit IntegrationExample;

{
  LicenseGuard - Integration Example
  Complete example of how to integrate LicenseGuard validation in your Delphi application

  INSTRUCTIONS:
  1. Copy this file to your project
  2. Copy required units (LG.*.pas) to your project
  3. Update MASTER_KEY constant
  4. Distribute premium.sis with your application
  5. Call ValidateLicense at application startup
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, System.IOUtils, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls,
  LG.LicenseValidator, LG.LicenseData, LG.HardwareInfo;

type
  TFormExample = class(TForm)
    PanelTop: TPanel;
    Label1: TLabel;
    lblLicenseStatus: TLabel;
    GroupBox1: TGroupBox;
    memoLicenseInfo: TMemo;
    GroupBox2: TGroupBox;
    btnLoadLicense: TButton;
    btnShowHardwareID: TButton;
    btnValidate: TButton;
    StatusBar1: TStatusBar;
    OpenDialog1: TOpenDialog;
    btnFeatureDemo: TButton;
    btnFeatureFull: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnLoadLicenseClick(Sender: TObject);
    procedure btnShowHardwareIDClick(Sender: TObject);
    procedure btnValidateClick(Sender: TObject);
    procedure btnFeatureDemoClick(Sender: TObject);
    procedure btnFeatureFullClick(Sender: TObject);
  private
    FValidator: TLicenseValidator;
    FLicensePath: string;
    FControlPath: string;

    function ValidateLicense: Boolean;
    procedure UpdateUI;
    procedure LoadLicenseConfig;
    procedure SaveLicenseConfig;
    function CheckFeatureAccess(const AFeatureName: string): Boolean;
  public
    { Public declarations }
  end;

var
  FormExample: TFormExample;

implementation

{$R *.dfm}

const
  // CRITICAL: Use the same master key that was used to generate licenses
  MASTER_KEY = 'YourSecureMasterKey-ChangeThis-MustBe32CharsOrMore';

  // Application information
  APP_NAME = 'MyApplication';
  APP_VERSION = '1.0.0';

{ TFormExample }

procedure TFormExample.FormCreate(Sender: TObject);
begin
  // Initialize paths
  FControlPath := TPath.Combine(ExtractFilePath(Application.ExeName), 'premium.sis');

  // Load license configuration
  LoadLicenseConfig;

  // Create validator
  FValidator := TLicenseValidator.Create(MASTER_KEY);
  FValidator.ApplicationVersion := APP_VERSION;

  // Try to load and validate license
  if (FLicensePath <> '') and FileExists(FLicensePath) then
  begin
    if ValidateLicense then
    begin
      UpdateUI;
      StatusBar1.SimpleText := 'License: Valid';
    end
    else
    begin
      StatusBar1.SimpleText := 'License: Invalid or Expired';
      ShowMessage('Please load a valid license file to continue.');
    end;
  end
  else
  begin
    StatusBar1.SimpleText := 'License: Not Loaded';
    ShowMessage('No license found. Please load a license file.');
  end;
end;

procedure TFormExample.FormDestroy(Sender: TObject);
begin
  SaveLicenseConfig;
  FValidator.Free;
end;

procedure TFormExample.LoadLicenseConfig;
var
  ConfigFile: string;
  Config: TStringList;
begin
  ConfigFile := TPath.Combine(ExtractFilePath(Application.ExeName), 'license.cfg');

  if not FileExists(ConfigFile) then
    Exit;

  Config := TStringList.Create;
  try
    Config.LoadFromFile(ConfigFile);
    if Config.Count > 0 then
      FLicensePath := Config[0];
  finally
    Config.Free;
  end;
end;

procedure TFormExample.SaveLicenseConfig;
var
  ConfigFile: string;
  Config: TStringList;
begin
  ConfigFile := TPath.Combine(ExtractFilePath(Application.ExeName), 'license.cfg');

  Config := TStringList.Create;
  try
    Config.Add(FLicensePath);
    Config.SaveToFile(ConfigFile);
  finally
    Config.Free;
  end;
end;

function TFormExample.ValidateLicense: Boolean;
var
  ValidationResult: TValidationResult;
begin
  Result := False;

  if not FileExists(FLicensePath) then
  begin
    ShowMessage('License file not found: ' + FLicensePath);
    Exit;
  end;

  if not FileExists(FControlPath) then
  begin
    ShowMessage('Control file not found: ' + FControlPath + #13#10 +
                'Please ensure premium.sis is in the application folder.');
    Exit;
  end;

  try
    // Load and validate license
    ValidationResult := FValidator.LoadLicenseFromZip(FLicensePath, FControlPath);

    if ValidationResult.IsValid then
    begin
      // Show warning if expiring soon
      if ValidationResult.WarningMessage <> '' then
        ShowMessage('Warning: ' + ValidationResult.WarningMessage);

      Result := True;
    end
    else
    begin
      ShowMessage('License Validation Failed:' + #13#10 + ValidationResult.ErrorMessage);
      Result := False;
    end;
  except
    on E: Exception do
    begin
      ShowMessage('Error validating license: ' + E.Message);
      Result := False;
    end;
  end;
end;

procedure TFormExample.UpdateUI;
var
  LicData: TLicenseData;
  Status: string;
begin
  if not Assigned(FValidator) then
    Exit;

  LicData := FValidator.LicenseData;

  // Update license status label
  if FValidator.ValidationResult.IsValid then
  begin
    lblLicenseStatus.Caption := 'Licensed to: ' + LicData.ClientName;
    lblLicenseStatus.Font.Color := clGreen;

    case LicData.LicenseType of
      ltFull: Status := 'Full License';
      ltDemo: Status := 'Demo License';
      ltTrial: Status := 'Trial License';
    end;
  end
  else
  begin
    lblLicenseStatus.Caption := 'No Valid License';
    lblLicenseStatus.Font.Color := clRed;
    Status := 'Invalid';
  end;

  // Update memo with detailed info
  memoLicenseInfo.Lines.Clear;
  memoLicenseInfo.Lines.Add('=== LICENSE INFORMATION ===');
  memoLicenseInfo.Lines.Add('');
  memoLicenseInfo.Lines.Add('Status: ' + Status);
  memoLicenseInfo.Lines.Add('Serial: ' + LicData.LicenseSerial);
  memoLicenseInfo.Lines.Add('Client: ' + LicData.ClientName);
  memoLicenseInfo.Lines.Add('Company: ' + LicData.ClientCompany);
  memoLicenseInfo.Lines.Add('Application: ' + LicData.ApplicationName);
  memoLicenseInfo.Lines.Add('Distributor: ' + LicData.DistributorName);
  memoLicenseInfo.Lines.Add('');

  if LicData.Expiration.HasExpiration then
  begin
    memoLicenseInfo.Lines.Add('Expires: ' + DateToStr(LicData.Expiration.ExpirationDate));
    memoLicenseInfo.Lines.Add('Days Until Expiration: ' + IntToStr(LicData.Expiration.DaysUntilExpiration));
  end
  else
    memoLicenseInfo.Lines.Add('Expires: Never');

  memoLicenseInfo.Lines.Add('');

  if LicData.HardwareBinding.Enabled then
  begin
    memoLicenseInfo.Lines.Add('Hardware Binding: Enabled');
    memoLicenseInfo.Lines.Add('Binding Type: ' + LicData.HardwareBinding.BindingType);
    memoLicenseInfo.Lines.Add('Hardware ID: ' + Copy(LicData.HardwareBinding.HardwareID, 1, 16) + '...');
  end
  else
    memoLicenseInfo.Lines.Add('Hardware Binding: Disabled');

  if LicData.Notes <> '' then
  begin
    memoLicenseInfo.Lines.Add('');
    memoLicenseInfo.Lines.Add('Notes: ' + LicData.Notes);
  end;

  // Update feature buttons based on license type
  btnFeatureFull.Enabled := CheckFeatureAccess('FullFeatures');
end;

procedure TFormExample.btnLoadLicenseClick(Sender: TObject);
begin
  OpenDialog1.Filter := 'License Files (*.zip)|*.zip';
  OpenDialog1.InitialDir := ExtractFilePath(Application.ExeName);

  if OpenDialog1.Execute then
  begin
    FLicensePath := OpenDialog1.FileName;

    if ValidateLicense then
    begin
      UpdateUI;
      SaveLicenseConfig;
      StatusBar1.SimpleText := 'License: Valid';
      ShowMessage('License loaded and validated successfully!');
    end
    else
    begin
      StatusBar1.SimpleText := 'License: Invalid';
      ShowMessage('Failed to validate license.');
    end;
  end;
end;

procedure TFormExample.btnShowHardwareIDClick(Sender: TObject);
var
  HwInfo: string;
begin
  HwInfo := THardwareInfo.GetHardwareInfoString;

  ShowMessage('Your Hardware Information:' + #13#10#13#10 + HwInfo + #13#10#13#10 +
              'Send this information to support to receive a hardware-locked license.');
end;

procedure TFormExample.btnValidateClick(Sender: TObject);
begin
  if not Assigned(FValidator) then
  begin
    ShowMessage('No validator initialized');
    Exit;
  end;

  if ValidateLicense then
  begin
    UpdateUI;
    ShowMessage('License is valid!');
  end;
end;

function TFormExample.CheckFeatureAccess(const AFeatureName: string): Boolean;
begin
  Result := False;

  if not Assigned(FValidator) then
    Exit;

  if not FValidator.ValidationResult.IsValid then
    Exit;

  // Demo licenses have limited features
  if FValidator.LicenseData.LicenseType = ltDemo then
  begin
    // Only basic features allowed in demo
    Result := AFeatureName = 'BasicFeatures';
    Exit;
  end;

  // Full license - all features enabled
  if FValidator.LicenseData.LicenseType = ltFull then
  begin
    Result := True;
    Exit;
  end;

  // Trial licenses - check expiration
  if FValidator.LicenseData.LicenseType = ltTrial then
  begin
    Result := not FValidator.LicenseData.Expiration.IsExpired;
  end;
end;

procedure TFormExample.btnFeatureDemoClick(Sender: TObject);
begin
  if CheckFeatureAccess('BasicFeatures') then
    ShowMessage('Basic feature executed!')
  else
    ShowMessage('This feature requires a valid license.');
end;

procedure TFormExample.btnFeatureFullClick(Sender: TObject);
begin
  if CheckFeatureAccess('FullFeatures') then
    ShowMessage('Full feature executed!')
  else
    ShowMessage('This feature is not available in demo version. Please upgrade to full license.');
end;

end.
