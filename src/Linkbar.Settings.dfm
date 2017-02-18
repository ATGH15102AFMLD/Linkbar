object FrmProperties: TFrmProperties
  Left = 600
  Top = 263
  ActiveControl = chbLightStyle
  BiDiMode = bdLeftToRight
  BorderIcons = [biSystemMenu]
  BorderWidth = 4
  ClientHeight = 517
  ClientWidth = 383
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
    383
    517)
  PixelsPerInch = 96
  TextHeight = 14
  object pgc1: TPageControl
    Left = 5
    Top = 6
    Width = 374
    Height = 470
    ActivePage = tsAdditionally
    Align = alCustom
    Anchors = [akLeft, akTop, akRight]
    TabOrder = 0
    object tsOptions: TTabSheet
      Caption = 'View'
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      DesignSize = (
        366
        441)
      object lblSection2: TLabel
        Left = 8
        Top = 296
        Width = 108
        Height = 14
        Caption = 'Configure auto-hide'
        Transparent = True
      end
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
        Width = 346
        Height = 22
        Anchors = [akLeft, akTop, akRight]
        BevelOuter = bvNone
        ShowCaption = False
        TabOrder = 7
        object chbUseTxtColor: TCheckBox
          Left = 0
          Top = 0
          Width = 160
          Height = 22
          Align = alLeft
          Anchors = [akLeft, akTop, akRight, akBottom]
          Caption = 'Text color:'
          TabOrder = 0
          OnClick = OptionsChanged
        end
        object clbTextColor: TColorBox
          Left = 196
          Top = 0
          Width = 150
          Height = 22
          Align = alRight
          DefaultColorColor = clWhite
          NoneColorColor = clNone
          Selected = clWhite
          Style = [cbStandardColors, cbCustomColor, cbPrettyNames, cbCustomColors]
          TabOrder = 1
          OnChange = edtColorBgChange
        end
      end
      object pnlDummy1: TPanel
        Left = 8
        Top = 31
        Width = 346
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
          Left = 196
          Top = 0
          Width = 150
          Height = 22
          Align = alRight
          Style = csDropDownList
          TabOrder = 0
          OnChange = OptionsChanged
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
        Width = 346
        Height = 22
        Anchors = [akLeft, akTop, akRight]
        BevelOuter = bvNone
        ShowCaption = False
        TabOrder = 1
        object lblIconSize: TLabel
          Left = 0
          Top = 0
          Width = 51
          Height = 14
          Align = alLeft
          Caption = 'Icon size:'
          Layout = tlCenter
        end
        object bvlSpacer1: TBevel
          Left = 192
          Top = 0
          Width = 4
          Height = 22
          Align = alRight
          Shape = bsSpacer
          ExplicitLeft = 194
        end
        object nseIconSize: TnSpinEdit
          Left = 196
          Top = 0
          Width = 150
          Height = 22
          Align = alRight
          MaxValue = 0
          MinValue = 0
          TabOrder = 0
          Value = 0
          OnChange = OptionsChanged
        end
      end
      object pnlDummy3: TPanel
        Left = 8
        Top = 115
        Width = 346
        Height = 22
        Anchors = [akLeft, akTop, akRight]
        BevelOuter = bvNone
        ShowCaption = False
        TabOrder = 3
        object lblMargin: TLabel
          Left = 0
          Top = 0
          Width = 153
          Height = 14
          Align = alLeft
          Caption = 'Margins (horizontal/vertical):'
          Layout = tlCenter
        end
        object bvlSpacer2: TBevel
          Left = 269
          Top = 0
          Width = 4
          Height = 22
          Align = alRight
          Shape = bsSpacer
          ExplicitLeft = 268
        end
        object nseMarginH: TnSpinEdit
          Left = 196
          Top = 0
          Width = 73
          Height = 22
          Align = alRight
          MaxValue = 0
          MinValue = 0
          TabOrder = 0
          Value = 0
          OnChange = OptionsChanged
        end
        object nseMarginV: TnSpinEdit
          Left = 273
          Top = 0
          Width = 73
          Height = 22
          Align = alRight
          MaxValue = 0
          MinValue = 0
          TabOrder = 1
          Value = 0
          OnChange = OptionsChanged
        end
      end
      object pnlDummy4: TPanel
        Left = 8
        Top = 143
        Width = 346
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
          Left = 196
          Top = 0
          Width = 150
          Height = 22
          Align = alRight
          Style = csDropDownList
          TabOrder = 0
          OnChange = OptionsChanged
          Items.Strings = (
            'Left to right'
            'Up to down')
        end
      end
      object pnlDummy5: TPanel
        Left = 8
        Top = 171
        Width = 346
        Height = 22
        Anchors = [akLeft, akTop, akRight]
        BevelOuter = bvNone
        ShowCaption = False
        TabOrder = 5
        object Label1: TLabel
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
          Left = 196
          Top = 0
          Width = 150
          Height = 22
          Align = alRight
          Style = csDropDownList
          TabOrder = 0
          OnChange = OptionsChanged
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
        Width = 346
        Height = 22
        Anchors = [akLeft, akTop, akRight]
        BevelOuter = bvNone
        ShowCaption = False
        TabOrder = 6
        object Label6: TLabel
          Left = 0
          Top = 0
          Width = 105
          Height = 14
          Align = alLeft
          Caption = 'Text width/indent:'
          Layout = tlCenter
        end
        object bvlSpacer3: TBevel
          Left = 269
          Top = 0
          Width = 4
          Height = 22
          Align = alRight
          Shape = bsSpacer
          ExplicitLeft = 268
        end
        object nseTextWidth: TnSpinEdit
          Left = 196
          Top = 0
          Width = 73
          Height = 22
          Align = alRight
          MaxValue = 0
          MinValue = 0
          TabOrder = 0
          Value = 0
          OnChange = OptionsChanged
        end
        object nseTextOffset: TnSpinEdit
          Left = 273
          Top = 0
          Width = 73
          Height = 22
          Align = alRight
          MaxValue = 0
          MinValue = 0
          TabOrder = 1
          Value = 0
          OnChange = OptionsChanged
        end
      end
      object pnlDummy7: TPanel
        Left = 8
        Top = 317
        Width = 346
        Height = 21
        Anchors = [akLeft, akTop, akRight]
        BevelOuter = bvNone
        ShowCaption = False
        TabOrder = 9
        object lbl2: TLabel
          Left = 0
          Top = 0
          Width = 28
          Height = 14
          Align = alLeft
          Caption = 'Hide:'
          Layout = tlCenter
        end
        object chbAutoHide: TCheckBox
          Left = 196
          Top = 0
          Width = 150
          Height = 21
          Align = alRight
          Caption = 'Automatically'
          TabOrder = 0
          OnClick = OptionsChanged
        end
      end
      object pnlDummy8: TPanel
        Left = 8
        Top = 344
        Width = 346
        Height = 22
        Anchors = [akLeft, akTop, akRight]
        BevelOuter = bvNone
        ShowCaption = False
        TabOrder = 10
        object lbl1: TLabel
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
          Left = 196
          Top = 0
          Width = 150
          Height = 22
          Align = alRight
          Style = csDropDownList
          TabOrder = 0
          OnChange = OptionsChanged
          Items.Strings = (
            'Mouse hover'
            'Mouse left-click'
            'Mouse right-click')
        end
      end
      object chbAutoHideTransparency: TCheckBox
        Left = 8
        Top = 412
        Width = 345
        Height = 17
        Anchors = [akLeft, akTop, akRight]
        Caption = 'Transparent when hidden'
        TabOrder = 12
        OnClick = OptionsChanged
      end
      object pnlDummy9: TPanel
        Left = 8
        Top = 372
        Width = 346
        Height = 22
        Anchors = [akLeft, akTop, akRight]
        BevelOuter = bvNone
        ShowCaption = False
        TabOrder = 11
        object Label3: TLabel
          Left = 0
          Top = 0
          Width = 56
          Height = 14
          Align = alLeft
          Caption = 'Delay, ms:'
          Layout = tlCenter
        end
        object bvlSpacer4: TBevel
          Left = 192
          Top = 0
          Width = 4
          Height = 22
          Align = alRight
          Shape = bsSpacer
          ExplicitLeft = 194
        end
        object nseAutoShowDelay: TnSpinEdit
          Left = 196
          Top = 0
          Width = 150
          Height = 22
          Align = alRight
          MaxValue = 60000
          MinValue = 0
          TabOrder = 0
          Value = 0
          OnChange = OptionsChanged
        end
      end
      object pnlDummy10: TPanel
        Left = 8
        Top = 87
        Width = 346
        Height = 22
        Anchors = [akLeft, akTop, akRight]
        BevelOuter = bvNone
        ShowCaption = False
        TabOrder = 2
        object btnBgColorShowHide: TSpeedButton
          Left = 322
          Top = 0
          Width = 24
          Height = 22
          Align = alRight
          Caption = '...'
          OnClick = btnBgColorClick
        end
        object edtColorBg: TEdit
          Tag = 3
          Left = 196
          Top = 0
          Width = 126
          Height = 22
          Align = alRight
          Alignment = taCenter
          CharCase = ecUpperCase
          MaxLength = 8
          TabOrder = 1
          Text = 'FFFFFFFF'
          OnChange = edtColorBgChange
          OnKeyPress = edtColorBgKeyPress
        end
        object chbUseBkgColor: TCheckBox
          Left = 0
          Top = 0
          Width = 160
          Height = 22
          Align = alLeft
          Anchors = [akLeft, akTop, akRight, akBottom]
          Caption = 'Background color:'
          TabOrder = 0
          OnClick = OptionsChanged
        end
      end
      object pnlDummy12: TPanel
        Left = 8
        Top = 255
        Width = 346
        Height = 22
        Anchors = [akLeft, akTop, akRight]
        BevelOuter = bvNone
        ShowCaption = False
        TabOrder = 8
        object lblGlowSize: TLabel
          Left = 0
          Top = 0
          Width = 54
          Height = 14
          Align = alLeft
          Caption = 'Glow size:'
          Layout = tlCenter
        end
        object bvlSpacer5: TBevel
          Left = 192
          Top = 0
          Width = 4
          Height = 22
          Align = alRight
          Shape = bsSpacer
          ExplicitLeft = 194
        end
        object nseGlowSize: TnSpinEdit
          Left = 196
          Top = 0
          Width = 150
          Height = 22
          Align = alRight
          MaxValue = 16
          MinValue = 0
          TabOrder = 0
          Value = 0
          OnChange = OptionsChanged
        end
      end
    end
    object tsAdditionally: TTabSheet
      Caption = 'Additional'
      ImageIndex = 1
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object lblSectionWin8: TLabel
        Left = 8
        Top = 82
        Width = 105
        Height = 14
        Caption = 'For Windows 8/8.1'
        Transparent = True
      end
      object lblSectionWin7: TLabel
        Left = 8
        Top = 8
        Width = 82
        Height = 14
        Caption = 'For Windows 7'
        Transparent = True
      end
      object chbAeroGlass: TCheckBox
        Left = 8
        Top = 118
        Width = 343
        Height = 17
        Align = alCustom
        Anchors = [akLeft, akTop, akRight]
        Caption = 'Enable AeroGlass support (installed separately)'
        TabOrder = 1
        WordWrap = True
        OnClick = OptionsChanged
      end
      object chbLightStyle: TCheckBox
        Left = 8
        Top = 28
        Width = 343
        Height = 48
        Align = alCustom
        Anchors = [akLeft, akTop, akRight]
        Caption = 'Use style like taskbar with combined buttons'
        TabOrder = 0
        WordWrap = True
        OnClick = OptionsChanged
      end
      object chbShowHints: TCheckBox
        Left = 3
        Top = 371
        Width = 367
        Height = 17
        Align = alCustom
        Caption = 'Show hints'
        TabOrder = 2
        Visible = False
        OnClick = OptionsChanged
      end
    end
    object tsAbout: TTabSheet
      Caption = 'About'
      ImageIndex = 1
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      DesignSize = (
        366
        441)
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
        Top = 115
        Width = 68
        Height = 14
        Caption = 'System info:'
      end
      object lblLocalizer: TLabel
        Left = 8
        Top = 76
        Width = 75
        Height = 14
        Caption = 'localizer: Asaq'
      end
      object lblSysInfo: TLabel
        Left = 8
        Top = 135
        Width = 347
        Height = 60
        Anchors = [akLeft, akTop, akRight]
        AutoSize = False
        Caption = 'lblSysInfo'
        WordWrap = True
        ExplicitWidth = 361
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
    end
  end
  object btnApply: TButton
    Left = 298
    Top = 488
    Width = 80
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'Apply'
    TabOrder = 3
    OnClick = DialogButtonClick
  end
  object btnCancel: TButton
    Left = 214
    Top = 488
    Width = 80
    Height = 25
    Anchors = [akTop, akRight]
    Cancel = True
    Caption = 'Cancel'
    TabOrder = 2
    OnClick = btnCancelClick
  end
  object btnOk: TButton
    Left = 130
    Top = 488
    Width = 80
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'OK'
    Default = True
    TabOrder = 1
    OnClick = DialogButtonClick
  end
end
