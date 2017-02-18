{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{            Copyright (c) 2010-2017 Asaq               }
{*******************************************************}

unit Linkbar.Settings;

{$i linkbar.inc}

interface

uses
  Windows, SysUtils, Classes, Forms, StdCtrls, NewSpin, ExtCtrls, Controls, mUnit,
  Vcl.ComCtrls, Winapi.Messages, Vcl.Buttons, ColorPicker, VCLTee.TeCanvas;

type
  TFrmProperties = class(TForm)
    pgc1: TPageControl;
    tsOptions: TTabSheet;
    tsAbout: TTabSheet;
    lblScreenEdge: TLabel;
    lblIconSize: TLabel;
    lblMargin: TLabel;
    lblOrder: TLabel;
    Label6: TLabel;
    Label1: TLabel;
    cbbTextLayout: TComboBox;
    chbAutoHide: TCheckBox;
    lblVer: TLabel;
    lblEmail: TLabel;
    linkEmail: TLinkLabel;
    linkWeb: TLinkLabel;
    lblWeb: TLabel;
    Label2: TLabel;
    chbAutoHideTransparency: TCheckBox;
    cbbScreenPosition: TComboBox;
    pnlDummy1: TPanel;
    pnlDummy2: TPanel;
    pnlDummy3: TPanel;
    pnlDummy6: TPanel;
    pnlDummy4: TPanel;
    pnlDummy5: TPanel;
    cbbItemOrder: TComboBox;
    btnApply: TButton;
    btnCancel: TButton;
    btnOk: TButton;
    nseIconSize: TnSpinEdit;
    nseMarginH: TnSpinEdit;
    nseMarginV: TnSpinEdit;
    nseTextWidth: TnSpinEdit;
    nseTextOffset: TnSpinEdit;
    lblSection2: TLabel;
    lblSection1: TLabel;
    pnlDummy8: TPanel;
    lbl1: TLabel;
    cbbAutoShowMode: TComboBox;
    pnlDummy7: TPanel;
    lbl2: TLabel;
    tsAdditionally: TTabSheet;
    lblSectionWin8: TLabel;
    lblSectionWin7: TLabel;
    lblLocalizer: TLabel;
    chbShowHints: TCheckBox;
    chbLightStyle: TCheckBox;
    chbAeroGlass: TCheckBox;
    lblSysInfo: TLabel;
    pnlDummy9: TPanel;
    Label3: TLabel;
    nseAutoShowDelay: TnSpinEdit;
    pnlDummy10: TPanel;
    btnBgColorShowHide: TSpeedButton;
    pnlDummy11: TPanel;
    edtColorBg: TEdit;
    chbUseBkgColor: TCheckBox;
    chbUseTxtColor: TCheckBox;
    bvlSpacer2: TBevel;
    bvlSpacer3: TBevel;
    bvlSpacer1: TBevel;
    bvlSpacer4: TBevel;
    pnlDummy12: TPanel;
    lblGlowSize: TLabel;
    bvlSpacer5: TBevel;
    nseGlowSize: TnSpinEdit;
    clbTextColor: TColorBox;
    procedure FormMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure linkEmailLinkClick(Sender: TObject; const Link: string;
      LinkType: TSysLinkType);
    procedure linkWebLinkClick(Sender: TObject; const Link: string;
      LinkType: TSysLinkType);
    procedure DialogButtonClick(Sender: TObject);
    procedure OptionsChanged(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnCancelClick(Sender: TObject);
    procedure btnBgColorClick(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);
    procedure edtColorBgKeyPress(Sender: TObject; var Key: Char);
    procedure edtColorBgChange(Sender: TObject);
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure WMNCHitTest(var Message: TWMNCHitTest); message WM_NCHITTEST;
  private
    FLinkbar: TLinkbarWcl;
    FColorPicker: TfrmColorPicker;
    FBackgroundColor: Cardinal;
    FTextColor: Cardinal;
    procedure SetBackgroundColor(AValue: Cardinal);
    procedure SetTextColor(AValue: Cardinal);
    function ScaleDimension(const X: Integer): Integer;
  public
    constructor Create(AOwner: TLinkbarWcl); reintroduce;
    property BackgroundColor: Cardinal read FBackgroundColor write SetBackgroundColor;
    property TextColor: Cardinal read FTextColor write SetTextColor;
  end;

var
  FrmProperties: TFrmProperties;

implementation

{$R *.dfm}

uses
  Math, Graphics, Linkbar.Consts, Linkbar.OS, Linkbar.Shell, Linkbar.Themes,
  Linkbar.Loc, Linkbar.Common;

function TFrmProperties.ScaleDimension(const X: Integer): Integer;
begin
  Result := MulDiv(X, Self.PixelsPerInch, 96);
end;

procedure TFrmProperties.SpeedButton2Click(Sender: TObject);
begin
  nseIconSize.Value := StrToIntDef(TSpeedButton(Sender).Caption, nseIconSize.Value);
end;

procedure TFrmProperties.WMNCHitTest(var Message: TWMNCHitTest);
// Disable window resize
begin
  inherited;
  PreventSizing(Message.Result);
end;

procedure TFrmProperties.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.ExStyle := Params.ExStyle or WS_EX_APPWINDOW;
end;

constructor TFrmProperties.Create(AOwner: TLinkbarWcl);
var
  lang: TLanguages;
  maxlabelwidth, ctrlwidth, y1: integer;
  VO1, VO2, VO3: Integer;
begin
  inherited Create(AOwner);

  Font.Name := Screen.MenuFont.Name;
  LbTranslateComponent(Self);

  ReduceSysMenu(Handle);

  VO1 := ScaleDimension(7);
  VO2 := ScaleDimension(9);
  VO3 := ScaleDimension(12);

  FLinkbar := AOwner;

  pgc1.ActivePageIndex := 0;

  maxlabelwidth := 0;
  maxlabelwidth := Max(maxlabelwidth, lblScreenEdge.Width);
  maxlabelwidth := Max(maxlabelwidth, lblIconSize.Width);
  maxlabelwidth := Max(maxlabelwidth, lblMargin.Width);
  maxlabelwidth := Max(maxlabelwidth, lblOrder.Width);
  maxlabelwidth := Max(maxlabelwidth, Label1.Width);
  maxlabelwidth := Max(maxlabelwidth, Label6.Width);
  maxlabelwidth := Max(maxlabelwidth, ScaleDimension(180));
  maxlabelwidth := maxlabelwidth + ScaleDimension(10);
  ctrlwidth := cbbScreenPosition.Width;

  GetTitleFont(lblSection1.Font);
  lblSection2.Font := lblSection1.Font;
  lblVer.Font := lblSection1.Font;

  // ---------------------------------------------------------------------------
  // Page Options
  // ---------------------------------------------------------------------------
  // Position on screen --------------------------------------------------------
  pnlDummy1.Top := lblSection1.BoundsRect.Bottom + VO1;
  pnlDummy1.Height := cbbScreenPosition.BoundsRect.Bottom;
  // Icon size -----------------------------------------------------------------
  pnlDummy2.Top := pnlDummy1.BoundsRect.Bottom + VO1;
  pnlDummy2.Height := pnlDummy1.Height;
  nseIconSize.MinValue := ICON_SIZE_MIN;
  nseIconSize.MaxValue := ICON_SIZE_MAX;
  nseIconSize.Value := FLinkbar.IconSize;

  // Color ---------------------------------------------------------------------
  pnlDummy10.Top := pnlDummy2.BoundsRect.Bottom + VO1;
  pnlDummy10.Height := pnlDummy1.Height;

  FColorPicker := TfrmColorPicker.Create(Self);
  FColorPicker.Font := Font;
  LbTranslateComponent(FColorPicker);

  // Margins -------------------------------------------------------------------
  pnlDummy3.Top := pnlDummy10.BoundsRect.Bottom + VO1;
  pnlDummy3.Height := pnlDummy1.Height;
  // Margin Left/Right Spinedit
  nseMarginH.MinValue := MARGIN_MIN;
  nseMarginH.MaxValue := MARGIN_MAX;
  nseMarginH.Value := FLinkbar.ItemMargin.cx;
  // Margin Top/Bottom Spinedit
  nseMarginV.MinValue := MARGIN_MIN;
  nseMarginV.MaxValue := MARGIN_MAX;
  nseMarginV.Value := FLinkbar.ItemMargin.cy;

  // Item order ----------------------------------------------------------------
  pnlDummy4.Top := pnlDummy3.BoundsRect.Bottom + VO1;
  pnlDummy4.Height := pnlDummy1.Height;

  // Text position -------------------------------------------------------------
  pnlDummy5.Top := pnlDummy4.BoundsRect.Bottom + VO1;
  pnlDummy5.Height := pnlDummy1.Height;

  // Text width/offset ---------------------------------------------------------
  pnlDummy6.Top := pnlDummy5.BoundsRect.Bottom + VO1;
  pnlDummy6.Height := pnlDummy1.Height;
  // Width
  nseTextWidth.MinValue := TEXT_WIDTH_MIN;
  nseTextWidth.MaxValue := TEXT_WIDTH_MAX;
  nseTextWidth.Value := FLinkbar.TextWidth;
  // Text indent
  nseTextOffset.MinValue := TEXT_OFFSET_MIN;
  nseTextOffset.MaxValue := TEXT_OFFSET_MAX;
  nseTextOffset.Value := FLinkbar.TextOffset;

  pnlDummy11.Top := pnlDummy6.BoundsRect.Bottom + VO1;
  pnlDummy11.Height := pnlDummy1.Height;
  clbTextColor.ItemHeight := ScaleDimension(16);

  // Glow size
  pnlDummy12.Top := pnlDummy11.BoundsRect.Bottom + VO1;
  pnlDummy12.Height := pnlDummy1.Height;
  nseGlowSize.MinValue := GLOW_SIZE_MIN;
  nseGlowSize.MaxValue := GLOW_SIZE_MAX;
  nseGlowSize.Value := FLinkbar.GlowSize;

  lblSection2.Top := pnlDummy12.BoundsRect.Bottom + VO1*2;

  pnlDummy7.Top := lblSection2.BoundsRect.Bottom + VO1;
  pnlDummy7.Height := pnlDummy1.Height;

  pnlDummy8.Top := pnlDummy7.BoundsRect.Bottom + VO1;
  pnlDummy8.Height := pnlDummy1.Height;

  pnlDummy9.Top := pnlDummy8.BoundsRect.Bottom + VO1;
  pnlDummy9.Height := pnlDummy1.Height;

  chbAutoHideTransparency.Top := pnlDummy9.BoundsRect.Bottom + VO3;

  // ---------------------------------------------------------------------------
  // Page Additionally
  // ---------------------------------------------------------------------------
  lblSectionWin7.Font := lblSection1.Font;
  if LbLongLang
  then chbLightStyle.Height := chbLightStyle.Height * 2;
  chbLightStyle.Top := lblSectionWin7.BoundsRect.Bottom + VO1;
  chbLightStyle.Hint := chbLightStyle.Caption;
  chbLightStyle.ShowHint := True;
  lblSectionWin8.Font := lblSection1.Font;
  lblSectionWin8.Top := chbLightStyle.BoundsRect.Bottom + VO1*2;
  chbAeroGlass.Top := lblSectionWin8.BoundsRect.Bottom + VO1;

  pgc1.Height := tsOptions.Top + chbAutoHideTransparency.BoundsRect.Bottom
    + VO2 + tsOptions.Left;

  btnOk.Top := pgc1.BoundsRect.Bottom + ScaleDimension(8);
  btnCancel.Top := btnOk.Top;
  btnApply.Top := btnOk.Top;

  ClientWidth := maxlabelwidth + ctrlwidth + (pnlDummy1.Left + tsOptions.Left + pgc1.Left) * 2;
  if IsWindows7 then y1 := 5 else y1 := 8;
  ClientHeight := btnOk.BoundsRect.Bottom + ScaleDimension(y1);

  linkWeb.Left := lblWeb.BoundsRect.Right + ScaleDimension(8);
  linkEmail.Left := lblEmail.BoundsRect.Right + ScaleDimension(8);

  // Set values
  cbbScreenPosition.ItemIndex := Ord(FLinkbar.ScreenAlign);
  cbbItemOrder.ItemIndex := Ord(FLinkbar.ItemOrder);
  cbbTextLayout.ItemIndex := Ord(FLinkbar.TextLayout);
  chbAutoHide.Checked := FLinkbar.AutoHide;
  chbAutoHideTransparency.Checked := FLinkbar.AutoHideTransparency;
  cbbAutoShowMode.ItemIndex := Ord(FLinkbar.AutoShowMode);
  nseAutoShowDelay.Value := FLinkbar.AutoShowDelay;
  chbLightStyle.Checked := FLinkbar.IsLightStyle;

  chbUseBkgColor.Checked := FLinkbar.UseBkgColor;
  chbUseTxtColor.Checked := FLinkbar.UseTxtColor;

  BackgroundColor := FLinkbar.BkgColor;
  TextColor := FLinkbar.TxtColor;

  chbAeroGlass.Checked := FLinkbar.EnableAeroGlass;

  OptionsChanged(nil);

  { Disable OS-dependent options }
  // Windows 7
  lblSectionWin7.Enabled := IsWindows7;
  chbLightStyle.Enabled := IsWindows7;
  // Windows 8, 8.1
  lblSectionWin8.Enabled := IsWindows8And8Dot1;
  chbAeroGlass.Enabled := IsWindows8And8Dot1;

  lblVer.Caption    := lblVer.Caption + ' ' + VersionToString;
  linkWeb.Caption   := '<a>' + URL_WEB + '</a>';
  linkEmail.Caption := '<a>' + URL_EMAIL + '</a>';

  lang := TLanguages.Create;
  lblSysInfo.Caption := TOSVersion.ToString
      + '; LCID '
      + IntToStr(lang.UserDefaultLocale) + ' (' + IntToHex(lang.UserDefaultLocale, 3) + ')'
      + ' ' + lang.NameFromLocaleID[lang.UserDefaultLocale];
  lang.Free;

  btnApply.Enabled := False;
end;

procedure TFrmProperties.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TFrmProperties.FormDestroy(Sender: TObject);
begin
  FrmProperties := nil;
  FColorPicker.Free;
  FLinkbar.PropertiesFormDestroyed;
end;

procedure TFrmProperties.FormMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
var spin: TnSpinedit;
begin
  if Assigned(ActiveControl)
     and (ActiveControl.ClassType = TnSpinedit)
  then spin := TnSpinedit(ActiveControl)
  else spin := nil;

  if Assigned(spin) then
  begin
    if wheeldelta > 0 then spin.Value := spin.Value + spin.Increment;
    if wheeldelta < 0 then spin.Value := spin.Value - spin.Increment;
  end;
end;

procedure TFrmProperties.linkEmailLinkClick(Sender: TObject; const Link: string;
  LinkType: TSysLinkType);
begin
  if not SendShellEmail(Application.Handle, URL_EMAIL,
    APP_NAME_LINKBAR,
    'Version: ' + VersionToString
    + '%0D%0A' + 'OS: ' + lblSysInfo.Caption)
  then begin
  end;
end;

procedure TFrmProperties.linkWebLinkClick(Sender: TObject; const Link: string;
  LinkType: TSysLinkType);
begin
  LBShellExecute(0, 'open', URL_WEB);
end;

procedure TFrmProperties.OptionsChanged(Sender: TObject);
begin
  btnApply.Enabled := True;

  // Color additional options
  edtColorBg.Enabled := chbUseBkgColor.Checked;
  btnBgColorShowHide.Enabled := chbUseBkgColor.Checked;
  clbTextColor.Enabled := chbUseTxtColor.Checked;

  // Autohide additional options
  cbbAutoShowMode.Enabled := chbAutoHide.Checked;
  chbAutoHideTransparency.Enabled := chbAutoHide.Checked;
  lbl1.Enabled := chbAutoHide.Checked;
  Label3.Enabled := chbAutoHide.Checked
                    and (TAutoShowMode(cbbAutoShowMode.ItemIndex)= smMouseHover);
  nseAutoShowDelay.Enabled := Label3.Enabled;

  // Text additional options
  Label6.Enabled := cbbTextLayout.ItemIndex > 0;
  nseTextWidth.Enabled := cbbTextLayout.ItemIndex > 0;
  nseTextOffset.Enabled := cbbTextLayout.ItemIndex > 0;
end;

procedure TFrmProperties.btnCancelClick(Sender: TObject);
begin
  Close;
end;

procedure TFrmProperties.DialogButtonClick(Sender: TObject);
var temp_ah: Boolean;
begin
  if ((Sender = btnOk) and not btnApply.Enabled)
  then begin
    Close;
    Exit;
  end;

  if (Sender = btnOk)
  then begin
    AlphaBlendValue := 0;
    AlphaBlend := True;
  end;

  FLinkbar.EnableAeroGlass := chbAeroGlass.Checked;

  FLinkbar.AutoShowDelay := nseAutoShowDelay.Value;

  FLinkbar.UseBkgColor := chbUseBkgColor.Checked;
  FLinkbar.BkgColor := FBackgroundColor;
  FLinkbar.UseTxtColor := chbUseTxtColor.Checked;
  FLinkbar.TxtColor := RGB(GetBValue(FTextColor), GetGValue(FTextColor), GetRValue(FTextColor));

  FLinkbar.GlowSize := nseGlowSize.Value;

  FLinkbar.IsLightStyle := chbLightStyle.Checked;
  FLinkbar.AutoShowMode := TAutoShowMode(cbbAutoShowMode.ItemIndex);
  FLinkbar.ItemOrder := TItemOrder(cbbItemOrder.ItemIndex);
  FLinkbar.TextLayout := TTextLayout(cbbTextLayout.ItemIndex);
  FLinkbar.TextWidth := EnsureRange(nseTextWidth.Value, TEXT_WIDTH_MIN, TEXT_WIDTH_MAX);
  FLinkbar.TextOffset := EnsureRange(nseTextOffset.Value, TEXT_OFFSET_MIN, TEXT_OFFSET_MAX);
  FLinkbar.IconSize := EnsureRange(nseIconSize.Value, ICON_SIZE_MIN, ICON_SIZE_MAX);
  FLinkbar.ItemMargin := TSize.Create(
    EnsureRange(nseMarginH.Value, MARGIN_MIN, MARGIN_MAX),
    EnsureRange(nseMarginV.Value, MARGIN_MIN, MARGIN_MAX)
  );
  FLinkbar.AutoHideTransparency := chbAutoHideTransparency.Checked;

  FLinkbar.UpdateItemSizes;

  // for avoid double message "autohide panel already exists..."
  temp_ah := FLinkbar.AutoHide;
  FLinkbar.ScreenAlign := TScreenAlign(cbbScreenPosition.ItemIndex);
  if (temp_ah = FLinkbar.AutoHide)
  then FLinkbar.AutoHide := chbAutohide.Checked;

  if (Sender = btnOk)
  then begin
    Close;
    Exit;
  end;
  btnApply.Enabled := False;
  ActiveControl := btnOk;

  chbAutoHide.Checked := FLinkbar.AutoHide;
end;

procedure TFrmProperties.edtColorBgChange(Sender: TObject);
begin
  if (Sender = edtColorBg) 
  then FBackgroundColor := StrToIntDef(HexDisplayPrefix + edtColorBg.Text, 0);
  
  if (Sender = clbTextColor)
  then FTextColor := clbTextColor.Selected;
  
  OptionsChanged(Sender);
end;

procedure TFrmProperties.edtColorBgKeyPress(Sender: TObject; var Key: Char);
begin
  if (Key = #8)
  then Exit;

  if not CharInSet(Key, ['a'..'f', 'A'..'F', '0'..'9'])
  then Key := #0;
end;

procedure TFrmProperties.btnBgColorClick(Sender: TObject);
begin
  if (Sender = btnBgColorShowHide)
  then begin
    FColorPicker.Color := BackgroundColor;
    if (FColorPicker.ShowModal = mrOk)
    then BackgroundColor := FColorPicker.Color;
  end;
end;

procedure TFrmProperties.SetBackgroundColor(AValue: Cardinal);
begin
  FBackgroundColor := AValue;
  edtColorBg.Text := IntToHex(FBackgroundColor, 8);
end;

procedure TFrmProperties.SetTextColor(AValue: Cardinal);
begin
  FTextColor := AValue and $ffffff;
  clbTextColor.Selected := RGB(GetBValue(FTextColor), GetGValue(FTextColor), GetRValue(FTextColor));
end;

end.

