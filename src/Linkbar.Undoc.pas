{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{            Copyright (c) 2010-2021 Asaq               }
{*******************************************************}

unit Linkbar.Undoc;

{$i linkbar.inc}

interface

uses
  Winapi.Windows, System.SysUtils;

const
  U_WCA_CLIENTRENDERING_POLICY_WIN7 = 16;
  U_WCA_CLIENTRENDERING_POLICY_WIN8 = 15;

  // Windows 10 AeroGlass
  U_WCA_ACCENT_POLICY = 19;

  U_WCA_ACCENT_STATE_DISABLED = 0;
  U_WCA_ACCENT_STATE_ENABLE_GRADIENT = 1;
  U_WCA_ACCENT_STATE_ENABLE_TRANSPARENTGRADIENT = 2;
  U_WCA_ACCENT_STATE_ENABLE_BLURBEHIND = 3;
  U_WCA_ACCENT_STATE_ENABLE_ACRYLICBLURBEHIND = 4;
  U_WCA_ACCENT_STATE_INVALID_STATE = 5;

  U_WCA_ACCENT_FLAG_DEFAULT = 0;
  U_WCA_ACCENT_FLAG_DRAW_ALL = $13;
  U_WCA_ACCENT_FLAG_DRAW_LEFT_BORDER = $20;
  U_WCA_ACCENT_FLAG_DRAW_TOP_BORDER = $40;
  U_WCA_ACCENT_FLAG_DRAW_RIGHT_BORDER = $80;
  U_WCA_ACCENT_FLAG_DRAW_BOTTOM_BORDER = $100;

type
  tagCOLORIZATIONPARAMS = record
    Color: COLORREF;
    Afterglow: COLORREF;
    ColorBalance: UINT;
    AfterglowBalance: UINT;
    BlurBalance: UINT;
    GlassReflectionIntensity: UINT;
    OpaqueBlend: DWORD; // BOOL
    Extra: DWORD; // Win8 has extra parameter
  end;
  TColorizationParams = tagCOLORIZATIONPARAMS;
  PColorizationParams = ^TColorizationParams;

  TDwmGetColorizationParameters = function(out parameters: TColorizationParams): HRESULT; stdcall;

  // http://a-whiter.livejournal.com/1385.html
  // http://undoc.airesoft.co.uk/user32.dll/SetWindowCompositionAttribute.php
  tagWCADATA = packed record
    dwAttribute: NativeUInt;     // the attribute to query, see below
    pvAttribute: Pointer;        // buffer to store the result
    cbAttribute: ULONG;          // size of the pData buffer
  end;
  TWcaData = tagWCADATA;
  PWcaData = ^TWcaData;

  tagACCENTPOLICY = packed record
    AccentState: Integer;
    AccentFlags: Integer;
    GradientColor: COLORREF;
    AnimationId: Integer;
  end;
  TWcaAccentPolicy = tagACCENTPOLICY;
  PWcaAccentPolicy = ^TWcaAccentPolicy;

  TDwmSetWindowCompositionAttribute = function(hwnd: HWND; pAttrData: PWcaData): BOOL; stdcall;

  // Get Metro Colors
  TGetImmersiveUserColorSetPreference = function(bForceCheckRegistry: BOOL; bSkipCheckOnFail: BOOL): Integer; stdcall;
  TGetImmersiveColorTypeFromName = function(const pName: PChar): Integer; stdcall;
  TGetImmersiveColorFromColorSetEx = function(dwImmersiveColorSet: UINT; dwImmersiveColorType: UINT; bIgnoreHighContrast: BOOL; dwHighContrastCacheMode: UINT): COLORREF; stdcall;

var
  UDwmGetColorizationParametersProc: TDwmGetColorizationParameters = nil;
  UDwmSetWindowCompositionAttributeProc: TDwmSetWindowCompositionAttribute = nil;
  //
  UGetImmersiveUserColorSetPreferenceProc: TGetImmersiveUserColorSetPreference = nil;
  UGetImmersiveColorTypeFromNameProc: TGetImmersiveColorTypeFromName = nil;
  UGetImmersiveColorFromColorSetExProc: TGetImmersiveColorFromColorSetEx = nil;

implementation

uses Linkbar.OS;

function LoadUndocFunctions: boolean;
var hlib: THandle;
begin
  // dwmapi.dll
  hlib := GetModuleHandle('DWMAPI.DLL');
  if (hlib <> 0)
  then begin
    @UDwmGetColorizationParametersProc := GetProcAddress(hlib, LPCSTR(127));
  end;

  // user32.dll
  hlib := GetModuleHandle('USER32.DLL');
  if (hlib <> 0)
  then begin
    @UDwmSetWindowCompositionAttributeProc := GetProcAddress(hlib, LPCSTR('SetWindowCompositionAttribute'));
  end;

  // uxtheme.dll
  if IsWindows10OrAbove
  then begin
    hlib := GetModuleHandle('UXTHEME.DLL');
    if (hlib <> 0)
       //and (GetModuleVersion(hlib) >= $6020000)
    then begin
      @UGetImmersiveColorFromColorSetExProc := GetProcAddress(hlib, LPCSTR(95));
      @UGetImmersiveColorTypeFromNameProc := GetProcAddress(hlib, LPCSTR(96));
      if Assigned(UGetImmersiveColorFromColorSetExProc)
         and Assigned(UGetImmersiveColorTypeFromNameProc)
      then @UGetImmersiveUserColorSetPreferenceProc := GetProcAddress(hlib, LPCSTR(98));
    end;
  end;

  Result := True;
end;

initialization
  LoadUndocFunctions;

end.
