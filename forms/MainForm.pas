unit MainForm;

{
  LicenseGuard - Main Form
  Main user interface for license management
}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ComCtrls, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Grids, System.DateUtils,
  LG.LicenseData, LG.LicenseGenerator, LG.DataManager, LG.HardwareInfo,
  LG.Database, LG.DatabaseLogger;

type
  TFormMain = class(TForm)
    PageControl1: TPageControl;
    TabGenerate: TTabSheet;
    TabApplications: TTabSheet;
    TabDistributors: TTabSheet;
    TabHistory: TTabSheet;
    TabSettings: TTabSheet;

    // Generate License Tab
    GroupBox1: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
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
    memoNotes: TMemo;
    btnGenerateLicense: TButton;
    btnGenerateDemo: TButton;
    GroupBox2: TGroupBox;
    memoLicenseInfo: TMemo;

    // Applications Tab
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

    // Distributors Tab
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

    // History Tab
    GroupBox5: TGroupBox;
    lvLicenseHistory: TListView;
    btnRefreshHistory: TButton;
    btnOpenLicenseFolder: TButton;

    // Settings Tab
    GroupBox6: TGroupBox;
    Label17: TLabel;
    Label18: TLabel;
    edtMasterKey: TEdit;
    edtOutputPath: TEdit;
    btnBrowseOutput: TButton;
    btnSaveSettings: TButton;
    btnGenerateControlFile: TButton;
    btnShowHardwareInfo: TButton;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnGenerateLicenseClick(Sender: TObject);
    procedure btnGenerateDemoClick(Sender: TObject);
    procedure btnAddApplicationClick(Sender: TObject);
    procedure btnUpdateApplicationClick(Sender: TObject);
    procedure btnDeleteApplicationClick(Sender: TObject);
    procedure btnAddDistributorClick(Sender: TObject);
    procedure btnUpdateDistributorClick(Sender: TObject);
    procedure btnDeleteDistributorClick(Sender: TObject);
    procedure btnGetHardwareIDClick(Sender: TObject);
    procedure btnRefreshHistoryClick(Sender: TObject);
    procedure btnOpenLicenseFolderClick(Sender: TObject);
    procedure btnSaveSettingsClick(Sender: TObject);
    procedure btnGenerateControlFileClick(Sender: TObject);
    procedure btnShowHardwareInfoClick(Sender: TObject);
    procedure chkExpiresClick(Sender: TObject);
    procedure chkHardwareBindingClick(Sender: TObject);
    procedure lvApplicationsClick(Sender: TObject);
    procedure lvDistributorsClick(Sender: TObject);
    procedure btnBrowseOutputClick(Sender: TObject);

  private
    FDatabase: TLGDatabase;
    FLogger: TLGDatabaseLogger;
    FGenerator: TLicenseGenerator;
    FDataManager: TDataManager;
    FMasterKey: string;

    procedure LoadSettings;
    procedure SaveSettings;
    procedure RefreshApplicationsList;
    procedure RefreshDistributorsList;
    procedure RefreshLicenseHistory;
    procedure LoadApplicationsToCombo;
    procedure LoadDistributorsToCombo;
    procedure ClearApplicationFields;
    procedure ClearDistributorFields;
  public
    { Public declarations }
  end;

var
  FormMain: TFormMain;

implementation

{$R *.dfm}

uses
  System.IOUtils, System.IniFiles, Winapi.ShellAPI, System.StrUtils,
  System.TypInfo, Vcl.FileCtrl;

procedure TFormMain.FormCreate(Sender: TObject);
var
  DBConfig: TDatabaseConfig;
begin
  FMasterKey := 'DefaultMasterKey-ChangeThis-InProduction';

  LoadSettings;

  // Inicializar base de datos
  FDatabase := TLGDatabase.Create;
  DBConfig := FDatabase.LoadConfig; // Cargar configuración guardada o usar default
  try
    FDatabase.Connect(DBConfig);
  except
    on E: Exception do
    begin
      ShowMessage('Error al conectar a la base de datos: ' + E.Message);
      Application.Terminate;
      Exit;
    end;
  end;

  // Inicializar logger
  FLogger := TLGDatabaseLogger.Create(FDatabase);

  // Inicializar generador y data manager
  FGenerator := TLicenseGenerator.Create(FMasterKey);
  FDataManager := TDataManager.Create(FDatabase, FLogger);

  FLogger.LogInfo(lcSystem, 'LicenseGuard application started', 'Application startup');

  RefreshApplicationsList;
  RefreshDistributorsList;
  RefreshLicenseHistory;
  LoadApplicationsToCombo;
  LoadDistributorsToCombo;

  dtpExpiration.Date := IncYear(Now, 1);
  chkExpires.Checked := False;
  chkExpiresClick(nil);

  chkHardwareBinding.Checked := False;
  chkHardwareBindingClick(nil);
