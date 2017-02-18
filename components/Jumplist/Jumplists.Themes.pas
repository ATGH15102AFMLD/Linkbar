{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{            Copyright (c) 2010-2017 Asaq               }
{*******************************************************}

unit Jumplists.Themes;

{$i linkbar.inc}

interface

uses
  Windows, Vcl.Graphics, System.Classes;

const
  { Linkbar jumplist background part id }
  LBJL_BGPID_BODY   = 0;
  LBJL_BGPID_FOOTER = 1;

  { Linkbar jumplist item part id }
  LBJL_ITPID_BTN     = 0;
  LBJL_ITPID_BTN_LFT = 1;
  LBJL_ITPID_PIN     = 2;
  LBJL_ITPID_FOOT    = 3;

  { Linkbar jumplist item state id }
  LBJL_ITSID_NORMAL   = 0;
  LBJL_ITSID_HOT      = 1;
  LBJL_ITSID_SELECTED = 2;
  LBJL_ITSID_NEW      = 3;

  procedure ThemeJlInit;
  procedure ThemeJlDeinit;

  procedure ThemeJlDrawBackground(const AHdc: HDC; const APart: Integer;
    const AFullRect, AClipRect: TRect);

  procedure ThemeJlDrawButton(const AHdc: HDC; const APart, AState: Integer;
    const ABtnRect: TRect);


implementation

uses Vcl.Themes, Winapi.UxTheme, Winapi.ShlObj, Linkbar.OS;

const
  { Jumplists background PartId }
  JLP_JUMPLIST_BODY   = 12;                                                     { Body }
  JLP_JUMPLIST_FOOTER = 13;                                                     { Footer }

  { Jumplists splitbutton PartId for Windows 7 }
  JLBP_W7_JUMPLIST_SPLITBUTTON_LEFT   = 28;                                     { Left }
  JLBP_W7_JUMPLIST_BUTTON             = 29;                                     { Button }
  JLBP_W7_JUMPLIST_SPLITBUTTON_CENTER = 30;                                     { Center }
  JLBP_W7_JUMPLIST_SPLITBUTTON_RIGHT  = 31;                                     { Right }

  { Jumplists splitbutton PartId for Windows 8, 8.1 }
  JLBP_W8_JUMPLIST_SPLITBUTTON_LEFT   = 32;                                     { Left }
  JLBP_W8_JUMPLIST_BUTTON             = 33;                                     { Button }
  JLBP_W8_JUMPLIST_SPLITBUTTON_CENTER = 34;                                     { Center }
  JLBP_W8_JUMPLIST_SPLITBUTTON_RIGHT  = 35;                                     { Right }

  { Jumplists splitbutton StateId for Windows 7, 8, 8.1 }
  JLBS_HOT      = 0;                                                            { Hot }
  JLBS_UNK1     = 1;                                                            { Unknown_1 }
  JLBS_PRESSED  = 2;                                                            { Pressed }
  JLBS_SELECTED = 3;                                                            { Selected }
  JLBS_NEW      = 4;                                                            { New }
  JLBS_UNK2     = 5;                                                            { Unknown_2 }

  { Jumplists colors for Windows 10 }
  JLIC_W10_NORMAL   : Cardinal = $2b2b2b;
  JLIC_W10_HOT      : Cardinal = $404040;
  JLIC_W10_SELECTED : Cardinal = $535353;
  JLIC_W10_NEW      : Cardinal = $83e2fe;

var
  hJlTheme: HTHEME;

////////////////////////////////////////////////////////////////////////////////
// Draw background
////////////////////////////////////////////////////////////////////////////////

procedure Win10_DrawJlBackground(const AHdc: HDC; const APart: Integer;
  const AFullRect, AClipRect: TRect);
var color: COLORREF;
    brush: HBRUSH;
begin
  if (APart = LBJL_BGPID_BODY)
  then color := JLIC_W10_NORMAL
  else color := JLIC_W10_HOT;
  brush := CreateSolidBrush(color);
  FillRect(AHdc, AClipRect, brush);
  DeleteObject(brush);
end;

procedure Win78_DrawJlBackground(const AHdc: HDC; const APart: Integer;
  const AFullRect, AClipRect: TRect);
var cr: TRect;
    brush: HBRUSH;
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
    if (APart = LBJL_BGPID_BODY)
    then DrawThemeBackground(hJlTheme, AHdc, JLP_JUMPLIST_BODY,   0, AFullRect, @cr)
    else DrawThemeBackground(hJlTheme, AHdc, JLP_JUMPLIST_FOOTER, 0, AFullRect, @cr);
  end
  else begin
    // For Windows 7 (98)
    brush := GetSysColorBrush(COLOR_MENU);
    FillRect(AHdc, AClipRect, brush);
    // DeleteObject(brush); System color brushes are owned by the system
  end;
end;

procedure ThemeJlDrawBackground(const AHdc: HDC; const APart: Integer;
  const AFullRect, AClipRect: TRect);
begin
  if (IsWindows10)
  then Win10_DrawJlBackground(AHdc, APart, AFullRect, AClipRect)
  else Win78_DrawJlBackground(AHdc, APart, AFullRect, AClipRect);
end;

////////////////////////////////////////////////////////////////////////////////
// Draw button
////////////////////////////////////////////////////////////////////////////////

procedure Win10_DrawJlButton(const AHdc: HDC; const APart, AState: Integer;
  const ABtnRect: TRect);
var color: COLORREF;
    brush: HBRUSH;
begin
  case APart of
    LBJL_ITPID_BTN, LBJL_ITPID_BTN_LFT:
      begin
        case AState of
          LBJL_ITSID_NORMAL:   color := JLIC_W10_NORMAL;
          LBJL_ITSID_HOT:      color := JLIC_W10_HOT;
          LBJL_ITSID_SELECTED: color := JLIC_W10_HOT;
          LBJL_ITSID_NEW:      color := JLIC_W10_NEW;
          else Exit;
        end;
      end;
    LBJL_ITPID_PIN, LBJL_ITPID_FOOT:
      begin
        case AState of
          LBJL_ITSID_NORMAL:   color := JLIC_W10_NORMAL;
          LBJL_ITSID_HOT:      color := JLIC_W10_HOT;
          LBJL_ITSID_SELECTED: color := JLIC_W10_SELECTED;
          else Exit;
        end;
      end;
    else Exit;
  end;

  brush := CreateSolidBrush(color);
  FillRect(AHdc, ABtnRect, brush);
  DeleteObject(brush);
end;

procedure Win78_DrawJlButton(const AHdc: HDC; const APart, AState: Integer;
  const ABtnRect: TRect);
var part, state: Integer;
    pen: HPEN;
begin
  if (StyleServices.Enabled)
  then begin
    case APart of
      LBJL_ITPID_BTN, LBJL_ITPID_FOOT:
        if (IsWindows7)
        then part := JLBP_W7_JUMPLIST_BUTTON
        else part := JLBP_W8_JUMPLIST_BUTTON;
      LBJL_ITPID_BTN_LFT:
        if (IsWindows7)
        then part := JLBP_W7_JUMPLIST_SPLITBUTTON_LEFT
        else part := JLBP_W8_JUMPLIST_SPLITBUTTON_LEFT;
      LBJL_ITPID_PIN:
        if (IsWindows7)
        then part := JLBP_W7_JUMPLIST_SPLITBUTTON_RIGHT
        else part := JLBP_W8_JUMPLIST_SPLITBUTTON_RIGHT;
      else Exit;
    end;

    case AState of
      LBJL_ITSID_NORMAL:   Exit;  // normal state empty
      LBJL_ITSID_HOT:      state := JLBS_HOT;
      LBJL_ITSID_SELECTED: state := JLBS_SELECTED;
      LBJL_ITSID_NEW:      state := JLBS_NEW;
      else Exit;
    end;

    // Pin button always draw in selected state
    if (APart = LBJL_ITPID_PIN) then state := JLBS_SELECTED;

    DrawThemeBackground(hJlTheme, AHdc, part, state, ABtnRect, nil);
  end
  else begin
    case APart of
      LBJL_ITPID_BTN, LBJL_ITPID_BTN_LFT, LBJL_ITPID_FOOT:
      begin
        case AState of
          LBJL_ITSID_HOT, LBJL_ITSID_SELECTED:
            FillRect(AHdc, ABtnRect, GetSysColorBrush(COLOR_MENUHILIGHT));
          LBJL_ITSID_NEW:
            FillRect(AHdc, ABtnRect, GetSysColorBrush(COLOR_INFOBK));
          else Exit;
        end;
      end;
      LBJL_ITPID_PIN:
      begin
        if (AState in [LBJL_ITSID_HOT, LBJL_ITSID_SELECTED])
        then begin
          FillRect(AHdc, ABtnRect, GetSysColorBrush(COLOR_MENUHILIGHT));
          pen := CreatePen(PS_SOLID, 1, GetSysColor(COLOR_WINDOWFRAME));
          SelectObject(AHdc, pen);
          Rectangle(AHdc, ABtnRect.Left, ABtnRect.Top, ABtnRect.Right, ABtnRect.Bottom);
        end;
      end
      else Exit;
    end;
  end;
end;

procedure ThemeJlDrawButton(const AHdc: HDC; const APart, AState: Integer;
    const ABtnRect: TRect);
begin
  if (IsWindows10)
  then Win10_DrawJlButton(AHdc, APart, AState, ABtnRect)
  else Win78_DrawJlButton(AHdc, APart, AState, ABtnRect);
end;

////////////////////////////////////////////////////////////////////////////////
// Theme init/deinit
////////////////////////////////////////////////////////////////////////////////

procedure ThemeJlInit;
begin
end;

procedure ThemeJlDeinit;
begin
  CloseThemeData(hJlTheme);
  hJlTheme := 0;
end;

end.
