{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{            Copyright (c) 2010-2017 Asaq               }
{*******************************************************}

unit MyHint;

interface

uses 
  Windows, Vcl.Controls, System.Classes, Winapi.CommCtrl, Winapi.Messages, System.SysUtils;

type
  TTooltipHintWindow = class(THintWindow)
  private
    TooltipWnd: HWND;
    TooltipInfo: TToolInfo;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure ActivateHint(Rect: TRect; const AHint: string); override;
    function CalcHintRect(MaxWidth: Integer; const AHint: string; AData: TCustomData): TRect; override;
    function ShouldHideHint: Boolean; override;
  end;

implementation

procedure TTooltipHintWindow.ActivateHint(Rect: TRect; const AHint: string);
begin
  inherited;
  TooltipInfo.lpszText := PChar(AHint);
  SendMessage(TooltipWnd, TTM_UPDATETIPTEXT, 0, LParam(@TooltipInfo));
  SendMessage(TooltipWnd, TTM_TRACKPOSITION, 0, MakeLParam(Rect.TopLeft.X, Rect.TopLeft.Y));
  SendMessage(TooltipWnd, TTM_TRACKACTIVATE, WParam(True), LParam(@TooltipInfo));
end;

function TTooltipHintWindow.CalcHintRect(MaxWidth: Integer; const AHint: string;
  AData: TCustomData): TRect;
begin
  Result := Rect(0,0,0,0);
end;

constructor TTooltipHintWindow.Create(AOwner: TComponent);
begin
  inherited;
  TooltipWnd := CreateWindowEx(WS_EX_TOPMOST or WS_EX_TRANSPARENT, TOOLTIPS_CLASS,
    nil, TTS_NOPREFIX or TTS_ALWAYSTIP, 0, 0, 0, 0, 0, 0, HInstance, nil);

  SendMessage(TooltipWnd, TTM_SETMAXTIPWIDTH, 0, 0);

  FillChar(TooltipInfo, SizeOf(TooltipInfo), 0);
  TooltipInfo.cbSize := SizeOf(TooltipInfo);
  TooltipInfo.uFlags := TTF_TRACK or TTF_TRANSPARENT;
  TooltipInfo.uId := 1;
  SendMessage(TooltipWnd, TTM_ADDTOOL, 0, LParam(@TooltipInfo));
end;

destructor TTooltipHintWindow.Destroy;
begin
  DestroyWindow(TooltipWnd);
  inherited;
end;

function TTooltipHintWindow.ShouldHideHint: Boolean;
begin
  Result := inherited;
  SendMessage(TooltipWnd, TTM_TRACKACTIVATE, WParam(False), LParam(@TooltipInfo));
end;

end.
