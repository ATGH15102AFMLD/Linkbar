{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{            Copyright (c) 2010-2018 Asaq               }
{*******************************************************}

unit Linkbar.SettingsForm;

{$i linkbar.inc}

interface

uses
  System.SysUtils, System.Classes,
  Winapi.Windows, Winapi.Messages,
  Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Buttons, Vcl.Controls, Vcl.ComCtrls, Vcl.Menus,
  NewSpin, mUnit, ColorPicker, HotKey;

type
  TFrmProperties = class(TForm)
    pgc1: TPageControl;
    tsView: TTabSheet;
    tsAbout: TTabSheet;
    lblScreenEdge: TLabel;
    lblIconSize: TLabel;
    lblMargin: TLabel;
    lblOrder: TLabel;
    lblTextWidthIdent: TLabel;
    lblTextPosition: TLabel;
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
    lblShow: TLabel;
    cbbAutoShowMode: TComboBox;
    pnlDummy7: TPanel;
    lbl2: TLabel;
    tsAdditionally: TTabSheet;
    lblLocalizer: TLabel;
    lblSysInfo: TLabel;
    pnlDelay: TPanel;
    lblDelay: TLabel;
    nseAutoShowDelay: TnSpinEdit;
    pnlDummy10: TPanel;
    btnBkgndColorEdit: TSpeedButton;
    pnlDummy11: TPanel;
    edtBkgndColor: TEdit;
    chbUseBkgndColor: TCheckBox;
    chbUseTextColor: TCheckBox;
    bvlSpacer2: TBevel;
    bvlSpacer3: TBevel;
    pnlDummy12: TPanel;
    lblGlowSize: TLabel;
    nseGlowSize: TnSpinEdit;
    clbTextColor: TColorBox;
    pmSysInfo: TPopupMenu;
    imCopy: TMenuItem;
    pnlLightStyle: TPanel;
    chbLightStyle: TCheckBox;
    lblSectionAdditional: TLabel;
    chbAeroGlass: TCheckBox;
    chbShowHints: TCheckBox;
    pnlHotkey: TPanel;
    lblHotKey: TLabel;
    tsAutohide: TTabSheet;
    pnlJumplistShowMode: TPanel;
    lblJumplistShowMode: TLabel;
    cbbJumplistShowMode: TComboBox;
    lblSectionJumplist: TLabel;
    pnlDummy13: TPanel;
    chbStayOnTop: TCheckBox;
    pnlJumplistRecentMax: TPanel;
    lblJumplistRecentMax: TLabel;
    nseJumplistRecentMax: TnSpinEdit;
    pnlDummy21: TPanel;
    Bevel1: TBevel;
    pnlLook: TPanel;
    lblLook: TLabel;
    cbbLook: TComboBox;
    pnlCornerGapWidth: TPanel;
    lblCornerGapWidth: TLabel;
    Bevel2: TBevel;
    nseCorner1GapWidth: TnSpinEdit;
    nseCorner2GapWidth: TnSpinEdit;
    lblGithub: TLabel;
    linkGithub: TLinkLabel;
    procedure FormMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure linkEmailLinkClick(Sender: TObject; const Link: string;
      LinkType: TSysLinkType);
    procedure linkWebLinkClick(Sender: TObject; const Link: string;
      LinkType: TSysLinkType);
    procedure DialogButtonClick(Sender: TObject);
    procedure Changed(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnCancelClick(Sender: TObject);
    procedure btnBgColorClick(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);
    procedure edtBkgndColorKeyPress(Sender: TObject; var Key: Char);
    procedure edtBkgndColorChange(Sender: TObject);
    procedure imCopyClick(Sender: TObject);
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure WMNCHitTest(var Message: TWMNCHitTest); message WM_NCHITTEST;
  private
    FLinkbar: TLinkbarWcl;
    FColorPicker: TfrmColorPicker;
    FBackgroundColor: Cardinal;
    FTextColor: Cardinal;
    edtHotKey: THotKeyEdit;
    FCanChanged: Boolean;
    procedure SetBackgroundColor(AValue: Cardinal);
    procedure SetTextColor(AValue: Cardinal);
    function ScaleDimension(const X: Integer): Integer;
    procedure L10n;
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
  Math, Graphics, Vcl.Clipbrd,
  Linkbar.Consts, Linkbar.OS, Linkbar.Shell, Linkbar.Themes, Linkbar.L10n, Linkbar.Common;

function TFrmProperties.ScaleDimension(const X: Integer): Integer;
begin
  Result := MulDiv(X, Self.PixelsPerInch, 96);
end;

procedure TFrmProperties.SpeedButton2Click(Sender: TObject);
begin
  nseIconSize.Value := StrToIntDef(TSpeedButton(Sender).Caption, nseIconSize.Value);
end;

{ Prevent window resizing }
procedure TFrmProperties.WMNCHitTest(var Message: TWMNCHitTest);
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
var maxlabelwidth, ctrlwidth, y1: integer;
    VO1, VO2, VO3: Integer;
begin
  FCanChanged := False;

  inherited Create(AOwner);

  FLinkbar := AOwner;
  Font.Name := Screen.MenuFont.Name;

  // Create editors
  edtHotKey := THotKeyEdit.Create(pnlHotkey);
  edtHotKey.Parent := pnlHotkey;
  edtHotKey.Align := alClient;
  edtHotKey.OnChange := Changed;
  FColorPicker := TfrmColorPicker.Create(Self);
  FColorPicker.Font := Font;

  L10n;

  ReduceSysMenu(Handle);

  VO1 := ScaleDimension(7);
  VO2 := ScaleDimension(9);
  VO3 := ScaleDimension(12);

  pgc1.ActivePageIndex := 0;

  maxlabelwidth := 0;
  maxlabelwidth := Max(maxlabelwidth, lblScreenEdge.Width);
  maxlabelwidth := Max(maxlabelwidth, lblIconSize.Width);
  maxlabelwidth := Max(maxlabelwidth, lblMargin.Width);
  maxlabelwidth := Max(maxlabelwidth, lblOrder.Width);
  maxlabelwidth := Max(maxlabelwidth, lblTextPosition.Width);
  maxlabelwidth := Max(maxlabelwidth, lblTextWidthIdent.Width);
  maxlabelwidth := Max(maxlabelwidth, lblCornerGapWidth.Width);
  maxlabelwidth := Max(maxlabelwidth, ScaleDimension(180));
  maxlabelwidth := maxlabelwidth + ScaleDimension(16);
  ctrlwidth := cbbScreenPosition.Width;

  GetTitleFont(lblSection1.Font);
  lblSection2.Font := lblSection1.Font;
  lblVer.Font := lblSection1.Font;

  // ---------------------------------------------------------------------------
  // Page View
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

  pnlDummy13.Top := pnlDummy12.BoundsRect.Bottom + VO1;
  pnlDummy13.Height := pnlDummy1.Height;

  // ---------------------------------------------------------------------------
  // Page AutoHide
  // ---------------------------------------------------------------------------

  pnlDummy7.Top := lblSection2.BoundsRect.Bottom + VO1;
  pnlDummy7.Height := pnlDummy1.Height;

  pnlDummy8.Top := pnlDummy7.BoundsRect.Bottom + VO1;
  pnlDummy8.Height := pnlDummy1.Height;

  pnlDelay.Top := pnlDummy8.BoundsRect.Bottom + VO1;
  pnlDelay.Height := pnlDummy1.Height;

  pnlCornerGapWidth.Top := pnlDelay.BoundsRect.Bottom + VO1;
  pnlCornerGapWidth.Height := pnlDummy1.Height;
  nseCorner1GapWidth.MinValue := CORNER_GAP_WIDTH_MIN;
  nseCorner1GapWidth.MaxValue := CORNER_GAP_WIDTH_MAX;
  nseCorner2GapWidth.MinValue := CORNER_GAP_WIDTH_MIN;
  nseCorner2GapWidth.MaxValue := CORNER_GAP_WIDTH_MAX;

  pnlHotkey.Top := pnlCornerGapWidth.BoundsRect.Bottom + VO1;
  pnlHotkey.Height := pnlDummy1.Height;

  chbAutoHideTransparency.Top := pnlHotkey.BoundsRect.Bottom + VO3;

  // ---------------------------------------------------------------------------
  // Page Additionally
  // ---------------------------------------------------------------------------
  lblSectionJumplist.Font := lblSection1.Font;
  pnlJumplistShowMode.Top := lblSectionJumplist.BoundsRect.Bottom + VO1;
  pnlJumplistShowMode.Height := pnlDummy1.Height;
  pnlJumplistRecentMax.Top := pnlJumplistShowMode.BoundsRect.Bottom + VO1;
  pnlJumplistRecentMax.Height := (pnlDummy1.Height * 3) div 2;
  nseJumplistRecentMax.Top := (pnlDummy21.Height - nseJumplistRecentMax.Height) div 2;
  nseJumplistRecentMax.MinValue := JUMPLIST_RECENTMAX_MIN;
  nseJumplistRecentMax.MaxValue := JUMPLIST_RECENTMAX_MAX;

  { OS-dependent options }
  lblSectionAdditional.Font := lblSection1.Font;
  lblSectionAdditional.Top := pnlJumplistRecentMax.BoundsRect.Bottom + VO1*2;
  // Windows 7
  pnlLightStyle.Visible := IsWindows7;
  pnlLightStyle.Top := lblSectionAdditional.BoundsRect.Bottom + VO1;
  pnlLightStyle.Height := (pnlDummy1.Height * 3) div 2;
  // Windows 8/8.1
  chbAeroGlass.Visible := IsWindows8And8Dot1;
  chbAeroGlass.Top := lblSectionAdditional.BoundsRect.Bottom + VO1;
  // Windows 10s
  pnlLook.Visible := IsWindows10;
  pnlLook.Top := lblSectionAdditional.BoundsRect.Bottom + VO1;
  pnlLook.Height := pnlDummy1.Height;

  pgc1.Height := tsView.Top + pnlDummy13.BoundsRect.Bottom
    + VO2 + tsView.Left;

  btnOk.Top := pgc1.BoundsRect.Bottom + ScaleDimension(8);
  btnCancel.Top := btnOk.Top;
  btnApply.Top := btnOk.Top;

  // Calc Client Width & Height
  ClientWidth := maxlabelwidth + ctrlwidth + (pnlDummy1.Left + tsView.Left + pgc1.Left) * 2;
  if IsWindows7 then y1 := 5 else y1 := 8;
  ClientHeight := btnOk.BoundsRect.Bottom + ScaleDimension(y1);

  linkWeb.Left := lblWeb.BoundsRect.Right + ScaleDimension(8);
  linkEmail.Left := lblEmail.BoundsRect.Right + ScaleDimension(8);
  linkGithub.Left := lblGithub.BoundsRect.Right + ScaleDimension(8);

  // Set values
  cbbScreenPosition.ItemIndex := Ord(FLinkbar.ScreenAlign);
  cbbItemOrder.ItemIndex := Ord(FLinkbar.ItemOrder);
  cbbTextLayout.ItemIndex := Ord(FLinkbar.TextLayout);
  chbAutoHide.Checked := FLinkbar.AutoHide;
  chbAutoHideTransparency.Checked := FLinkbar.AutoHideTransparency;
  cbbAutoShowMode.ItemIndex := Ord(FLinkbar.AutoShowMode);
  nseAutoShowDelay.Value := FLinkbar.AutoShowDelay;
  chbLightStyle.Checked := FLinkbar.IsLightStyle;
  chbUseBkgndColor.Checked := FLinkbar.UseBkgndColor;
  chbUseTextColor.Checked := FLinkbar.UseTextColor;
  cbbJumplistShowMode.ItemIndex := Ord(FLinkbar.JumplistShowMode);
  nseJumplistRecentMax.Value := FLinkbar.JumplistRecentMax;
  chbStayOnTop.Checked := FLinkbar.StayOnTop;
  cbbLook.ItemIndex := Ord(FLinkbar.LookMode);
  nseCorner1GapWidth.Value := FLinkbar.Corner1GapWidth;
  nseCorner2GapWidth.Value := FLinkbar.Corner2GapWidth;

  edtHotKey.HotkeyInfo := FLinkbar.HotkeyInfo;

  BackgroundColor := FLinkbar.BackgroundColor;
  TextColor := FLinkbar.TextColor;

  chbAeroGlass.Checked := FLinkbar.EnableAeroGlass;

  lblVer.Caption     := Format(lblVer.Caption, [VersionToString]);
  linkWeb.Caption    := '<a>' + URL_WEB + '</a>';
  linkEmail.Caption  := '<a>' + URL_EMAIL + '</a>';
  linkGithub.Caption := '<a>' + URL_GITHUB + '</a>';

  lblSysInfo.Caption := TOSVersion.ToString
      + ' '  + Languages.LocaleName[Languages.IndexOf(Languages.UserDefaultLocale)]
      + ' '  + IntToStr(Languages.UserDefaultLocale)
      + ' (' + IntToHex(Languages.UserDefaultLocale, 3) + ')'
      + ' '  + Languages.NameFromLocaleID[Languages.UserDefaultLocale];

  FCanChanged := True;
  Changed(nil);
  btnApply.Enabled := False;
end;

procedure TFrmProperties.L10n;
begin
  // Tabs
  L10nControl(tsView,            'Properties.View');
  L10nControl(tsAutoHide,        'Properties.PageAutoHide');
  L10nControl(tsAdditionally,    'Properties.Additional');
  L10nControl(tsAbout,           'Properties.About');
  // View
  L10nControl(lblSection1,       'Properties.Appearance');
  L10nControl(lblScreenEdge,     'Properties.Position');
  L10nControl(cbbScreenPosition, ['Properties.Left', 'Properties.Top', 'Properties.Right', 'Properties.Bottom']);
  L10nControl(lblIconSize,       'Properties.IconSize');
  L10nControl(chbUseBkgndColor,  'Properties.BgColor');
  L10nControl(lblMargin,         'Properties.Margins');
  L10nControl(lblOrder,          'Properties.Order');
  L10nControl(cbbItemOrder,      ['Properties.LtR', 'Properties.UtD']);
  L10nControl(lblTextPosition,   'Properties.TextPos');
  L10nControl(cbbTextLayout,     ['Properties.Without' , 'Properties.Left', 'Properties.Top', 'Properties.Right', 'Properties.Bottom']);
  L10nControl(lblTextWidthIdent, 'Properties.TextWidth');
  L10nControl(chbUseTextColor,   'Properties.TextColor');
  L10nControl(lblGlowSize,       'Properties.GlowSize');
  L10nControl(chbStayOnTop,      'Properties.AlwaysOnTop');
  // Autohide
  L10nControl(lblSection2,       'Properties.AutoHide');
  L10nControl(lbl2,              'Properties.Hide');
  L10nControl(chbAutoHide,       'Properties.Automatically');
  L10nControl(lblShow,           'Properties.Show');
  L10nControl(cbbAutoShowMode,   ['Properties.MouseHover', 'Properties.MouseLC', 'Properties.MouseRC']);
  L10nControl(lblDelay,          'Properties.Delay');
  L10nControl(lblCornerGapWidth, 'Properties.CornerTransWidth');
  L10nControl(lblHotKey,         'Properties.HotKey');
  L10nControl(chbAutoHideTransparency, 'Properties.AutoHideTransparency');
  // Additional
  L10nControl(lblSectionJumplist,   'Properties.Jumplists');
  L10nControl(lblJumplistShowMode,  'Properties.Show');
  L10nControl(cbbJumplistShowMode,  ['Properties.No', 'Properties.MouseRC']);
  L10nControl(lblJumplistRecentMax, 'Properties.JumplistRecentMaxItems');
  L10nControl(lblSectionAdditional, 'Properties.Additional');
  L10nControl(chbLightStyle,        'Properties.Style1');
  //L10nControl(lblSectionWin8,       'Properties.ForW8');
  L10nControl(chbAeroGlass,         'Properties.AeroGlass');
  //L10nControl(lblSectionWin10,      'Properties.ForW10');
  L10nControl(lblLook,              'Properties.Look');
  L10nControl(cbbLook,              ['Properties.Opaque', 'Properties.Transparent', 'Properties.Glass']);
  // About
  L10nControl(lblVer,               'Properties.Version');
  L10nControl(lblLocalizer,         'Properties.Localizer');
  L10nControl(Label2,               'Properties.SystemInfo');
  // Buttons
  L10nControl(btnOk,                'Properties.Ok');
  L10nControl(btnCancel,            'Properties.Cancel');
  L10nControl(btnApply,             'Properties.Apply');
end;

procedure TFrmProperties.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TFrmProperties.FormDestroy(Sender: TObject);
begin
  FrmProperties := nil;
  FColorPicker.Free;
  PostMessage(FLinkbar.Handle, LM_DOAUTOHIDE, 0, 0);
end;

procedure TFrmProperties.FormMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
var spin: TnSpinedit;
begin
  if Assigned(ActiveControl)
     and (ActiveControl.ClassType = TnSpinedit)
  then begin
    spin := TnSpinedit(ActiveControl);
    spin.Value := spin.Value + Sign(WheelDelta) * spin.Increment;
    Handled := True;
  end;
end;

procedure TFrmProperties.imCopyClick(Sender: TObject);
begin
  Clipboard.AsText := lblSysInfo.Caption;
end;

procedure TFrmProperties.linkEmailLinkClick(Sender: TObject; const Link: string;
  LinkType: TSysLinkType);
begin
  if not SendShellEmail(Application.Handle, URL_EMAIL,
    APP_NAME_LINKBAR,
    lblVer.Caption
    + '%0D%0A' + 'OS: ' + lblSysInfo.Caption)
  then begin
  end;
end;

procedure TFrmProperties.linkWebLinkClick(Sender: TObject; const Link: string;
  LinkType: TSysLinkType);
begin
  LBShellExecute(0, 'open', URL_WEB);
end;

procedure TFrmProperties.Changed(Sender: TObject);
var ah: Boolean;
begin
  if (not FCanChanged)
  then Exit;

  btnApply.Enabled := True;

  // Color additional options
  edtBkgndColor.Enabled := chbUseBkgndColor.Checked;
  btnBkgndColorEdit.Enabled := chbUseBkgndColor.Checked;
  clbTextColor.Enabled := chbUseTextColor.Checked;

  // Autohide additional options
  ah := chbAutoHide.Checked;
  cbbAutoShowMode.Enabled := ah;
  chbAutoHideTransparency.Enabled := ah;
  lblShow.Enabled := ah;
  // Mouse-Hover Delay
  lblDelay.Enabled := ah;
  nseAutoShowDelay.Enabled := lblDelay.Enabled;
  // Hotkey
  lblHotKey.Enabled := ah;
  edtHotKey.Enabled := lblHotKey.Enabled;

  lblCornerGapWidth.Enabled := ah;
  nseCorner1GapWidth.Enabled := ah;
  nseCorner2GapWidth.Enabled := ah;

  // Text additional options
  lblTextWidthIdent.Enabled := cbbTextLayout.ItemIndex > 0;
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

  FLinkbar.BackgroundColor := FBackgroundColor;
  FLinkbar.TextColor := FTextColor;
  FLinkbar.UseBkgndColor := chbUseBkgndColor.Checked;
  FLinkbar.UseTextColor := chbUseTextColor.Checked;

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
  FLinkbar.JumplistShowMode := TJumplistShowMode(cbbJumplistShowMode.ItemIndex);
  FLinkbar.JumplistRecentMax := nseJumplistRecentMax.Value;
  FLinkbar.StayOnTop := chbStayOnTop.Checked;
  FLinkbar.LookMode := TLookMode(cbbLook.ItemIndex);
  FLinkbar.Corner1GapWidth := nseCorner1GapWidth.Value;
  FLinkbar.Corner2GapWidth := nseCorner2GapWidth.Value;

  FLinkbar.UpdateItemSizes;

  // for avoid double message "autohide panel already exists..."
  temp_ah := FLinkbar.AutoHide;
  FLinkbar.ScreenAlign := TScreenAlign(cbbScreenPosition.ItemIndex);
  if (temp_ah = FLinkbar.AutoHide)
  then FLinkbar.AutoHide := chbAutohide.Checked;

  FLinkbar.HotkeyInfo := edtHotKey.HotkeyInfo;

  FLinkbar.SaveSettings;

  if (Sender = btnOk)
  then begin
    Close;
    Exit;
  end;

  chbAutoHide.Checked := FLinkbar.AutoHide;
  btnApply.Enabled := False;
  ActiveControl := btnOk;
end;

procedure TFrmProperties.edtBkgndColorChange(Sender: TObject);
begin
  if (Sender = edtBkgndColor)
  then FBackgroundColor := Cardinal(StrToIntDef(HexDisplayPrefix + edtBkgndColor.Text, 0));

  if (Sender = clbTextColor)
  then FTextColor := Cardinal(clbTextColor.Selected);

  Changed(Sender);
end;

procedure TFrmProperties.edtBkgndColorKeyPress(Sender: TObject; var Key: Char);
begin
  if (Key = #8)
  then Exit;

  if not CharInSet(Key, ['a'..'f', 'A'..'F', '0'..'9'])
  then Key := #0;
end;

procedure TFrmProperties.btnBgColorClick(Sender: TObject);
begin
  if (Sender = btnBkgndColorEdit)
  then begin
    FColorPicker.Color := BackgroundColor;
    if (FColorPicker.ShowModal = mrOk)
    then BackgroundColor := FColorPicker.Color;
  end;
end;

procedure TFrmProperties.SetBackgroundColor(AValue: Cardinal);
begin
  FBackgroundColor := AValue;
  edtBkgndColor.Text := IntToHex(FBackgroundColor, 8);
end;

procedure TFrmProperties.SetTextColor(AValue: Cardinal);
begin
  FTextColor := AValue and $ffffff;
  clbTextColor.Selected := FTextColor;
end;

end.

