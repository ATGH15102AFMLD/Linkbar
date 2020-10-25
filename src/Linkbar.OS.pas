{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{            Copyright (c) 2010-2018 Asaq               }
{*******************************************************}


unit Linkbar.OS;

{$i linkbar.inc}

interface

uses Windows, SysUtils;

var
  IsWindowsXP,
  IsWindowsVista,
  IsWindows7,
  IsWindows8,
  IsWindows8dot1,
  IsWindows8And8Dot1,
  IsWindows10: Boolean;

  IsWindowsXPOrAbove,
  IsWindowsVistaOrAbove,
  IsWindows7OrAbove,
  IsWindows8OrAbove,
  IsWindows8Dot1OrAbove,
  IsWindows10OrAbove: Boolean;

  IsMinimumSupportedOS: Boolean;

  IsJumplistAvailable: Boolean;

  VersionToString: string;

  function SystemInfo: string;

implementation

uses System.SysConst;

function SystemInfo: string;
var
  langLocaleId: TLocaleID;
  langName, langLocaleName: String;
  index: Integer;
begin
  langLocaleId := TLanguages.UserDefaultLocale;
  langName := sUnknown;
  langLocaleName := sUnknown;

  index := Languages.IndexOf(langLocaleId);
  if (index <> - 1)
  then begin
    langName := Languages.Name[index];
    if (langName = '')
    then langName := sUnknown;

    langLocaleName := Languages.LocaleName[index];
    if (langLocaleName = '')
    then langLocaleName := sUnknown;
  end;

  Result := TOSVersion.ToString
    + ' '  + langLocaleName
    + ' '  + IntToStr(langLocaleId)
    + ' (' + IntToHex(langLocaleId, 3) + ')'
    + ' '  + langName;
end;

function GetVersionString: string;
var resInfo: HRSRC;
    resDate: HGLOBAL;
    sz: DWORD;
    res, resCopy: Pointer;
    fileInfo: PVSFixedFileInfo;
    dummy: DWORD;
    major, minor, release: Word;
    data: PChar;
    len: UINT;
begin
  Result := 'Unknown';

  resInfo := FindResource(HInstance, MakeIntResource(VS_VERSION_INFO), RT_VERSION);
  if (resInfo = 0)
  then Exit;

  sz := SizeofResource(HInstance, resInfo);
  if (sz = 0)
  then Exit;

  resCopy := GetMemory(sz);
  try
    resDate := LoadResource(HInstance, resInfo);
    if (resDate = 0)
    then Exit;
    res := LockResource(resDate);
    if (res <> nil)
    then CopyMemory(resCopy, res, sz);

    //FreeResource(resDate); not needed

    if VerQueryValue(resCopy, '\', Pointer(fileInfo), dummy) and (dummy > 0)
    then begin
      major   := HiWord(fileInfo^.dwFileVersionMS);
      minor   := LoWord(fileInfo^.dwFileVersionMS);
      release := HiWord(fileInfo^.dwFileVersionLS);
      Result  := Format('%d.%d.%d', [major, minor, release]);
      if ((fileInfo^.dwFileFlags and VS_FF_DEBUG) <> 0)
      then Result := Result + '/Debug';
      if (fileInfo^.dwFileFlags and VS_FF_SPECIALBUILD) <> 0
      then Result := Result + '/Dev';
      if (fileInfo^.dwFileFlags and VS_FF_PRERELEASE) <> 0
      then Result := Result + '/Prerelease';
      if (fileInfo^.dwFileFlags and VS_FF_PRIVATEBUILD) <> 0
      then begin
        if VerQueryValue(resCopy, '\\StringFileInfo\\040904E4\\PrivateBuild', Pointer(data), len)
        then Result := Result + '/' + string(data);
      end;
    end;

  finally
    FreeMemory(resCopy);
  end;
end;

procedure InitOS;
begin
  VersionToString := GetVersionString;

  IsWindowsXPOrAbove    := TOSVersion.Check( 5, 1);
  IsWindowsVistaOrAbove := TOSVersion.Check( 6, 0);
  IsWindows7OrAbove     := TOSVersion.Check( 6, 1);
  IsWindows8OrAbove     := TOSVersion.Check( 6, 2);
  IsWindows8Dot1OrAbove := TOSVersion.Check( 6, 3);
  IsWindows10OrAbove    := TOSVersion.Check(10, 0);

  IsMinimumSupportedOS  := IsWindowsVistaOrAbove;

  IsWindowsXP        := IsWindowsXPOrAbove     and not IsWindowsVistaOrAbove;
  IsWindowsVista     := IsWindowsVistaOrAbove  and not IsWindows7OrAbove;
  IsWindows7         := IsWindows7OrAbove      and not IsWindows8OrAbove;
  IsWindows8         := IsWindows8OrAbove      and not IsWindows8Dot1OrAbove;
  IsWindows8Dot1     := IsWindows8Dot1OrAbove  and not IsWindows10OrAbove;
  IsWindows8And8Dot1 := IsWindows8OrAbove      and not IsWindows10OrAbove;
  IsWindows10        := IsWindows10OrAbove;

  IsJumplistAvailable := (IsWindows7 or IsWindows8 or IsWindows8Dot1 or IsWindows10);
end;

initialization
  InitOS;

end.
