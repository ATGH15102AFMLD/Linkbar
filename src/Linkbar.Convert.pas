{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{   Conversion of old linkbars to local (portable)      }
{*******************************************************}

{ An old bar ("Shared bars", "User bars") keeps its settings in a .lbr file and its
  shortcuts in a separate working directory. The conversion
    1. copies the working directory to  <app folder>\linkbars\<name>\
    2. writes the settings there as bar.lbr (local = 1, without the old directory)
    3. moves the old .lbr (and the old working directory, when it is in the
       application or Roaming folder) to the Recycle Bin
  The old data are removed only after the copy was successful. }

unit Linkbar.Convert;

{$i linkbar.inc}

interface

uses
  System.Classes;

{ Convert old (not local) bars from the list of settings files. Returns the number of
  converted bars. The old files are removed from AFiles. }
function ConvertOldBars(const AFiles: TStringList): Integer;

{ Number of old (not local) bars in the list }
function CountOldBars(const AFiles: TStringList): Integer;

implementation

uses
  Winapi.Windows, Winapi.ShellAPI,
  System.SysUtils, System.IniFiles, System.IOUtils, System.StrUtils, System.Types,
  Linkbar.Consts, Linkbar.Shell;

function IsLocalBar(const AFileName: string): Boolean;
var ini: TMemIniFile;
begin
  ini := TMemIniFile.Create(AFileName);
  try
    Result := ini.ReadBool(INI_SECTION_MAIN, INI_LOCAL_BAR, False);
  finally
    ini.Free;
  end;
end;

function CountOldBars(const AFiles: TStringList): Integer;
begin
  Result := 0;
  for var f in AFiles
  do if (not IsLocalBar(f))
     then Inc(Result);
end;

{ Recursive copy of a folder. False when something fails. }
function CopyTree(const ASrc, ADst: string): Boolean;
begin
  Result := False;
  try
    if (not ForceDirectories(ADst))
    then Exit;
    for var f in TDirectory.GetFiles(ASrc)
    do TFile.Copy(f, IncludeTrailingPathDelimiter(ADst) + ExtractFileName(f), True);
    for var d in TDirectory.GetDirectories(ASrc)
    do if (not CopyTree(d, IncludeTrailingPathDelimiter(ADst) + ExtractFileName(d)))
       then Exit;
    Result := True;
  except
    Result := False;
  end;
end;

{ Move a file or a folder to the Recycle Bin (it can be restored) }
procedure ToRecycleBin(const APath: string);
var
  op: TSHFileOpStruct;
  fromPath: string;
begin
  fromPath := ExcludeTrailingPathDelimiter(APath) + #0#0;
  FillChar(op, SizeOf(op), 0);
  op.wFunc := FO_DELETE;
  op.pFrom := PChar(fromPath);
  op.fFlags := FOF_ALLOWUNDO or FOF_NOCONFIRMATION or FOF_NOERRORUI or FOF_SILENT;
  SHFileOperation(op);
end;

function IsInside(const AFolder, ARoot: string): Boolean;
begin
  Result := (ARoot <> '')
            and StartsText(IncludeTrailingPathDelimiter(ARoot), IncludeTrailingPathDelimiter(AFolder));
end;

{ Name of a folder that does not exist yet in <app>\linkbars\ }
function UniqueBarDir(const AName: string): string;
var base: string; n: Integer;
begin
  base := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)) + DN_LOCAL_BARS);
  Result := base + AName;
  n := 1;
  while DirectoryExists(Result)
  do begin
    Inc(n);
    Result := base + AName + '_' + IntToStr(n);
  end;
end;

function SafeName(const AName: string): string;
const BAD = '\/:*?"<>|';
begin
  Result := Trim(AName);
  for var i := 1 to Length(Result)
  do if (Pos(Result[i], BAD) > 0) or (Result[i] < ' ')
     then Result[i] := '_';
  Result := Result.TrimRight(['.', ' ']);
  if (Result = '')
  then Result := 'Linkbar';
end;

function ConvertOne(const ALbr: string): Boolean;
var
  ini: TIniFile;
  src, dst, name, roaming, appDir: string;
begin
  Result := False;

  ini := TIniFile.Create(ALbr);
  try
    src := ExcludeTrailingPathDelimiter(ini.ReadString(INI_SECTION_MAIN, INI_DIR_LINKS, ''));
  finally
    ini.Free;
  end;

  if (src = '') or (not DirectoryExists(src))
  then Exit;

  name := ExtractFileName(src);
  if (name = '')
  then name := TPath.GetFileNameWithoutExtension(ALbr);
  dst := UniqueBarDir(SafeName(name));

  // 1. shortcuts
  if (not CopyTree(src, dst))
  then begin
    // do not leave a half-made copy
    if DirectoryExists(dst)
    then ToRecycleBin(dst);
    Exit;
  end;

  // 2. settings -> bar.lbr (local)
  try
    TFile.Copy(ALbr, IncludeTrailingPathDelimiter(dst) + FN_LOCAL_BAR, True);
    ini := TIniFile.Create(IncludeTrailingPathDelimiter(dst) + FN_LOCAL_BAR);
    try
      ini.WriteBool(INI_SECTION_MAIN, INI_LOCAL_BAR, True);
      ini.DeleteKey(INI_SECTION_MAIN, INI_DIR_LINKS);
    finally
      ini.Free;
    end;
  except
    ToRecycleBin(dst);
    Exit;
  end;

  if (not FileExists(IncludeTrailingPathDelimiter(dst) + FN_LOCAL_BAR))
  then Exit;

  // 3. the copy is ready: remove the old bar (Recycle Bin)
  roaming := GetLinkbarRoamingFolderPath;
  appDir := ExtractFilePath(ParamStr(0));
  ToRecycleBin(ALbr);
  // old directory only when it belongs to Linkbar (not e.g. a shared network folder)
  if IsInside(src, roaming) or IsInside(src, appDir)
  then ToRecycleBin(src);

  Result := True;
end;

function ConvertOldBars(const AFiles: TStringList): Integer;
begin
  Result := 0;
  for var i := AFiles.Count - 1 downto 0
  do begin
    if (not IsLocalBar(AFiles[i]))
       and ConvertOne(AFiles[i])
    then begin
      AFiles.Delete(i);
      Inc(Result);
    end;
  end;
end;

end.