end;

procedure TFormMain.FormDestroy(Sender: TObject);
begin
  SaveSettings;

  if Assigned(FLogger) then
    FLogger.LogInfo(lcSystem, 'LicenseGuard application closed', 'Application shutdown');

  FGenerator.Free;
  FDataManager.Free;
  FLogger.Free;
  FDatabase.Free;
end;

procedure TFormMain.LoadSettings;
var
  IniFile: TIniFile;
  IniPath: string;
begin
  IniPath := TPath.Combine(ExtractFilePath(Application.ExeName), 'LicenseGuard.ini');

  if not TFile.Exists(IniPath) then
    Exit;

  IniFile := TIniFile.Create(IniPath);
  try
    FMasterKey := IniFile.ReadString('Settings', 'MasterKey', FMasterKey);
    edtMasterKey.Text := FMasterKey;
    edtOutputPath.Text := IniFile.ReadString('Settings', 'OutputPath',
      TPath.Combine(TPath.GetDocumentsPath, 'LicenseGuard'));
  finally
    IniFile.Free;
  end;
end;

procedure TFormMain.SaveSettings;
var
  IniFile: TIniFile;
  IniPath: string;
begin
  IniPath := TPath.Combine(ExtractFilePath(Application.ExeName), 'LicenseGuard.ini');

  IniFile := TIniFile.Create(IniPath);
  try
    IniFile.WriteString('Settings', 'MasterKey', edtMasterKey.Text);
    IniFile.WriteString('Settings', 'OutputPath', edtOutputPath.Text);
  finally
    IniFile.Free;
  end;
end;

procedure TFormMain.btnSaveSettingsClick(Sender: TObject);
begin
  FMasterKey := edtMasterKey.Text;

  FGenerator.Free;
  FGenerator := TLicenseGenerator.Create(FMasterKey);
  FGenerator.OutputPath := edtOutputPath.Text;

  SaveSettings;

  ShowMessage('Settings saved successfully');
end;

procedure TFormMain.RefreshApplicationsList;
var
  Apps: TArray<TApplicationInfo>;
  App: TApplicationInfo;
  Item: TListItem;
begin
  lvApplications.Items.Clear;

  Apps := FDataManager.GetAllApplications;
  for App in Apps do
  begin
    Item := lvApplications.Items.Add;
    Item.Caption := IntToStr(App.ID);
    Item.SubItems.Add(App.Name);
    Item.SubItems.Add(App.Description);
    Item.SubItems.Add(App.CurrentVersion);
    Item.SubItems.Add(DateToStr(App.CreatedDate));
  end;
end;

procedure TFormMain.RefreshDistributorsList;
var
  Dists: TArray<TDistributorInfo>;
  Dist: TDistributorInfo;
  Item: TListItem;
begin
  lvDistributors.Items.Clear;

  Dists := FDataManager.GetAllDistributors;
  for Dist in Dists do
  begin
    Item := lvDistributors.Items.Add;
    Item.Caption := IntToStr(Dist.ID);
    Item.SubItems.Add(Dist.Name);
    Item.SubItems.Add(Dist.SerialNumber);
    Item.SubItems.Add(Dist.ContactEmail);
    Item.SubItems.Add(Dist.ContactPhone);
    if Dist.Active then
      Item.SubItems.Add('Yes')
    else
      Item.SubItems.Add('No');
  end;
end;

procedure TFormMain.RefreshLicenseHistory;
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
    Item := lvLicenseHistory.Items.Add;
    Item.Caption := Rec.LicenseSerial;
    Item.SubItems.Add(Rec.ClientName);
    Item.SubItems.Add(Rec.ApplicationName);
    Item.SubItems.Add(Rec.DistributorName);
    Item.SubItems.Add(DateTimeToStr(Rec.CreatedDate));

    // Convertir tipo de licencia a string
    case Rec.LicenseType of
      ltFull: LicenseTypeStr := 'Full';
      ltDemo: LicenseTypeStr := 'Demo';
      ltTrial: LicenseTypeStr := 'Trial';
    else
      LicenseTypeStr := 'Unknown';
    end;
    Item.SubItems.Add(LicenseTypeStr);
  end;
