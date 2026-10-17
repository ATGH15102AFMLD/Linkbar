object BarCreatorWCl: TBarCreatorWCl
  Left = 0
  Top = 0
  ActiveControl = rbLocalDir
  BorderIcons = [biSystemMenu]
  Caption = 'New linkbar'
  ClientHeight = 185
  ClientWidth = 420
  Color = clBtnFace
  DefaultMonitor = dmMainForm
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Default'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  DesignSize = (
    420
    185)
  PixelsPerInch = 96
  TextHeight = 14
  object lblWorkDir: TLabel
    Left = 8
    Top = 98
    Width = 89
    Height = 14
    Caption = 'Choose a folder:'
  end
  object Label1: TLabel
    Left = 8
    Top = 8
    Width = 97
    Height = 14
    Caption = 'Create linkbar for:'
  end
  object btnSetWorkDir: TButton
    Left = 379
    Top = 117
    Width = 33
    Height = 22
    Anchors = [akTop, akRight]
    Caption = '...'
    TabOrder = 3
    OnClick = Button1Click
    ExplicitLeft = 383
  end
  object edtWorkDir: TEdit
    Left = 8
    Top = 117
    Width = 365
    Height = 22
    TabStop = False
    Anchors = [akLeft, akTop, akRight]
    Color = clBtnFace
    Enabled = False
    ReadOnly = True
    TabOrder = 4
    OnChange = edtWorkDirChange
    ExplicitWidth = 369
  end
  object rbLocalDir: TRadioButton
    Left = 8
    Top = 27
    Width = 404
    Height = 17
    Anchors = [akLeft, akTop, akRight]
    Caption = '&Local path (portable, next to the application)'
    Checked = True
    TabOrder = 0
    TabStop = True
    OnClick = rbModeClick
    ExplicitWidth = 408
  end
  object rbAppDir: TRadioButton
    Left = 8
    Top = 50
    Width = 404
    Height = 17
    Anchors = [akLeft, akTop, akRight]
    Caption = '&Anyone who uses this computer (all users)'
    TabOrder = 1
    OnClick = rbModeClick
    ExplicitWidth = 408
  end
  object rbUserDir: TRadioButton
    Left = 8
    Top = 73
    Width = 404
    Height = 17
    Anchors = [akLeft, akTop, akRight]
    Caption = 'Only for &me (%s)'
    TabOrder = 2
    OnClick = rbModeClick
    ExplicitWidth = 408
  end
  object Panel1: TPanel
    Left = 0
    Top = 144
    Width = 420
    Height = 41
    Align = alBottom
    BevelOuter = bvNone
    ParentBackground = False
    ShowCaption = False
    TabOrder = 5
    ExplicitTop = 141
    ExplicitWidth = 424
    DesignSize = (
      420
      41)
    object btnCreate: TButton
      Left = 249
      Top = 8
      Width = 79
      Height = 25
      Anchors = [akTop, akRight]
      Caption = '&Create'
      TabOrder = 0
      OnClick = btnCreateClick
    end
    object Panel2: TPanel
      Left = 0
      Top = 0
      Width = 420
      Height = 1
      Align = alTop
      BevelOuter = bvNone
      Color = cl3DLight
      ParentBackground = False
      ShowCaption = False
      TabOrder = 1
      ExplicitWidth = 424
    end
    object btnCancel: TButton
      Left = 334
      Top = 8
      Width = 79
      Height = 25
      Anchors = [akTop, akRight]
      Cancel = True
      Caption = 'C&ancel'
      TabOrder = 2
      OnClick = btnCancelClick
    end
  end
  object FileOpenDialog_NL: TFileOpenDialog
    FavoriteLinks = <>
    FileTypes = <>
    Options = [fdoNoChangeDir, fdoPickFolders, fdoPathMustExist, fdoNoReadOnlyReturn]
    Left = 328
    Top = 3
  end
end
