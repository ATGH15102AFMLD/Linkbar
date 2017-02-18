{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{            Copyright (c) 2010-2017 Asaq               }
{*******************************************************}

unit Linkbar.OS;

{$i linkbar.inc}

interface

uses Windows, SysUtils;

  procedure InitOS;
  function VersionToString: string;

var
  IsWindowsXP, IsWindowsVista, IsWindows7, IsWindows8, IsWindows8dot1,
  IsWindows8And8Dot1, IsWindows10: Boolean;
  IsWindowsXPOrAbove, IsWindowsVistaOrAbove, IsWindows7OrAbove,
  IsWindows8OrAbove, IsWindows8Dot1OrAbove, IsWindows10OrAbove: Boolean;
  IsMinimumSupportedOS: Boolean;
  IsJumplistAvailable: Boolean;

implementation

{ TMyVersion }

function VersionToString: string;
var
  iBufferSize: DWORD;
  iDummy: DWORD;
  pBuffer: Pointer;
  FName: string;
  pFileInfo: PVSFixedFileInfo;
  Major, Minor, Release: Word;
begin
  FName := GetModuleName(HInstance);
  iBufferSize := GetFileVersionInfoSize(PChar(FName), iDummy);
  if (iBufferSize > 0) then
  begin
    GetMem(pBuffer, iBufferSize);
    try
      // get fixed file info (language independent)
      GetFileVersionInfo(PChar(FName), 0, iBufferSize, pBuffer);
      VerQueryValue(pBuffer, '\', Pointer(pFileInfo), iDummy);
      // read version blocks
      Major   := HiWord(pFileInfo^.dwFileVersionMS);
      Minor   := LoWord(pFileInfo^.dwFileVersionMS);
      Release := HiWord(pFileInfo^.dwFileVersionLS);
      Result := Format('%d.%d.%d', [Major, Minor, Release]);
      if (pFileInfo^.dwFileFlags and VS_FF_SPECIALBUILD) <> 0
      then Result := Result + '/Experimental';
      if ((pFileInfo^.dwFileFlags and VS_FF_DEBUG) <> 0)
      then Result := Result + '/Debug';
      if (pFileInfo^.dwFileFlags and VS_FF_PRERELEASE) <> 0
      then Result := Result + '/Prerelease';
      if (pFileInfo^.dwFileFlags and VS_FF_PRIVATEBUILD) <> 0
      then Result := Result + ' Beta 1';
    finally
      FreeMem(pBuffer);
    end;
  end;
end;

procedure InitOS;
begin
  IsWindowsXPOrAbove    := CheckWin32Version( 5, 1);
  IsWindowsVistaOrAbove := CheckWin32Version( 6, 0);
  IsWindows7OrAbove     := CheckWin32Version( 6, 1);
  IsWindows8OrAbove     := CheckWin32Version( 6, 2);
  IsWindows8Dot1OrAbove := CheckWin32Version( 6, 3);
  IsWindows10OrAbove    := CheckWin32Version(10, 0);

  IsMinimumSupportedOS  := IsWindowsVistaOrAbove;

  IsWindowsXP     := IsWindowsXPOrAbove     and not IsWindowsVistaOrAbove;
  IsWindowsVista  := IsWindowsVistaOrAbove  and not IsWindows7OrAbove;
  IsWindows7      := IsWindows7OrAbove      and not IsWindows8OrAbove;
  IsWindows8      := IsWindows8OrAbove      and not IsWindows8Dot1OrAbove;
  IsWindows8Dot1  := IsWindows8Dot1OrAbove  and not IsWindows10OrAbove;
  IsWindows8And8Dot1 := IsWindows8OrAbove    and not IsWindows10OrAbove;
  IsWindows10     := IsWindows10OrAbove;

  IsJumplistAvailable := (IsWindows7 or IsWindows8 or IsWindows8Dot1 or IsWindows10);
end;

end.
