{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{            Copyright (c) 2010-2018 Asaq               }
{*******************************************************}

unit ExplorerMenu;

{$i linkbar.inc}

interface

uses
  System.SysUtils, System.Classes,
  Winapi.Windows, Winapi.Messages, Winapi.ShlObj, Winapi.ActiveX,
  Linkbar.Shell;

const
  LM_CM_ITEMS  = WM_USER + 11;
  LM_CM_RENAME = WM_USER + 12;
  LM_CM_INVOKE = WM_USER + 13;

  procedure ExplorerMenuPopup(const AWnd: HWND; const APidl: PItemIDList;
    const AScrPt: TPoint; const AShift: Boolean; const ASubMenu: HMENU);
  procedure OpenByDefaultVerb(const AWnd: HWND; const APidl: PItemIDList);
  function BitmapFromIcon(AIcon: HICON; ASize: integer): HBITMAP;

implementation

const
  SCRATCH_QCM_FIRST = 20;
  SCRATCH_QCM_LAST = FCIDM_SHVIEWLAST;

var
  g_cm2: IContextMenu2;
  g_cm3: IContextMenu3;

function MenuCallback(Wnd: HWND; Msg: UINT; WParam: WPARAM; LParam: LPARAM): LRESULT; stdcall;
begin
  if Assigned(g_cm3)
  then begin
    if Succeeded(g_cm3.HandleMenuMsg2(Msg, WParam, LParam, Result))
    then Exit;
  end
  else if Assigned(g_cm2)
  then begin
    if Succeeded(g_cm2.HandleMenuMsg(Msg, WParam, LParam))
    then begin
      Result := 0;
      Exit;
    end;
  end;
  Result := DefWindowProc(Wnd, Msg, wParam, lParam);
end;

function CreateMenuCallbackWnd: HWND;
const
  IcmCallbackWnd = 'ICMCALLBACKWND';
var WndClass: TWndClass;
begin
  FillChar(WndClass, SizeOf(WndClass), 0);
  WndClass.lpszClassName := PChar(IcmCallbackWnd);
  WndClass.lpfnWndProc := @MenuCallback;
  WndClass.hInstance := HInstance;
  Winapi.Windows.RegisterClass(WndClass);
  Result := CreateWindow(IcmCallbackWnd, '', 0, 0, 0, 0, 0, HWND_MESSAGE, 0, 0, nil);
end;

// Converts an icon to a bitmap
function BitmapFromIcon(AIcon: HICON; ASize: integer): HBITMAP;
var bi: TBitmapInfo;
    rc: TRect;
    dc: HDC;
    bits: Pointer;
    bmp: HBITMAP;
    bmp0: HGDIOBJ;
begin
	FillChar(bi, SizeOf(bi), 0);
	bi.bmiHeader.biSize := SizeOf(TBitmapInfoHeader);
	bi.bmiHeader.biWidth := ASize;
  bi.bmiHeader.biHeight := ASize;
	bi.bmiHeader.biPlanes := 1;
	bi.bmiHeader.biBitCount := 32;
	rc := TRect.Create(0, 0, ASize, ASize);
	dc := CreateCompatibleDC(0);
  bmp := CreateDIBSection(dc, bi, DIB_RGB_COLORS, bits, 0, 0);
	bmp0 := SelectObject(dc, bmp);
	FillRect(dc, rc, HBRUSH(GetStockObject(BLACK_BRUSH)));
	DrawIconEx(dc, 0, 0, AIcon, ASize, ASize, 0, 0, DI_NORMAL);
	SelectObject(dc, bmp0);
	DeleteDC(dc);
	Result := bmp;
end;

procedure ExplorerMenuPopup(const AWnd: HWND; const APidl: PItemIDList;
  const AScrPt: TPoint; const AShift: Boolean; const ASubMenu: HMENU);

  procedure RemoveMultipleSeparators(const AMenu: HMENU);
  var i, count: Integer;
      separator: Boolean;
      mi: TMenuItemInfo;
  begin
    FillChar(mi, SizeOf(mi), 0);
    mi.cbSize := SizeOf(mi);
    mi.fMask := MIIM_FTYPE;
    separator := True;
    count := GetMenuItemCount(AMenu);
    i := 0;
    while (i < count) do
    begin
      mi.fType := 0;
      if (GetMenuItemInfo(AMenu, i, True, mi))
         and (mi.fType = MFT_SEPARATOR)
         and separator
      then DeleteMenu(AMenu, i, MF_BYPOSITION)
      else Inc(i);
      separator := mi.fType = MFT_SEPARATOR
    end;
    if (count > 0) and separator
    then DeleteMenu(AMenu, count-1, MF_BYPOSITION);
  end;

var
  NeedUninitialize: Boolean;
  Menu: HMenu;
  ICMenu: IContextMenu;
  uFlags: UINT;
  i, n, insertBefore: Integer;
  id: Cardinal;
  verbcmd: array[0..MAXBYTE] of AnsiChar;
	Command: LongBool;
  iCmd: Integer;
  Info: TCMInvokeCommandInfoEx;
  CallbackWindow: HWND;
  miinfo: TMenuItemInfo;
  hIco: HICON;
  hbmp: HBITMAP;
  iconsize: Integer;
begin
  NeedUninitialize := Succeeded(CoInitializeEx(nil, COINIT_MULTITHREADED));
  try
    if Succeeded(GetUIObjectOfPidl(AWnd, APidl, IID_IContextMenu, ICMenu))
    then try
      CallbackWindow := 0; hbmp := 0;
      Menu := CreatePopupMenu;
      if (Menu <> 0)
      then try
        uFlags := CMF_NORMAL or CMF_CANRENAME;
        if AShift
        then uFlags := uFlags or CMF_EXTENDEDVERBS;

        if Succeeded(ICMenu.QueryContextMenu(Menu, 0, SCRATCH_QCM_FIRST, SCRATCH_QCM_LAST, uFlags))
        then begin
          if (ASubMenu <> 0)
          then begin
            // Get position for insert Linkbar menu - before "Properties"
            insertBefore := -1;
            n := GetMenuItemCount(Menu);
            for i := 0 to n-1 do
            begin
              verbcmd[0] := #0;
              id := GetMenuItemID(Menu, i);
              if (id >= SCRATCH_QCM_FIRST)
                 and (id <= SCRATCH_QCM_LAST)
                 and Succeeded(ICMenu.GetCommandString(id-SCRATCH_QCM_FIRST, GCS_VERBA, nil,
                      verbcmd, Length(verbcmd)))
                 and SameStr(String(verbcmd), 'properties')
              then begin
                insertBefore := i;
                Break;
              end;
            end;
            // separator
            FillChar(miinfo, SizeOf(miinfo), 0);
            miinfo.cbSize := SizeOf(miinfo);
            miinfo.fMask := MIIM_TYPE;
            miinfo.fType := MFT_SEPARATOR;
            InsertMenuItem(Menu, insertBefore, True, miinfo);

            // Linkbar submenu item
            FillChar(miinfo, SizeOf(miinfo), 0);
            miinfo.cbSize := SizeOf(miinfo);
            miinfo.fMask := MIIM_SUBMENU or MIIM_STRING;
            miinfo.hSubMenu := ASubMenu;
            miinfo.dwTypeData := PChar('Linkbar');
            InsertMenuItem(Menu, insertBefore, True, miinfo);

            // Icon for Linkbar submenu item
            iconsize := GetSystemMetrics(SM_CXSMICON);
            hIco := LoadImage(HInstance, MakeIntResource('MAINICON'), IMAGE_ICON,
              iconsize, iconsize, LR_DEFAULTCOLOR);
            if (hIco <> 0)
            then begin
              hbmp := BitmapFromIcon(hIco, iconsize);
              DestroyIcon(hIco);
              FillChar(miinfo, SizeOf(miinfo), 0);
              miinfo.cbSize := SizeOf(miinfo);
              miinfo.fMask := MIIM_BITMAP;
              miinfo.hbmpItem := hbmp;
              SetMenuItemInfo(Menu, insertBefore, True, miinfo);
            end;

            // Sometimes menus have multiple separators e.g. for html shortcut
            // In Explorer.exe there is no such
            RemoveMultipleSeparators(Menu);
          end;

          ICMenu.QueryInterface(IContextMenu2, g_cm2);
          ICMenu.QueryInterface(IContextMenu3, g_cm3);
          CallbackWindow := CreateMenuCallbackWnd;

					try
						Command := TrackPopupMenuEx(Menu, TPM_RETURNCMD or TPM_RIGHTBUTTON,
              AScrPt.X, AScrPt.Y, CallbackWindow, nil);
					finally
						g_cm2 := nil;
						g_cm3 := nil;
						if (hbmp <> 0)
            then DeleteObject(hbmp);
					end;

          if (Command)
					then begin
						iCmd := LongInt(Command);
						if (iCmd < SCRATCH_QCM_FIRST)
            then PostMessage(AWnd, LM_CM_ITEMS, 0, iCmd)
						else begin
							iCmd := iCmd - SCRATCH_QCM_FIRST;
							verbcmd[0] := #0;
							if Succeeded(ICMenu.GetCommandString(iCmd, GCS_VERBA, nil,verbcmd, SizeOf(verbcmd)))
								 and SameStr(String(verbcmd), 'rename')
							then PostMessage(AWnd, LM_CM_RENAME, 0, 0)
							else begin
								FillChar(Info, SizeOf(Info), 0);
								Info.cbSize := SizeOf(Info);
								Info.fMask := CMIC_MASK_UNICODE
									or CMIC_MASK_PTINVOKE
									or CMIC_MASK_FLAG_LOG_USAGE
									or CMIC_MASK_NOASYNC;
								if (GetKeyState(VK_CONTROL) < 0)
								then Info.fMask := Info.fMask or CMIC_MASK_CONTROL_DOWN;
								if (GetKeyState(VK_SHIFT) < 0)
								then Info.fMask := Info.fMask or CMIC_MASK_SHIFT_DOWN;
								Info.hwnd := AWnd;
								Info.nShow := SW_SHOWNORMAL;
								Info.lpVerb := MakeIntResourceA(iCmd);
								Info.lpVerbW := MakeIntResourceW(iCmd);
								Info.ptInvoke := AScrPt;
                PostMessage(AWnd, LM_CM_INVOKE, 0, iCmd);
								EnableWindow(AWnd, False);
								ICMenu.InvokeCommand(PCMInvokeCommandInfo(@Info)^);
								EnableWindow(AWnd, True);
							end;
						end;
					end;
        end;
      finally
        DestroyMenu(Menu);
        if (CallbackWindow <> 0)
        then DestroyWindow(CallbackWindow);
      end;
    finally
      ICMenu := nil;
    end;
  finally
    if NeedUninitialize
    then CoUninitialize;
  end;
end;

procedure OpenByDefaultVerb(const AWnd: HWND; const APidl: PItemIDList);
var
  pMenu: IContextMenu;
  Menu: HMENU;
  id: UINT;
  Info: TCMInvokeCommandInfo;
begin
  if Succeeded(GetUIObjectOfPidl(AWnd, APidl, IID_IContextMenu, pMenu))
  then try
    Menu := CreatePopupMenu;
    if (Menu <> 0)
    then try
      if Succeeded(pMenu.QueryContextMenu(Menu, 0, FCIDM_SHVIEWFIRST,
        FCIDM_SHVIEWLAST, CMF_DEFAULTONLY))
      then begin
        id := GetMenuDefaultItem(Menu, 0, 0);
        if (id <> UINT(-1))
        then begin
          FillChar(Info, SizeOf(Info), 0);
          Info.cbSize := SizeOf(Info);
          Info.fMask := CMIC_MASK_FLAG_LOG_USAGE;
          Info.hwnd := AWnd;
          Info.nShow := SW_NORMAL;
          Info.lpVerb := MakeIntResourceA(id - FCIDM_SHVIEWFIRST);
          pMenu.InvokeCommand(Info);
        end
        else begin
          if (GetLastError <> 0)
          then RaiseLastOSError;
        end;
      end;
    finally
      DestroyMenu(Menu);
    end;
  finally
    pMenu := nil;
  end;
end;

end.

