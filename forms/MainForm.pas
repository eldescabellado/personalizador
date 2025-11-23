unit MainForm;

{
  LicenseGuard - Main Form
  Integrated with File Verification functionality
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls,
  Vcl.ExtCtrls, System.IOUtils, Vcl.FileCtrl,
  LG.LicenseData, LG.DataManager, LG.LicenseGenerator, LG.Encryption, LG.HardwareInfo,
  LG.FileVerification;

type
  TFormMain = class(TForm)
    PageControl1: TPageControl;
    TabGenerate: TTabSheet;
    TabApplications: TTabSheet;
    TabDistributors: TTabSheet;
    TabHistory: TTabSheet;
    TabSettings: TTabSheet;
    GroupBox1: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label19: TLabel;
    edtClientName: TEdit;
    edtClientCompany: TEdit;
    cboApplication: TComboBox;
    cboDistributor: TComboBox;
    edtVersions: TEdit;
    chkExpires: TCheckBox;
    dtpExpiration: TDateTimePicker;
    chkHardwareBinding: TCheckBox;
    cboBindingType: TComboBox;
    edtHardwareID: TEdit;
    btnGetHardwareID: TButton;
    chkFileVerification: TCheckBox;
    edtVerificationFile: TEdit;
    btnBrowseVerificationFile: TButton;
    memoNotes: TMemo;
    btnGenerateLicense: TButton;
    btnGenerateDemo: TButton;
    GroupBox2: TGroupBox;
    memoLicenseInfo: TMemo;
    GroupBox3: TGroupBox;
    Label9: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    edtAppName: TEdit;
    edtAppDescription: TEdit;
    edtAppVersion: TEdit;
    btnAddApplication: TButton;
    btnUpdateApplication: TButton;
    btnDeleteApplication: TButton;
    lvApplications: TListView;
    GroupBox4: TGroupBox;
    Label12: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    edtDistName: TEdit;
    edtDistEmail: TEdit;
    edtDistPhone: TEdit;
    edtDistAddress: TEdit;
    edtDistSerial: TEdit;
    btnAddDistributor: TButton;
    btnUpdateDistributor: TButton;
    btnDeleteDistributor: TButton;
    lvDistributors: TListView;
    GroupBox5: TGroupBox;
    lvLicenseHistory: TListView;
    btnRefreshHistory: TButton;
    btnOpenLicenseFolder: TButton;
    GroupBox6: TGroupBox;
    Label17: TLabel;
    Label18: TLabel;
    edtMasterKey: TEdit;
    edtOutputPath: TEdit;
    btnBrowseOutput: TButton;
    btnSaveSettings: TButton;
    btnGenerateControlFile: TButton;
    btnShowHardwareInfo: TButton;
    OpenDialog1: TOpenDialog;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure chkExpiresClick(Sender: TObject);
    procedure chkHardwareBindingClick(Sender: TObject);
    procedure chkFileVerificationClick(Sender: TObject);
    procedure btnGetHardwareIDClick(Sender: TObject);
    procedure btnBrowseVerificationFileClick(Sender: TObject);
    procedure btnGenerateLicenseClick(Sender: TObject);
    procedure btnGenerateDemoClick(Sender: TObject);
    procedure btnAddApplicationClick(Sender: TObject);
    procedure btnUpdateApplicationClick(Sender: TObject);
    procedure btnDeleteApplicationClick(Sender: TObject);
    procedure lvApplicationsClick(Sender: TObject);
    procedure btnAddDistributorClick(Sender: TObject);
    procedure btnUpdateDistributorClick(Sender: TObject);
    procedure btnDeleteDistributorClick(Sender: TObject);
    procedure lvDistributorsClick(Sender: TObject);
    procedure btnRefreshHistoryClick(Sender: TObject);
    procedure btnOpenLicenseFolderClick(Sender: TObject);
    procedure btnBrowseOutputClick(Sender: TObject);
    procedure btnSaveSettingsClick(Sender: TObject);
    procedure btnGenerateControlFileClick(Sender: TObject);
    procedure btnShowHardwareInfoClick(Sender: TObject);
  private
    FDataManager: TDataManager;
    FLicenseGenerator: TLicenseGenerator;
    FMasterKey: string;
    FOutputPath: string;
    FVerificationFilePath: string;

    procedure LoadSettings;
    procedure SaveSettings;
    procedure LoadApplications;
    procedure LoadDistributors;
    procedure LoadLicenseHistory;
    procedure UpdateVerificationControls;
    function ValidateInput: Boolean;
    procedure ShowLicenseInfo(const ALicenseData: TLicenseData; const AFilePath: string);
  public
    { Public declarations }
  end;

var
  FormMain: TFormMain;

implementation

{$R *.dfm}

uses
  System.IniFiles, System.DateUtils, System.StrUtils, Winapi.ShellAPI;

const
  CONFIG_FILE = 'LicenseGuard.ini';

{ TFormMain }

procedure TFormMain.FormCreate(Sender: TObject);
var
  DataPath: string;
begin
  // Initialize paths
  DataPath := TPath.Combine(TPath.GetDocumentsPath, 'LicenseGuard\Data');
  if not TDirectory.Exists(DataPath) then
    TDirectory.CreateDirectory(DataPath);

  // Load settings
  LoadSettings;

  // Initialize components
  FDataManager := TDataManager.Create(DataPath);
  FLicenseGenerator := TLicenseGenerator.Create(FMasterKey);
  FLicenseGenerator.OutputPath := FOutputPath;

  // Initialize controls
  dtpExpiration.Enabled := False;
  cboBindingType.Enabled := False;
  edtHardwareID.Enabled := False;
  btnGetHardwareID.Enabled := False;
  edtVerificationFile.Enabled := False;
  btnBrowseVerificationFile.Enabled := False;

  // Load data
  LoadApplications;
  LoadDistributors;
  LoadLicenseHistory;

  // Set default expiration date
  dtpExpiration.Date := IncDay(Now, 365);
end;

procedure TFormMain.FormDestroy(Sender: TObject);
begin
  SaveSettings;
  FLicenseGenerator.Free;
  FDataManager.Free;
end;

procedure TFormMain.LoadSettings;
var
  IniFile: TIniFile;
  ConfigPath: string;
begin
  ConfigPath := TPath.Combine(ExtractFilePath(ParamStr(0)), CONFIG_FILE);
  IniFile := TIniFile.Create(ConfigPath);
  try
    FMasterKey := IniFile.ReadString('Settings', 'MasterKey', 'DefaultMasterKey2024!@#$');
    FOutputPath := IniFile.ReadString('Settings', 'OutputPath',
      TPath.Combine(TPath.GetDocumentsPath, 'LicenseGuard\Licenses'));

    edtMasterKey.Text := FMasterKey;
    edtOutputPath.Text := FOutputPath;

    if not TDirectory.Exists(FOutputPath) then
      TDirectory.CreateDirectory(FOutputPath);
  finally
    IniFile.Free;
  end;
end;

procedure TFormMain.SaveSettings;
var
  IniFile: TIniFile;
  ConfigPath: string;
begin
  ConfigPath := TPath.Combine(ExtractFilePath(ParamStr(0)), CONFIG_FILE);
  IniFile := TIniFile.Create(ConfigPath);
  try
    IniFile.WriteString('Settings', 'MasterKey', FMasterKey);
    IniFile.WriteString('Settings', 'OutputPath', FOutputPath);
  finally
    IniFile.Free;
  end;
end;

procedure TFormMain.LoadApplications;
var
  Apps: TArray<TApplicationInfo>;
  App: TApplicationInfo;
  Item: TListItem;
begin
  cboApplication.Clear;
  lvApplications.Items.Clear;

  Apps := FDataManager.GetAllApplications;
  for App in Apps do
  begin
    cboApplication.Items.AddObject(App.Name, TObject(App.ID));

    Item := lvApplications.Items.Add;
    Item.Caption := IntToStr(App.ID);
    Item.SubItems.Add(App.Name);
    Item.SubItems.Add(App.Description);
    Item.SubItems.Add(App.CurrentVersion);
    Item.SubItems.Add(DateTimeToStr(App.CreatedDate));
  end;

  if cboApplication.Items.Count > 0 then
    cboApplication.ItemIndex := 0;
end;

procedure TFormMain.LoadDistributors;
var
  Dists: TArray<TDistributorInfo>;
  Dist: TDistributorInfo;
  Item: TListItem;
begin
  cboDistributor.Clear;
  lvDistributors.Items.Clear;

  Dists := FDataManager.GetAllDistributors;
  for Dist in Dists do
  begin
    cboDistributor.Items.AddObject(Dist.Name, TObject(Dist.ID));

    Item := lvDistributors.Items.Add;
    Item.Caption := IntToStr(Dist.ID);
    Item.SubItems.Add(Dist.Name);
    Item.SubItems.Add(Dist.SerialNumber);
    Item.SubItems.Add(Dist.ContactEmail);
    Item.SubItems.Add(Dist.ContactPhone);
    Item.SubItems.Add(BoolToStr(Dist.Active, True));
  end;

  if cboDistributor.Items.Count > 0 then
    cboDistributor.ItemIndex := 0;
end;

procedure TFormMain.LoadLicenseHistory;
var
  Records: TArray<TLicenseRecord>;
  Rec: TLicenseRecord;
  Item: TListItem;
  LicenseTypeStr: string;
begin
  lvLicenseHistory.Items.Clear;

  Records := FDataManager.GetAllLicenseRecords;
  for Rec in Records do
  begin
    case Rec.LicenseType of
      ltFull: LicenseTypeStr := 'Full';
      ltDemo: LicenseTypeStr := 'Demo';
      ltTrial: LicenseTypeStr := 'Trial';
    else
      LicenseTypeStr := 'Unknown';
    end;

    Item := lvLicenseHistory.Items.Add;
    Item.Caption := Rec.LicenseSerial;
    Item.SubItems.Add(Rec.ClientName);
    Item.SubItems.Add(Rec.ApplicationName);
    Item.SubItems.Add(Rec.DistributorName);
    Item.SubItems.Add(DateTimeToStr(Rec.CreatedDate));
    Item.SubItems.Add(LicenseTypeStr);
  end;
end;

procedure TFormMain.chkExpiresClick(Sender: TObject);
begin
  dtpExpiration.Enabled := chkExpires.Checked;
end;

procedure TFormMain.chkHardwareBindingClick(Sender: TObject);
begin
  cboBindingType.Enabled := chkHardwareBinding.Checked;
  edtHardwareID.Enabled := chkHardwareBinding.Checked;
  btnGetHardwareID.Enabled := chkHardwareBinding.Checked;
end;

procedure TFormMain.chkFileVerificationClick(Sender: TObject);
begin
  UpdateVerificationControls;
end;

procedure TFormMain.UpdateVerificationControls;
begin
  edtVerificationFile.Enabled := chkFileVerification.Checked;
  btnBrowseVerificationFile.Enabled := chkFileVerification.Checked;

  if not chkFileVerification.Checked then
  begin
    edtVerificationFile.Text := '';
    FVerificationFilePath := '';
  end;
end;

procedure TFormMain.btnBrowseVerificationFileClick(Sender: TObject);
var
  FileInfo: TFileVerificationInfo;
begin
  OpenDialog1.Title := 'Select File for Verification';
  OpenDialog1.Filter := 'All Files (*.*)|*.*';
  OpenDialog1.FileName := '';

  if OpenDialog1.Execute then
  begin
    FVerificationFilePath := OpenDialog1.FileName;
    edtVerificationFile.Text := ExtractFileName(FVerificationFilePath);

    try
      FileInfo := TFileVerificationHelper.GetFileInfo(FVerificationFilePath);

      ShowMessage(Format('Verification File Selected:'#13#10 +
                        'Name: %s'#13#10 +
                        'Size: %d bytes'#13#10 +
                        'SHA256: %s',
                        [FileInfo.FileName,
                         FileInfo.FileSize,
                         FileInfo.FileHash]));
    except
      on E: Exception do
      begin
        ShowMessage('Error reading verification file: ' + E.Message);
        edtVerificationFile.Text := '';
        FVerificationFilePath := '';
      end;
    end;
  end;
end;

procedure TFormMain.btnGetHardwareIDClick(Sender: TObject);
begin
  try
    edtHardwareID.Text := THardwareInfo.GetHardwareID(cboBindingType.Text);
    ShowMessage('Hardware ID retrieved successfully');
  except
    on E: Exception do
      ShowMessage('Error getting hardware ID: ' + E.Message);
  end;
end;

function TFormMain.ValidateInput: Boolean;
begin
  Result := False;

  if Trim(edtClientName.Text) = '' then
  begin
    ShowMessage('Please enter client name');
    edtClientName.SetFocus;
    Exit;
  end;

  if cboApplication.ItemIndex < 0 then
  begin
    ShowMessage('Please select an application');
    cboApplication.SetFocus;
    Exit;
  end;

  if cboDistributor.ItemIndex < 0 then
  begin
    ShowMessage('Please select a distributor');
    cboDistributor.SetFocus;
    Exit;
  end;

  if chkFileVerification.Checked and (FVerificationFilePath = '') then
  begin
    ShowMessage('Please select a verification file');
    Exit;
  end;

  if chkFileVerification.Checked and not FileExists(FVerificationFilePath) then
  begin
    ShowMessage('Verification file not found: ' + FVerificationFilePath);
    Exit;
  end;

  Result := True;
end;

procedure TFormMain.btnGenerateLicenseClick(Sender: TObject);
var
  LicenseData: TLicenseData;
  AppID, DistID: Integer;
  App: TApplicationInfo;
  Dist: TDistributorInfo;
  Versions: TArray<string>;
  FilePath: string;
  LicenseRecord: TLicenseRecord;
begin
  if not ValidateInput then
    Exit;

  try
    // Initialize license data
    LicenseData.Initialize;
    try
      // Get selected application and distributor
      AppID := Integer(cboApplication.Items.Objects[cboApplication.ItemIndex]);
      DistID := Integer(cboDistributor.Items.Objects[cboDistributor.ItemIndex]);

      App := FDataManager.GetApplication(AppID);
      Dist := FDataManager.GetDistributor(DistID);

      // Set basic info
      LicenseData.ClientName := edtClientName.Text;
      LicenseData.ClientCompany := edtClientCompany.Text;
      LicenseData.ApplicationName := App.Name;
      LicenseData.ApplicationID := IntToStr(App.ID);
      LicenseData.DistributorName := Dist.Name;
      LicenseData.DistributorSerial := Dist.SerialNumber;
      LicenseData.LicenseType := ltFull;

      // Version tolerance
      if Trim(edtVersions.Text) = '' then
      begin
        LicenseData.VersionTolerance.AllowAnyVersion := True;
      end
      else
      begin
        LicenseData.VersionTolerance.AllowAnyVersion := False;
        Versions := System.StrUtils.SplitString(edtVersions.Text, ',');
        LicenseData.VersionTolerance.AllowedVersions := Versions;
      end;

      // Expiration
      LicenseData.Expiration.HasExpiration := chkExpires.Checked;
      if chkExpires.Checked then
      begin
        LicenseData.Expiration.ExpirationDate := dtpExpiration.DateTime;
        LicenseData.Expiration.GracePeriodDays := 0;
      end;

      // Hardware binding
      LicenseData.HardwareBinding.Enabled := chkHardwareBinding.Checked;
      if chkHardwareBinding.Checked then
      begin
        LicenseData.HardwareBinding.BindingType := cboBindingType.Text;
        LicenseData.HardwareBinding.HardwareID := edtHardwareID.Text;
      end;

      // File verification
      if chkFileVerification.Checked then
      begin
        FLicenseGenerator.SetFileVerification(LicenseData, FVerificationFilePath,
          'License verification file: ' + ExtractFileName(FVerificationFilePath));
      end
      else
      begin
        LicenseData.FileVerification := TFileVerificationInfo.Empty;
      end;

      // Notes
      LicenseData.Notes := memoNotes.Lines.Text;

      // Generate license
      FilePath := FLicenseGenerator.GenerateLicense(LicenseData, edtClientCompany.Text);

      // Show license info
      ShowLicenseInfo(LicenseData, FilePath);

      // Save to history
      LicenseRecord.LicenseSerial := LicenseData.LicenseSerial;
      LicenseRecord.ClientName := LicenseData.ClientName;
      LicenseRecord.ClientCompany := LicenseData.ClientCompany;
      LicenseRecord.ApplicationName := LicenseData.ApplicationName;
      LicenseRecord.DistributorName := LicenseData.DistributorName;
      LicenseRecord.CreatedDate := LicenseData.CreatedDate;
      if LicenseData.Expiration.HasExpiration then
        LicenseRecord.ExpirationDate := LicenseData.Expiration.ExpirationDate
      else
        LicenseRecord.ExpirationDate := 0;
      LicenseRecord.LicenseType := LicenseData.LicenseType;
      LicenseRecord.FilePath := FilePath;

      FDataManager.AddLicenseRecord(LicenseRecord);
      LoadLicenseHistory;

      ShowMessage('License generated successfully!'#13#10 +
                  'File: ' + FilePath);

    finally
      LicenseData.Free;
    end;
  except
    on E: Exception do
      ShowMessage('Error generating license: ' + E.Message);
  end;
end;

procedure TFormMain.btnGenerateDemoClick(Sender: TObject);
var
  ClientName, AppName: string;
  FilePath: string;
begin
  if cboApplication.ItemIndex < 0 then
  begin
    ShowMessage('Please select an application');
    Exit;
  end;

  ClientName := edtClientName.Text;
  if Trim(ClientName) = '' then
    ClientName := 'DEMO_' + FormatDateTime('yyyymmdd_hhnnss', Now);

  AppName := cboApplication.Text;

  try
    FilePath := FLicenseGenerator.GenerateDemoLicense(ClientName, AppName, 30);
    LoadLicenseHistory;
    ShowMessage('Demo license generated successfully!'#13#10 +
                'File: ' + FilePath);
  except
    on E: Exception do
      ShowMessage('Error generating demo license: ' + E.Message);
  end;
end;

procedure TFormMain.ShowLicenseInfo(const ALicenseData: TLicenseData; const AFilePath: string);
var
  Info: TStringList;
  LicenseTypeStr, ExpiresStr, HardwareStr, FileVerifStr: string;
begin
  Info := TStringList.Create;
  try
    case ALicenseData.LicenseType of
      ltFull: LicenseTypeStr := 'Full';
      ltDemo: LicenseTypeStr := 'Demo';
      ltTrial: LicenseTypeStr := 'Trial';
    else
      LicenseTypeStr := 'Unknown';
    end;

    if ALicenseData.Expiration.HasExpiration then
      ExpiresStr := DateTimeToStr(ALicenseData.Expiration.ExpirationDate)
    else
      ExpiresStr := 'Never';

    if ALicenseData.HardwareBinding.Enabled then
      HardwareStr := ALicenseData.HardwareBinding.BindingType
    else
      HardwareStr := 'None';

    if ALicenseData.FileVerification.Enabled then
      FileVerifStr := ALicenseData.FileVerification.FileName
    else
      FileVerifStr := 'None';

    Info.Add('=== LICENSE INFORMATION ===');
    Info.Add('');
    Info.Add('License Serial: ' + ALicenseData.LicenseSerial);
    Info.Add('License Type: ' + LicenseTypeStr);
    Info.Add('Client: ' + ALicenseData.ClientName);
    Info.Add('Company: ' + ALicenseData.ClientCompany);
    Info.Add('Application: ' + ALicenseData.ApplicationName);
    Info.Add('Distributor: ' + ALicenseData.DistributorName);
    Info.Add('Created: ' + DateTimeToStr(ALicenseData.CreatedDate));
    Info.Add('Expires: ' + ExpiresStr);
    Info.Add('Hardware Binding: ' + HardwareStr);
    Info.Add('File Verification: ' + FileVerifStr);
    Info.Add('');
    Info.Add('File Path: ' + AFilePath);

    memoLicenseInfo.Lines.Assign(Info);
  finally
    Info.Free;
  end;
end;

// Application management
procedure TFormMain.btnAddApplicationClick(Sender: TObject);
begin
  if Trim(edtAppName.Text) = '' then
  begin
    ShowMessage('Please enter application name');
    Exit;
  end;

  try
    FDataManager.AddApplication(edtAppName.Text, edtAppDescription.Text, edtAppVersion.Text);
    LoadApplications;
    edtAppName.Clear;
    edtAppDescription.Clear;
    edtAppVersion.Clear;
  except
    on E: Exception do
      ShowMessage('Error adding application: ' + E.Message);
  end;
end;

procedure TFormMain.btnUpdateApplicationClick(Sender: TObject);
var
  App: TApplicationInfo;
begin
  if lvApplications.Selected = nil then
  begin
    ShowMessage('Please select an application');
    Exit;
  end;

  try
    App := FDataManager.GetApplication(StrToInt(lvApplications.Selected.Caption));
    App.Name := edtAppName.Text;
    App.Description := edtAppDescription.Text;
    App.CurrentVersion := edtAppVersion.Text;
    FDataManager.UpdateApplication(App);
    LoadApplications;
  except
    on E: Exception do
      ShowMessage('Error updating application: ' + E.Message);
  end;
end;

procedure TFormMain.btnDeleteApplicationClick(Sender: TObject);
begin
  if lvApplications.Selected = nil then
  begin
    ShowMessage('Please select an application');
    Exit;
  end;

  if MessageDlg('Are you sure you want to delete this application?',
                mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    try
      FDataManager.DeleteApplication(StrToInt(lvApplications.Selected.Caption));
      LoadApplications;
    except
      on E: Exception do
        ShowMessage('Error deleting application: ' + E.Message);
    end;
  end;
end;

procedure TFormMain.lvApplicationsClick(Sender: TObject);
var
  App: TApplicationInfo;
begin
  if lvApplications.Selected <> nil then
  begin
    try
      App := FDataManager.GetApplication(StrToInt(lvApplications.Selected.Caption));
      edtAppName.Text := App.Name;
      edtAppDescription.Text := App.Description;
      edtAppVersion.Text := App.CurrentVersion;
    except
      // Ignore errors
    end;
  end;
end;

// Distributor management
procedure TFormMain.btnAddDistributorClick(Sender: TObject);
begin
  if Trim(edtDistName.Text) = '' then
  begin
    ShowMessage('Please enter distributor name');
    Exit;
  end;

  try
    FDataManager.AddDistributor(edtDistName.Text, edtDistEmail.Text,
                                edtDistPhone.Text, edtDistAddress.Text);
    LoadDistributors;
    edtDistName.Clear;
    edtDistEmail.Clear;
    edtDistPhone.Clear;
    edtDistAddress.Clear;
    edtDistSerial.Clear;
  except
    on E: Exception do
      ShowMessage('Error adding distributor: ' + E.Message);
  end;
end;

procedure TFormMain.btnUpdateDistributorClick(Sender: TObject);
var
  Dist: TDistributorInfo;
begin
  if lvDistributors.Selected = nil then
  begin
    ShowMessage('Please select a distributor');
    Exit;
  end;

  try
    Dist := FDataManager.GetDistributor(StrToInt(lvDistributors.Selected.Caption));
    Dist.Name := edtDistName.Text;
    Dist.ContactEmail := edtDistEmail.Text;
    Dist.ContactPhone := edtDistPhone.Text;
    Dist.Address := edtDistAddress.Text;
    FDataManager.UpdateDistributor(Dist);
    LoadDistributors;
  except
    on E: Exception do
      ShowMessage('Error updating distributor: ' + E.Message);
  end;
end;

procedure TFormMain.btnDeleteDistributorClick(Sender: TObject);
begin
  if lvDistributors.Selected = nil then
  begin
    ShowMessage('Please select a distributor');
    Exit;
  end;

  if MessageDlg('Are you sure you want to delete this distributor?',
                mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    try
      FDataManager.DeleteDistributor(StrToInt(lvDistributors.Selected.Caption));
      LoadDistributors;
    except
      on E: Exception do
        ShowMessage('Error deleting distributor: ' + E.Message);
    end;
  end;
end;

procedure TFormMain.lvDistributorsClick(Sender: TObject);
var
  Dist: TDistributorInfo;
begin
  if lvDistributors.Selected <> nil then
  begin
    try
      Dist := FDataManager.GetDistributor(StrToInt(lvDistributors.Selected.Caption));
      edtDistName.Text := Dist.Name;
      edtDistEmail.Text := Dist.ContactEmail;
      edtDistPhone.Text := Dist.ContactPhone;
      edtDistAddress.Text := Dist.Address;
      edtDistSerial.Text := Dist.SerialNumber;
    except
      // Ignore errors
    end;
  end;
end;

procedure TFormMain.btnRefreshHistoryClick(Sender: TObject);
begin
  LoadLicenseHistory;
end;

procedure TFormMain.btnOpenLicenseFolderClick(Sender: TObject);
begin
  if TDirectory.Exists(FOutputPath) then
    ShellExecute(0, 'open', PChar(FOutputPath), nil, nil, SW_SHOWNORMAL)
  else
    ShowMessage('Output folder not found: ' + FOutputPath);
end;

procedure TFormMain.btnBrowseOutputClick(Sender: TObject);
var
  Dir: string;
begin
  Dir := FOutputPath;
  if SelectDirectory('Select output directory', '', Dir) then
  begin
    FOutputPath := Dir;
    edtOutputPath.Text := Dir;
    if Assigned(FLicenseGenerator) then
      FLicenseGenerator.OutputPath := Dir;
  end;
end;

procedure TFormMain.btnSaveSettingsClick(Sender: TObject);
begin
  FMasterKey := edtMasterKey.Text;
  FOutputPath := edtOutputPath.Text;
  SaveSettings;

  if Assigned(FLicenseGenerator) then
  begin
    FLicenseGenerator.Free;
    FLicenseGenerator := TLicenseGenerator.Create(FMasterKey);
    FLicenseGenerator.OutputPath := FOutputPath;
  end;

  ShowMessage('Settings saved successfully');
end;

procedure TFormMain.btnGenerateControlFileClick(Sender: TObject);
begin
  try
    FLicenseGenerator.CreateControlFile(FOutputPath);
    ShowMessage('Control file generated successfully!');
  except
    on E: Exception do
      ShowMessage('Error generating control file: ' + E.Message);
  end;
end;

procedure TFormMain.btnShowHardwareInfoClick(Sender: TObject);
begin
  ShowMessage(THardwareInfo.GetHardwareInfoString);
end;

end.
