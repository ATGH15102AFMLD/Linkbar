{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{            Copyright (c) 2010-2018 Asaq               }
{*******************************************************}

unit Linkbar.Theme;

{$i linkbar.inc}

interface

uses
  GdiPlus,
  System.Classes, System.Math, Vcl.Graphics, Vcl.Themes,
  Winapi.Windows, Winapi.UxTheme, Winapi.Dwmapi,
  Linkbar.Consts, Linkbar.Graphics;

type
  PDrawBackgroundParams = ^TDrawBackgroundParams;
  TDrawBackgroundParams = record
    Bitmap: THBitmap;
    Align: TPanelAlign;
    ClipRect: TRect;
    IsLight: Boolean;
    BgColor: Cardinal;
  end;

  TLookMode = record
    Color: TLook;
    Transparency: TTransparencyMode;
  end;

  procedure ThemeDrawButton(const ABitmap: THBitmap; const ARect: TRect; APressed: Boolean);
  procedure ThemeDrawHover(const ABitmap: THBitmap; const AAlign: TPanelAlign; const ARect: TRect);
  procedure ThemeDrawSeparator(const ABitmap: THBitmap; const AAlign: TPanelAlign; const ARect: TRect);
  procedure ThemeDrawBackground(PParams: PDrawBackgroundParams);
  procedure ThemeUpdateBlur(const AWnd: HWND; const AEnabled: Boolean);
  procedure ThemeInitData(const AWnd: HWND; AIsLight: Boolean);
  procedure ThemeCloseData;
  procedure ThemeGetTaskbarColor(out AColor: Cardinal; const ALookMode: TLookMode);
  procedure ThemeSetWindowAttribute78(const AWnd: HWND);
  procedure ThemeSetWindowAttribute10(const AWnd: HWND; const ATransparencyMode: TTransparencyMode; const AColor: Cardinal);
  procedure ThemeSetWindowAccentPolicy10(const AWnd: HWND; const ATransparencyMode: TTransparencyMode; const AColor: Cardinal);
  procedure GetTitleFont(AFont: TFont);
  function GetImmersiveColorFromName(const AName: string): Cardinal;

  function SwapRedBlue(const AColor: Cardinal): Cardinal; inline;
  function ScaleDimension(const AValue: Integer): Integer; inline;

var
  ThemeButtonNormalTextColor, ThemeButtonSelectedTextColor, ThemeButtonPressedTextColor: TColor;

implementation

uses
  Linkbar.OS, Linkbar.Undoc, Vcl.Forms;

const
  LB_TBP_BUTTON_WV = 1;
  LB_TBP_BUTTON_W7 = 5;

  LB_TBS_BUTTON_NORMAL_WV   = 0;
  LB_TBS_BUTTON_PRESSED_WV  = 3;
  LB_TBS_BUTTON_SELECTED_WV = 3;

  LB_TBS_BUTTON_NORMAL_W7   = 3;
  LB_TBS_BUTTON_PRESSED_W7  = 5;
  LB_TBS_BUTTON_SELECTED_W7 = 9;

var
  hBackground: HTHEME = 0;
  hBackgroundVertical: HTHEME = 0;
  hButton: HTHEME = 0;
  hButtonVertical: HTHEME = 0;

////////////////////////////////////////////////////////////////////////////////
// DWM
////////////////////////////////////////////////////////////////////////////////

{ Sets Color Alpha to 1 if it is 0 }
function FixAlpha(const AColor: Cardinal): Cardinal; inline;
begin
  Result := (Max(1, AColor shr 24) shl 24) or (AColor and $00FFFFFF);
end;

{ Swap Red and Blue channel }
function SwapRedBlue(const AColor: Cardinal): Cardinal; inline;
begin
  Result := (AColor and $FF00FF00) or ((AColor and 255) shl 16) or ((AColor shr 16) and 255);
end;

function ScaleDimension(const AValue: Integer): Integer;
begin
  Result := MulDiv(AValue, Screen.PixelsPerInch, 96);
end;

{$REGION ' Another methods of obtaining taskbar color on Windows8 (not Worked) '}
{
function GetTaskbarColor8_3(): Cardinal;
var cp: TColorizationParams;
    ir, ig, ib, ir2, ig2, ib2, dr, dg, db, dc, da: Integer;
    brightness, glowBalance: Integer;
begin
  Result := 0;
  if Assigned(UDwmGetColorizationParametersProc)
  then begin
    UDwmGetColorizationParametersProc(cp);
    // boost the color balance to better match the Windows 7 menu
    cp.ColorBalance := Floor(100.0 * Power(cp.ColorBalance / 100.0, 0.5));
    ir := (cp.Color shr 16) and 255;
    ig := (cp.Color shr 8) and 255;
    ib := (cp.Color) and 255;
    ir2 := (cp.Afterglow shr 16) and 255;
    ig2 := (cp.Afterglow shr 8) and 255;
    ib2 := (cp.Afterglow) and 255;

    brightness := (ir*21 + ig*72 + ib*7) div 255; // [0..100]
    glowBalance := (brightness * cp.AfterglowBalance) div 100; // [0..100]

    dr := MulDiv(ir2*glowBalance+ir*100, cp.ColorBalance*255, 10000);
    dg := MulDiv(ig2*glowBalance+ig*100, cp.ColorBalance*255, 10000);
    db := MulDiv(ib2*glowBalance+ib*100, cp.ColorBalance*255, 10000);
    dc := ((glowBalance + 100) * cp.ColorBalance * 255) div 10000;

    da := ((100 - cp.AfterglowBalance - cp.BlurBalance)*255) div 100;

    if (cp.OpaqueBlend <> 0) or (da >= 255)
    then da := 255
    else if (da <= 0)
         then begin
           dr := 0;
           dg := 0;
           db := 0;
           da := 0;
         end;

    if (dc > 0)
    then begin
      dr := dr div dc;
      dg := dg div dc;
      db := db div dc;
    end;

    dr := EnsureRange(dr, 0, 255);
    dg := EnsureRange(dg, 0, 255);
    db := EnsureRange(db, 0, 255);

    Result := (dr shl 16) or (dg shl 8) or db or (da shl 24);
  end;
end;

function BlendColors(AColor1, AColor2: TGPColor; ABalance: Cardinal): TGPColor;

  function BlendAlphaValue(a, b: Byte; t: Byte): Byte;
  var c: Single;
  begin
    c := a + (b - a) * t / 100.0;
    Result := Min(Round(c), 255);
  end;

  function BlendColorValue(a, b: Byte; t: Single): Byte;
  var c: Single;
  begin
    c := Sqrt(a * a + (b * b - a * a) * t / 100.0);
    Result := Min(Round(c), 255);
  end;

begin
  ABalance := Min(100, Max(0, ABalance));
  Result := TGPColor.MakeARGB(
    BlendAlphaValue(AColor1.A, AColor2.A, ABalance),
    BlendColorValue(AColor1.R, AColor2.R, ABalance),
    BlendColorValue(AColor1.G, AColor2.G, ABalance),
    BlendColorValue(AColor1.B, AColor2.B, ABalance)
  );
end;

function GetTaskbarColor8_2(): Cardinal;
var cp: TColorizationParams;
    color1, color2: TGPColor;
begin
  Result := 0;
  if Assigned(UDwmGetColorizationParametersProc)
  then begin
    UDwmGetColorizationParametersProc(cp);
    color1 := TGPColor.Create(cp.Color);
    //color2 := TGPColor.Create($1AAAAAAA);
    color2 := TGPColor.Create($80d9d9d9);
    //color1.Alpha := 217; // colr2.Alpha;
    color1.Alpha := color2.Alpha;
    color1 := BlendColors(color2, color1, cp.ColorBalance);
    Result := color1.Value;
  end;
end;
}
{$ENDREGION}

function GetTaskbarColor8(): Cardinal;
var cp: TColorizationParams;
    r, g, b, gray, alpha: Cardinal;
begin
  Result := 0;
  if Assigned(UDwmGetColorizationParametersProc)
  then begin
    UDwmGetColorizationParametersProc(cp);
    r := (cp.Color shr 16) and 255;
    g := (cp.Color shr 8) and 255;
    b := (cp.Color) and 255;
    gray := 217 * (100 - cp.ColorBalance) + 50;
    r := (r * cp.ColorBalance + gray) div 100;
    g := (g * cp.ColorBalance + gray) div 100;
    b := (b * cp.ColorBalance + gray) div 100;
    alpha := (cp.Color shr 24) and 255;
    alpha := alpha * 65 div 100;
    Result := (r shl 16) or (g shl 8) or b or (alpha shl 24);
  end;
end;

function GetMetroGlassColor(): Cardinal; // For Windows 10
var atype, aset: Integer;
begin
  Result := $ff00ff00;
  if Assigned(UGetImmersiveUserColorSetPreferenceProc)
  then begin
    atype := UGetImmersiveColorTypeFromNameProc('ImmersiveStartBackground');
    if (atype >= 0)
    then begin
      aset := UGetImmersiveUserColorSetPreferenceProc(False, False);
      Result := UGetImmersiveColorFromColorSetExProc(aset, atype, True, 0);
      Result := SwapRedBlue(Result);
      //sResult := (Result and $FFFFFF) or (Cardinal(217) shl 24); // Default taskbar opacity 85%
    end;
  end;
end;

function GetImmersiveColorFromName(const AName: string): Cardinal;
var atype, aset: Integer;
begin
  Result := 0;

  if Assigned(UGetImmersiveUserColorSetPreferenceProc)
  then begin
    {reg := TRegistry.Create;
    try
      reg.RootKey := HKEY_CURRENT_USER;
      if reg.OpenKeyReadOnly('Software\Microsoft\Windows\CurrentVersion\Themes\Personalize')
         and (reg.GetDataType('EnableTransparency') = rdInteger)
      then transparent := reg.ReadInteger('EnableTransparency') <> 0;
    finally
      reg.Free;
    end;}

    atype := UGetImmersiveColorTypeFromNameProc(PChar(AName));
    if (atype >= 0)
    then begin
      aset := UGetImmersiveUserColorSetPreferenceProc(False, False);
      Result := UGetImmersiveColorFromColorSetExProc(aset, atype, True, 0);
      //Result := SwapRedBlue(Result);
    end;
  end;
end;

function GetTaskbarColor10(const ALookMode: TLookMode): Cardinal;
var transparent: Boolean;
    name: string;
begin
  Result := 0;

  if ALookMode.Color = ELookCustom
  then Exit;

  transparent := ALookMode.Transparency <> tmOpaque;

  if ALookMode.Color = ELookAccent
  then begin
    if (transparent)
    then name := 'ImmersiveSystemAccentDark3'
    else name := 'ImmersiveSystemAccentDark2';
  end

  else if ALookMode.Color = ELookLight
  then name := 'ImmersiveLightChromeTaskbarBase'

  else if ALookMode.Color = ELookDark
  then name := 'ImmersiveDarkChromeTaskbarBase';

  Result := GetImmersiveColorFromName(name);
  Result := SwapRedBlue(Result);

  if (transparent)
  then Result := (Result and $FFFFFF) or (Cardinal(198) shl 24); // Default taskbar opacity 85%
end;

procedure ThemeGetTaskbarColor(out AColor: Cardinal; const ALookMode: TLookMode);
begin
  if IsWindows7 then AColor := 0
  else if IsWindows8dot1 then AColor := GetTaskbarColor8()
  else if IsWindows10 then AColor := GetTaskbarColor10(ALookMode);
end;

procedure ThemeSetWindowAccentPolicy10(const AWnd: HWND; const ATransparencyMode: TTransparencyMode; const AColor: Cardinal);
const WCA_ACCENT_STATE: array[TTransparencyMode] of Integer = (U_WCA_ACCENT_STATE_ENABLE_GRADIENT,
                                                               U_WCA_ACCENT_STATE_ENABLE_TRANSPARENTGRADIENT,
                                                               U_WCA_ACCENT_STATE_ENABLE_ACRYLICBLURBEHIND,
                                                               U_WCA_ACCENT_STATE_DISABLED);
var wcad: TWcaData;
    AccentPolicy: TWcaAccentPolicy;
begin
  // Set window accent policy
  // https://withinrafael.com/2015/07/08/adding-the-aero-glass-blur-to-your-windows-10-apps/
  if Assigned(UDwmSetWindowCompositionAttributeProc)
  then begin
    wcad.dwAttribute := U_WCA_ACCENT_POLICY;
    wcad.cbAttribute := SizeOf(AccentPolicy);
    wcad.pvAttribute := @AccentPolicy;

    {if (ATransparencyMode = tmOpaque)
    then begin
      // When AccentState changes from Transparent to Opaque then under the window
      // appears a "transparent ghost". It does not change its size with the Linkbar window
      // Taskbar has similar bug. Reported this to the MS Feedback Hud
      FillChar(AccentPolicy, SizeOf(AccentPolicy), 0);
      AccentPolicy.AccentState := U_WCA_ACCENT_STATE_DISABLED;
      UDwmSetWindowCompositionAttributeProc(AWnd, @wcad);
    end;}

    AccentPolicy.AccentState := WCA_ACCENT_STATE[ATransparencyMode];
    AccentPolicy.AccentFlags := U_WCA_ACCENT_FLAG_DRAW_ALL;
    AccentPolicy.GradientColor := SwapRedBlue(AColor);
    AccentPolicy.AnimationId := 0;
    UDwmSetWindowCompositionAttributeProc(AWnd, @wcad);
  end;
end;

procedure ThemeSetWindowAttribute10(const AWnd: HWND; const ATransparencyMode: TTransparencyMode; const AColor: Cardinal);
var bAttr: Boolean;
    iAttr: Integer;
begin
  // Exclude from Aero Peek
  bAttr := True;
  DwmSetWindowAttribute(AWnd, DWMWA_EXCLUDED_FROM_PEEK, @bAttr, SizeOf(bAttr));
  // Exclude from Flip3D and display it above the Flip3D rendering
  iAttr := DWMFLIP3D_EXCLUDEABOVE;
  DwmSetWindowAttribute(AWnd, DWMWA_FLIP3D_POLICY, @iAttr, SizeOf(iAttr));
  // Set accent policy
  ThemeSetWindowAccentPolicy10(AWnd, ATransparencyMode, AColor);
end;

procedure ThemeSetWindowAttribute78(const AWnd: HWND);
var bAttr, bPolicy1, bPolicy2: BOOL;
    iAttr: Integer;
    wcad: TWcaData;
begin
  // Exclude from Aero Peek
  bAttr := True;
  DwmSetWindowAttribute(AWnd, DWMWA_EXCLUDED_FROM_PEEK, @bAttr, SizeOf(bAttr));

  // Exclude from Flip3D and display it below the Flip3D rendering
  iAttr := DWMFLIP3D_EXCLUDEBELOW;
  DwmSetWindowAttribute(AWnd, DWMWA_FLIP3D_POLICY, @iAttr, SizeOf(iAttr));

  if (IsWindows8And8Dot1 and not GlobalAeroGlassEnabled)
  then Exit;

  // http://a-whiter.livejournal.com/1385.html
  // http://a-whiter.livejournal.com/2495.html
  // Set non-client rendering policy
  bPolicy1 := True;
  DwmSetWindowAttribute(AWnd, DWMWA_NCRENDERING_POLICY, @bPolicy1, SizeOf(bPolicy1));
  // Set client rendering policy
  if Assigned(UDwmSetWindowCompositionAttributeProc)
  then begin
    if IsWindows8OrAbove
    then wcad.dwAttribute := U_WCA_CLIENTRENDERING_POLICY_WIN8
    else wcad.dwAttribute := U_WCA_CLIENTRENDERING_POLICY_WIN7;
    bPolicy2 := True;
    wcad.pvAttribute := @bPolicy2;
    wcad.cbAttribute := SizeOf(bPolicy2);
    UDwmSetWindowCompositionAttributeProc(AWnd, @wcad);
  end;
end;

procedure ThemeUpdateBlur(const AWnd: HWND; const AEnabled: Boolean);
var
  BlurBehind: TDwmBlurBehind;
  r: TRect;
begin
  if IsWindows10OrAbove
     or (not DwmCompositionEnabled)
  then Exit;

  FillChar(BlurBehind, SizeOf(BlurBehind), 0);
  BlurBehind.dwFlags := DWM_BB_ENABLE;
  BlurBehind.fEnable := AEnabled;
  if AEnabled
  then begin
    if GetWindowRect(AWnd, r)
    then begin
      BlurBehind.dwFlags := BlurBehind.dwFlags or DWM_BB_BLURREGION;
      BlurBehind.hRgnBlur := CreateRectRgnIndirect( Rect(0, 0, r.width, r.height) );
    end;
    if (IsWindowsVista)
    then begin
      BlurBehind.dwFlags := BlurBehind.dwFlags or DWM_BB_TRANSITIONONMAXIMIZED;
      BlurBehind.fTransitionOnMaximized := True;
    end;
  end;
  DwmEnableBlurBehindWindow(AWnd, BlurBehind);
  if (BlurBehind.hRgnBlur <> 0)
  then DeleteObject(BlurBehind.hRgnBlur);
end;

////////////////////////////////////////////////////////////////////////////////
// Draw Themes Button
////////////////////////////////////////////////////////////////////////////////

procedure WinXP_DrawThemedButton(const ABitmap: THBitmap; const ARect: TRect; APressed: Boolean);
var
  DrawFlags: Cardinal;
begin
  { Draw as button }
  DrawFlags := DFCS_BUTTONPUSH;
  if APressed
  then DrawFlags := DrawFlags or DFCS_PUSHED
  else DrawFlags := DrawFlags or DFCS_HOT;
  DrawFrameControl(ABitmap.Dc, ARect, DFC_BUTTON, DrawFlags);
  ABitmap.OpaqueRect(ARect);
end;

procedure Win7_DrawThemedButton(ADc: HDC; const ARect: TRect; APressed: Boolean);
var
  PaintRect: TRect;
  State: Integer;
  Part: Integer;
begin
  if IsWindowsVista
  then begin
    Part := LB_TBP_BUTTON_WV;
    if APressed
    then State := LB_TBS_BUTTON_PRESSED_WV
    else State := LB_TBS_BUTTON_NORMAL_WV;
  end
  else begin
    Part := LB_TBP_BUTTON_W7;
    if APressed
    then State := LB_TBS_BUTTON_PRESSED_W7
    else State := LB_TBS_BUTTON_NORMAL_W7;
  end;
  PaintRect := ARect;
  DrawThemeBackground(hButton, ADc, Part, State, PaintRect, @PaintRect);
end;

procedure Win10_DrawThemedButton(ADc: HDC; const ARect: TRect; APressed: Boolean);
var
  gpDrawer: IGPGraphics;
  color: Cardinal;
begin
  gpDrawer := TGPGraphics.Create(ADc);

  if (GlobalLook = ELookLight)
  then color := (Trunc(255.0 * 0.10) shl 24) or $00000000
  else color := (Trunc(255.0 * 0.10) shl 24) or $00ffffff;

  gpDrawer.FillRectangle(TGPSolidBrush.Create(color), TGPRect.Create(ARect));
end;

procedure ThemeDrawButton(const ABitmap: THBitmap; const ARect: TRect;
  APressed: Boolean);
begin
  if IsWindows10
  then Win10_DrawThemedButton(ABitmap.Dc, ARect, APressed)

  else begin
    if StyleServices.Enabled
    then Win7_DrawThemedButton(ABitmap.Dc, ARect, APressed)
    else WinXP_DrawThemedButton(ABitmap, ARect, APressed);
  end;
end;

////////////////////////////////////////////////////////////////////////////////
// Draw Themes Drag&Drop hovered item
////////////////////////////////////////////////////////////////////////////////

procedure WinXP_DrawThemedHover(const ABitmap: THBitmap; const ARect: TRect);
begin
  WinXP_DrawThemedButton(ABitmap, ARect, False);
end;

procedure Win7_DrawThemedHover(ADc: HDC; const AAlign: TPanelAlign; const ARect: TRect);
var
  PaintRect: TRect;
  State: Integer;
  Part: Integer;
  th: HTHEME;
begin
  if IsWindowsVista
  then begin
    Part := LB_TBP_BUTTON_WV;
    State := LB_TBS_BUTTON_SELECTED_WV;
    th := hButton;
  end
  else begin
    Part := LB_TBP_BUTTON_W7;
    State := LB_TBS_BUTTON_SELECTED_W7;
    if (AAlign = EPanelAlignLeft) or (AAlign = EPanelAlignRight)
    then th := hButtonVertical
    else th := hButton;
  end;
  PaintRect := ARect;
  DrawThemeBackground(th, ADc, Part, State, PaintRect, @PaintRect);
end;

procedure Win10_DrawThemedHover(ADc: HDC; const ARect: TRect);
begin
  Win10_DrawThemedButton(ADc, ARect, False);
end;

procedure ThemeDrawHover(const ABitmap: THBitmap; const AAlign: TPanelAlign; const ARect: TRect);
begin
  if IsWindows10
  then Win10_DrawThemedHover(ABitmap.Dc, ARect)

  else begin
    if StyleServices.Enabled
    then Win7_DrawThemedHover(ABitmap.Dc, AAlign, ARect)
    else WinXP_DrawThemedHover(ABitmap, ARect);
  end;
end;

////////////////////////////////////////////////////////////////////////////////
// Draw Themes Separator
////////////////////////////////////////////////////////////////////////////////

procedure WinXP_DrawThemedSeparator(const ABitmap: THBitmap; const AAlign: TPanelAlign; const ARect: TRect);
const
  OFFSETS: Array[TPanelAlign] of Array[0..1] of Integer = ((4, 6),(4, 6),(6, 4),(6, 4));
var
  r: TRect;
begin
  if (AAlign = EPanelAlignLeft) or (AAlign = EPanelAlignRight)
  then begin
    r.Height := 3;
    r.Width := ARect.Width - OFFSETS[AAlign][0] - OFFSETS[AAlign][1];
    r.Location := ARect.Location + TPoint.Create(OFFSETS[AAlign][0], (ARect.Height - 3) div 2);
  end
  else begin
    r.Width := 3;
    r.Height := ARect.Height - OFFSETS[AAlign][0] - OFFSETS[AAlign][1];
    r.Location := ARect.Location + TPoint.Create((ARect.Width - 3) div 2, OFFSETS[AAlign][0]);
  end;

  DrawEdge(ABitmap.Dc, r, BDR_RAISEDINNER, BF_RECT);

  ABitmap.OpaqueRect(r);
end;

procedure Win7_DrawThemedSeparator(const ADc: HDC; const AAlign: TPanelAlign; const ARect: TRect);
const
  OFFSETS: Array[TPanelAlign] of Array[0..1] of Integer = ((4, 6),(4, 6),(6, 4),(6, 4));
var
  gpDrawer: IGPGraphics;
  gpPen: IGPPen;
  color1, color2: Cardinal;
  l, r, t, b: Integer;
begin
  color1 := (Trunc(255.0 * 0.15) shl 24) or $00000000;
  color2 := (Trunc(255.0 * 0.11) shl 24) or $00ffffff;

  gpDrawer := TGPGraphics.Create(ADc);
  gpPen := TGPPen.Create(color1, 1);

  if (AAlign = EPanelAlignLeft) or (AAlign = EPanelAlignRight)
  then begin
    l := ARect.Left + OFFSETS[AAlign][0];
    r := ARect.Right - OFFSETS[AAlign][1];
    t := ARect.Top + (ARect.Height - 2) div 2;
    gpDrawer.DrawLine(gpPen, l, t, r, t);
    gpPen.Color := color2;
    Inc(t);
    gpDrawer.DrawLine(gpPen, l, t, r, t);
  end
  else begin
    t := ARect.Top + OFFSETS[AAlign][0];
    b := ARect.Bottom - OFFSETS[AAlign][1];
    l := ARect.Left + (ARect.Width - 2) div 2;
    gpDrawer.DrawLine(gpPen, l, t, l, b);
    gpPen.Color := color2;
    Inc(l);
    gpDrawer.DrawLine(gpPen, l, t, l, b);
  end;
end;

procedure Win10_DrawThemedSeparator(const ADc: HDC; const AAlign: TPanelAlign; const ARect: TRect);
var
  sr: TSize;
  r: TRect;
  gpDrawer: IGPGraphics;
  color: Cardinal;
  name: string;
begin
  sr := TSize.Create(ScaleDimension(2), ScaleDimension(4));

  if (AAlign = EPanelAlignLeft) or (AAlign = EPanelAlignRight)
  then begin
    r := TRect.Create(
      TPoint.Create(ARect.Left + sr.cy, ARect.Top + ((ARect.Height - sr.cx) div 2)),
      ARect.Width - 2 * sr.cy, sr.cx);
  end
  else begin
    r := TRect.Create(
      TPoint.Create(ARect.Left + ((ARect.Width - sr.cx) div 2), ARect.Top + sr.cy),
      sr.cx, ARect.Height - 2 * sr.cy);
  end;

  // Like Taskbar button shevron
  case GlobalLook of
    ELookLight:  name := 'ImmersiveSystemAccent';
    ELookDark:   name := 'ImmersiveSystemAccentLight2';
    ELookAccent: name := 'ImmersiveSystemAccentLight3';
  end;
  color := SwapRedBlue(GetImmersiveColorFromName(name));
  //color := (Trunc(255.0 * 0.932) shl 24) or (color and $00ffffff);

  gpDrawer := TGPGraphics.Create(ADc);
  gpDrawer.FillRectangle(TGPSolidBrush.Create(color), TGPRect.Create(r));
end;

procedure ThemeDrawSeparator(const ABitmap: THBitmap; const AAlign: TPanelAlign; const ARect: TRect);
begin
  if IsWindows10
  then Win10_DrawThemedSeparator(ABitmap.Dc, AAlign, ARect)

  else begin
    if (StyleServices.Enabled)
    then Win7_DrawThemedSeparator(ABitmap.Dc, AAlign, ARect)
    else WinXP_DrawThemedSeparator(ABitmap, AAlign, ARect);
  end;
end;

////////////////////////////////////////////////////////////////////////////////
// Draw Themes Background
////////////////////////////////////////////////////////////////////////////////

const
  LB_PARTID: array[TPanelAlign, Boolean] of integer = (
    (TBP_BACKGROUNDLEFT,   3),
    (TBP_BACKGROUNDTOP,    2),
    (TBP_BACKGROUNDRIGHT,  4),
    (TBP_BACKGROUNDBOTTOM, 1)
  );

procedure WinXP_DrawThemedBackground(PParams: PDrawBackgroundParams);
const BF_FLAGS: array[TPanelAlign] of UINT = (BF_RIGHT, BF_BOTTOM, BF_LEFT, BF_TOP);
var
  dc: HDC;
  r: TRect;
begin
  r := PParams.ClipRect;
  dc := PParams.Bitmap.Dc;
  FillRect(dc, r, GetSysColorBrush(COLOR_3DFACE));
  DrawEdge(dc, r, BDR_RAISED, BF_FLAGS[PParams.Align]);
  PParams.Bitmap.OpaqueRect(PParams.ClipRect);
end;

procedure WinVista_DrawThemedBackground(PParams: PDrawBackgroundParams);
var
  dc: HDC;
  gpDrawer: IGPGraphics;
  part: Integer;
begin
  if not StyleServices.Enabled
  then WinXP_DrawThemedBackground(PParams)
  else begin
    dc := PParams.Bitmap.Dc;
    gpDrawer := TGPGraphics.Create(dc);
    gpDrawer.SetClip( TGPRect.Create(PParams.ClipRect) );
    gpDrawer.Clear( TGPColor.Create($01000000) );

    part := LB_PARTID[PParams.Align, False];
    DrawThemeBackground(hBackground, dc, part, 0, PParams.Bitmap.Bound, @PParams.ClipRect);
  end;
end;

{$REGION ' BG for Windows 7 '}
procedure Win7Pure_DrawThemedBackground(PParams: PDrawBackgroundParams);
var
  dc: HDC;
  gpDrawer: IGPGraphics;
  part: Integer;
begin
  dc := PParams.Bitmap.Dc;
  gpDrawer := TGPGraphics.Create(dc);
  gpDrawer.SetClip( TGPRect.Create(PParams.ClipRect) );
  gpDrawer.Clear( TGPColor.Create($01000000) );

  part := LB_PARTID[PParams.Align, PParams.IsLight];
  DrawThemeBackground(hBackground, dc, part, 0, PParams.Bitmap.Bound, @PParams.ClipRect);
end;

procedure Win7Aero_DrawThemedBackground(PParams: PDrawBackgroundParams);
var
  dc: HDC;
  gpDrawer: IGPGraphics;
  part: Integer;
  th: HTHEME;
begin
  dc := PParams.Bitmap.Dc;
  gpDrawer := TGPGraphics.Create(dc);
  gpDrawer.SetClip( TGPRect.Create(PParams.ClipRect) );
  gpDrawer.Clear( FixAlpha(PParams.BgColor) );

  part := LB_PARTID[PParams.Align, PParams.IsLight];

  if PParams.Align in [EPanelAlignLeft, EPanelAlignRight]
  then th := hBackgroundVertical
  else th := hBackground;

  DrawThemeBackground(th, dc, part, 0, PParams.Bitmap.Bound, @PParams.ClipRect);
end;

procedure Win7_DrawThemedBackground(PParams: PDrawBackgroundParams);
begin
  if StyleServices.Enabled
  then begin
    if DwmCompositionEnabled
    then Win7Aero_DrawThemedBackground(PParams)
    else Win7Pure_DrawThemedBackground(PParams)
  end
  else begin
    WinXP_DrawThemedBackground(PParams);
  end;
end;
{$ENDREGION}

{$REGION ' BG for Windows 8/8.1 '}
procedure Win8Def_DrawThemedBackground(PParams: PDrawBackgroundParams);
var
  dc: HDC;
  gpDrawer: IGPGraphics;
  part: integer;
begin
  dc := PParams.Bitmap.Dc;
  gpDrawer := TGPGraphics.Create(dc);
  gpDrawer.SetClip( TGPRect.Create(PParams.ClipRect) );
  gpDrawer.Clear( FixAlpha(PParams.BgColor) );

  part := LB_PARTID[PParams.Align, False];
  DrawThemeBackground(hBackground, dc, part, 0, PParams.Bitmap.Bound, @PParams.ClipRect);
end;

procedure Win8AG_DrawThemedBackground(PParams: PDrawBackgroundParams);
var
  dc: HDC;
  gpDrawer: IGPGraphics;
  part: integer;
begin
  dc := PParams.Bitmap.Dc;
  gpDrawer := TGPGraphics.Create(dc);
  gpDrawer.SetClip( TGPRect.Create(PParams.ClipRect) );
  gpDrawer.Clear( FixAlpha(PParams.BgColor) );

  part := LB_PARTID[PParams.Align, False];
  DrawThemeBackground(hBackground, dc, part, 0, PParams.Bitmap.Bound, @PParams.ClipRect);
end;

procedure Win8_DrawThemedBackground(PParams: PDrawBackgroundParams);
begin
  if GlobalAeroGlassEnabled
  then Win8AG_DrawThemedBackground(PParams)
  else Win8Def_DrawThemedBackground(PParams);
end;
{$ENDREGION}

procedure Win10_DrawThemedBackground(PParams: PDrawBackgroundParams);
var gpDrawer: IGPGraphics;
begin
  gpDrawer := TGPGraphics.Create(PParams.Bitmap.Dc);
  gpDrawer.SetClip( TGPRect.Create(PParams.ClipRect) );
  gpDrawer.Clear($01000000);
end;

procedure ThemeDrawBackground(PParams: PDrawBackgroundParams);
begin
  if IsWindows10
  then Win10_DrawThemedBackground(PParams)

  else if IsWindows8And8Dot1
  then Win8_DrawThemedBackground(PParams)

  else if IsWindows7
  then Win7_DrawThemedBackground(PParams)

  else if IsWindowsVista
  then WinVista_DrawThemedBackground(PParams)

  else if IsWindowsXP
  then WinXP_DrawThemedBackground(PParams);
end;

////////////////////////////////////////////////////////////////////////////////
// Open/Close HTHEME's
////////////////////////////////////////////////////////////////////////////////

procedure ThemeInitData(const AWnd: HWND; AIsLight: Boolean);
var color: COLORREF;
begin
  if (not IsMinimumSupportedOS) or (AWnd = 0)
  then Exit;

  ThemeCloseData;

  if not StyleServices.Enabled then Exit;

  // for Windows Vista
  if IsWindowsVista
  then begin
    if DwmCompositionEnabled
    then begin
      hBackground := OpenThemeData(AWnd, 'TaskBarComposited::TaskBar');
      hButton := OpenThemeData(AWnd, 'TaskBandComposited::Toolbar');
    end
    else begin
      hBackground := OpenThemeData(AWnd, 'TaskBar::TaskBar');
      hButton := OpenThemeData(AWnd, 'TaskBand::Toolbar');
    end;
    ThemeButtonNormalTextColor := clWhite;
    ThemeButtonSelectedTextColor := clWhite;
    ThemeButtonPressedTextColor := clWhite;
    Exit;
  end;

  if IsWindows8OrAbove
  then AIsLight := False;

  // for Windows 7/8/8.1/10
  if DwmCompositionEnabled
  then begin
    // NOTE:
    // taskband composited textures separated in two styles for horizontal
    // and vertical position
    if AIsLight
    then begin
      hBackground := OpenThemeData(AWnd, 'TaskBand2Composited::TaskBand2');
      hBackgroundVertical := OpenThemeData(AWnd, 'TaskBand2CompositedVertical::TaskBand2');
    end
    else begin
      hBackground := OpenThemeData(AWnd, 'TaskBar2Composited::TaskBar');
      hBackgroundVertical := hBackground;
    end;
    hButton := OpenThemeData(AWnd, 'TaskBand2Composited::TaskBand2');
    hButtonVertical := OpenThemeData(AWnd, 'TaskBand2CompositedVertical::TaskBand2');
  end
  else begin
    if AIsLight
    then hBackground := OpenThemeData(AWnd, 'TaskBand2::TaskBand2')
    else hBackground := OpenThemeData(AWnd, 'TaskBar2::TaskBar');
    hButton := OpenThemeData(AWnd, 'TaskBand2::TaskBand2');
    hButtonVertical := OpenThemeData(AWnd, 'TaskBand2Vertical::TaskBand2');
  end;

  // Get button text colors
  {
  if IsWindows7
  then begin
    ThemeButtonNormalTextColor := clBtnText;
    ThemeButtonSelectedTextColor := clBtnText;
    ThemeButtonPressedTextColor := clBtnText;
  end
  else begin
  {}
    // NOTE: Normal and Selected StateId are confused or I do not understand
    // This work on Windows 8/8.1 with Default and HighContrast themes
    // Normal
    if GetThemeColor(hButton, LB_TBP_BUTTON_W7, LB_TBS_BUTTON_SELECTED_W7, TMT_TEXTCOLOR, color) = S_OK
    then ThemeButtonNormalTextColor := color//SwapRedBlue(color)
    else ThemeButtonNormalTextColor := clBlack;
    // Selected
    if GetThemeColor(hButton, LB_TBP_BUTTON_W7, LB_TBS_BUTTON_NORMAL_W7, TMT_TEXTCOLOR, color) = S_OK
    then ThemeButtonSelectedTextColor := color//SwapRedBlue(color)
    else ThemeButtonSelectedTextColor := clBlack;
    // Pressed
    if GetThemeColor(hButton, LB_TBP_BUTTON_W7, LB_TBS_BUTTON_PRESSED_W7, TMT_TEXTCOLOR, color) = S_OK
    then ThemeButtonPressedTextColor := color//SwapRedBlue(color)
    else ThemeButtonPressedTextColor := clBlack;
  {
  end;
  {}
end;

procedure ThemeCloseData;
begin
  CloseThemeData(hBackground); hBackground := 0;
  CloseThemeData(hBackgroundVertical); hBackgroundVertical := 0;
  CloseThemeData(hButton); hButton := 0;
  CloseThemeData(hButtonVertical); hButtonVertical := 0;
end;

procedure GetTitleFont(AFont: TFont);
var theme: HTHEME;
    color: Cardinal;
    fontstyle: TFontStyles;
    logfont: TLogFont;
begin
  if StyleServices.Enabled
  then begin
    theme := OpenThemeData(0, VSCLASS_TEXTSTYLE);
    if (theme > 0)
    then begin
      // Color
      GetThemeColor(theme, TEXT_MAININSTRUCTION, 1, TMT_TEXTCOLOR, color);
      AFont.Color := TColorRef(color);
      // Height and styles
      if (GetThemeFont(theme, 0, TEXT_MAININSTRUCTION, 1, TMT_FONT, logfont) = S_OK)
      then begin
        AFont.Height := logfont.lfHeight;
        fontstyle := [];
        if (logfont.lfWeight >= FW_BOLD) then fontstyle := fontstyle + [fsBold];
        if (logfont.lfItalic > 1) then fontstyle := fontstyle + [fsItalic];
        if (logfont.lfUnderline > 1) then fontstyle := fontstyle + [fsUnderline];
        if (logfont.lfStrikeOut > 1) then fontstyle := fontstyle + [fsStrikeOut];
      end;
      AFont.Style := fontstyle;
      CloseThemeData(theme);
    end;
  end
  else begin
    AFont.Style := [fsBold];
  end;
end;

end.
