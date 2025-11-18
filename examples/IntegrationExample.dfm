object FormExample: TFormExample
  Left = 0
  Top = 0
  Caption = 'LicenseGuard Integration Example'
  ClientHeight = 500
  ClientWidth = 700
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
  object PanelTop: TPanel
    Left = 0
    Top = 0
    Width = 700
    Height = 80
    Align = alTop
    BevelOuter = bvNone
    Color = clWhite
    ParentBackground = False
    TabOrder = 0
    object Label1: TLabel
      Left = 16
      Top = 16
      Width = 292
      Height = 19
      Caption = 'LicenseGuard Integration Example'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblLicenseStatus: TLabel
      Left = 16
      Top = 48
      Width = 107
      Height = 13
      Caption = 'License Status: None'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clRed
      Font.Height = -11
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
    end
  end
  object GroupBox1: TGroupBox
    Left = 0
    Top = 80
    Width = 700
    Height = 200
    Align = alTop
    Caption = ' License Information '
    TabOrder = 1
    object memoLicenseInfo: TMemo
      Left = 2
      Top = 15
      Width = 696
      Height = 183
      Align = alClient
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
  object GroupBox2: TGroupBox
    Left = 0
    Top = 280
    Width = 700
    Height = 200
    Align = alClient
    Caption = ' Actions '
    TabOrder = 2
    object btnLoadLicense: TButton
      Left = 16
      Top = 24
      Width = 200
      Height = 35
      Caption = 'Load License File...'
      TabOrder = 0
      OnClick = btnLoadLicenseClick
    end
    object btnShowHardwareID: TButton
      Left = 16
      Top = 72
      Width = 200
      Height = 35
      Caption = 'Show Hardware ID'
      TabOrder = 1
      OnClick = btnShowHardwareIDClick
    end
    object btnValidate: TButton
      Left = 16
      Top = 120
      Width = 200
      Height = 35
      Caption = 'Validate License'
      TabOrder = 2
      OnClick = btnValidateClick
    end
    object btnFeatureDemo: TButton
      Left = 240
      Top = 24
      Width = 200
      Height = 35
      Caption = 'Test Basic Feature'
      TabOrder = 3
      OnClick = btnFeatureDemoClick
    end
    object btnFeatureFull: TButton
      Left = 240
      Top = 72
      Width = 200
      Height = 35
      Caption = 'Test Full Feature'
      Enabled = False
      TabOrder = 4
      OnClick = btnFeatureFullClick
    end
  end
  object StatusBar1: TStatusBar
    Left = 0
    Top = 480
    Width = 700
    Height = 20
    Panels = <>
    SimplePanel = True
  end
  object OpenDialog1: TOpenDialog
    Left = 472
    Top = 24
  end
end
