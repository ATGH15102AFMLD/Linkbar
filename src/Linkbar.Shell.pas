{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{            Copyright (c) 2010-2018 Asaq               }
{*******************************************************}

unit Linkbar.Shell;

{$i linkbar.inc}

interface

uses
  Windows, SysUtils, Classes, Forms,
  ShellAPI, ActiveX, ComObj, ShlObj, KnownFolders;

  function SHExtractIcon(APath: PChar; AIndex: Integer; AIconSize: Integer): HICON;

  function GetUIObjectOfPidl(AWnd: HWND; const APidl: PItemIDList;
    const ARiid: TIID; out ppv): HRESULT;

  function GetUIObjectOfFile(AWnd: HWND; const AFileName: String;
    const ARiid: TIID; out ppv): HRESULT;

  function LBCreateCommandParam(const AKey, AValue: string): string;

  procedure LBShellExecute(const AWnd: HWND; const AOperation, AFileName: String;
    const AParameters: String = ''; const ADirectory: String = '';
    const AShowCmd: Integer = SW_SHOWNORMAL);

  function LBCreateProcess(const AApplicationName: String;
    const ACommandLine: string = ''): Boolean;

  function GetLinkbarRoamingFolderPath: string;

  function NewShortcut(const APath: string): HRESULT;

  procedure OpenDirectoryByName(const AName: string);

  procedure SHRenameOp(AWnd: HWND; AFromName, AToName: string);
  procedure SHDeleteOp(AWnd: HWND; APath: string; AAllowUndo: Boolean);
  function SHRaname(AWnd: HWND; APidl: PItemIDList; const ARenameText: string): HRESULT;

  function SendShellEmail(AWnd: HWND; ARecipientEmail, ASubject, ABody: string): boolean;

  function RegisterBitBucketNotify(AWnd: HWND; AMessage: Cardinal): Cardinal;
  procedure UnregisterBitBucketNotify(ANotify: Cardinal);

implementation

uses StrUtils, Graphics, Linkbar.L10n;

type
  TSHExtractIconsW = function(pszFileName: LPCWSTR; nIconIndex: Integer; cxIcon,
    cyIcon: Integer; var phIcon: HICON; var pIconId: Cardinal; nIcons: Cardinal;
    flags: Cardinal): UINT; stdcall;

var USHExtractIconsWProc: TSHExtractIconsW = nil;

function SHExtractIcon(APath: PChar; AIndex: Integer; AIconSize: Integer): HICON;
var icon, dummy: HICON;
    h: HMODULE;
    id: Cardinal;
    r: UINT;
begin
  icon := 0;
  if not Assigned(USHExtractIconsWProc)
  then begin
    h := GetModuleHandle(shell32);
    if (h <> 0)
    then @USHExtractIconsWProc := GetProcAddress(h, LPCSTR('SHExtractIconsW'));
  end;
  if Assigned(USHExtractIconsWProc)
  then begin
    id := 0;
    r := USHExtractIconsWProc(APath, AIndex, AIconSize, AIconSize, icon, id, 1, LR_DEFAULTCOLOR);
    if (r = 0)
    then DestroyIcon(icon);
  end
  else begin
    r := ExtractIconEx(APath, AIndex, icon, dummy, 1);
    if (r = 0)
    then Exit(0);
    DestroyIcon(dummy);
  end;
  Result := icon;
end;

procedure OpenDirectoryByName(const AName: string);
begin
  LBShellExecute(0, 'open', AName);
end;

procedure SHRenameOp(AWnd: HWND; AFromName, AToName: string);
var
  lpFileOp: TSHFileOpStruct;
begin
  FillChar(lpFileOp, SizeOf(lpFileOp), 0);
  lpFileOp.Wnd := AWnd;
  lpFileOp.wFunc := FO_RENAME;
  lpFileOp.pFrom := PChar(AFromName + #0);
  lpFileOp.pTo := PChar(AToName + #0);
  lpFileOp.fFlags := FOF_ALLOWUNDO;
  SHFileOperation(lpFileOp);
end;

procedure SHDeleteOp(AWnd: HWND; APath: string; AAllowUndo: Boolean);
var
  lpFileOp: TSHFileOpStruct;
begin
  FillChar(lpFileOp, SizeOf(lpFileOp), 0);
  lpFileOp.Wnd := AWnd;
  lpFileOp.wFunc := FO_DELETE;
  lpFileOp.pFrom := PChar(APath + #0);
  lpFileOp.fFlags := 0;
  if AAllowUndo
  then lpFileOp.fFlags := lpFileOp.fFlags or FOF_ALLOWUNDO;
  SHFileOperation(lpFileOp);
end;

function SHRaname(AWnd: HWND; APidl: PItemIDList; const ARenameText: string): HRESULT;
var pFolder: IShellFolder;
    child: PItemIDList;
    newpidl: PItemIDList;
begin
  // NOTE: SHBindToParent does not allocate a new PIDL;
  // it simply receives a pointer through this parameter.
  // Therefore, you are not responsible for freeing this resource.
  Result := SHBindToParent(APidl, IShellFolder, Pointer(pFolder), child);
  if Succeeded(Result)
  then begin
    Result := pFolder.SetNameOf(AWnd, child, PChar(ARenameText),
      SHGDN_INFOLDER or SHGDN_FOREDITING, newpidl);
    if Succeeded(Result)
    then CoTaskMemFree(newpidl);
  end;
end;

function GetUIObjectOfFolder(AWnd: HWND; const APath: String;
  const ARiid: TIID; out ppv): HRESULT;
var
  pDesktop: IShellFolder;
  pidl: PItemIDList;
begin
  Result := SHGetDesktopFolder(pDesktop);
  if Succeeded(Result)
  then try
    Result := pDesktop.ParseDisplayName(AWnd, nil, PChar(APath), PULONG(nil)^, pidl, PULONG(nil)^);
    if Succeeded(Result)
    then try
      Result := pDesktop.BindToObject(pidl, nil, ARiid, ppv);
    finally
      CoTaskMemFree(pidl);
    end;
  finally
    pDesktop := nil;
  end;
end;

function GetUIObjectOfPidl(AWnd: HWND; const APidl: PItemIDList;
  const ARiid: TIID; out ppv): HRESULT;
var
  psf: IShellFolder;
  pidlChild: PItemIDList;
begin
  Result := SHBindToParent(APidl, IID_IShellFolder, Pointer(psf), pidlChild);
  if Succeeded(Result)
  then try
    Result := psf.GetUIObjectOf(AWnd, 1, pidlChild, ARiid, nil, ppv);
  finally
    psf := nil;
  end;
end;

function GetUIObjectOfFile(AWnd: HWND; const AFileName: String;
  const ARiid: TIID; out ppv): HRESULT;
var
  pidl: PItemIDList;
  psf: IShellFolder;
  pidlChild: PItemIDList;
begin
  Result := SHParseDisplayName(PChar(AFileName), nil, pidl, 0, PDWORD(nil)^);
  if Succeeded(Result)
  then try
    Result := SHBindToParent(pidl, IID_IShellFolder, Pointer(psf), pidlChild);
    if Succeeded(Result)
    then try
      Result := psf.GetUIObjectOf(AWnd, 1, pidlChild, ARiid, nil, ppv);
    finally
      psf := nil;
    end;
  finally
    CoTaskMemFree(pidl);
  end;
end;

function LBCreateCommandParam(const AKey, AValue: string): string;
var quote: string;
begin
  if Pos(' ', AValue) > 0
  then quote := '"'
  else quote := '';
  Result := ' /' + AKey + quote + AValue + quote;
end;

procedure LBShellExecute(const AWnd: HWND; const AOperation, AFileName: String;
  const AParameters: String = ''; const ADirectory: String = '';
  const AShowCmd: Integer = SW_SHOWNORMAL);
var
  ExecInfo: TShellExecuteInfo;
  NeedUninitialize: Boolean;
begin
  Assert(AFileName <> '');

  NeedUninitialize := SUCCEEDED(CoInitializeEx(nil, COINIT_APARTMENTTHREADED or COINIT_DISABLE_OLE1DDE));
  try
    FillChar(ExecInfo, SizeOf(ExecInfo), 0);
    ExecInfo.cbSize := SizeOf(ExecInfo);

    ExecInfo.Wnd := AWnd;
    ExecInfo.lpVerb := Pointer(AOperation);
    ExecInfo.lpFile := PChar(AFileName);
    ExecInfo.lpParameters := Pointer(AParameters);
    ExecInfo.lpDirectory := Pointer(ADirectory);
    ExecInfo.nShow := AShowCmd;
    ExecInfo.fMask := SEE_MASK_NOASYNC;
    {$IFDEF UNICODE}
    // http://www.transl-gunsmoker.ru/2015/01/what-does-SEEMASKUNICODE-flag-in-ShellExecuteEx-actually-do.html
    ExecInfo.fMask := ExecInfo.fMask or SEE_MASK_UNICODE;
    {$ENDIF}
    Win32Check(ShellExecuteEx(@ExecInfo));
  finally
    if NeedUninitialize then
      CoUninitialize;
  end;
end;

function GetLinkbarRoamingFolderPath: string;
var
  pszPath: PChar;
begin
  // NOTE: SHGetKnownFolderPath Vista, Server 2008
  if Succeeded( SHGetKnownFolderPath(FOLDERID_RoamingAppData, KF_FLAG_DEFAULT,
    0, pszPath) )
  then begin
    Result := IncludeTrailingPathDelimiter(pszPath) + 'Linkbar' + PathDelim;
    CoTaskMemFree(pszPath);
  end else
  begin
    result := ExtractFilePath(Application.ExeName);
    MessageBox(Application.Handle, 'Can''t use Roaming folder',
      PChar(Application.Title), MB_ICONEXCLAMATION or MB_OK);
  end;
end;

function NewShortcut(const APath: string): HRESULT;
var
  lnkname: string;
  filename: array[0..MAX_PATH] of Char;
  hFile: THandle;
  SI: TStartupInfo;
  PI: TProcessInformation;
  app: array[0..MAX_PATH] of Char;
  cmd: string;
begin
  Result := S_FALSE;
  lnkname := L10nMui(GetModuleHandle(LB_FN_NEWSHORTCUT), LB_RS_NSC_FILENAME);
  if PathMakeUniqueName(filename, MAX_PATH, 'scut.lnk', PChar(lnkname + '.lnk'), PChar(APath))
  then begin
    hFile := CreateFile(filename, GENERIC_WRITE, 0, nil, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
    if (hFile <> INVALID_HANDLE_VALUE)
    then
    begin
      CloseHandle(hFile);
      // Run the shortcut wizard
      // %windir%\system32\rundll32.exe - another path
      ExpandEnvironmentStrings('%SystemRoot%\System32\rundll32.exe', app, MAX_PATH);
      cmd := Format('rundll32.exe appwiz.cpl,NewLinkHere %s', [filename]);
      FillChar(SI, SizeOf(SI), 0);
      SI.cb := SizeOf(SI);
      FillChar(PI, SizeOf(PI), 0);
      if CreateProcess( app, PChar(cmd), nil, nil, False, NORMAL_PRIORITY_CLASS, nil,
        PChar(APath), SI, PI )
      then begin
        CloseHandle(PI.hThread);
        CloseHandle(PI.hProcess);
        Result := S_OK;
      end
      else
        DeleteFile(filename);
    end
    else if (GetLastError = ERROR_ACCESS_DENIED)
    then begin
      // TODO:
      // there was a problem, most likely UAC didn't let us create a folder
    end;
  end;
end;

function LBCreateProcess(const AApplicationName: String;
  const ACommandLine: string = ''): Boolean;
var SI: TStartupInfo;
    PI: TProcessInformation;
    cmd: string;
begin
  cmd := AApplicationName;
  if (ACommandLine <> '')
  then cmd := cmd + ' ' + ACommandLine;
  FillChar(SI, SizeOf(SI), 0);
  SI.cb := SizeOf(SI);
  FillChar(PI, SizeOf(PI), 0);
  Result := CreateProcess( Pointer(AApplicationName), Pointer(cmd), nil, nil,
    False, NORMAL_PRIORITY_CLASS, nil, nil, SI, PI );
  if Result
  then begin
    CloseHandle(PI.hThread);
    CloseHandle(PI.hProcess);
  end;
end;

function SendShellEmail(AWnd: HWND; ARecipientEmail, ASubject, ABody: string): boolean;
// Send an email to this recipient with a subject and a body
var
  iResult: integer;
  s : string;
begin
  if (Trim(ARecipientEmail) = '')
  then ARecipientEmail := 'mail';
  s := 'mailto:' + ARecipientEmail;
  s := s + '?subject=' + ASubject;
  if (Trim(ABody) <> '')
  then s := s + '&body=' + ABody;
  iResult := ShellExecute(0, 'open', PChar(s), nil, nil, SW_SHOWNORMAL);
  Result := (iResult > 0);
end;

function RegisterBitBucketNotify(AWnd: HWND; AMessage: Cardinal): Cardinal;
var pidl: PItemIDList;
    cne: TSHChangeNotifyEntry;
begin
  pidl := nil;
  if Succeeded(SHGetSpecialFolderLocation(0,CSIDL_BITBUCKET, pidl))
  then begin
    cne.pidl := pidl;
    cne.fRecursive := True;
    Result := SHChangeNotifyRegister(AWnd, SHCNRF_InterruptLevel or SHCNRF_ShellLevel,
      SHCNE_UPDATEIMAGE, AMessage, 1, cne);
    CoTaskMemFree(pidl);
  end
  else Result := 0;
end;

procedure UnregisterBitBucketNotify(ANotify: Cardinal);
begin
  SHChangeNotifyDeregister(ANotify);
end;

end.



