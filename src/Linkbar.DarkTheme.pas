unit Linkbar.DarkTheme;

interface

uses
  Winapi.Windows,
  Winapi.UxTheme,
  System.Math;

procedure InitDarkMode();
procedure AllowDarkModeForApp(Allow: BOOL);
function AllowDarkModeForWindow(Wnd: HWND; Allow: BOOL): BOOL;

implementation

uses System.SysUtils, Linkbar.OS;

const
  PRREFFERED_APP_MODE_DEFAULT     = 0;
  PRREFFERED_APP_MODE_ALLOW_DARK  = 1;
  PRREFFERED_APP_MODE_FORCE_DARK  = 2;
  PRREFFERED_APP_MODE_FORCE_LIGHT = 3;

type
  // 1809 17763
  TShouldAppsUseDarkMode = function(): BOOL; stdcall; // ordinal 132
  TAllowDarkModeForWindow = function(Wnd: HWND; Allow: BOOL): BOOL; stdcall; // ordinal 133
  TAllowDarkModeForApp = function(Allow: BOOL): BOOL; stdcall; // ordinal 135, in 180
  TRefreshImmersiveColorPolicyState = procedure(); stdcall; // ordinal 104
  // 1903 18362
  //TShouldSystemUseDarkMode = function(): BOOL; stdcall; // ordinal 138
  TSetPreferredAppMode = function(AppMode: UINT): UINT; stdcall; // ordinal 135, in 1903


var
  GlobalDarkModeSupported: Boolean = False;
  GlobalDarkModeEnabled: Boolean = False;

  UAllowDarkModeForApp:    TAllowDarkModeForApp = nil;
  UAllowDarkModeForWindow: TAllowDarkModeForWindow = nil;
  UShouldAppsUseDarkMode:  TShouldAppsUseDarkMode = nil;
  URefreshImmersiveColorPolicyState: TRefreshImmersiveColorPolicyState = nil;

  // 1903 18362
  //UShouldSystemUseDarkMode: TShouldSystemUseDarkMode = nil;
  USetPreferredAppMode:     TSetPreferredAppMode = nil;

function AllowDarkModeForWindow(Wnd: HWND; Allow: BOOL): BOOL;
begin
  Result := False;
  if (GlobalDarkModeSupported)
  then Result := UAllowDarkModeForWindow(Wnd, Allow);
end;

procedure AllowDarkModeForApp(Allow: BOOL);
begin
  if Assigned(UAllowDarkModeForApp)
  then UAllowDarkModeForApp(allow)

  else if Assigned(USetPreferredAppMode)
  then USetPreferredAppMode(IfThen(Allow, PRREFFERED_APP_MODE_ALLOW_DARK, PRREFFERED_APP_MODE_DEFAULT));
end;

procedure InitDarkMode();
var lib: HMODULE;
begin
  if not IsWindows10
  then Exit;

  lib := LoadLibrary('uxtheme.dll');
  if lib <> 0
  then begin
    if (TOSVersion.Build < 18362)
    then @UAllowDarkModeForApp := GetProcAddress(lib, MAKEINTRESOURCEA(135))
    else @USetPreferredAppMode := GetProcAddress(lib, MAKEINTRESOURCEA(135));

    //@UShouldAppsUseDarkMode := GetProcAddress(lib, MAKEINTRESOURCEA(132));
    @UAllowDarkModeForWindow := GetProcAddress(lib, MAKEINTRESOURCEA(133));
    //@URefreshImmersiveColorPolicyState := GetProcAddress(lib, MAKEINTRESOURCEA(104));

    //GlobalDarkModeEnabled := UShouldAppsUseDarkMode;

    if (Assigned(UAllowDarkModeForApp) or Assigned(USetPreferredAppMode))
       and Assigned(UAllowDarkModeForWindow)
    then begin
      GlobalDarkModeSupported := True;
    end;
  end;
end;


end.
