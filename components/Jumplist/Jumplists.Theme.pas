{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{            Copyright (c) 2010-2018 Asaq               }
{*******************************************************}

unit Jumplists.Theme;

{$i linkbar.inc}

interface

uses
  GdiPlus, Winapi.Windows, Linkbar.Consts;

const
  { Linkbar Jumplist PartId }
  LB_JLP_BODY          = 0;     // Body background
  LB_JLP_FOOTER        = 1;     // Footer background
  LB_JLP_BUTTON_LEFT   = 2;     // Left part of split button
  LB_JLP_BUTTON        = 3;     // Full Button
//LB_JLP_BUTTON_CENTER = 4;     // Middle part of split button
  LB_JLP_BUTTON_RIGHT  = 4;     // Right part of split button
  LB_JLP_FOOTER_BUTTON = 5;     // Footer button (equal Full Button)
  LB_JLP_COUNT         = 6;

  LB_JLP_PIN_BUTTON = LB_JLP_BUTTON_RIGHT;     // Pin button

  { Linkbar Jumplist PartId }
//LB_JLS_NORMAL        = 0;
  LB_JLS_HOT           = 0;
  LB_JLS_PRESSED       = 1;
  LB_JLS_SELECTED      = 2;
  LB_JLS_NEW           = 3;
  LB_JLS_COUNT         = 4;

  procedure ThemeJlInit;
  procedure ThemeJlDeinit;
  procedure ThemeJlDrawBackground(const AHdc: HDC; const APart: Integer; const AFullRect, AClipRect: TRect);
  procedure ThemeJlDrawButton(const AHdc: HDC; const APart, AState: Integer; const ABtnRect: TRect);
  procedure ThemeJlDrawSeparator(const AHdc: HDC; const ARect: TRect);
  procedure ThemeJlUpdate;

var
  W10_JLIC_Text_Header: Cardinal;

implementation

uses Vcl.Themes, Winapi.UxTheme, Linkbar.OS, Linkbar.Theme, Math;

const
  { OS type }
  LB_OST_W7    = 0;
  LB_OST_W8    = 1;
  LB_OST_W81   = 2;
  LB_OST_COUNT = 3;

  { Jumplist parts (different for 7/8/8.1) }
  // Windows 7
  JLP7_BODY           = 12;
  JLP7_FOOTER         = 13;
  JLP7_BUTTON_LEFT    = 28;
  JLP7_BUTTON         = 29;
  JLP7_BUTTON_CENTER  = 30;
  JLP7_BUTTON_RIGHT   = 31;
  // Windows8
  JLP8_BODY           = 12;
  JLP8_FOOTER         = 13;
  JLP8_BUTTON_LEFT    = 32;
  JLP8_BUTTON         = 33;
  JLP8_BUTTON_CENTER  = 34;
  JLP8_BUTTON_RIGHT   = 35;
  // Windows 8.1
  JLP81_BODY          = 3;
  JLP81_FOOTER        = 4;
  JLP81_BUTTON_LEFT   = 10;
  JLP81_BUTTON        = 11;
  JLP81_BUTTON_CENTER = 11;
  JLP81_BUTTON_RIGHT  = 12;

  { Jumplist states }
  JLS_NORMAL   = 0;
  JLS_HOT      = 1;
  JLS_PRESSED  = 2;
  JLS_SELECTED = 3;
  JLS_NEW      = 4;

  { Jumplist HTHEME PartId }
  JL_HTHEME_PID: array[0..LB_OST_COUNT-1, 0..LB_JLP_COUNT-1] of Integer = (
    // Windows 7
    (JLP7_BODY, JLP7_FOOTER, JLP7_BUTTON_LEFT, JLP7_BUTTON, {JLP7_BUTTON_CENTER,} JLP7_BUTTON_RIGHT, JLP7_BUTTON),
    // Windows 8
    (JLP8_BODY, JLP8_FOOTER, JLP8_BUTTON_LEFT, JLP8_BUTTON, {JLP8_BUTTON_CENTER,} JLP8_BUTTON_RIGHT, JLP8_BUTTON),
    // Windows 8.1
    (JLP81_BODY, JLP81_FOOTER, JLP81_BUTTON_LEFT, JLP81_BUTTON, {JLP81_BUTTON_CENTER,} JLP81_BUTTON_RIGHT, JLP81_BUTTON) );

  { Jumplist HTHEME StateId for Buttons }
  JL_HTHEME_SID: array[0..LB_JLS_COUNT-1] of Integer =
    ({-1, }JLS_NORMAL, JLS_PRESSED, JLS_SELECTED, JLS_NEW);

  { Jumplist colors for Windows 10
  // Style 1
  JLIC_W10_NORMAL   : Cardinal = $1b1b1b;//$2b2b2b;
  JLIC_W10_HOT      : Cardinal = $404040;
  JLIC_W10_SELECTED : Cardinal = $535353;
  JLIC_W10_NEW      : Cardinal = $83e2fe;
  { Style 2
  JLIC_W10_BODY     : Cardinal = $000000;
  JLIC_W10_FOOTER   : Cardinal = $2b2b2b;
  JLIC_W10_BTN_HOT  : Cardinal = $191919;
  JLIC_W10_PIN_HOT  : Cardinal = $2b2b2b;
  JLIC_W10_FOT_HOT  : Cardinal = $404040;
  JLIC_W10_NEW      : Cardinal = $83e2fe; {}

var
  hJlTheme: HTHEME;
  osIndex: Integer;
  // Windows 10 colors
  W10_JLIC_Body: Cardinal;
  W10_JLIC_Footer: Cardinal;
  W10_JLIC_Item_Selected: Cardinal;
  W10_JLIC_Item_Hot: Cardinal;
  W10_JLIC_Separator: Cardinal;

// Accent, Dark
// hot      $19ffffff - white w/ alpha 10% - 22.5           ?ImmersiveDarkListLow
// selected $30ffffff - white w/ alpha 19% - 48.45          ?ImmersiveDarkListMedium
//
// Light
// hot      $99ffffff - white w/ alpha 60% - 153
// selected $d4ffffff - white w/ alpha 83% - 211.65


function BlendBW(Color1: Cardinal; Color2: Byte; Alpha: Single): Cardinal;
var R, G, B, C: Single;
begin
  B := (($000000FF and Color1)       ) / 255.0;
  G := (($0000FF00 and Color1) Shr 8 ) / 255.0;
  R := (($00FF0000 and Color1) Shr 16) / 255.0;
  C := Color2 / 255.0;

  R := Min(R * (1.0 - Alpha) + C * Alpha, 1.0) * 255.0;
  G := Min(G * (1.0 - Alpha) + C * Alpha, 1.0) * 255.0;
  B := Min(B * (1.0 - Alpha) + C * Alpha, 1.0) * 255.0;

  Result := Trunc(R) + (Trunc(G) shl 8) + (Trunc(B) shl 16);
end;

procedure ThemeJlUpdate;
begin
  if not IsWindows10
  then Exit;

  case GlobalLook of
    ELookLight:
      begin
        W10_JLIC_Body          := $ffD5D5D5;
        W10_JLIC_Footer        := $ffE4E4E4;
        W10_JLIC_Item_Selected := $d4ffffff;
        W10_JLIC_Item_Hot      := $99ffffff;
        W10_JLIC_Separator     := (Trunc(255 * 0.40) shl 24) or $000000;
      end;
    ELookDark:
      begin
        W10_JLIC_Body          := SwapRedBlue(GetImmersiveColorFromName('ImmersiveDarkChromeMedium'));
        W10_JLIC_Footer        := SwapRedBlue(GetImmersiveColorFromName('ImmersiveDarkChromeTaskbarBase'));
        W10_JLIC_Item_Selected := $30ffffff;
        W10_JLIC_Item_Hot      := $19ffffff;
        W10_JLIC_Separator     := (Trunc(255 * 0.40) shl 24) or $ffffff;
      end;
    ELookAccent:
      begin
        W10_JLIC_Body          := SwapRedBlue(GetImmersiveColorFromName('ImmersiveSystemAccentDark1'));
        W10_JLIC_Footer        := SwapRedBlue(GetImmersiveColorFromName('ImmersiveSystemAccentDark2'));
        W10_JLIC_Item_Selected := $30ffffff;
        W10_JLIC_Item_Hot      := $19ffffff;
        W10_JLIC_Separator     := (Trunc(255 * 0.40) shl 24) or $ffffff;
      end;
    ELookCustom:
      begin
      end;
  end;

  // Calc header text color
  // Dark, Accent: Body + (White w/ 60% alpha)
  // Light       : Body + (Black w/ 60% alpha)
  W10_JLIC_Text_Header := BlendBW(W10_JLIC_Body, IfThen(GlobalLook = ELookLight, $00, $ff), 0.6);
end;

////////////////////////////////////////////////////////////////////////////////
// Draw background
////////////////////////////////////////////////////////////////////////////////

{ Style 1 }
procedure Win10_DrawJlBackground(const AHdc: HDC; const APart: Integer; const AFullRect, AClipRect: TRect);
var color: COLORREF;
    gpDrawer: IGPGraphics;
begin
  if (APart = LB_JLP_BODY)
  then color := W10_JLIC_Body
  else color := W10_JLIC_Footer;

  gpDrawer := TGPGraphics.Create(AHdc);
  gpDrawer.FillRectangle(TGPSolidBrush.Create(color), TGPRect.Create(AClipRect));
end;

{$REGION ' Win10_DrawJlBackground #2 '}
{ Style 2
procedure Win10_DrawJlBackground(const AHdc: HDC; const APart: Integer;
  const AFullRect, AClipRect: TRect);
var color: COLORREF;
begin
  if (APart = LB_JLP_BODY)
  then color := JLIC_W10_BODY
  else color := JLIC_W10_FOOTER;
  brh0 := SelectObject(AHdc, GetStockObject(DC_BRUSH));
  SetDCBrushColor(AHdc, color);
  FillRect(AHdc, AClipRect, GetStockObject(DC_BRUSH));
  SelectObject(AHdc, brh0);
end; {}
{$ENDREGION}

procedure Win78_DrawJlBackground(const AHdc: HDC; const APart: Integer; const AFullRect, AClipRect: TRect);
var cr: TRect;
begin
  if (StyleServices.Enabled)
  then begin
    if (hJlTheme = 0)
    then hJlTheme := OpenThemeData(0, 'StartPanelComposited::StartPanelPriv');
  end;
  if (hJlTheme <> 0)
  then begin
    // For Windows 7 (Aero), 8, 8.1
    cr := AClipRect;
    DrawThemeBackground(hJlTheme, AHdc, JL_HTHEME_PID[osIndex, APart], 0, AFullRect, @cr)
  end
  else begin
    // For Windows 7 (98)
    FillRect(AHdc, AClipRect, GetSysColorBrush(COLOR_MENU));
  end;
end;

procedure ThemeJlDrawBackground(const AHdc: HDC; const APart: Integer; const AFullRect, AClipRect: TRect);
begin
  if (IsWindows10)
  then Win10_DrawJlBackground(AHdc, APart, AFullRect, AClipRect)
  else Win78_DrawJlBackground(AHdc, APart, AFullRect, AClipRect);
end;

////////////////////////////////////////////////////////////////////////////////
// Draw button
////////////////////////////////////////////////////////////////////////////////

procedure Win10_DrawJlButton(const AHdc: HDC; const APart, AState: Integer; const ABtnRect: TRect);
var
  color: Cardinal;
  gpDrawer: IGPGraphics;
begin
  case APart of
    LB_JLP_BUTTON, LB_JLP_BUTTON_LEFT, LB_JLP_FOOTER_BUTTON:
      begin
        case AState of
          LB_JLS_HOT, LB_JLS_SELECTED: color:= W10_JLIC_Item_Hot;
          else Exit;
        end;
      end;
    LB_JLP_PIN_BUTTON:
      begin
        case AState of
          LB_JLS_HOT:      color := W10_JLIC_Item_Hot;
          LB_JLS_SELECTED: color := W10_JLIC_Item_Selected;
          else Exit;
        end;
      end;
    else Exit;
  end;

  gpDrawer := TGPGraphics.Create(AHdc);
  //gpDrawer.SetClip( TGPRect.Create(ABtnRect) );
  gpDrawer.FillRectangle(TGPSolidBrush.Create(color), TGPRect.Create(ABtnRect));
end;

procedure Win78_DrawJlButton(const AHdc: HDC; const APart, AState: Integer; const ABtnRect: TRect);
var part, state: Integer;
    pen0: HPEN;
    brh0: HBRUSH;
begin
  if (StyleServices.Enabled)
  then begin
    //if (AState = LB_JLS_NORMAL)
    //then Exit; // normal state empty

    part := JL_HTHEME_PID[osIndex, APart];
    if (APart = LB_JLP_PIN_BUTTON)
    then state := JL_HTHEME_SID[LB_JLS_SELECTED]
    else state := JL_HTHEME_SID[AState];

    DrawThemeBackground(hJlTheme, AHdc, part, state, ABtnRect, nil);
  end
  else begin
    case APart of
      LB_JLP_BUTTON, LB_JLP_BUTTON_LEFT, LB_JLP_FOOTER_BUTTON:
      begin
        case AState of
          LB_JLS_HOT, LB_JLS_SELECTED:
            FillRect(AHdc, ABtnRect, GetSysColorBrush(COLOR_HIGHLIGHT));
          LB_JLS_NEW:
            FillRect(AHdc, ABtnRect, GetSysColorBrush(COLOR_INFOBK));
          else Exit;
        end;
      end;
      LB_JLP_PIN_BUTTON:
      begin
        if (AState in [LB_JLS_HOT, LB_JLS_SELECTED])
        then begin
          pen0 := SelectObject(AHdc, GetStockObject(DC_PEN));
          brh0 := SelectObject(AHdc, GetStockObject(DC_BRUSH));

          SetDCPenColor(AHdc, GetSysColor(COLOR_WINDOWFRAME));
          SetDCBrushColor(AHdc, GetSysColor(COLOR_HIGHLIGHT));
          Rectangle(AHdc, ABtnRect.Left, ABtnRect.Top, ABtnRect.Right, ABtnRect.Bottom);

          SelectObject(AHdc, brh0);
          SelectObject(AHdc, pen0);
        end;
      end
      else Exit;
    end;
  end;
end;

procedure ThemeJlDrawButton(const AHdc: HDC; const APart, AState: Integer; const ABtnRect: TRect);
begin
  if (IsWindows10)
  then Win10_DrawJlButton(AHdc, APart, AState, ABtnRect)
  else Win78_DrawJlButton(AHdc, APart, AState, ABtnRect);
end;

////////////////////////////////////////////////////////////////////////////////
// Draw separator
////////////////////////////////////////////////////////////////////////////////

procedure Win10_DrawJlSeparator(const AHdc: HDC; const ARect: TRect);
var gpDrawer: IGPGraphics;
begin
  gpDrawer := TGPGraphics.Create(AHdc);
  gpDrawer.FillRectangle(TGPSolidBrush.Create(W10_JLIC_Separator), TGPRect.Create(ARect));
end;

procedure Win78_DrawJlSeparator(const AHdc: HDC; const ARect: TRect);
begin
  // Draw in place
end;

procedure ThemeJlDrawSeparator(const AHdc: HDC; const ARect: TRect);
begin
  if (IsWindows10)
  then Win10_DrawJlSeparator(AHdc, ARect)
  else Win78_DrawJlSeparator(AHdc, ARect);
end;

////////////////////////////////////////////////////////////////////////////////
// Theme init/deinit
////////////////////////////////////////////////////////////////////////////////

function GetOsIndex(): Integer; inline; // [0 - Windows7, 1 - Windows8, 2 - Windows8.1]
begin
  if IsWindows7
  then Result := LB_OST_W7
  else if IsWindows8
       then Result := LB_OST_W8
       else Result := LB_OST_W81;
end;

procedure ThemeJlInit;
begin
  osIndex := GetOsIndex();
end;

procedure ThemeJlDeinit;
begin
  CloseThemeData(hJlTheme);
  hJlTheme := 0;
end;

end.
