object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'Window Explorer'
  ClientHeight = 295
  ClientWidth = 379
  Color = clBtnFace
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  DesignSize = (
    379
    295)
  PixelsPerInch = 96
  TextHeight = 13
  object lbChild: TListBox
    Left = 151
    Top = 8
    Width = 220
    Height = 279
    Anchors = [akLeft, akTop, akRight, akBottom]
    ItemHeight = 13
    TabOrder = 0
    OnDblClick = lbChildDblClick
    OnMouseDown = lbChildMouseDown
  end
  object edtWindowName: TEdit
    Left = 8
    Top = 8
    Width = 137
    Height = 21
    TabOrder = 1
    OnChange = edtWindowNameChange
    OnKeyDown = edtWindowNameKeyDown
    OnKeyPress = edtWindowNameKeyPress
  end
  object tbTransparency: TTrackBar
    Left = 8
    Top = 35
    Width = 137
    Height = 30
    Max = 255
    Min = 55
    Frequency = 20
    Position = 55
    TabOrder = 2
    OnChange = tbTransparencyChange
  end
  object btnBorderlessFullscreen: TButton
    Left = 8
    Top = 71
    Width = 137
    Height = 25
    Caption = 'Borderless Fullscreen'
    TabOrder = 3
    OnClick = btnBorderlessFullscreenClick
  end
  object cbHideTaskbar: TCheckBox
    Left = 8
    Top = 102
    Width = 137
    Height = 17
    Caption = 'Hide Taskbar'
    TabOrder = 4
    OnClick = cbHideTaskbarClick
  end
end