end;

procedure TFormMain.LoadApplicationsToCombo;
var
  Apps: TArray<TApplicationInfo>;
  App: TApplicationInfo;
begin
  cboApplication.Items.Clear;

  Apps := FDataManager.GetAllApplications;
  for App in Apps do
    cboApplication.Items.AddObject(App.Name, TObject(App.ID));

  if cboApplication.Items.Count > 0 then
    cboApplication.ItemIndex := 0;
end;

procedure TFormMain.LoadDistributorsToCombo;
var
  Dists: TArray<TDistributorInfo>;
  Dist: TDistributorInfo;
begin
  cboDistributor.Items.Clear;

  Dists := FDataManager.GetAllDistributors;
  for Dist in Dists do
    cboDistributor.Items.AddObject(Dist.Name, TObject(Dist.ID));

  if cboDistributor.Items.Count > 0 then
    cboDistributor.ItemIndex := 0;
end;

procedure TFormMain.btnGenerateLicenseClick(Sender: TObject);
var
  LicenseData: TLicenseData;
  OutputPath: string;
  App: TApplicationInfo;
  Dist: TDistributorInfo;
  LicRecord: TLicenseRecord;
  Versions: TStringList;
  I: Integer;
begin
  if Trim(edtClientName.Text) = '' then
  begin
    ShowMessage('Please enter client name');
    Exit;
  end;

  if cboApplication.ItemIndex < 0 then
  begin
    ShowMessage('Please select an application');
    Exit;
  end;

  if cboDistributor.ItemIndex < 0 then
  begin
    ShowMessage('Please select a distributor');
    Exit;
  end;

  // Initialize license data
  LicenseData.Initialize;
  try
    // Client info
    LicenseData.ClientName := edtClientName.Text;
    LicenseData.ClientCompany := edtClientCompany.Text;

    // Application info
    App := FDataManager.GetApplication(Integer(cboApplication.Items.Objects[cboApplication.ItemIndex]));
    LicenseData.ApplicationName := App.Name;
    LicenseData.ApplicationID := IntToStr(App.ID);

    // Distributor info
    Dist := FDataManager.GetDistributor(Integer(cboDistributor.Items.Objects[cboDistributor.ItemIndex]));
    LicenseData.DistributorName := Dist.Name;
    LicenseData.DistributorSerial := Dist.SerialNumber;

    // Version tolerance
    if Trim(edtVersions.Text) <> '' then
    begin
      Versions := TStringList.Create;
      try
        Versions.CommaText := edtVersions.Text;
        SetLength(LicenseData.VersionTolerance.AllowedVersions, Versions.Count);
        for I := 0 to Versions.Count - 1 do
          LicenseData.VersionTolerance.AllowedVersions[I] := Trim(Versions[I]);
        LicenseData.VersionTolerance.AllowAnyVersion := False;
      finally
        Versions.Free;
      end;
    end
    else
      LicenseData.VersionTolerance.AllowAnyVersion := True;

    // Expiration
    LicenseData.Expiration.HasExpiration := chkExpires.Checked;
    if chkExpires.Checked then
    begin
      LicenseData.Expiration.ExpirationDate := dtpExpiration.Date;
      LicenseData.Expiration.GracePeriodDays := 7;
    end;

    // Hardware binding
    LicenseData.HardwareBinding.Enabled := chkHardwareBinding.Checked;
    if chkHardwareBinding.Checked then
    begin
      LicenseData.HardwareBinding.BindingType := cboBindingType.Text;
      LicenseData.HardwareBinding.HardwareID := edtHardwareID.Text;
    end;

    // Notes
    LicenseData.Notes := memoNotes.Text;

    // Generate license
    OutputPath := FGenerator.GenerateLicense(LicenseData, edtClientCompany.Text);

    // Add to history
    LicRecord.LicenseSerial := LicenseData.LicenseSerial;
    LicRecord.ClientName := LicenseData.ClientName;
    LicRecord.ClientCompany := LicenseData.ClientCompany;
    LicRecord.ContactEmail := '';
    LicRecord.ApplicationName := LicenseData.ApplicationName;
    LicRecord.ApplicationVersion := App.CurrentVersion;
    LicRecord.DistributorName := LicenseData.DistributorName;
    LicRecord.DistributorSerial := LicenseData.DistributorSerial;
    LicRecord.CreatedDate := Now;
    LicRecord.ExpirationDate := LicenseData.Expiration.ExpirationDate;
    LicRecord.LicenseType := ltFull;
    // Convertir string a enum
    if SameText(LicenseData.HardwareBinding.BindingType, 'MAC') then
      LicRecord.HardwareBindingType := hbtMAC
    else if SameText(LicenseData.HardwareBinding.BindingType, 'CPU') then
      LicRecord.HardwareBindingType := hbtCPU
    else if SameText(LicenseData.HardwareBinding.BindingType, 'Disk') then
      LicRecord.HardwareBindingType := hbtDisk
    else if SameText(LicenseData.HardwareBinding.BindingType, 'Combined') then
      LicRecord.HardwareBindingType := hbtCombined
    else
      LicRecord.HardwareBindingType := hbtNone;
    LicRecord.HardwareID := LicenseData.HardwareBinding.HardwareID;
    LicRecord.DemoExpiresDate := 0;
    LicRecord.ControlFileHash := LicenseData.ControlFileHash;
    LicRecord.FilePath := OutputPath;

    FDataManager.AddLicenseRecord(LicRecord);

    // Show success message
    memoLicenseInfo.Lines.Clear;
    memoLicenseInfo.Lines.Add('License generated successfully!');
    memoLicenseInfo.Lines.Add('');
    memoLicenseInfo.Lines.Add('License Serial: ' + LicenseData.LicenseSerial);
    memoLicenseInfo.Lines.Add('Output File: ' + OutputPath);
    memoLicenseInfo.Lines.Add('');
    memoLicenseInfo.Lines.Add('Distribute this file to: ' + edtClientCompany.Text);

    RefreshLicenseHistory;

    if MessageDlg('License generated successfully. Open output folder?',
      mtConfirmation, [mbYes, mbNo], 0) = mrYes then
      ShellExecute(0, 'open', PChar(ExtractFilePath(OutputPath)), nil, nil, SW_SHOW);

  finally
    LicenseData.Free;
  end;
