object FormLicenseTester: TFormLicenseTester
  Left = 0
  Top = 0
  Caption = 'LicenseGuard - License Tester'
  ClientHeight = 720
  ClientWidth = 1000
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Size = 8
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 1000
    Height = 65
    Align = alTop
    BevelOuter = bvNone
    Color = 2303264
    ParentBackground = False
    TabOrder = 0
    object lblTitle: TLabel
      Left = 16
      Top = 16
      Width = 391
      Height = 33
      Caption = 'LicenseGuard - License Tester'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -27
      Font.Name = 'Segoe UI'
      Font.Size = 20
      Font.Style = [fsBold]
      ParentFont = False
    end
  end
  object pnlMain: TPanel
    Left = 0
    Top = 65
    Width = 1000
    Height = 611
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    object grpApplicationInfo: TGroupBox
      Left = 16
      Top = 16
      Width = 968
      Height = 89
      Caption = ' Application Information '
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Size = 8
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 0
      object lblAppName: TLabel
        Left = 16
        Top = 28
        Width = 103
        Height = 13
        Caption = 'Application Name:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Size = 8
        Font.Style = []
        ParentFont = False
      end
      object lblAppVersion: TLabel
        Left = 400
        Top = 28
        Width = 42
        Height = 13
        Caption = 'Version:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Size = 8
        Font.Style = []
        ParentFont = False
      end
      object edtAppName: TEdit
        Left = 16
        Top = 47
        Width = 361
        Height = 21
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Size = 8
        Font.Style = []
        ParentFont = False
        TabOrder = 0
        Text = 'Test Application'
      end
      object edtAppVersion: TEdit
        Left = 400
        Top = 47
        Width = 121
        Height = 21
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Size = 8
        Font.Style = []
        ParentFont = False
        TabOrder = 1
        Text = '1.0.0'
      end
      object btnSetAppInfo: TButton
        Left = 544
        Top = 45
        Width = 145
        Height = 25
        Caption = 'Set Application Info'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Size = 8
        Font.Style = []
        ParentFont = False
        TabOrder = 2
        OnClick = btnSetAppInfoClick
      end
    end
    object grpLicenseFile: TGroupBox
      Left = 16
      Top = 120
      Width = 968
      Height = 89
      Caption = ' License File '
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Size = 8
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 1
      object edtLicensePath: TEdit
        Left = 16
        Top = 32
        Width = 793
        Height = 21
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Size = 8
        Font.Style = []
        ParentFont = False
        TabOrder = 0
      end
      object btnBrowse: TButton
        Left = 824
        Top = 30
        Width = 121
        Height = 25
        Caption = 'Browse...'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Size = 8
        Font.Style = []
        ParentFont = False
        TabOrder = 1
        OnClick = btnBrowseClick
      end
      object btnLoadLicense: TButton
        Left = 16
        Top = 59
        Width = 929
        Height = 25
        Caption = 'Load and Validate License'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Size = 8
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 2
        OnClick = btnLoadLicenseClick
      end
    end
    object grpLicenseInfo: TGroupBox
      Left = 16
      Top = 224
      Width = 481
      Height = 217
      Caption = ' License Information '
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Size = 8
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 2
      object memoLicenseInfo: TMemo
        Left = 16
        Top = 24
        Width = 449
        Height = 177
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Courier New'
        Font.Size = 8
        Font.Style = []
        ParentFont = False
        ReadOnly = True
        ScrollBars = ssVertical
        TabOrder = 0
      end
    end
    object grpValidation: TGroupBox
      Left = 512
      Top = 224
      Width = 472
      Height = 105
      Caption = ' Validation Status '
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Size = 8
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 3
      object lblValidationStatus: TLabel
        Left = 16
        Top = 28
        Width = 41
        Height = 13
        Caption = 'Status:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Size = 8
        Font.Style = []
        ParentFont = False
      end
      object lblStatus: TLabel
        Left = 120
        Top = 24
        Width = 71
        Height = 19
        Caption = 'NO LICENSE'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clGray
        Font.Height = -16
        Font.Name = 'Tahoma'
        Font.Size = 12
        Font.Style = []
        ParentFont = False
      end
      object lblDaysRemaining: TLabel
        Left = 16
        Top = 60
        Width = 91
        Height = 13
        Caption = 'Days Remaining:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Size = 8
        Font.Style = []
        ParentFont = False
      end
      object lblDaysValue: TLabel
        Left = 120
        Top = 60
        Width = 21
        Height = 13
        Caption = 'N/A'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Size = 8
        Font.Style = []
        ParentFont = False
      end
    end
    object grpHardwareInfo: TGroupBox
      Left = 512
      Top = 336
      Width = 472
      Height = 105
      Caption = ' Hardware Information '
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Size = 8
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 4
      object memoHardwareInfo: TMemo
        Left = 16
        Top = 24
        Width = 329
        Height = 65
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Courier New'
        Font.Size = 8
        Font.Style = []
        ParentFont = False
        ReadOnly = True
        ScrollBars = ssVertical
        TabOrder = 0
      end
      object btnRefreshHardware: TButton
        Left = 360
        Top = 24
        Width = 97
        Height = 65
        Caption = 'Refresh Hardware Info'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Size = 8
        Font.Style = []
        ParentFont = False
        TabOrder = 1
        WordWrap = True
        OnClick = btnRefreshHardwareClick
      end
    end
    object grpFeatureTest: TGroupBox
      Left = 16
      Top = 456
      Width = 968
      Height = 137
      Caption = ' Feature Access Testing '
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Size = 8
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 5
      object lblCustomFeature: TLabel
        Left = 16
        Top = 92
        Width = 138
        Height = 13
        Caption = 'Custom Feature Name:'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Size = 8
        Font.Style = []
        ParentFont = False
      end
      object btnTestBasicFeature: TButton
        Left = 16
        Top = 32
        Width = 297
        Height = 41
        Caption = 'Test Basic Feature Access'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Size = 8
        Font.Style = []
        ParentFont = False
        TabOrder = 0
        OnClick = btnTestBasicFeatureClick
      end
      object btnTestFullFeature: TButton
        Left = 336
        Top = 32
        Width = 297
        Height = 41
        Caption = 'Test Full Feature Access'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Size = 8
        Font.Style = []
        ParentFont = False
        TabOrder = 1
        OnClick = btnTestFullFeatureClick
      end
      object btnTestCustomFeature: TButton
        Left = 648
        Top = 85
        Width = 297
        Height = 41
        Caption = 'Test Custom Feature'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Size = 8
        Font.Style = []
        ParentFont = False
        TabOrder = 2
        OnClick = btnTestCustomFeatureClick
      end
      object edtCustomFeature: TEdit
        Left = 176
        Top = 89
        Width = 457
        Height = 21
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Size = 8
        Font.Style = []
        ParentFont = False
        TabOrder = 3
        Text = 'AdvancedReports'
      end
    end
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 676
    Width = 1000
    Height = 44
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    object btnClearAll: TButton
      Left = 16
      Top = 8
      Width = 145
      Height = 33
      Caption = 'Clear All'
      TabOrder = 0
      OnClick = btnClearAllClick
    end
    object btnExit: TButton
      Left = 839
      Top = 8
      Width = 145
      Height = 33
      Caption = 'Exit'
      TabOrder = 1
      OnClick = btnExitClick
    end
  end
  object StatusBar1: TStatusBar
    Left = 0
    Top = 701
    Width = 1000
    Height = 19
    Panels = <>
    SimplePanel = True
  end
  object OpenDialog1: TOpenDialog
    Left = 920
    Top = 24
  end
end
