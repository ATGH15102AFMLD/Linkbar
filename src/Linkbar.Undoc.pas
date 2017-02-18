{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{            Copyright (c) 2010-2017 Asaq               }
{*******************************************************}

unit Linkbar.Undoc;

{$i linkbar.inc}

interface

uses
  Windows, SysUtils;

const
  U_WCA_CLIENTRENDERING_POLICY_WIN7   = 16;
  U_WCA_CLIENTRENDERING_POLICY_WIN8   = 15;

  // Windows 10 AeroGlass
  U_WCA_ACCENT_POLICY = 19;

  U_WCA_ACCENT_STATE_DISABLED = 0;
	U_WCA_ACCENT_STATE_ENABLE_GRADIENT = 1;
	U_WCA_ACCENT_STATE_ENABLE_TRANSPARENTGRADIENT = 2;
	U_WCA_ACCENT_STATE_ENABLE_BLURBEHIND = 3;
	U_WCA_ACCENT_STATE_INVALID_STATE = 4;

  U_WCA_ACCENT_FLAG_DEFAULT = 0;
  U_WCA_ACCENT_FLAG_DRAW_LEFT_BORDER = $20;
  U_WCA_ACCENT_FLAG_DRAW_TOP_BORDER = $40;
  U_WCA_ACCENT_FLAG_DRAW_RIGHT_BORDER = $80;
  U_WCA_ACCENT_FLAG_DRAW_BOTTOM_BORDER = $100;

type
  tagCOLORIZATIONPARAMS = record
    clrColor        : COLORREF;  //ColorizationColor
    clrAftGlow      : COLORREF;  //ColorizationAfterglow
    nIntensity      : UINT;      //ColorizationColorBalance -> 0-100
    clrAftGlowBal   : UINT;      //ColorizationAfterglowBalance
    clrBlurBal      : UINT;      //ColorizationBlurBalance
    clrGlassReflInt : UINT;      //ColorizationGlassReflectionIntensity
    fOpaque         : BOOL;
  end;
  TColorizationParams = tagCOLORIZATIONPARAMS;
  PColorizationParams = ^TColorizationParams;

  TDwmGetColorizationParameters = procedure(out parameters: TColorizationParams); stdcall;

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
    GradientColor: Integer;
    AnimationId: Integer;
  end;
  TWcaAccentPolicy = tagACCENTPOLICY;
  PWcaAccentPolicy = ^TWcaAccentPolicy;

  TDwmSetWindowCompositionAttribute = function(hwnd: HWND;
    pAttrData: PWcaData): BOOL; stdcall;

var
  UDwmGetColorizationParametersProc: TDwmGetColorizationParameters = nil;
  UDwmSetWindowCompositionAttributeProc: TDwmSetWindowCompositionAttribute = nil;

implementation

const
  lnDwmApi = 'DWMAPI.DLL';
  NameDwmGetColorizationParameters = 127;

  lnUser32 = 'USER32.DLL';
  NameSetWindowCompositionAttribute = 'SetWindowCompositionAttribute';
  NameUpdateLayeredWindowIndirect = 'UpdateLayeredWindowIndirect';

function LoadUndocFunctions: boolean;
var
  hDwmApi: THandle;
  hUser32: THandle;
begin
  // dwmapi.dll
  hDwmApi := GetModuleHandle(lnDwmApi);
  if (hDwmApi >= 32)
  then begin
    @UDwmGetColorizationParametersProc := GetProcAddress( hDwmApi,
      LPCSTR(NameDwmGetColorizationParameters) );
  end;

  // user32.dll
  hUser32 := GetModuleHandle(lnUser32);
  if (hUser32 >= 32)
  then begin
    @UDwmSetWindowCompositionAttributeProc := GetProcAddress( hUser32,
      LPCSTR(NameSetWindowCompositionAttribute) );
  end;

  Result := Assigned(UDwmGetColorizationParametersProc)
    and Assigned(UDwmSetWindowCompositionAttributeProc);
end;

initialization
  LoadUndocFunctions;

end.
