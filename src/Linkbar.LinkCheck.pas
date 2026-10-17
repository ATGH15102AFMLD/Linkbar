{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{   Link check: is the target of a shortcut reachable   }
{*******************************************************}

{ Checks run in background threads, so the bar never waits for a slow network.
  The check ONLY READS: it never changes, repairs or deletes any shortcut/file.
  Result is posted to the bar window as the message LM_LINKCHECK:
    WParam = item hash, LParam = Ord(TLinkState)
  lsOk          - target exists / the web server answered
  lsMissing     - the place (drive, share, web server) works, but the target is not there
  lsUnreachable - the place itself (network drive, server, web) does not answer in time }

unit Linkbar.LinkCheck;

{$i linkbar.inc}

interface

uses
  Winapi.Windows;

{ Queue a check of the shortcut file (.lnk, .url, .website). Safe to call often:
  a request for an item that is already waiting is ignored. }
procedure LinkCheckRequest(AWnd: HWND; AHash: Cardinal; const AFileName: string);

implementation

uses
  System.SysUtils, System.Classes, System.SyncObjs, System.Generics.Collections,
  System.IniFiles, System.StrUtils, System.Threading,
  System.Net.HttpClient, System.Net.URLClient,
  Winapi.ActiveX, Winapi.ShlObj, Winapi.Messages,
  Linkbar.Consts;

const
  WORKER_COUNT  = 4;
  PATH_TIMEOUT  = 5000;   // ms: longer = the place is unreachable
  HTTP_TIMEOUT  = 5000;   // ms

type
  TRequest = record
    Wnd: HWND;
    Hash: Cardinal;
    FileName: string;
  end;

  TWorker = class(TThread)
  protected
    procedure Execute; override;
  end;

var
  Lock: TCriticalSection;
  Requests: TQueue<TRequest>;
  Pending: TDictionary<Cardinal, Boolean>;
  Wake: TSemaphore;
  WorkersStarted: Boolean = False;

////////////////////////////////////////////////////////////////////////////////
// Checks
////////////////////////////////////////////////////////////////////////////////

function ExpandEnv(const AStr: string): string;
var
  buf: array[0..MAX_PATH * 2] of Char;
  n: DWORD;
begin
  n := ExpandEnvironmentStrings(PChar(AStr), buf, Length(buf));
  if (n > 0) and (n <= DWORD(Length(buf)))
  then Result := buf
  else Result := AStr;
end;

{ Does the path exist? Returns False when the answer did not come in time
  (typical for a dead network server). }
function PathExistsTimeout(const APath: string; out AExists: Boolean): Boolean;
var
  found: Boolean;
  task: ITask;
  path: string;
begin
  found := False;
  path := APath;
  task := TTask.Run(
    procedure
    begin
      found := (GetFileAttributes(PChar(path)) <> INVALID_FILE_ATTRIBUTES);
    end);
  Result := task.Wait(PATH_TIMEOUT);
  AExists := Result and found;
end;

function CheckPath(const APath: string): TLinkState;
var
  exists, answered: Boolean;
  root: string;
begin
  answered := PathExistsTimeout(APath, exists);
  if (not answered)
  then Exit(lsUnreachable);
  if (exists)
  then Exit(lsOk);

  // Target is not there. Is the place (drive, \\server\share) alive?
  root := ExtractFileDrive(APath);
  if (root = '')
  then Exit(lsMissing);

  answered := PathExistsTimeout(IncludeTrailingPathDelimiter(root), exists);
  if (not answered) or (not exists)
  then Exit(lsUnreachable);

  Result := lsMissing;
end;

function CheckHttp(const AUrl: string): TLinkState;
var
  client: THTTPClient;
  resp: IHTTPResponse;
begin
  client := THTTPClient.Create;
  try
    client.ConnectionTimeout := HTTP_TIMEOUT;
    client.ResponseTimeout := HTTP_TIMEOUT;
    try
      resp := client.Head(AUrl);
      // Any answer means the server is alive. Only "not found" is a broken link.
      if (resp.StatusCode = 404) or (resp.StatusCode = 410)
      then Result := lsMissing
      else Result := lsOk;
    except
      Result := lsUnreachable;
    end;
  finally
    client.Free;
  end;
end;

{ Target path of a .lnk file, '' when it has none (e.g. Store apps). Read only. }
function ResolveLnk(const AFileName: string): string;
var
  link: IShellLink;
  pf: IPersistFile;
  buf: array[0..MAX_PATH] of Char;
  fd: TWin32FindData;
begin
  Result := '';
  if Failed(CoCreateInstance(CLSID_ShellLink, nil, CLSCTX_INPROC_SERVER, IShellLink, link))
  then Exit;
  pf := link as IPersistFile;
  if Failed(pf.Load(PChar(AFileName), STGM_READ))
  then Exit;
  buf[0] := #0;
  FillChar(fd, SizeOf(fd), 0);
  if Succeeded(link.GetPath(@buf[0], MAX_PATH, fd, SLGP_RAWPATH))
  then Result := ExpandEnv(string(buf));
end;

function ReadUrlFile(const AFileName: string): string;
var
  ini: TMemIniFile;
begin
  ini := TMemIniFile.Create(AFileName);
  try
    Result := Trim(ini.ReadString('InternetShortcut', 'URL', ''));
  finally
    ini.Free;
  end;
end;

function CheckFile(const AFileName: string): TLinkState;
var
  ext, target: string;
begin
  ext := LowerCase(ExtractFileExt(AFileName));

  if (ext = '.url') or (ext = '.website')
  then begin
    target := ReadUrlFile(AFileName);
    if StartsText('http://', target) or StartsText('https://', target)
    then Exit(CheckHttp(target));
    Exit(lsUnknown);
  end;

  if (ext = '.lnk')
  then begin
    target := Trim(ResolveLnk(AFileName));
    target := AnsiDequotedStr(target, '"');
    if (target = '')
    then Exit(lsUnknown);
    Exit(CheckPath(target));
  end;

  Result := lsUnknown;
end;

////////////////////////////////////////////////////////////////////////////////
// Worker threads
////////////////////////////////////////////////////////////////////////////////

procedure TWorker.Execute;
var
  req: TRequest;
  got: Boolean;
  state: TLinkState;
begin
  CoInitializeEx(nil, COINIT_APARTMENTTHREADED);
  try
    while not Terminated
    do begin
      Wake.WaitFor(INFINITE);
      if Terminated
      then Break;

      got := False;
      Lock.Enter;
      try
        if (Requests.Count > 0)
        then begin
          req := Requests.Dequeue;
          got := True;
        end;
      finally
        Lock.Leave;
      end;
      if (not got)
      then Continue;

      try
        state := CheckFile(req.FileName);
      except
        state := lsUnknown;
      end;

      Lock.Enter;
      try
        Pending.Remove(req.Hash);
      finally
        Lock.Leave;
      end;

      PostMessage(req.Wnd, LM_LINKCHECK, WPARAM(req.Hash), LPARAM(Ord(state)));
    end;
  finally
    CoUninitialize;
  end;
end;

procedure LinkCheckRequest(AWnd: HWND; AHash: Cardinal; const AFileName: string);
var
  req: TRequest;
begin
  req.Wnd := AWnd;
  req.Hash := AHash;
  req.FileName := AFileName;

  Lock.Enter;
  try
    if Pending.ContainsKey(AHash)
    then Exit;
    Pending.Add(AHash, True);
    Requests.Enqueue(req);

    if (not WorkersStarted)
    then begin
      WorkersStarted := True;
      for var i := 1 to WORKER_COUNT
      do begin
        var w := TWorker.Create(True);
        w.FreeOnTerminate := True;
        w.Start;
      end;
    end;
  finally
    Lock.Leave;
  end;

  Wake.Release;
end;

initialization
  Lock := TCriticalSection.Create;
  Requests := TQueue<TRequest>.Create;
  Pending := TDictionary<Cardinal, Boolean>.Create;
  Wake := TSemaphore.Create(nil, 0, MaxInt, '');

// No finalization on purpose: background threads may still wait for the network
// and the process ends right after the bar is closed.

end.
