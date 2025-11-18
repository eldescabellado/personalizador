object FormMain: TFormMain
  Left = 0
  Top = 0
  Caption = 'LicenseGuard - License Management System'
  ClientHeight = 600
  ClientWidth = 900
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object PageControl1: TPageControl
    Left = 0
    Top = 0
    Width = 900
    Height = 600
    ActivePage = TabGenerate
    Align = alClient
    TabOrder = 0
    object TabGenerate: TTabSheet
      Caption = 'Generate License'
      object GroupBox1: TGroupBox
        Left = 3
        Top = 3
        Width = 500
        Height = 550
        Caption = ' License Information '
        TabOrder = 0
        object Label1: TLabel
          Left = 16
          Top = 24
          Width = 60
          Height = 13
          Caption = 'Client Name:'
        end
        object Label2: TLabel
          Left = 16
          Top = 51
          Width = 80
          Height = 13
          Caption = 'Client Company:'
        end
        object Label3: TLabel
          Left = 16
          Top = 78
          Width = 57
          Height = 13
          Caption = 'Application:'
        end
        object Label4: TLabel
          Left = 16
          Top = 105
          Width = 56
          Height = 13
          Caption = 'Distributor:'
        end
        object Label5: TLabel
          Left = 16
          Top = 132
          Width = 126
          Height = 13
          Caption = 'Allowed Versions (comma-separated):'
        end
        object Label6: TLabel
          Left = 16
          Top = 205
          Width = 73
          Height = 13
          Caption = 'Expiration Date:'
        end
        object Label7: TLabel
          Left = 16
          Top = 265
          Width = 62
          Height = 13
          Caption = 'Binding Type:'
        end
        object Label8: TLabel
          Left = 16
          Top = 292
          Width = 67
          Height = 13
          Caption = 'Hardware ID:'
        end
        object edtClientName: TEdit
          Left = 160
          Top = 21
          Width = 313
          Height = 21
          TabOrder = 0
        end
        object edtClientCompany: TEdit
          Left = 160
          Top = 48
          Width = 313
          Height = 21
          TabOrder = 1
        end
        object cboApplication: TComboBox
          Left = 160
          Top = 75
          Width = 313
          Height = 21
          Style = csDropDownList
          TabOrder = 2
        end
        object cboDistributor: TComboBox
          Left = 160
          Top = 102
          Width = 313
          Height = 21
          Style = csDropDownList
          TabOrder = 3
        end
        object edtVersions: TEdit
          Left = 16
          Top = 151
          Width = 457
          Height = 21
          TabOrder = 4
          TextHint = 'e.g., 1.0, 1.1, 2.0 (leave empty for any version)'
        end
        object chkExpires: TCheckBox
          Left = 16
          Top = 178
          Width = 120
          Height = 17
          Caption = 'License Expires'
          TabOrder = 5
          OnClick = chkExpiresClick
        end
        object dtpExpiration: TDateTimePicker
          Left = 160
          Top = 202
          Width = 186
          Height = 21
          Date = 44562.000000000000000000
          Time = 0.708531724537037000
          TabOrder = 6
        end
        object chkHardwareBinding: TCheckBox
          Left = 16
          Top = 238
          Width = 150
          Height = 17
          Caption = 'Enable Hardware Binding'
          TabOrder = 7
          OnClick = chkHardwareBindingClick
        end
        object cboBindingType: TComboBox
          Left = 160
          Top = 262
          Width = 186
          Height = 21
          Style = csDropDownList
          ItemIndex = 0
          TabOrder = 8
          Text = 'COMBINED'
          Items.Strings = (
            'COMBINED'
            'MAC'
            'CPU'
            'DISK')
        end
        object edtHardwareID: TEdit
          Left = 160
          Top = 289
          Width = 235
          Height = 21
          TabOrder = 9
        end
        object btnGetHardwareID: TButton
          Left = 401
          Top = 287
          Width = 72
          Height = 25
          Caption = 'Get Current'
          TabOrder = 10
          OnClick = btnGetHardwareIDClick
        end
        object memoNotes: TMemo
          Left = 16
          Top = 325
          Width = 457
          Height = 89
          Lines.Strings = (
            '')
          ScrollBars = ssVertical
          TabOrder = 11
        end
        object btnGenerateLicense: TButton
          Left = 16
          Top = 430
          Width = 200
          Height = 40
          Caption = 'Generate Full License'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'Tahoma'
          Font.Style = [fsBold]
          ParentFont = False
          TabOrder = 12
          OnClick = btnGenerateLicenseClick
        end
        object btnGenerateDemo: TButton
          Left = 273
          Top = 430
          Width = 200
          Height = 40
          Caption = 'Generate Demo License'
          TabOrder = 13
          OnClick = btnGenerateDemoClick
        end
      end
      object GroupBox2: TGroupBox
        Left = 509
        Top = 3
        Width = 375
        Height = 550
        Caption = ' Generated License Info '
        TabOrder = 1
        object memoLicenseInfo: TMemo
          Left = 10
          Top = 20
          Width = 355
          Height = 520
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'Courier New'
          Font.Style = []
          ParentFont = False
          ReadOnly = True
          ScrollBars = ssVertical
          TabOrder = 0
        end
      end
    end
    object TabApplications: TTabSheet
      Caption = 'Applications'
      ImageIndex = 1
      object GroupBox3: TGroupBox
        Left = 3
        Top = 3
        Width = 350
        Height = 200
        Caption = ' Application Details '
        TabOrder = 0
        object Label9: TLabel
          Left = 16
          Top = 24
          Width = 31
          Height = 13
          Caption = 'Name:'
        end
        object Label10: TLabel
          Left = 16
          Top = 51
          Width = 60
          Height = 13
          Caption = 'Description:'
        end
        object Label11: TLabel
          Left = 16
          Top = 105
          Width = 41
          Height = 13
          Caption = 'Version:'
        end
        object edtAppName: TEdit
          Left = 100
          Top = 21
          Width = 233
          Height = 21
          TabOrder = 0
        end
        object edtAppDescription: TEdit
          Left = 16
          Top = 70
          Width = 317
          Height = 21
          TabOrder = 1
        end
        object edtAppVersion: TEdit
          Left = 100
          Top = 102
          Width = 100
          Height = 21
          TabOrder = 2
        end
        object btnAddApplication: TButton
          Left = 16
          Top = 142
          Width = 100
          Height = 30
          Caption = 'Add'
          TabOrder = 3
          OnClick = btnAddApplicationClick
        end
        object btnUpdateApplication: TButton
          Left = 122
          Top = 142
          Width = 100
          Height = 30
          Caption = 'Update'
          TabOrder = 4
          OnClick = btnUpdateApplicationClick
        end
        object btnDeleteApplication: TButton
          Left = 228
          Top = 142
          Width = 100
          Height = 30
          Caption = 'Delete'
          TabOrder = 5
          OnClick = btnDeleteApplicationClick
        end
      end
      object lvApplications: TListView
        Left = 3
        Top = 209
        Width = 880
        Height = 355
        Columns = <
          item
            Caption = 'ID'
            Width = 50
          end
          item
            Caption = 'Name'
            Width = 200
          end
          item
            Caption = 'Description'
            Width = 300
          end
          item
            Caption = 'Version'
            Width = 100
          end
          item
            Caption = 'Created'
            Width = 120
          end>
        GridLines = True
        ReadOnly = True
        RowSelect = True
        TabOrder = 1
        ViewStyle = vsReport
        OnClick = lvApplicationsClick
      end
    end
    object TabDistributors: TTabSheet
      Caption = 'Distributors'
      ImageIndex = 2
      object GroupBox4: TGroupBox
        Left = 3
        Top = 3
        Width = 450
        Height = 250
        Caption = ' Distributor Details '
        TabOrder = 0
        object Label12: TLabel
          Left = 16
          Top = 24
          Width = 31
          Height = 13
          Caption = 'Name:'
        end
        object Label13: TLabel
          Left = 16
          Top = 51
          Width = 31
          Height = 13
          Caption = 'Email:'
        end
        object Label14: TLabel
          Left = 16
          Top = 78
          Width = 36
          Height = 13
          Caption = 'Phone:'
        end
        object Label15: TLabel
          Left = 16
          Top = 105
          Width = 43
          Height = 13
          Caption = 'Address:'
        end
        object Label16: TLabel
          Left = 16
          Top = 159
          Width = 33
          Height = 13
          Caption = 'Serial:'
        end
        object edtDistName: TEdit
          Left = 100
          Top = 21
          Width = 333
          Height = 21
          TabOrder = 0
        end
        object edtDistEmail: TEdit
          Left = 100
          Top = 48
          Width = 333
          Height = 21
          TabOrder = 1
        end
        object edtDistPhone: TEdit
          Left = 100
          Top = 75
          Width = 200
          Height = 21
          TabOrder = 2
        end
        object edtDistAddress: TEdit
          Left = 16
          Top = 124
          Width = 417
          Height = 21
          TabOrder = 3
        end
        object edtDistSerial: TEdit
          Left = 100
          Top = 156
          Width = 333
          Height = 21
          Color = clBtnFace
          ReadOnly = True
          TabOrder = 4
        end
        object btnAddDistributor: TButton
          Left = 16
          Top = 194
          Width = 130
          Height = 30
          Caption = 'Add'
          TabOrder = 5
          OnClick = btnAddDistributorClick
        end
        object btnUpdateDistributor: TButton
          Left = 152
          Top = 194
          Width = 130
          Height = 30
          Caption = 'Update'
          TabOrder = 6
          OnClick = btnUpdateDistributorClick
        end
        object btnDeleteDistributor: TButton
          Left = 288
          Top = 194
          Width = 130
          Height = 30
          Caption = 'Delete'
          TabOrder = 7
          OnClick = btnDeleteDistributorClick
        end
      end
      object lvDistributors: TListView
        Left = 3
        Top = 259
        Width = 880
        Height = 305
        Columns = <
          item
            Caption = 'ID'
            Width = 50
          end
          item
            Caption = 'Name'
            Width = 200
          end
          item
            Caption = 'Serial'
            Width = 180
          end
          item
            Caption = 'Email'
            Width = 180
          end
          item
            Caption = 'Phone'
            Width = 120
          end
          item
            Caption = 'Active'
            Width = 60
          end>
        GridLines = True
        ReadOnly = True
        RowSelect = True
        TabOrder = 1
        ViewStyle = vsReport
        OnClick = lvDistributorsClick
      end
    end
    object TabHistory: TTabSheet
      Caption = 'License History'
      ImageIndex = 3
      object GroupBox5: TGroupBox
        Left = 3
        Top = 3
        Width = 880
        Height = 560
        Caption = ' License Records '
        TabOrder = 0
        object lvLicenseHistory: TListView
          Left = 10
          Top = 20
          Width = 860
          Height = 490
          Columns = <
            item
              Caption = 'Serial'
              Width = 200
            end
            item
              Caption = 'Client'
              Width = 150
            end
            item
              Caption = 'Application'
              Width = 150
            end
            item
              Caption = 'Distributor'
              Width = 150
            end
            item
              Caption = 'Created'
              Width = 120
            end
            item
              Caption = 'Type'
              Width = 80
            end>
          GridLines = True
          ReadOnly = True
          RowSelect = True
          TabOrder = 0
          ViewStyle = vsReport
        end
        object btnRefreshHistory: TButton
          Left = 10
          Top = 516
          Width = 150
          Height = 30
          Caption = 'Refresh'
          TabOrder = 1
          OnClick = btnRefreshHistoryClick
        end
        object btnOpenLicenseFolder: TButton
          Left = 166
          Top = 516
          Width = 150
          Height = 30
          Caption = 'Open License Folder'
          TabOrder = 2
          OnClick = btnOpenLicenseFolderClick
        end
      end
    end
    object TabSettings: TTabSheet
      Caption = 'Settings'
      ImageIndex = 4
      object GroupBox6: TGroupBox
        Left = 3
        Top = 3
        Width = 600
        Height = 300
        Caption = ' Configuration '
        TabOrder = 0
        object Label17: TLabel
          Left = 16
          Top = 24
          Width = 116
          Height = 13
          Caption = 'Master Encryption Key:'
        end
        object Label18: TLabel
          Left = 16
          Top = 78
          Width = 67
          Height = 13
          Caption = 'Output Path:'
        end
        object edtMasterKey: TEdit
          Left = 16
          Top = 43
          Width = 560
          Height = 21
          PasswordChar = '*'
          TabOrder = 0
        end
        object edtOutputPath: TEdit
          Left = 16
          Top = 97
          Width = 480
          Height = 21
          TabOrder = 1
        end
        object btnBrowseOutput: TButton
          Left = 502
          Top = 95
          Width = 75
          Height = 25
          Caption = 'Browse...'
          TabOrder = 2
          OnClick = btnBrowseOutputClick
        end
        object btnSaveSettings: TButton
          Left = 16
          Top = 140
          Width = 150
          Height = 35
          Caption = 'Save Settings'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'Tahoma'
          Font.Style = [fsBold]
          ParentFont = False
          TabOrder = 3
          OnClick = btnSaveSettingsClick
        end
        object btnGenerateControlFile: TButton
          Left = 16
          Top = 190
          Width = 200
          Height = 35
          Caption = 'Generate Control File'
          TabOrder = 4
          OnClick = btnGenerateControlFileClick
        end
        object btnShowHardwareInfo: TButton
          Left = 16
          Top = 240
          Width = 200
          Height = 35
          Caption = 'Show Hardware Information'
          TabOrder = 5
          OnClick = btnShowHardwareInfoClick
        end
      end
    end
  end
end
