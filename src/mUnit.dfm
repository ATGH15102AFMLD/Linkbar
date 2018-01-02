object LinkbarWcl: TLinkbarWcl
  Left = 505
  Top = 192
  ClientHeight = 68
  ClientWidth = 365
  Color = clBtnFace
  DefaultMonitor = dmMainForm
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
  PixelsPerInch = 96
  TextHeight = 16
  object pMenu: TPopupMenu
    Left = 8
    Top = 8
    object imNewShortcut: TMenuItem
      Caption = 'New shortcut'
      OnClick = imNewShortcutClick
    end
    object imOpenWorkdir: TMenuItem
      Caption = 'Open working directory'
      GroupIndex = 2
      OnClick = imOpenWorkdirClick
    end
    object N1: TMenuItem
      Caption = '-'
      GroupIndex = 2
    end
    object imAddBar: TMenuItem
      Caption = 'Create linkbar...'
      GroupIndex = 2
      OnClick = imAddBarClick
    end
    object imRemoveBar: TMenuItem
      Caption = 'Delete the linkbar'
      GroupIndex = 2
      OnClick = imRemoveBarClick
    end
    object N2: TMenuItem
      Caption = '-'
      GroupIndex = 2
    end
    object imLockBar: TMenuItem
      AutoCheck = True
      Caption = 'Lock the linkbar'
      GroupIndex = 2
      OnClick = imLockBarClick
    end
    object imSortAlphabet: TMenuItem
      Caption = 'Sort alphabetically'
      GroupIndex = 2
      OnClick = imSortAlphabetClick
    end
    object imProperties: TMenuItem
      Caption = 'Properties'
      GroupIndex = 2
      OnClick = imPropertiesClick
    end
    object N3: TMenuItem
      Caption = '-'
      GroupIndex = 2
    end
    object imClose: TMenuItem
      Caption = 'Close'
      GroupIndex = 2
      OnClick = imCloseClick
    end
    object imCloseAll: TMenuItem
      Caption = 'Close all'
      GroupIndex = 2
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
