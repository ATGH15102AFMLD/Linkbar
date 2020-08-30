object HotkeyEdit: THotkeyEdit
  Left = 0
  Top = 0
  Width = 251
  Height = 22
  TabOrder = 0
  OnResize = FrameResize
  object Bevel1: TBevel
    Left = 197
    Top = 0
    Width = 54
    Height = 22
    Align = alRight
    Shape = bsSpacer
    ExplicitLeft = 349
  end
  object htkKey: THotKey
    Left = 210
    Top = 1
    Width = 29
    Height = 21
    AutoSize = False
    HotKey = 112
    Modifiers = []
    TabOrder = 0
    OnChange = Changed
  end
  object pnlButtons: TPanel
    Left = 4
    Top = 0
    Width = 193
    Height = 22
    Align = alRight
    BevelOuter = bvNone
    ShowCaption = False
    TabOrder = 1
    object Bevel2: TBevel
      Left = 169
      Top = 0
      Width = 3
      Height = 22
      Align = alLeft
      Shape = bsSpacer
    end
    object Bevel3: TBevel
      Left = 126
      Top = 0
      Width = 3
      Height = 22
      Align = alLeft
      Shape = bsSpacer
    end
    object Bevel4: TBevel
      Left = 83
      Top = 0
      Width = 3
      Height = 22
      Align = alLeft
      Shape = bsSpacer
    end
    object Bevel5: TBevel
      Left = 40
      Top = 0
      Width = 3
      Height = 22
      Align = alLeft
      Shape = bsSpacer
    end
    object btnAlt: TSpeedButton
      Left = 86
      Top = 0
      Width = 40
      Height = 22
      Align = alLeft
      AllowAllUp = True
      GroupIndex = 3
      Caption = 'Alt'
      OnClick = btnShiftClick
      ExplicitLeft = 56
    end
    object btnCtrl: TSpeedButton
      Left = 43
      Top = 0
      Width = 40
      Height = 22
      Align = alLeft
      AllowAllUp = True
      GroupIndex = 2
      Caption = 'Ctrl'
      OnClick = btnShiftClick
      ExplicitLeft = 16
    end
    object btnShift: TSpeedButton
      Left = 0
      Top = 0
      Width = 40
      Height = 22
      Align = alLeft
      AllowAllUp = True
      GroupIndex = 1
      Caption = 'Shift'
      OnClick = btnShiftClick
      ExplicitLeft = 35
    end
    object btnWin: TSpeedButton
      Left = 129
      Top = 0
      Width = 40
      Height = 22
      Align = alLeft
      AllowAllUp = True
      GroupIndex = 4
      Caption = 'Win'
      OnClick = btnShiftClick
      ExplicitLeft = 182
    end
  end
end