end;

procedure TFormMain.btnGenerateDemoClick(Sender: TObject);
var
  ClientName, AppName: string;
  Days: Integer;
  OutputPath: string;
begin
  ClientName := InputBox('Demo License', 'Enter client name:', '');
  if Trim(ClientName) = '' then
    Exit;

  if cboApplication.ItemIndex < 0 then
  begin
    ShowMessage('Please select an application first');
    Exit;
  end;

  AppName := cboApplication.Text;
  Days := StrToIntDef(InputBox('Demo License', 'Enter demo period (days):', '30'), 30);

  OutputPath := FGenerator.GenerateDemoLicense(ClientName, AppName, Days);

  ShowMessage(Format('Demo license generated successfully!'#13#10 +
    'Valid for %d days'#13#10 +
    'Output: %s', [Days, OutputPath]));

  RefreshLicenseHistory;
end;

procedure TFormMain.btnAddApplicationClick(Sender: TObject);
begin
  if Trim(edtAppName.Text) = '' then
  begin
    ShowMessage('Please enter application name');
    Exit;
  end;

  FDataManager.AddApplication(edtAppName.Text, edtAppDescription.Text, edtAppVersion.Text);

  RefreshApplicationsList;
  LoadApplicationsToCombo;
  ClearApplicationFields;

  ShowMessage('Application added successfully');
end;

procedure TFormMain.btnUpdateApplicationClick(Sender: TObject);
var
  App: TApplicationInfo;
begin
  if lvApplications.Selected = nil then
  begin
    ShowMessage('Please select an application to update');
    Exit;
  end;

  App := FDataManager.GetApplication(StrToInt(lvApplications.Selected.Caption));
  App.Name := edtAppName.Text;
  App.Description := edtAppDescription.Text;
  App.CurrentVersion := edtAppVersion.Text;

  FDataManager.UpdateApplication(App);

  RefreshApplicationsList;
  LoadApplicationsToCombo;

  ShowMessage('Application updated successfully');
end;

