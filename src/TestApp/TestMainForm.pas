unit TestMainForm;

{
  LicenseGuard - License Tester Main Form
  Main form for testing license validation
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.ComCtrls, LG.LicenseValidator, LG.LicenseData, LG.HardwareInfo;

type
  TFormLicenseTester = class(TForm)
    pnlTop: TPanel;
    lblTitle: TLabel;
    pnlMain: TPanel;
    grpLicenseFile: TGroupBox;
    edtLicensePath: TEdit;
    btnBrowse: TButton;
    btnLoadLicense: TButton;
    grpLicenseInfo: TGroupBox;
    memoLicenseInfo: TMemo;
    grpValidation: TGroupBox;
    lblValidationStatus: TLabel;
    lblStatus: TLabel;
    lblDaysRemaining: TLabel;
    lblDaysValue: TLabel;
    grpHardwareInfo: TGroupBox;
    memoHardwareInfo: TMemo;
    btnRefreshHardware: TButton;
    grpFeatureTest: TGroupBox;
    btnTestBasicFeature: TButton;
    btnTestFullFeature: TButton;
    btnTestCustomFeature: TButton;
    edtCustomFeature: TEdit;
    lblCustomFeature: TLabel;
    OpenDialog1: TOpenDialog;
    pnlBottom: TPanel;
    btnClearAll: TButton;
    btnExit: TButton;
    StatusBar1: TStatusBar;
    grpApplicationInfo: TGroupBox;
    lblAppName: TLabel;
    edtAppName: TEdit;
    lblAppVersion: TLabel;
    edtAppVersion: TEdit;
    btnSetAppInfo: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnBrowseClick(Sender: TObject);
    procedure btnLoadLicenseClick(Sender: TObject);
    procedure btnRefreshHardwareClick(Sender: TObject);
    procedure btnTestBasicFeatureClick(Sender: TObject);
    procedure btnTestFullFeatureClick(Sender: TObject);
    procedure btnTestCustomFeatureClick(Sender: TObject);
    procedure btnClearAllClick(Sender: TObject);
    procedure btnExitClick(Sender: TObject);
    procedure btnSetAppInfoClick(Sender: TObject);
  private
    FValidator: TLicenseValidator;
    FApplicationName: string;
    FApplicationVersion: string;
    procedure UpdateHardwareInfo;
    procedure UpdateLicenseInfo;
    procedure UpdateValidationStatus;
    procedure ClearLicenseInfo;
    function CheckFeatureAccess(const AFeatureName: string): Boolean;
  public
    { Public declarations }
  end;

var
  FormLicenseTester: TFormLicenseTester;

implementation

{$R *.dfm}

procedure TFormLicenseTester.FormCreate(Sender: TObject);
begin
  // Create validator with default master key
  FValidator := TLicenseValidator.Create('DefaultMasterKey2024!@#$');
  
  // Default application info
  FApplicationName := 'Test Application';
  FApplicationVersion := '1.0.0';
  edtAppName.Text := FApplicationName;
  edtAppVersion.Text := FApplicationVersion;
  
  // Update hardware info on startup
  UpdateHardwareInfo;
  
  // Clear license info
  ClearLicenseInfo;
  
  StatusBar1.SimpleText := 'Ready - No license loaded';
end;

procedure TFormLicenseTester.FormDestroy(Sender: TObject);
begin
  FValidator.Free;
end;

procedure TFormLicenseTester.btnBrowseClick(Sender: TObject);
begin
  OpenDialog1.Filter := 'License Files (*.zip)|*.zip|All Files (*.*)|*.*';
  OpenDialog1.Title := 'Select License File';
  
  if OpenDialog1.Execute then
  begin
    edtLicensePath.Text := OpenDialog1.FileName;
  end;
end;

procedure TFormLicenseTester.btnLoadLicenseClick(Sender: TObject);
var
  LicensePath: string;
  ValidationResult: TValidationResult;
begin
  LicensePath := Trim(edtLicensePath.Text);
  
  if LicensePath = '' then
  begin
    ShowMessage('Please select a license file first.');
    Exit;
  end;
  
  if not FileExists(LicensePath) then
  begin
    ShowMessage('License file not found: ' + LicensePath);
    Exit;
  end;
  
  try
    Screen.Cursor := crHourGlass;
    try
      // Load the license from ZIP (control file path can be empty for auto-detection)
      ValidationResult := FValidator.LoadLicenseFromZip(
        LicensePath,
        ''  // Empty string for control file path (auto-detect)
      );
      
      // Check if it's valid for this application
      if ValidationResult.IsValid then
      begin
        if not FValidator.IsValidForApplication(FApplicationName, FApplicationVersion) then
        begin
          ValidationResult := TValidationResult.Failure('Application name or version mismatch');
        end;
      end;
      
      // Update UI with results
      UpdateLicenseInfo;
      UpdateValidationStatus;
      
      if ValidationResult.IsValid then
      begin
        StatusBar1.SimpleText := 'License loaded successfully - VALID';
        ShowMessage('License validated successfully!' + sLineBreak + sLineBreak +
                   'Client: ' + FValidator.LicenseData.ClientName);
      end
      else
      begin
        StatusBar1.SimpleText := 'License loaded - INVALID: ' + ValidationResult.ErrorMessage;
        ShowMessage('License validation failed!' + sLineBreak + sLineBreak +
                   'Error: ' + ValidationResult.ErrorMessage);
      end;
      
      if ValidationResult.WarningMessage <> '' then
      begin
        ShowMessage('Warning: ' + ValidationResult.WarningMessage);
      end;
      
    finally
      Screen.Cursor := crDefault;
    end;
  except
    on E: Exception do
    begin
      ShowMessage('Error loading license: ' + E.Message);
      StatusBar1.SimpleText := 'Error loading license';
    end;
  end;
end;

procedure TFormLicenseTester.btnRefreshHardwareClick(Sender: TObject);
begin
  UpdateHardwareInfo;
  ShowMessage('Hardware information refreshed.');
end;

procedure TFormLicenseTester.btnSetAppInfoClick(Sender: TObject);
begin
  FApplicationName := Trim(edtAppName.Text);
  FApplicationVersion := Trim(edtAppVersion.Text);
  
  if (FApplicationName = '') or (FApplicationVersion = '') then
  begin
    ShowMessage('Please enter both application name and version.');
    Exit;
  end;
  
  ShowMessage('Application info updated:' + sLineBreak +
             'Name: ' + FApplicationName + sLineBreak +
             'Version: ' + FApplicationVersion + sLineBreak + sLineBreak +
             'Reload the license to validate with new settings.');
  
  StatusBar1.SimpleText := 'Application info updated - Reload license to validate';
end;

procedure TFormLicenseTester.btnTestBasicFeatureClick(Sender: TObject);
begin
  if CheckFeatureAccess('BasicFeatures') then
    ShowMessage('✓ Basic Feature Access: GRANTED' + sLineBreak + sLineBreak +
               'This feature is available with your current license.')
  else
    ShowMessage('✗ Basic Feature Access: DENIED' + sLineBreak + sLineBreak +
               'Please load a valid license to access this feature.');
end;

procedure TFormLicenseTester.btnTestFullFeatureClick(Sender: TObject);
begin
  if CheckFeatureAccess('FullFeatures') then
    ShowMessage('✓ Full Feature Access: GRANTED' + sLineBreak + sLineBreak +
               'All features are available with your current license.')
  else
    ShowMessage('✗ Full Feature Access: DENIED' + sLineBreak + sLineBreak +
               'This feature requires a full license. ' +
               'You may have a trial or demo license.');
end;

procedure TFormLicenseTester.btnTestCustomFeatureClick(Sender: TObject);
var
  FeatureName: string;
begin
  FeatureName := Trim(edtCustomFeature.Text);
  
  if FeatureName = '' then
  begin
    ShowMessage('Please enter a feature name to test.');
    Exit;
  end;
  
  if CheckFeatureAccess(FeatureName) then
    ShowMessage('✓ Feature "' + FeatureName + '": GRANTED' + sLineBreak + sLineBreak +
               'This feature is available with your current license.')
  else
    ShowMessage('✗ Feature "' + FeatureName + '": DENIED' + sLineBreak + sLineBreak +
               'This feature is not available with your current license.');
end;

procedure TFormLicenseTester.btnClearAllClick(Sender: TObject);
begin
  if MessageDlg('Clear all license information?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    edtLicensePath.Text := '';
    ClearLicenseInfo;
    StatusBar1.SimpleText := 'Ready - No license loaded';
  end;
end;

procedure TFormLicenseTester.btnExitClick(Sender: TObject);
begin
  Close;
end;

procedure TFormLicenseTester.UpdateHardwareInfo;
begin
  // Use the public GetHardwareInfoString method
  memoHardwareInfo.Lines.Text := THardwareInfo.GetHardwareInfoString;
end;

procedure TFormLicenseTester.UpdateLicenseInfo;
begin
  if Assigned(FValidator.LicenseData) then
  begin
    memoLicenseInfo.Lines.Text := FValidator.GetLicenseInfo;
  end
  else
  begin
    memoLicenseInfo.Lines.Clear;
    memoLicenseInfo.Lines.Add('No license loaded');
  end;
end;

procedure TFormLicenseTester.UpdateValidationStatus;
var
  ValidationResult: TValidationResult;
begin
  if Assigned(FValidator.LicenseData) then
  begin
    ValidationResult := FValidator.Validate;
    
    if ValidationResult.IsValid then
    begin
      lblStatus.Caption := 'VALID';
      lblStatus.Font.Color := clGreen;
      lblStatus.Font.Style := [fsBold];
    end
    else
    begin
      lblStatus.Caption := 'INVALID';
      lblStatus.Font.Color := clRed;
      lblStatus.Font.Style := [fsBold];
    end;
    
    if ValidationResult.DaysUntilExpiration > 0 then
      lblDaysValue.Caption := IntToStr(ValidationResult.DaysUntilExpiration) + ' days'
    else if ValidationResult.DaysUntilExpiration = 0 then
      lblDaysValue.Caption := 'Expires today'
    else if ValidationResult.DaysUntilExpiration = MaxInt then
      lblDaysValue.Caption := 'Never (Perpetual)'
    else
      lblDaysValue.Caption := 'Expired';
  end
  else
  begin
    lblStatus.Caption := 'NO LICENSE';
    lblStatus.Font.Color := clGray;
    lblStatus.Font.Style := [];
    lblDaysValue.Caption := 'N/A';
  end;
end;

procedure TFormLicenseTester.ClearLicenseInfo;
begin
  memoLicenseInfo.Lines.Clear;
  memoLicenseInfo.Lines.Add('No license loaded');
  lblStatus.Caption := 'NO LICENSE';
  lblStatus.Font.Color := clGray;
  lblStatus.Font.Style := [];
  lblDaysValue.Caption := 'N/A';
end;

function TFormLicenseTester.CheckFeatureAccess(const AFeatureName: string): Boolean;
var
  ValidationResult: TValidationResult;
begin
  Result := False;
  
  if not Assigned(FValidator.LicenseData) then
  begin
    Exit;
  end;
  
  ValidationResult := FValidator.Validate;
  
  if not ValidationResult.IsValid then
  begin
    Exit;
  end;
  
  // Check feature based on license type
  case FValidator.LicenseData.LicenseType of
    ltFull:
      Result := True; // Full license has access to all features
      
    ltTrial:
      begin
        // Trial has limited features
        if (AFeatureName = 'BasicFeatures') or (AFeatureName = 'Trial') then
          Result := True;
      end;
      
    ltDemo:
      begin
        // Demo has basic features only
        if AFeatureName = 'BasicFeatures' then
          Result := True;
      end;
  end;
  
  // Check custom fields for specific feature flags
  if FValidator.LicenseData.CustomFields.ContainsKey(AFeatureName) then
  begin
    Result := FValidator.LicenseData.CustomFields[AFeatureName] = 'true';
  end;
end;

end.
