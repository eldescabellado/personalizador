program LicenseGuard;

{
  LicenseGuard - License Generation and Management System
  Main application entry point
}

uses
  Vcl.Forms,
  MainForm in '..\forms\MainForm.pas' {FormMain},
  LG.Encryption in '..\units\LG.Encryption.pas',
  LG.LicenseData in '..\units\LG.LicenseData.pas',
  LG.LicenseGenerator in '..\units\LG.LicenseGenerator.pas',
  LG.LicenseValidator in '..\units\LG.LicenseValidator.pas',
  LG.HardwareInfo in '..\units\LG.HardwareInfo.pas',
  LG.DataManager in '..\units\LG.DataManager.pas',
  LG.FileVerification in '..\units\LG.FileVerification.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'LicenseGuard - License Management System';
  Application.CreateForm(TFormMain, FormMain);
  Application.Run;
end.
