object frmColorPicker: TfrmColorPicker
  Left = 660
  Top = 197
  BorderIcons = [biSystemMenu]
  BorderStyle = bsDialog
  Caption = 'Color'
  ClientHeight = 243
  ClientWidth = 201
  Color = clBtnFace
  ParentFont = True
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  Position = poOwnerFormCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  DesignSize = (
    201
    243)
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 0
    Top = 29
    Width = 205
    Height = 174
    BevelOuter = bvNone
    ParentColor = True
    TabOrder = 0
    object imgColorBox: TImage
      Left = 32
      Top = 5
      Width = 137
      Height = 137
      OnMouseDown = imgColorBoxMouseDown
      OnMouseMove = imgColorBoxMouseMove
      OnMouseUp = imgColorBoxMouseUp
    end
    object imgZBar: TImage
      Left = 5
      Top = 147
      Width = 191
      Height = 22
      OnMouseDown = imgColorBarMouseDown
      OnMouseMove = imgColorBarMouseMove
      OnMouseUp = imgColorBarMouseUp
    end
    object imgColor: TImage
      Left = 174
      Top = 5
      Width = 22
      Height = 137
      OnMouseDown = imgColorMouseDown
    end
    object imgAlpha: TImage
      Left = 5
      Top = 5
      Width = 22
      Height = 137
      OnMouseDown = imgAlphaMouseDown
      OnMouseMove = imgAlphaMouseMove
      OnMouseUp = imgAlphaMouseUp
    end
  end
  object editColor: TEdit
    Tag = 3
    Left = 32
    Top = 5
    Width = 137
    Height = 21
    Alignment = taCenter
    CharCase = ecUpperCase
    MaxLength = 8
    TabOrder = 1
    Text = 'FFFFFFFF'
    OnKeyDown = editColor1KeyDown
    OnKeyPress = editColor1KeyPress
    OnKeyUp = editColor1KeyUp
  end
  object btnOk: TButton
    Left = 8
    Top = 210
    Width = 89
    Height = 25
    Anchors = [akTop, akRight]
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 2
  end
  object btnCancel: TButton
    Left = 103
    Top = 210
    Width = 90
    Height = 25
    Anchors = [akTop, akRight]
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 3
  end
  object ilMain: TImageList
    ColorDepth = cd32Bit
    Left = 104
    Top = 24
  end
end
