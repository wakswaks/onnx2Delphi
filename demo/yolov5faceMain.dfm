object frmFaceDetection: TfrmFaceDetection
  Left = 0
  Top = 0
  Caption = 'Face Detection - ONNX Runtime'
  ClientHeight = 700
  ClientWidth = 900
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 15
  object imgDisplay: TImage
    Left = 0
    Top = 65
    Width = 900
    Height = 635
    Align = alClient
    Proportional = True
    Stretch = True
    ExplicitLeft = 8
    ExplicitTop = 48
    ExplicitWidth = 884
    ExplicitHeight = 544
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 0
    Width = 900
    Height = 65
    Align = alTop
    BevelOuter = bvNone
    Padding.Left = 10
    Padding.Top = 10
    Padding.Right = 10
    Padding.Bottom = 10
    TabOrder = 0
    object lblStatus: TLabel
      Left = 488
      Top = 10
      Width = 402
      Height = 45
      Align = alRight
      Alignment = taCenter
      Caption = 'Please select an image to start'
      Layout = tlCenter
    end
    object btnSelectImage: TButton
      Left = 10
      Top = 10
      Width = 150
      Height = 40
      Caption = 'Select Image'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 0
      OnClick = btnSelectImageClick
    end
    object btnDetectFaces: TButton
      Left = 180
      Top = 10
      Width = 150
      Height = 40
      Caption = 'Detect Faces'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 1
      OnClick = btnDetectFacesClick
    end
  end
  object OpenDialog: TOpenDialog
    Filter = 'Image Files|*.jpg;*.jpeg;*.png;*.bmp;*.gif|All Files|*.*'
    Title = 'Select Image File'
    Left = 500
    Top = 650
  end
end
