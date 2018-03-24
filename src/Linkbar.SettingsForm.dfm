object FrmProperties: TFrmProperties
  Left = 206
  Top = 169
  BiDiMode = bdLeftToRight
  BorderIcons = [biSystemMenu]
  BorderWidth = 4
  ClientHeight = 409
  ClientWidth = 408
  Color = clBtnFace
  DefaultMonitor = dmMainForm
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'MS Shell Dlg 2'
  Font.Style = []
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  ParentBiDiMode = False
  Position = poScreenCenter
  OnClose = FormClose
  OnDestroy = FormDestroy
  OnMouseWheel = FormMouseWheel
  DesignSize = (
    408
    409)
  PixelsPerInch = 96
  TextHeight = 14
  object pgc1: TPageControl
    Left = 5
    Top = 6
    Width = 399
    Height = 361
    ActivePage = tsAbout
    Align = alCustom
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 0
    object tsView: TTabSheet
      Caption = 'View'
      DesignSize = (
        391
        332)
      object lblSection1: TLabel
        Left = 8
        Top = 8
        Width = 119
        Height = 14
        Caption = 'Configure appearance'
        Transparent = True
      end
      object pnlDummy11: TPanel
        Left = 8
        Top = 227
        Width = 371
        Height = 22
        Anchors = [akLeft, akTop, akRight]
        BevelOuter = bvNone
        ShowCaption = False
        TabOrder = 7
        object chbUseTextColor: TCheckBox
          Left = 0
          Top = 0
          Width = 185
          Height = 22
          Align = alLeft
          Anchors = [akLeft, akTop, akRight, akBottom]
          Caption = 'Text color:'
          TabOrder = 0
          OnClick = Changed
        end
        object clbTextColor: TColorBox
          Left = 208
          Top = 0
          Width = 163
          Height = 22
          Align = alRight
          DefaultColorColor = clWhite
          NoneColorColor = clNone
          Selected = clWhite
          Style = [cbStandardColors, cbCustomColor, cbPrettyNames, cbCustomColors]
          TabOrder = 1
          OnChange = edtBkgndColorChange
        end
      end
      object pnlDummy1: TPanel
        Left = 8
        Top = 31
        Width = 371
        Height = 22
        Anchors = [akLeft, akTop, akRight]
        BevelOuter = bvNone
        ShowCaption = False
        TabOrder = 0
        object lblScreenEdge: TLabel
          Left = 0
          Top = 0
          Width = 104
          Height = 22
          Align = alLeft
          Caption = 'Position on screen:'
          Layout = tlCenter
          ExplicitHeight = 14
        end
        object cbbScreenPosition: TComboBox
          Left = 208
          Top = 0
          Width = 163
          Height = 22
          Align = alRight
          Style = csDropDownList
          TabOrder = 0
          OnChange = Changed
          Items.Strings = (
            'Left'
            'Top'
            'Right'
            'Bottom')
        end
      end
      object pnlDummy2: TPanel
        Left = 8
        Top = 59
        Width = 371
        Height = 22
        Anchors = [akLeft, akTop, akRight]
        BevelOuter = bvNone
        ShowCaption = False
        TabOrder = 1
        object lblIconSize: TLabel
          Left = 0
          Top = 0
          Width = 51
          Height = 22
          Align = alLeft
          Caption = 'Icon size:'
          Layout = tlCenter
          ExplicitHeight = 14
        end
        object nseIconSize: TnSpinEdit
          Left = 208
          Top = 0
          Width = 163
          Height = 22
          Align = alRight
          MaxValue = 0
          MinValue = 0
          TabOrder = 0
          Value = 0
          OnChange = Changed
        end
      end
      object pnlDummy3: TPanel
        Left = 8
        Top = 115
        Width = 371
        Height = 22
        Anchors = [akLeft, akTop, akRight]
        BevelOuter = bvNone
        ShowCaption = False
        TabOrder = 3
        object lblMargin: TLabel
          Left = 0
          Top = 0
          Width = 153
          Height = 22
          Align = alLeft
          Caption = 'Margins (horizontal/vertical):'
          Layout = tlCenter
          ExplicitHeight = 14
        end
        object bvlSpacer2: TBevel
          Left = 287
          Top = 0
          Width = 5
          Height = 22
          Align = alRight
          Shape = bsSpacer
        end
        object nseMarginH: TnSpinEdit
          Left = 208
          Top = 0
          Width = 79
          Height = 22
          Align = alRight
          MaxValue = 0
          MinValue = 0
          TabOrder = 0
          Value = 0
          OnChange = Changed
        end
        object nseMarginV: TnSpinEdit
          Left = 292
          Top = 0
          Width = 79
          Height = 22
          Align = alRight
          MaxValue = 0
          MinValue = 0
          TabOrder = 1
          Value = 0
          OnChange = Changed
        end
      end
      object pnlDummy4: TPanel
        Left = 8
        Top = 143
        Width = 371
        Height = 22
        Anchors = [akLeft, akTop, akRight]
        BevelOuter = bvNone
        ShowCaption = False
        TabOrder = 4
        object lblOrder: TLabel
          Left = 0
          Top = 0
          Width = 105
          Height = 22
          Align = alLeft
          Caption = 'Order of shortcuts:'
          Layout = tlCenter
          ExplicitHeight = 14
        end
        object cbbItemOrder: TComboBox
          Left = 208
          Top = 0
          Width = 163
          Height = 22
          Align = alRight
          Style = csDropDownList
          TabOrder = 0
          OnChange = Changed
          Items.Strings = (
            'Left to right'
            'Up to down')
        end
      end
      object pnlDummy5: TPanel
        Left = 8
        Top = 171
        Width = 371
        Height = 22
        Anchors = [akLeft, akTop, akRight]
        BevelOuter = bvNone
        ShowCaption = False
        TabOrder = 5
        object lblTextPosition: TLabel
          Left = 0
          Top = 0
          Width = 76
          Height = 22
          Align = alLeft
          Caption = 'Text position:'
          Layout = tlCenter
          ExplicitHeight = 14
        end
        object cbbTextLayout: TComboBox
          Left = 208
          Top = 0
          Width = 163
          Height = 22
          Align = alRight
          Style = csDropDownList
          TabOrder = 0
          OnChange = Changed
          Items.Strings = (
            'Without text'
            'Left'
            'Top'
            'Right'
            'Bottom')
        end
      end
      object pnlDummy6: TPanel
        Left = 8
        Top = 199
        Width = 371
        Height = 22
        Anchors = [akLeft, akTop, akRight]
        BevelOuter = bvNone
        ShowCaption = False
        TabOrder = 6
        object lblTextWidthIdent: TLabel
          Left = 0
          Top = 0
          Width = 105
          Height = 22
          Align = alLeft
          Caption = 'Text width/indent:'
          Layout = tlCenter
          ExplicitHeight = 14
        end
        object bvlSpacer3: TBevel
          Left = 287
          Top = 0
          Width = 5
          Height = 22
          Align = alRight
          Shape = bsSpacer
        end
        object nseTextWidth: TnSpinEdit
          Left = 208
          Top = 0
          Width = 79
          Height = 22
          Align = alRight
          MaxValue = 0
          MinValue = 0
          TabOrder = 0
          Value = 0
          OnChange = Changed
        end
        object nseTextOffset: TnSpinEdit
          Left = 292
          Top = 0
          Width = 79
          Height = 22
          Align = alRight
          MaxValue = 0
          MinValue = 0
          TabOrder = 1
          Value = 0
          OnChange = Changed
        end
      end
      object pnlDummy10: TPanel
        Left = 8
        Top = 87
        Width = 371
        Height = 22
        Anchors = [akLeft, akTop, akRight]
        BevelOuter = bvNone
        ShowCaption = False
        TabOrder = 2
        object btnBkgndColorEdit: TSpeedButton
          Left = 348
          Top = 0
          Width = 23
          Height = 22
          Align = alRight
          Caption = '...'
          OnClick = btnBgColorClick
        end
        object edtBkgndColor: TEdit
          Tag = 3
          Left = 208
          Top = 0
          Width = 140
          Height = 22
          Align = alRight
          Alignment = taCenter
          CharCase = ecUpperCase
          MaxLength = 8
          TabOrder = 1
          Text = 'FFFFFFFF'
          OnChange = edtBkgndColorChange
          OnKeyPress = edtBkgndColorKeyPress
        end
        object chbUseBkgndColor: TCheckBox
          Left = 0
          Top = 0
          Width = 185
          Height = 22
          Align = alLeft
          Anchors = [akLeft, akTop, akRight, akBottom]
          Caption = 'Background color:'
          TabOrder = 0
          OnClick = Changed
        end
      end
      object pnlDummy12: TPanel
        Left = 8
        Top = 255
        Width = 371
        Height = 22
        Anchors = [akLeft, akTop, akRight]
        BevelOuter = bvNone
        ShowCaption = False
        TabOrder = 8
        object lblGlowSize: TLabel
          Left = 0
          Top = 0
          Width = 54
          Height = 22
          Align = alLeft
          Caption = 'Glow size:'
          Layout = tlCenter
          ExplicitHeight = 14
        end
        object nseGlowSize: TnSpinEdit
          Left = 208
          Top = 0
          Width = 163
          Height = 22
          Align = alRight
          MaxValue = 16
          MinValue = 0
          TabOrder = 0
          Value = 0
          OnChange = Changed
        end
      end
      object pnlDummy13: TPanel
        Left = 8
        Top = 283
        Width = 371
        Height = 21
        Anchors = [akLeft, akTop, akRight]
        BevelOuter = bvNone
        ShowCaption = False
        TabOrder = 9
        object chbStayOnTop: TCheckBox
          Left = 0
          Top = 0
          Width = 371
          Height = 21
          Align = alClient
          Caption = 'Always on top'
          TabOrder = 0
          OnClick = Changed
        end
      end
    end
    object tsAutohide: TTabSheet
      Caption = 'Autohide'
      ImageIndex = 3
      DesignSize = (
        391
        332)
      object lblSection2: TLabel
        Left = 8
        Top = 8
        Width = 108
        Height = 14
        Caption = 'Configure auto-hide'
        Transparent = True
      end
      object chbAutoHideTransparency: TCheckBox
        Left = 8
        Top = 255
        Width = 370
        Height = 17
        Anchors = [akLeft, akTop, akRight]
        Caption = 'Transparent when hidden'
        TabOrder = 5
        OnClick = Changed
      end
      object pnlDelay: TPanel
        Left = 8
        Top = 84
        Width = 371
        Height = 22
        Anchors = [akLeft, akTop, akRight]
        BevelOuter = bvNone
        ParentColor = True
        ShowCaption = False
        TabOrder = 2
        object lblDelay: TLabel
          Left = 0
          Top = 0
          Width = 56
          Height = 22
          Align = alLeft
          Caption = 'Delay, ms:'
          Layout = tlCenter
          ExplicitHeight = 14
        end
        object nseAutoShowDelay: TnSpinEdit
          Left = 208
          Top = 0
          Width = 163
          Height = 22
          Align = alRight
          Increment = 50
          MaxValue = 60000
          MinValue = 0
          TabOrder = 0
          Value = 0
          OnChange = Changed
        end
      end
      object pnlDummy7: TPanel
        Left = 8
        Top = 29
        Width = 371
        Height = 21
        Anchors = [akLeft, akTop, akRight]
        BevelOuter = bvNone
        ShowCaption = False
        TabOrder = 0
        object lbl2: TLabel
          Left = 0
          Top = 0
          Width = 28
          Height = 21
          Align = alLeft
          Caption = 'Hide:'
          Layout = tlCenter
          ExplicitHeight = 14
        end
        object chbAutoHide: TCheckBox
          Left = 208
          Top = 0
          Width = 163
          Height = 21
          Align = alRight
          Caption = 'Automatically'
          TabOrder = 0
          OnClick = Changed
        end
      end
      object pnlDummy8: TPanel
        Left = 8
        Top = 56
        Width = 371
        Height = 22
        Anchors = [akLeft, akTop, akRight]
        BevelOuter = bvNone
        ParentColor = True
        ShowCaption = False
        TabOrder = 1
        object lblShow: TLabel
          Left = 0
          Top = 0
          Width = 35
          Height = 22
          Align = alLeft
          Caption = 'Show:'
          Layout = tlCenter
          ExplicitHeight = 14
        end
        object cbbAutoShowMode: TComboBox
          Left = 208
          Top = 0
          Width = 163
          Height = 22
          Align = alRight
          Style = csDropDownList
          TabOrder = 0
          OnChange = Changed
          Items.Strings = (
            'Mouse hover'
            'Mouse left-click'
            'Mouse right-click')
        end
      end
      object pnlHotkey: TPanel
        Left = 8
        Top = 139
        Width = 371
        Height = 22
        Anchors = [akLeft, akTop, akRight]
        BevelOuter = bvNone
        ShowCaption = False
        TabOrder = 4
        object lblHotKey: TLabel
          Left = 0
          Top = 0
          Width = 105
          Height = 22
          Align = alLeft
          Caption = 'Keyboard shortcut:'
          Transparent = True
          Layout = tlCenter
          ExplicitHeight = 14
        end
      end
      object pnlCornerGapWidth: TPanel
        Left = 8
        Top = 111
        Width = 371
        Height = 22
        Anchors = [akLeft, akTop, akRight]
        BevelOuter = bvNone
        ShowCaption = False
        TabOrder = 3
        object lblCornerGapWidth: TLabel
          Left = 0
          Top = 0
          Width = 104
          Height = 22
          Align = alLeft
          Caption = 'Corner gaps width:'
          Layout = tlCenter
          ExplicitHeight = 14
        end
        object Bevel2: TBevel
          Left = 287
          Top = 0
          Width = 5
          Height = 22
          Align = alRight
          Shape = bsSpacer
        end
        object nseCorner1GapWidth: TnSpinEdit
          Left = 208
          Top = 0
          Width = 79
          Height = 22
          Align = alRight
          Increment = 20
          MaxValue = 0
          MinValue = 0
          TabOrder = 0
          Value = 0
          OnChange = Changed
        end
        object nseCorner2GapWidth: TnSpinEdit
          Left = 292
          Top = 0
          Width = 79
          Height = 22
          Align = alRight
          Increment = 20
          MaxValue = 0
          MinValue = 0
          TabOrder = 1
          Value = 0
          OnChange = Changed
        end
      end
    end
    object tsAdditionally: TTabSheet
      Caption = 'Additional'
      ImageIndex = 1
      DesignSize = (
        391
        332)
      object lblSectionAdditional: TLabel
        Left = 8
        Top = 110
        Width = 53
        Height = 14
        Caption = 'Additional'
        Transparent = True
      end
      object lblSectionJumplist: TLabel
        Left = 8
        Top = 8
        Width = 48
        Height = 14
        Caption = 'Jumplists'
        Transparent = True
      end
      object pnlLightStyle: TPanel
        Left = 8
        Top = 122
        Width = 371
        Height = 34
        Anchors = [akLeft, akTop, akRight]
        BevelOuter = bvNone
        ParentColor = True
        ShowCaption = False
        TabOrder = 2
        object chbLightStyle: TCheckBox
          Left = 0
          Top = 0
          Width = 371
          Height = 34
          Align = alTop
          Caption = 'Use style like taskbar with combined buttons'
          TabOrder = 0
          WordWrap = True
          OnClick = Changed
        end
      end
      object chbAeroGlass: TCheckBox
        Left = 8
        Top = 155
        Width = 368
        Height = 22
        Align = alCustom
        Anchors = [akLeft, akTop, akRight]
        Caption = 'Enable AeroGlass support (installed separately)'
        TabOrder = 3
        WordWrap = True
        OnClick = Changed
      end
      object chbShowHints: TCheckBox
        Left = 3
        Top = 300
        Width = 367
        Height = 17
        Align = alCustom
        Caption = 'Show hints'
        TabOrder = 5
        Visible = False
        OnClick = Changed
      end
      object pnlJumplistShowMode: TPanel
        Left = 8
        Top = 31
        Width = 371
        Height = 22
        Anchors = [akLeft, akTop, akRight]
        BevelOuter = bvNone
        ShowCaption = False
        TabOrder = 0
        object lblJumplistShowMode: TLabel
          Left = 0
          Top = 0
          Width = 35
          Height = 22
          Align = alLeft
          Caption = 'Show:'
          Layout = tlCenter
          ExplicitHeight = 14
        end
        object cbbJumplistShowMode: TComboBox
          Left = 208
          Top = 0
          Width = 163
          Height = 22
          Align = alRight
          Style = csDropDownList
          TabOrder = 0
          OnChange = Changed
          Items.Strings = (
            'Disabled'
            'Mouse right-click')
        end
      end
      object pnlJumplistRecentMax: TPanel
        Left = 8
        Top = 61
        Width = 371
        Height = 33
        Anchors = [akLeft, akTop, akRight]
        BevelOuter = bvNone
        ShowCaption = False
        TabOrder = 1
        object lblJumplistRecentMax: TLabel
          Left = 0
          Top = 0
          Width = 291
          Height = 33
          Align = alClient
          Caption = 'Max items:'
          Layout = tlCenter
          WordWrap = True
          ExplicitWidth = 58
          ExplicitHeight = 14
        end
        object Bevel1: TBevel
          Left = 291
          Top = 0
          Width = 32
          Height = 33
          Align = alRight
          Shape = bsSpacer
        end
        object pnlDummy21: TPanel
          Left = 323
          Top = 0
          Width = 48
          Height = 33
          Align = alRight
          BevelOuter = bvNone
          Caption = 'pnlDummy21'
          ShowCaption = False
          TabOrder = 0
          object nseJumplistRecentMax: TnSpinEdit
            Left = 0
            Top = 0
            Width = 48
            Height = 22
            Align = alCustom
            MaxValue = 99
            MinValue = 1
            TabOrder = 0
            Value = 1
            OnChange = Changed
          end
        end
      end
      object pnlLook: TPanel
        Left = 8
        Top = 193
        Width = 371
        Height = 22
        Anchors = [akLeft, akTop, akRight]
        BevelOuter = bvNone
        ShowCaption = False
        TabOrder = 4
        object lblLook: TLabel
          Left = 0
          Top = 0
          Width = 26
          Height = 22
          Align = alLeft
          Caption = 'Look'
          Layout = tlCenter
          ExplicitHeight = 14
        end
        object cbbLook: TComboBox
          Left = 208
          Top = 0
          Width = 163
          Height = 22
          Align = alRight
          Style = csDropDownList
          TabOrder = 0
          OnChange = Changed
          Items.Strings = (
            'Opaque'
            'Transparent'
            'Glass')
        end
      end
    end
    object tsAbout: TTabSheet
      Caption = 'About'
      ImageIndex = 1
      DesignSize = (
        391
        332)
      object lblVer: TLabel
        Left = 8
        Top = 8
        Width = 44
        Height = 14
        Align = alCustom
        Alignment = taCenter
        Caption = 'Version:'
      end
      object lblEmail: TLabel
        Left = 8
        Top = 36
        Width = 35
        Height = 14
        Caption = 'e-mail:'
      end
      object lblWeb: TLabel
        Left = 8
        Top = 56
        Width = 28
        Height = 14
        Caption = 'web:'
      end
      object Label2: TLabel
        Left = 8
        Top = 132
        Width = 68
        Height = 14
        Caption = 'System info:'
      end
      object lblLocalizer: TLabel
        Left = 8
        Top = 96
        Width = 75
        Height = 14
        Caption = 'localizer: Asaq'
      end
      object lblSysInfo: TLabel
        Left = 8
        Top = 152
        Width = 372
        Height = 70
        Anchors = [akLeft, akTop, akRight]
        AutoSize = False
        Caption = 'lblSysInfo'#13#10'1'#13#10'2'#13#10'3'#13#10'4'
        PopupMenu = pmSysInfo
        WordWrap = True
      end
      object lblGithub: TLabel
        Left = 8
        Top = 76
        Width = 41
        Height = 14
        Caption = 'GitHub:'
      end
      object linkEmail: TLinkLabel
        Left = 46
        Top = 36
        Width = 69
        Height = 18
        Caption = '<a href="">linkbar email</a>'
        TabOrder = 0
        TabStop = True
        OnLinkClick = linkEmailLinkClick
      end
      object linkWeb: TLinkLabel
        Left = 39
        Top = 56
        Width = 93
        Height = 18
        Caption = '<a href="">linkbar webpage</a>'
        TabOrder = 1
        TabStop = True
        OnLinkClick = linkWebLinkClick
      end
      object linkGithub: TLinkLabel
        Left = 52
        Top = 76
        Width = 77
        Height = 18
        Caption = '<a href="">linkbar github</a>'
        TabOrder = 2
        TabStop = True
        OnLinkClick = linkWebLinkClick
      end
    end
  end
  object btnApply: TButton
    Left = 324
    Top = 374
    Width = 80
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Apply'
    TabOrder = 3
    OnClick = DialogButtonClick
  end
  object btnCancel: TButton
    Left = 240
    Top = 374
    Width = 80
    Height = 25
    Anchors = [akTop, akRight]
    Cancel = True
    Caption = 'Cancel'
    TabOrder = 2
    OnClick = btnCancelClick
  end
  object btnOk: TButton
    Left = 156
    Top = 374
    Width = 80
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'OK'
    Default = True
    TabOrder = 1
    OnClick = DialogButtonClick
  end
  object pmSysInfo: TPopupMenu
    Left = 168
    Top = 80
    object imCopy: TMenuItem
      Caption = 'Copy'
      OnClick = imCopyClick
    end
  end
end
