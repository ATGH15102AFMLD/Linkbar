{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{            Copyright (c) 2010-2018 Asaq               }
{*******************************************************}

unit Linkbar.Taskbar;

{$i linkbar.inc}

interface

uses Windows, SysUtils;

type
  TDynRectArray = array of TRect;

  procedure GetUserWorkArea(var ARects: TDynRectArray);

implementation

uses Winapi.MultiMon, Winapi.ShellApi, Linkbar.OS, System.Generics.Collections;

type
  TRectList = TList<TRect>;

function EnumMonitorsProc(hm: HMONITOR; dc: HDC; r: PRect; Data: Pointer): Boolean; stdcall;
var list: TRectList;
    MonInfo: TMonitorInfo;
begin
  list := TRectList(Data);
  MonInfo.cbSize := SizeOf(MonInfo);
  GetMonitorInfo(hm, @MonInfo);
  list.Add(MonInfo.rcMonitor);
  Result := True;
end;

var _TaskbarCount: Integer;

function EnumWindowTaskbar(wnd: HWND; lParam: LPARAM): BOOL; stdcall;
var name: array[0..MAX_PATH] of Char;
    rc: TRect;
begin
  FillChar(name, SizeOf(name), 0);
  if ( GetClassName(wnd, name, Length(name)) > 0 )
     and (SameText(name, 'Shell_TrayWnd') or SameText(name, 'Shell_SecondaryTrayWnd'))
  then begin
    GetWindowRect(wnd, rc);
    TRectList(lParam).Add(rc);
    Dec(_TaskbarCount);
  end;
  Result := (_TaskbarCount > 0);
end;

procedure GetUserWorkArea(var ARects: TDynRectArray);
var list: TRectList;
    r: TRect;
    i: Integer;
    a: TAppBarData;
begin
  { Get monitors boundsrect }
  list := TRectList.Create;
  Winapi.MultiMon.EnumDisplayMonitors(0, nil, @EnumMonitorsProc, LPARAM(list));
  SetLength(ARects, list.Count);
  for i := 0 to list.Count-1
  do ARects[i] := list[i];
  list.Free;

  { 1. If taskbars autohiden then use monitor boundsrect }
  FillChar(a, SizeOf(a), 0);
  a.cbSize:= SizeOf(a);
  if ( (SHAppBarMessage(ABM_GETSTATE, a) and ABS_AUTOHIDE) <> 0 )
  then Exit; {}

  { 2. Windows 7 have one taskbar, get it rect & edge & monitor, recalc workarea }
  if IsWindows7
  then begin
    FillChar(a, SizeOf(a), 0);
    a.cbSize := SizeOf(a);
    a.hWnd := HWND_DESKTOP;
    if (SHAppBarMessage(ABM_GETTASKBARPOS, a) <> 0)
    then begin
      for i := 0 to High(ARects) do
        if PtInRect(ARects[i], TPoint.Create(a.rc.CenterPoint))
        then begin
          case a.uEdge of
            ABE_LEFT:   ARects[i].Left   := a.rc.Right;
            ABE_TOP:    ARects[i].Top    := a.rc.Bottom;
            ABE_RIGHT:  ARects[i].Right  := a.rc.Left;
            ABE_BOTTOM: ARects[i].Bottom := a.rc.Top;
          end;
          Break;
        end;
    end;
    Exit;
  end; {}

  { 3. Windows 8 and above. Find all taskbars }
  _TaskbarCount := Length(ARects);
  list := TRectList.Create;
  EnumWindows(@EnumWindowTaskbar, LPARAM(list));
  for r in list do
    for i := 0 to High(ARects) do
    begin
      if PtInRect(ARects[i], r.CenterPoint)
      then begin
        if (r.Left <> ARects[i].Left)                                           // tb on right
        then ARects[i].Right := r.Left
        else if (r.Right <> ARects[i].Right)                                    // tb on left
             then ARects[i].Left := r.Right
             else if (r.Top <> ARects[i].Top)                                   // tb on bottom
                  then ARects[i].Bottom := r.Top
                  else ARects[i].Top := r.Bottom;                               // tb on top
        Break;
      end;
    end;
  list.Free;
  {}
end;

end.