procedure TFormMain.btnDeleteApplicationClick(Sender: TObject);
begin
  if lvApplications.Selected = nil then
  begin
    ShowMessage('Please select an application to delete');
    Exit;
  end;

  if MessageDlg('Are you sure you want to delete this application?',
    mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    FDataManager.DeleteApplication(StrToInt(lvApplications.Selected.Caption));
    RefreshApplicationsList;
    LoadApplicationsToCombo;
    ClearApplicationFields;
    ShowMessage('Application deleted successfully');
  end;
end;

procedure TFormMain.btnAddDistributorClick(Sender: TObject);
begin
  if Trim(edtDistName.Text) = '' then
  begin
    ShowMessage('Please enter distributor name');
    Exit;
  end;

  FDataManager.AddDistributor(edtDistName.Text, edtDistEmail.Text,
    edtDistPhone.Text, edtDistAddress.Text);

  RefreshDistributorsList;
  LoadDistributorsToCombo;
  ClearDistributorFields;

  ShowMessage('Distributor added successfully');
end;

procedure TFormMain.btnUpdateDistributorClick(Sender: TObject);
var
  Dist: TDistributorInfo;
begin
  if lvDistributors.Selected = nil then
  begin
    ShowMessage('Please select a distributor to update');
    Exit;
  end;

  Dist := FDataManager.GetDistributor(StrToInt(lvDistributors.Selected.Caption));
  Dist.Name := edtDistName.Text;
  Dist.ContactEmail := edtDistEmail.Text;
  Dist.ContactPhone := edtDistPhone.Text;
  Dist.Address := edtDistAddress.Text;

  FDataManager.UpdateDistributor(Dist);

  RefreshDistributorsList;
  LoadDistributorsToCombo;

  ShowMessage('Distributor updated successfully');
end;

procedure TFormMain.btnDeleteDistributorClick(Sender: TObject);
begin
  if lvDistributors.Selected = nil then
  begin
    ShowMessage('Please select a distributor to delete');
    Exit;
  end;

  if MessageDlg('Are you sure you want to delete this distributor?',
    mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    FDataManager.DeleteDistributor(StrToInt(lvDistributors.Selected.Caption));
    RefreshDistributorsList;
    LoadDistributorsToCombo;
    ClearDistributorFields;
    ShowMessage('Distributor deleted successfully');
  end;
end;

procedure TFormMain.ClearApplicationFields;
begin
  edtAppName.Text := '';
  edtAppDescription.Text := '';
  edtAppVersion.Text := '';
end;

procedure TFormMain.ClearDistributorFields;
begin
  edtDistName.Text := '';
  edtDistEmail.Text := '';
  edtDistPhone.Text := '';
  edtDistAddress.Text := '';
  edtDistSerial.Text := '';
end;

procedure TFormMain.lvApplicationsClick(Sender: TObject);
var
  App: TApplicationInfo;
begin
  if lvApplications.Selected = nil then
    Exit;

  App := FDataManager.GetApplication(StrToInt(lvApplications.Selected.Caption));
  edtAppName.Text := App.Name;
  edtAppDescription.Text := App.Description;
  edtAppVersion.Text := App.CurrentVersion;
end;

procedure TFormMain.lvDistributorsClick(Sender: TObject);
var
  Dist: TDistributorInfo;
begin
  if lvDistributors.Selected = nil then
    Exit;

  Dist := FDataManager.GetDistributor(StrToInt(lvDistributors.Selected.Caption));
  edtDistName.Text := Dist.Name;
  edtDistEmail.Text := Dist.ContactEmail;
  edtDistPhone.Text := Dist.ContactPhone;
  edtDistAddress.Text := Dist.Address;
  edtDistSerial.Text := Dist.SerialNumber;
end;

procedure TFormMain.btnGetHardwareIDClick(Sender: TObject);
var
  BindingType: string;
begin
  if cboBindingType.ItemIndex < 0 then
  begin
    ShowMessage('Please select a binding type first');
    Exit;
  end;

  BindingType := cboBindingType.Text;
  edtHardwareID.Text := THardwareInfo.GetHardwareID(BindingType);
end;

procedure TFormMain.btnShowHardwareInfoClick(Sender: TObject);
begin
  ShowMessage(THardwareInfo.GetHardwareInfoString);
end;

procedure TFormMain.btnRefreshHistoryClick(Sender: TObject);
begin
  RefreshLicenseHistory;
end;

procedure TFormMain.btnOpenLicenseFolderClick(Sender: TObject);
begin
  ShellExecute(0, 'open', PChar(FGenerator.OutputPath), nil, nil, SW_SHOW);
end;

procedure TFormMain.btnGenerateControlFileClick(Sender: TObject);
begin
  FGenerator.CreateControlFile(FGenerator.OutputPath);
  ShowMessage('Control file (premium.sis) generated successfully in output folder');
end;

procedure TFormMain.btnBrowseOutputClick(Sender: TObject);
var
  Dir: string;
begin
  Dir := edtOutputPath.Text;
  if SelectDirectory('Select Output Folder', '', Dir) then
    edtOutputPath.Text := Dir;
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

end.
