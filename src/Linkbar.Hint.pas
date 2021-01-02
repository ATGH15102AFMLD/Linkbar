{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{            Copyright (c) 2010-2021 Asaq               }
{*******************************************************}

unit Linkbar.Hint;

{$i linkbar.inc}

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.CommCtrl, System.Classes, System.Types, Vcl.Controls;

type
  TTooltip32 = class
  private
    TipHwnd: HWND;
    TipToolInfo: TToolInfo;
  public
    constructor Create(AWndParent: HWND; AMargin: Integer = -1);
    destructor Destroy; override;
    procedure Activate(const APos: TPoint; const AText: string;
      const AHorzAlign: TAlignment; const AVertAlign: TVerticalAlignment);
    procedure Cancel;
    procedure Hide;
    procedure ThemeChanged;
  end;

implementation

uses Winapi.MultiMon, Winapi.UxTheme, Linkbar.DarkTheme;

constructor TTooltip32.Create(AWndParent: HWND; AMargin: Integer);
var margins: TRect;
begin
  // NOTE:
  // 1) A tooltip control always has the WS_POPUP and WS_EX_TOOLWINDOW window
  // styles, regardless of whether you specify them when creating the control.
  // 2) TTF_TRANSPARENT not work, WS_EX_TRANSPARENT fix it

  TipHwnd := CreateWindowEx(WS_EX_TOPMOST or WS_EX_TRANSPARENT,
    TOOLTIPS_CLASS, nil, TTS_NOPREFIX or TTS_ALWAYSTIP, 0, 0, 0, 0,
    AWndParent, 0, HInstance, nil);

  if (TipHwnd <> 0)
  then begin
    SetWindowTheme(TipHwnd, 'Explorer', nil);
    AllowDarkModeForWindow(TipHwnd, true);
    ThemeChanged;

    SendMessage(TipHwnd, TTM_SETMAXTIPWIDTH, 0, 400);

    if (AMargin > 0)
    then begin
      margins := Rect(AMargin, AMargin, AMargin, AMargin);
      SendMessage(TipHwnd, TTM_SETMARGIN, 0, LPARAM(@margins));
      // TODO: check the need for the following function in Windows Vista-8
      //if (not StyleServices.Enabled)
      //then SendMessage(TipHwnd, WM_SETFONT, WPARAM(Screen.IconFont.Handle), 0);
    end;

    FillChar(TipToolInfo, SizeOf(TipToolInfo), 0);
    TipToolInfo.cbSize := SizeOf(TToolInfo);
    TipToolInfo.uFlags := TTF_TRACK or TTF_ABSOLUTE or TTF_TRANSPARENT;
    TipToolInfo.uId := 1;
    SendMessage(TipHwnd, TTM_ADDTOOL, 0, LPARAM(@TipToolInfo));
  end;
end;

destructor TTooltip32.Destroy;
begin
  if (TipHwnd <> 0)
  then DestroyWindow(TipHwnd);
  inherited;
end;

procedure TTooltip32.ThemeChanged;
begin
  if (TipHwnd <> 0)
  then SendMessage(TipHwnd, WM_THEMECHANGED, 0, 0);
end;

procedure TTooltip32.Cancel;
begin
  if (TipHwnd <> 0)
  then SendMessage(TipHwnd, TTM_TRACKACTIVATE, WPARAM(False), LPARAM(@TipToolInfo));
end;

procedure TTooltip32.Hide;
begin
  if (TipHwnd <> 0)
  then SendMessage(TipHwnd, TTM_POP, 0, 0);
end;

function GetMonRectFromPoint(const APt: TPoint): TRect;
var monitor: HMONITOR;
    moninfo: TMonitorInfo;
begin
  monitor := Winapi.MultiMon.MonitorFromPoint(APt, MONITOR_DEFAULTTONEAREST);
  FillChar(moninfo, SizeOf(moninfo), 0);
  moninfo.cbSize := SizeOf(moninfo);
  GetMonitorInfo(monitor, @moninfo);
  Result := moninfo.rcMonitor;
end;

function FitTipRect(const r1, r2: TRect): TPoint;
var tr: TRect;
begin
  if PtInRect(r2, r1.TopLeft) and PtInRect(r2, r1.BottomRight)
  then Exit(r1.TopLeft);

  tr := r1;

  if tr.Right > r2.Right then tr.Left := r2.Right - r1.Width;
  if tr.Bottom > r2.Bottom then tr.Top := r2.Bottom - r1.Height;

  if tr.Left < r2.Left then tr.Left := r2.Left;
  if tr.Top < r2.Top then tr.Top := r2.Top;

  Result := tr.TopLeft;
end;

procedure TTooltip32.Activate(const APos: TPoint; const AText: string;
  const AHorzAlign: TAlignment; const AVertAlign: TVerticalAlignment);
var wr: TRect;
    pt, npt: TPoint;
begin
  if (TipHwnd = 0) or (AText = '')
  then Exit;

  pt := APos;

  TipToolInfo.lpszText := Pointer(AText);
  SendMessage(TipHwnd, TTM_UPDATETIPTEXT, 0, LPARAM(@TipToolInfo));

  SendMessage(TipHwnd, TTM_TRACKPOSITION, 0, PointToLParam(pt));
  SendMessage(TipHwnd, TTM_TRACKACTIVATE, WPARAM(True), LPARAM(@TipToolInfo));

  GetWindowRect(TipHwnd, wr);
  case AHorzAlign of
    taRightJustify: pt.X := pt.X - wr.Width;
    taCenter: pt.X := pt.X - wr.Width div 2;
  end;
  case AVertAlign of
    taAlignTop: pt.Y := pt.Y - wr.Height;
    taVerticalCenter: pt.Y := pt.Y - wr.Height div 2;
  end;

  wr.Location := pt;

  npt := FitTipRect(wr, GetMonRectFromPoint(APos));
  SendMessage(TipHwnd, TTM_TRACKPOSITION, 0, PointToLParam(npt));

  SetWindowPos(TipHwnd, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE or SWP_NOACTIVATE);
end;

end.

