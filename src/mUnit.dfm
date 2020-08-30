object LinkbarWcl: TLinkbarWcl
  Left = 505
  Top = 192
  ClientHeight = 68
  ClientWidth = 365
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -13
  Font.Name = 'Default'
  Font.Style = []
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  OnContextPopup = FormContextPopup
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyDown = FormKeyDown
  OnMouseDown = FormMouseDown
  OnMouseEnter = FormMouseEnter
  OnMouseLeave = FormMouseLeave
  OnMouseMove = FormMouseMove
  OnMouseUp = FormMouseUp
  OnResize = FormResize
  PixelsPerInch = 96
  TextHeight = 16
  object pMenu: TPopupMenu
    Left = 8
    Top = 8
    object imNew: TMenuItem
      Caption = 'New'
      GroupIndex = 3
      object imNewShortcut: TMenuItem
        Caption = 'Shortcut'
        GroupIndex = 3
        OnClick = imNewShortcutClick
      end
      object imNewSeparator: TMenuItem
        Caption = 'Separator'
        GroupIndex = 3
        OnClick = imNewSeparatorClick
      end
      object imAddBar: TMenuItem
        Caption = 'Linkbar'
        GroupIndex = 3
        OnClick = imAddBarClick
      end
    end
    object N2: TMenuItem
      Caption = '-'
      GroupIndex = 3
    end
    object imRemoveBar: TMenuItem
      Caption = 'Delete the linkbar...'
      GroupIndex = 3
      OnClick = imRemoveBarClick
    end
    object imOpenWorkdir: TMenuItem
      Tag = 10
      Caption = 'Open working directory'
      GroupIndex = 3
      OnClick = imOpenWorkdirClick
    end
    object N1: TMenuItem
      Caption = '-'
      GroupIndex = 3
    end
    object imLockBar: TMenuItem
      AutoCheck = True
      Caption = 'Lock the linkbar'
      GroupIndex = 3
      OnClick = imLockBarClick
    end
    object imSortAlphabet: TMenuItem
      Caption = 'Sort alphabetically'
      GroupIndex = 3
      OnClick = imSortAlphabetClick
    end
    object imProperties: TMenuItem
      Caption = 'Settings...'
      GroupIndex = 3
      OnClick = imPropertiesClick
    end
    object N3: TMenuItem
      Caption = '-'
      GroupIndex = 3
    end
    object imClose: TMenuItem
      Tag = 20
      Caption = 'Close'
      GroupIndex = 3
      ShortCut = 32884
      OnClick = imCloseClick
    end
    object imCloseAll: TMenuItem
      Tag = 10
      Caption = 'Close all'
      GroupIndex = 3
      OnClick = imCloseAllClick
    end
  end
  object tmrUpdate: TTimer
    Enabled = False
    Interval = 100
    OnTimer = tmrUpdateTimer
    Left = 48
    Top = 8
  end
end
