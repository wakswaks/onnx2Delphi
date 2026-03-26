object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'YOLOv5 '#30446#26631#26816#27979
  ClientHeight = 600
  ClientWidth = 800
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 13
  object Image1: TImage
    Left = 0
    Top = 65
    Width = 800
    Height = 513
    Align = alClient
    ExplicitLeft = 16
    ExplicitTop = 88
    ExplicitWidth = 305
    ExplicitHeight = 257
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 800
    Height = 65
    Align = alTop
    TabOrder = 0
    object btnSelectImage: TButton
      Left = 24
      Top = 16
      Width = 105
      Height = 33
      Caption = #36873#25321#22270#29255
      TabOrder = 0
      OnClick = btnSelectImageClick
    end
    object btnDetect: TButton
      Left = 152
      Top = 16
      Width = 105
      Height = 33
      Caption = #24320#22987#35782#21035
      TabOrder = 1
      OnClick = btnDetectClick
    end
    object Memo1: TMemo
      Left = 296
      Top = 10
      Width = 481
      Height = 49
      TabOrder = 2
    end
  end
  object StatusBar1: TStatusBar
    Left = 0
    Top = 578
    Width = 800
    Height = 22
    Panels = <>
    SimplePanel = True
    SimpleText = #23601#32490
  end
  object OpenDialog1: TOpenDialog
    Left = 40
    Top = 80
  end
end
