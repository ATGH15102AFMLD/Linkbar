{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{            Copyright (c) 2010-2017 Asaq               }
{*******************************************************}

unit Linkbar.Themes;

{$i linkbar.inc}

interface

uses
  GdiPlus, GdiPlusHelpers,
  Windows, SysUtils, Classes, Graphics, Controls, Forms,
  Winapi.UxTheme, Vcl.Themes, Winapi.Dwmapi,
  Linkbar.Consts;

type
  PDrawBackgroundParams = ^TDrawBackgroundParams;
  TDrawBackgroundParams = record
    Bitmap: TBitmap;
    Align: TScreenAlign;
    ClipRect: TRect;
    IsLight: Boolean;
    BgColor: Cardinal;
  end;

  procedure ThemeDrawButton(const ABitmap: TBitmap; const ARect: TRect;
    APressed: Boolean);
  procedure ThemeDrawHover(const ABitmap: TBitmap; const AAlign: TScreenAlign;
    const ARect: TRect);
  procedure ThemeDrawBackground(PParams: PDrawBackgroundParams);
  procedure ThemeDrawGlow(const ABitmap: TBitmap; const ARect: TRect; const AColor: Cardinal);
  procedure ThemeUpdateBlur(const AWnd: HWND; AEnabled: Boolean);
  procedure ThemeInitData(const AWnd: HWND; AIsLight: Boolean);
  procedure ThemeCloseData;
  procedure ThemeSetWindowAttribute(AWnd: HWND);
  procedure GetTitleFont(AFont: TFont);

var
  ExpAeroGlassEnabled: Boolean = False;

implementation

uses
  Math, Linkbar.OS, Linkbar.Undoc;

var
  hBackground: HTHEME = 0;
  hBackgroundVertical: HTHEME = 0;
  hButton: HTHEME = 0;
  hButtonVertical: HTHEME = 0;

////////////////////////////////////////////////////////////////////////////////
// DWM
////////////////////////////////////////////////////////////////////////////////

procedure ThemeSetWindowAttribute(AWnd: HWND);
var
  bAttr, bPolicy1, bPolicy2: BOOL;
  iAttr: Integer;
  wcad: TWcaData;
  AccentPolicy: TWcaAccentPolicy;
begin
  if not IsWindow(AWnd)
  then Exit;

  // Exclude from Aero Peek
  bAttr := True;
  DwmSetWindowAttribute(AWnd, DWMWA_EXCLUDED_FROM_PEEK, @bAttr, SizeOf(bAttr));
  // Exclude from Flip3D and display it above the Flip3D rendering
  iAttr := DWMFLIP3D_EXCLUDEBELOW;
  DwmSetWindowAttribute(AWnd, DWMWA_FLIP3D_POLICY, @iAttr, SizeOf(iAttr));

  if IsWindowsVista or IsWindows7
     or (IsWindows8And8Dot1 and ExpAeroGlassEnabled)
  then begin
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

  if IsWindows10
  then begin
    // Set window accent policy
    // https://withinrafael.com/2015/07/08/adding-the-aero-glass-blur-to-your-windows-10-apps/
    if Assigned(UDwmSetWindowCompositionAttributeProc)
    then begin
      AccentPolicy.AccentState := U_WCA_ACCENT_STATE_ENABLE_BLURBEHIND;
      AccentPolicy.AccentFlags := U_WCA_ACCENT_FLAG_DEFAULT;
      AccentPolicy.GradientColor := 0;
      AccentPolicy.AnimationId := 0;
      wcad.dwAttribute := U_WCA_ACCENT_POLICY;
      wcad.cbAttribute := SizeOf(AccentPolicy);
      wcad.pvAttribute := @AccentPolicy;
      UDwmSetWindowCompositionAttributeProc(AWnd, @wcad);
    end;
  end;
end;

procedure ThemeUpdateBlur(const AWnd: HWND; AEnabled: Boolean);
var
  BlurBehind: TDwmBlurBehind;
  r: TRect;
begin
  if (not IsWindowsVistaOrAbove or IsWindows10OrAbove) then Exit;

  if (IsWindows8And8Dot1 and not ExpAeroGlassEnabled)
  then AEnabled := False;

  if DwmCompositionEnabled
  then begin
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
end;

////////////////////////////////////////////////////////////////////////////////
// Draw Themes Button
////////////////////////////////////////////////////////////////////////////////

procedure WinXP_DrawThemedButton(const ABitmap: TBitmap; const ARect: TRect;
  APressed: Boolean);
var
  DrawFlags: Cardinal;
  drawer: IGPGraphics;
  bmp: TBitmap;
begin
  bmp := TBitmap.Create;
  bmp.PixelFormat := pf24bit;
  bmp.SetSize(ARect.Width, ARect.Height);
  { Draw as button }
  DrawFlags := DFCS_BUTTONPUSH;
  if APressed
  then DrawFlags := DrawFlags or DFCS_PUSHED
  else DrawFlags := DrawFlags or DFCS_HOT;
  DrawFrameControl(bmp.Canvas.Handle, Rect(0, 0, ARect.Width, ARect.Height), DFC_BUTTON, DrawFlags); {}
  drawer := ABitmap.ToGPGraphics;
  drawer.DrawImage(bmp.ToGPBitmap, ARect.Left, ARect.Top);
  bmp.Free;
end;

procedure Win7_DrawThemedButton(const ABitmap: TBitmap; const ARect: TRect;
  APressed: Boolean);
var
  PaintRect: TRect;
  State: Integer;
  Part: Integer;
begin
  if IsWindowsVista
  then begin
    Part := 1;
    if APressed
    then State := 3
    else State := 0;
  end
  else begin
    Part := 5;
    if APressed
    then State := 5
    else State := 3;
  end;
  PaintRect := ARect;
  DrawThemeBackground(hButton, ABitmap.Canvas.Handle, Part, State, PaintRect, @PaintRect);
end;

procedure ThemeDrawButton(const ABitmap: TBitmap; const ARect: TRect;
  APressed: Boolean);
begin
  if StyleServices.Enabled
  then Win7_DrawThemedButton(ABitmap, ARect, APressed)
  else WinXP_DrawThemedButton(ABitmap, ARect, APressed);
end;

////////////////////////////////////////////////////////////////////////////////
// Draw Themes Drag&Drop hovered item
////////////////////////////////////////////////////////////////////////////////

procedure WinXP_DrawThemedHover(const ABitmap: TBitmap; const ARect: TRect);
begin
  WinXP_DrawThemedButton(ABitmap, ARect, False);
end;

procedure Win7_DrawThemedHover(const ABitmap: TBitmap; const AAlign: TScreenAlign;
  const ARect: TRect);
var
  PaintRect: TRect;
  State: Integer;
  Part: Integer;
  th: HTHEME;
begin
  if IsWindowsVista
  then begin
    Part := 1;
    State := 3;
    th := hButton;
  end
  else begin
    Part := 5;
    State := 9;
    if (AAlign = saLeft) or (AAlign = saRight)
    then th := hButtonVertical
    else th := hButton;
  end;
  PaintRect := ARect;
  DrawThemeBackground(th, ABitmap.Canvas.Handle, Part, State, PaintRect, @PaintRect);
end;

procedure ThemeDrawHover(const ABitmap: TBitmap; const AAlign: TScreenAlign;
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

{ used in draw bg for Windows 8/8.1/10 }
function BlendColor_Old(AColor1, AColor2: TGPColor; ABalance: Cardinal): TGPColor;

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

{$REGION ' BG for Windows XP '}
procedure WinXP_DrawThemedBackground(PParams: PDrawBackgroundParams);
const BF_FLAGS: array[TScreenAlign] of UINT = (BF_RIGHT, BF_BOTTOM, BF_LEFT, BF_TOP);
var
  drawer: IGPGraphics;
  bmp: TBitmap;
  r: TRect;
begin
  bmp := TBitmap.Create;
  bmp.Canvas.Brush.Color := clBtnFace;
  bmp.SetSize(PParams.ClipRect.Width, PParams.ClipRect.Height);

  r := PParams.ClipRect;
  DrawEdge(bmp.Canvas.Handle, r, BDR_RAISED, BF_FLAGS[PParams.Align]);

  drawer := PParams.Bitmap.ToGPGraphics;
  drawer.DrawImage(bmp.ToGPBitmap, PParams.ClipRect.Left, PParams.ClipRect.Top);
  bmp.Free;
end;
{$ENDREGION}

{$REGION ' BG for Windows Vista '}

procedure WinVista_DrawThemedBackground(PParams: PDrawBackgroundParams);
var
  gpDrawer: IGPGraphics;
  part: Integer;
begin
  if not StyleServices.Enabled
  then WinXP_DrawThemedBackground(PParams)
  else begin
    gpDrawer := PParams.Bitmap.ToGPGraphics;
    gpDrawer.SetClip( TGPRect.Create(PParams.ClipRect) );
    gpDrawer.Clear( TGPColor.Create($01000000) );

    part := LB_PARTID[PParams.Align, False];

    DrawThemeBackground(hBackground, PParams.Bitmap.Canvas.Handle, part,
      0, Rect(0,0,PParams.Bitmap.Width,PParams.Bitmap.Height), @PParams.ClipRect);
  end;
end;
{$ENDREGION}

{$REGION ' BG for Windows 7 '}
procedure Win7Pure_DrawThemedBackground(PParams: PDrawBackgroundParams);
var
  gpDrawer: IGPGraphics;
  part: Integer;
begin
  gpDrawer := PParams.Bitmap.ToGPGraphics;
  gpDrawer.SetClip( TGPRect.Create(PParams.ClipRect) );
  gpDrawer.Clear( TGPColor.Create($01000000) );

  part := LB_PARTID[PParams.Align, PParams.IsLight];

  DrawThemeBackground(hBackground, PParams.Bitmap.Canvas.Handle, part,
    0, Rect(0,0,PParams.Bitmap.Width,PParams.Bitmap.Height), @PParams.ClipRect);
end;

procedure Win7Aero_DrawThemedBackground(PParams: PDrawBackgroundParams);
var
  gpDrawer: IGPGraphics;
  part: Integer;
  th: HTHEME;
  color: TGPColor;
begin
  gpDrawer := PParams.Bitmap.ToGPGraphics;
  gpDrawer.SetClip( TGPRect.Create(PParams.ClipRect) );

  color.Initialize(PParams.BgColor);
  color.Alpha := Max(color.Alpha, 1);

  gpDrawer.Clear(color);

  part := LB_PARTID[PParams.Align, PParams.IsLight];

  if (PParams.Align = saLeft) or (PParams.Align = saRight)
  then th := hBackgroundVertical
  else th := hBackground;

  DrawThemeBackground(th, PParams.Bitmap.Canvas.Handle, part,
    0, Rect(0,0,PParams.Bitmap.Width,PParams.Bitmap.Height), @PParams.ClipRect);
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
  gpDrawer: IGPGraphics;
  color1, color2: TGPColor;
  cp: TColorizationParams;
  part: integer;
begin
  gpDrawer := PParams.Bitmap.ToGPGraphics;
  gpDrawer.SetClip( TGPRect.Create(PParams.ClipRect) );

  if (PParams.BgColor > 0)
  then begin
    color1.Initialize(PParams.BgColor);
  end
  else begin
    if Assigned(UDwmGetColorizationParametersProc)
    then begin
      UDwmGetColorizationParametersProc(cp);
      color1 := TGPColor.Create(cp.clrColor);
      color2 := TGPColor.Create($bad9d9d9);
      color1.Alpha := color2.Alpha;
      color1 := BlendColor_Old(color2, color1, cp.nIntensity);
    end;
  end;

  color1.Alpha := Max(color1.Alpha, 1);
  gpDrawer.Clear(color1);

  part := LB_PARTID[PParams.Align, False];
  DrawThemeBackground(hBackground, PParams.Bitmap.Canvas.Handle, part,
    0, Rect(0,0,PParams.Bitmap.Width,PParams.Bitmap.Height), @PParams.ClipRect);
end;

procedure Win8AG_DrawThemedBackground(PParams: PDrawBackgroundParams);
var
  gpDrawer: IGPGraphics;
  part: integer;
  color: TGPColor;
begin
  gpDrawer := PParams.Bitmap.ToGPGraphics;
  gpDrawer.SetClip( TGPRect.Create(PParams.ClipRect) );

  color.Initialize(PParams.BgColor);
  color.Alpha := Max(color.Alpha, 1);
  gpDrawer.Clear(color);

  part := LB_PARTID[PParams.Align, False];
  DrawThemeBackground(hBackground, PParams.Bitmap.Canvas.Handle, part,
    0, Rect(0,0,PParams.Bitmap.Width,PParams.Bitmap.Height), @PParams.ClipRect);
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
const WIN10BASECOLOR = $ffd9d9d9;                                               // from internet
var
  gpDrawer: IGPGraphics;
  color: TGPColor;
  cp: TColorizationParams;
begin
  gpDrawer := PParams.Bitmap.ToGPGraphics;
  gpDrawer.SetClip( TGPRect.Create(PParams.ClipRect) );

  if (PParams.BgColor > 0)
  then begin
    color.Initialize(PParams.BgColor);
  end
  else begin
    if Assigned(UDwmGetColorizationParametersProc)
    then begin
      UDwmGetColorizationParametersProc(cp);
      color := TGPColor.Create(cp.clrColor);
      color.A := $e0;
      color.R := Round(color.R * 0.6);
      color.G := Round(color.G * 0.6);
      color.B := Round(color.B * 0.6);
    end;
  end;

  color.Alpha := Max(color.Alpha, 1);
  gpDrawer.Clear(color);

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

procedure ThemeDrawGlow(const ABitmap: TBitmap; const ARect: TRect;
  const AColor: Cardinal);
var
  gpDrawer: IGPGraphics;
  gpBrush: IGPSolidBrush;
begin
  gpDrawer := ABitmap.ToGPGraphics;
  gpBrush := TGPSolidBrush.Create(AColor);
  gpDrawer.FillRectangle(gpBrush, TGPRect.Create(ARect));
end;

////////////////////////////////////////////////////////////////////////////////
// Open/Close HTHEME's
////////////////////////////////////////////////////////////////////////////////

procedure ThemeInitData(const AWnd: HWND; AIsLight: Boolean);
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
    Exit;
  end;

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
