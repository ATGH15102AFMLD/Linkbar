object HotkeyEdit: THotkeyEdit
  Left = 0
  Top = 0
  Width = 353
  Height = 22
  TabOrder = 0
  OnResize = FrameResize
  object Bevel1: TBevel
    Left = 227
    Top = 0
    Width = 126
    Height = 22
    Align = alClient
    Shape = bsSpacer
    ExplicitLeft = 228
    ExplicitWidth = 86
  end
  object chbWin: TCheckBox
    Left = 172
    Top = 0
    Width = 55
    Height = 22
    Align = alLeft
    Caption = 'WIN +'
    TabOrder = 3
    OnClick = Changed
  end
  object chbAlt: TCheckBox
    Left = 121
    Top = 0
    Width = 51
    Height = 22
    Align = alLeft
    Caption = 'ALT +'
    TabOrder = 2
    OnClick = Changed
  end
  object chbCtrl: TCheckBox
    Left = 63
    Top = 0
    Width = 58
    Height = 22
    Align = alLeft
    Caption = 'CTRL +'
    TabOrder = 1
    OnClick = Changed
  end
  object chbShift: TCheckBox
    Left = 0
    Top = 0
    Width = 63
    Height = 22
    Align = alLeft
    Caption = 'SHIFT +'
    TabOrder = 0
    OnClick = Changed
  end
  object htkKey: THotKey
    Left = 255
    Top = 1
    Width = 86
    Height = 21
    AutoSize = False
    HotKey = 112
    Modifiers = []
    TabOrder = 4
    OnChange = Changed
  end
end
