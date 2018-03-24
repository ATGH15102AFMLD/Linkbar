{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{            Copyright (c) 2010-2018 Asaq               }
{*******************************************************}

unit Linkbar.Themes;

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
    Align: TScreenAlign;
    ClipRect: TRect;
    IsLight: Boolean;
    BgColor: Cardinal;
  end;

  procedure ThemeDrawButton(const ABitmap: THBitmap; const ARect: TRect;
    APressed: Boolean);
  procedure ThemeDrawHover(const ABitmap: THBitmap; const AAlign: TScreenAlign;
    const ARect: TRect);
  procedure ThemeDrawBackground(PParams: PDrawBackgroundParams);
  procedure ThemeUpdateBlur(const AWnd: HWND; const AEnabled: Boolean);
  procedure ThemeInitData(const AWnd: HWND; AIsLight: Boolean);
  procedure ThemeCloseData;
  procedure ThemeGetTaskbarColor(out AColor: Cardinal; const ALook: TLookMode);
  procedure ThemeSetWindowAttribute78(const AWnd: HWND);
  procedure ThemeSetWindowAttribute10(const AWnd: HWND; const ALookMode: TLookMode; const AColor: Cardinal);
  procedure ThemeSetWindowAccentPolicy10(const AWnd: HWND; const ALookMode: TLookMode; const AColor: Cardinal);
  procedure GetTitleFont(AFont: TFont);

var
  ExpAeroGlassEnabled: Boolean;
  ThemeButtonNormalTextColor, ThemeButtonSelectedTextColor, ThemeButtonPressedTextColor: TColor;

implementation

uses
  Linkbar.OS, Linkbar.Undoc;

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

function GetTaskbarColor10(const ALook: TLookMode): Cardinal;
var atype, aset: Integer;
    transparent: Boolean;
begin
  Result := 0;
  transparent := ALook <> lmOpaque;
  if Assigned(UGetImmersiveUserColorSetPreferenceProc)
  then begin
    if (transparent)
    then atype := UGetImmersiveColorTypeFromNameProc('ImmersiveSystemAccentDark3')
    else atype := UGetImmersiveColorTypeFromNameProc('ImmersiveSystemAccentDark2');
    if (atype >= 0)
    then begin
      aset := UGetImmersiveUserColorSetPreferenceProc(False, False);
      Result := UGetImmersiveColorFromColorSetExProc(aset, atype, True, 0);
      Result := SwapRedBlue(Result);
      if (transparent)
      then Result := (Result and $FFFFFF) or (Cardinal(217) shl 24); // Default taskbar opacity 85%
    end;
  end;
end;

procedure ThemeGetTaskbarColor(out AColor: Cardinal; const ALook: TLookMode);
begin
  if IsWindows7 then AColor := 0
  else if IsWindows8dot1 then AColor := GetTaskbarColor8()
  else if IsWindows10 then AColor := GetTaskbarColor10(ALook);
end;

procedure ThemeSetWindowAccentPolicy10(const AWnd: HWND; const ALookMode: TLookMode;{ const AUseColor: Boolean;} const AColor: Cardinal);
const WCA_ACCENT_STATE: array[TLookMode] of Integer = (U_WCA_ACCENT_STATE_ENABLE_GRADIENT,
                                                       U_WCA_ACCENT_STATE_ENABLE_TRANSPARENTGRADIENT,
                                                       U_WCA_ACCENT_STATE_ENABLE_BLURBEHIND,
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

    if (ALookMode = lmOpaque)
    then begin
      // When AccentState changed from Transparent to Opaque then under the window
      // there is a "transparent ghost". It does not change its size with the Linkbar window
      // Taskbar have similar bug. Reported this to the MS Feedback Hud
      FillChar(AccentPolicy, SizeOf(AccentPolicy), 0);
      AccentPolicy.AccentState := U_WCA_ACCENT_STATE_DISABLED;
      UDwmSetWindowCompositionAttributeProc(AWnd, @wcad);
    end;

    AccentPolicy.AccentState := WCA_ACCENT_STATE[ALookMode];
    AccentPolicy.AccentFlags := U_WCA_ACCENT_FLAG_DRAW_ALL;
    AccentPolicy.GradientColor := SwapRedBlue(AColor);
    AccentPolicy.AnimationId := 0;
    UDwmSetWindowCompositionAttributeProc(AWnd, @wcad);
  end;
end;

procedure ThemeSetWindowAttribute10(const AWnd: HWND; const ALookMode: TLookMode; {const AUseColor: Boolean;} const AColor: Cardinal);
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
  ThemeSetWindowAccentPolicy10(AWnd, ALookMode, AColor);
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

  if (IsWindows8And8Dot1 and not ExpAeroGlassEnabled)
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

procedure WinXP_DrawThemedButton(const ABitmap: THBitmap; const ARect: TRect;
  APressed: Boolean);
var
  DrawFlags: Cardinal;
begin
  { Draw as button }
  DrawFlags := DFCS_BUTTONPUSH;
  if APressed
  then DrawFlags := DrawFlags or DFCS_PUSHED
  else DrawFlags := DrawFlags or DFCS_HOT;
  DrawFrameControl(ABitmap.Dc, ARect, DFC_BUTTON, DrawFlags); {}
  ABitmap.OpaqueRect(ARect);
end;

procedure Win7_DrawThemedButton(const ABitmap: THBitmap; const ARect: TRect;
  APressed: Boolean);
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
  DrawThemeBackground(hButton, ABitmap.Dc, Part, State, PaintRect, @PaintRect);
end;

procedure ThemeDrawButton(const ABitmap: THBitmap; const ARect: TRect;
  APressed: Boolean);
begin
  if StyleServices.Enabled
  then Win7_DrawThemedButton(ABitmap, ARect, APressed)
  else WinXP_DrawThemedButton(ABitmap, ARect, APressed);
end;

////////////////////////////////////////////////////////////////////////////////
// Draw Themes Drag&Drop hovered item
////////////////////////////////////////////////////////////////////////////////

procedure WinXP_DrawThemedHover(const ABitmap: THBitmap; const ARect: TRect);
begin
  WinXP_DrawThemedButton(ABitmap, ARect, False);
end;

procedure Win7_DrawThemedHover(const ABitmap: THBitmap; const AAlign: TScreenAlign;
  const ARect: TRect);
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
    if (AAlign = saLeft) or (AAlign = saRight)
    then th := hButtonVertical
    else th := hButton;
  end;
  PaintRect := ARect;
  DrawThemeBackground(th, ABitmap.Dc, Part, State, PaintRect, @PaintRect);
end;

procedure ThemeDrawHover(const ABitmap: THBitmap; const AAlign: TScreenAlign;
  const ARect: TRect);
begin
  if StyleServices.Enabled
  then Win7_DrawThemedHover(ABitmap, AAlign, ARect)
  else WinXP_DrawThemedHover(ABitmap, ARect);
end;

////////////////////////////////////////////////////////////////////////////////
// Draw Themes Background
////////////////////////////////////////////////////////////////////////////////

const
  LB_PARTID: array[TScreenAlign, Boolean] of integer = (
    (TBP_BACKGROUNDLEFT,   3),
    (TBP_BACKGROUNDTOP,    2),
    (TBP_BACKGROUNDRIGHT,  4),
    (TBP_BACKGROUNDBOTTOM, 1)
  );

{$REGION ' BG for Windows XP '}
procedure WinXP_DrawThemedBackground(PParams: PDrawBackgroundParams);
const BF_FLAGS: array[TScreenAlign] of UINT = (BF_RIGHT, BF_BOTTOM, BF_LEFT, BF_TOP);
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
{$ENDREGION}

{$REGION ' BG for Windows Vista '}
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
{$ENDREGION}

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

  if PParams.Align in [saLeft, saRight]
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
  if ExpAeroGlassEnabled
  then Win8AG_DrawThemedBackground(PParams)
  else Win8Def_DrawThemedBackground(PParams);
end;
{$ENDREGION}

{$REGION ' BG for Windows 10 '}
procedure Win10_DrawThemedBackground(PParams: PDrawBackgroundParams);
var gpDrawer: IGPGraphics;
begin
  gpDrawer := TGPGraphics.Create(PParams.Bitmap.Dc);
  gpDrawer.SetClip( TGPRect.Create(PParams.ClipRect) );
  gpDrawer.Clear($01000000);
end;
{$ENDREGION}

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
  // NOTE: Normal and Selected StateId are confused or I do not understand
  // This work on Windows 8/8.1 with Default and HighContrast themes
  // Normal
  if GetThemeColor(hButton, LB_TBP_BUTTON_W7, LB_TBS_BUTTON_SELECTED_W7, TMT_TEXTCOLOR, color) = S_OK
  then ThemeButtonNormalTextColor := color
  else ThemeButtonNormalTextColor := clBlack;
  // Selected
  if GetThemeColor(hButton, LB_TBP_BUTTON_W7, LB_TBS_BUTTON_NORMAL_W7, TMT_TEXTCOLOR, color) = S_OK
  then ThemeButtonSelectedTextColor := color
  else ThemeButtonSelectedTextColor := clBlack;
  // Pressed
  if GetThemeColor(hButton, LB_TBP_BUTTON_W7, LB_TBS_BUTTON_PRESSED_W7, TMT_TEXTCOLOR, color) = S_OK
  then ThemeButtonPressedTextColor := color
  else ThemeButtonPressedTextColor := clBlack;
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
