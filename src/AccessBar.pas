{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{            Copyright (c) 2010-2017 Asaq               }
{*******************************************************}

unit AccessBar;

{$i linkbar.inc}

interface

uses
  Windows,
  Messages, SysUtils, Classes, Controls, Forms,
  ShellApi, Vcl.Dialogs, Linkbar.Consts, Linkbar.OS;

const
  APPBAR_CALLBACK =  WM_USER + 1;
  CUSTOM_ABN_FULLSCREENAPP =  WM_USER + 2;

type
  TQuerySizingEvent = procedure(Sender: TObject; AVertical: Boolean;
    var AWidth, AHeight: Integer) of object;
  TQuerySizedEvent = procedure(Sender: TObject; const AX, AY, AWidth, AHeight: Integer) of object;
  TQueryHideEvent = procedure(Sender: TObject; AEnabled: boolean) of object;

  THiddenForm = class (TCustomForm)
  private

    FAccessHandle: THandle;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure WndProc(var Msg: TMessage); override;
  public
    constructor CreateNew(AOwner: TComponent; Dummy: Integer = 0); override;
    destructor Destroy; override;
    procedure SetMonitor(const AMonitorNum: Integer);
    property AccessHandle: THandle read FAccessHandle write FAccessHandle;
  end;

  TAccessBar = class(TComponent)
  private
    gABRegistered: boolean;
    FOwnerOriginalWndProc: TWndMethod;
    FAutoHide: boolean;
    FSide: TScreenAlign;
    FQuerySizing: TQuerySizingEvent;
    FQuerySized: TQuerySizedEvent;
    FQueryAutoHide: TQueryHideEvent;
    FHandle: HWND;
    FBoundRect: TRect;
    // special form for autohide
    ahform: THiddenForm;
    procedure SetAutoHide(const AValue: boolean);
    procedure SetSide(const AValue: TScreenAlign);
    procedure AppBWndProc(var Msg: TMessage);
    function GetIsVertical: boolean;
  protected
    procedure RegisterAppBar;
    procedure UnregisterAppBar;
    procedure AppBarQuerySetPos;
    procedure AppBarSetAutoHide(AEnabled: Boolean);
  public
    MonitorNum: Integer;
    AutoHideMonitorNum: Integer;
    constructor Create(AOwner: TComponent); override;
    constructor Create2(AOwner: TComponent; iSide: TScreenAlign; iAutoHide: boolean); overload;
    destructor Destroy; override;
    procedure Loaded; override;
    property Vertical: boolean read GetIsVertical;
    procedure AppBarPosChanged;
    procedure AppBarFullScreenApp(AEnabled: Boolean);
  published
    property AutoHide: boolean read FAutoHide write SetAutoHide;
    property Side: TScreenAlign read FSide write SetSide default saTop;
    property QuerySizing: TQuerySizingEvent read FQuerySizing write FQuerySizing;
    property QuerySized: TQuerySizedEvent read FQuerySized write FQuerySized;
    property QueryAutoHide: TQueryHideEvent read FQueryAutoHide write FQueryAutoHide;
  end;

  function IsVertical(const AEdge: TScreenAlign): Boolean; inline;
  function IsHorizontal(const AEdge: TScreenAlign): Boolean; inline;

implementation

uses Types, Math, Linkbar.Loc;

const
  // Multi Monitor support, introduced in Windows 8
  ABM_GETAUTOHIDEBAREX = $0000000b;
  ABM_SETAUTOHIDEBAREX = $0000000c;

function IsVertical(const AEdge: TScreenAlign): Boolean; inline;
begin
  Result := (AEdge = saLeft) or (AEdge = saRight);
end;

function IsHorizontal(const AEdge: TScreenAlign): Boolean; inline;
begin
  Result := (AEdge = saTop) or (AEdge = saBottom);
end;

function ScreenEdgeToEdge(const se: TScreenAlign): UINT;
begin
  case se of
    saTop:    Result := ABE_TOP;
    saBottom: Result := ABE_BOTTOM;
    saLeft:   Result := ABE_LEFT;
    saRight:  Result := ABE_RIGHT;
  else
    Result := ABE_TOP;
  end;
end;

constructor THiddenForm.CreateNew(AOwner: TComponent; Dummy: Integer = 0);
var rabd: TAppBarData;
begin
  inherited CreateNew(AOwner);
  BorderStyle := bsNone;
  SetBounds(0,0,0,0);
  FillChar(rabd, SizeOf(rabd), 0);
  rabd.cbSize := SizeOf(rabd);
  rabd.hWnd := Self.Handle;
  rabd.uCallbackMessage := APPBAR_CALLBACK;
  FAccessHandle := 0;
  if SHAppBarMessage(ABM_NEW, rabd) = 0 then
       raise Exception.Create(SysErrorMessage(GetLastError()));
end;

procedure THiddenForm.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.Style := WS_POPUP or WS_DISABLED;
  Params.ExStyle := WS_EX_TOOLWINDOW;
end;

destructor THiddenForm.Destroy;
var rabd: TAppBarData;
begin
  FAccessHandle := 0;
  FillChar(rabd, SizeOf(rabd), 0);
  rabd.cbSize := SizeOf(rabd);
  rabd.hWnd := Self.Handle;
  if SHAppBarMessage(ABM_REMOVE, rabd) = 0 then
    raise Exception.Create(SysErrorMessage(GetLastError()));
  inherited Destroy;
end;

procedure THiddenForm.SetMonitor(const AMonitorNum: Integer);
var
  rabd: TAppBarData;
begin
  FillChar(rabd, SizeOf(rabd), 0);
  rabd.cbSize:= SizeOf(rabd);
  rabd.hWnd:= Handle;
  rabd.uEdge := ABE_TOP;
  rabd.rc := Screen.Monitors[AMonitorNum].BoundsRect;

  rabd.rc.Width := 0;
  rabd.rc.Height := 0;
  if SHAppBarMessage(ABM_SETPOS, rabd) = 0 then
    raise Exception.Create(SysErrorMessage(GetLastError()));

  MoveWindow(Handle, rabd.rc.Left, rabd.rc.Top, 0, 0, False);
end;

procedure THiddenForm.WndProc(var Msg: TMessage);
begin
  if Msg.Msg = APPBAR_CALLBACK
  then begin
    if (Msg.wParam = ABN_FULLSCREENAPP) and IsWindow(FAccessHandle)
    then SendMessage(FAccessHandle, CUSTOM_ABN_FULLSCREENAPP, 0, Msg.lParam);
  end
  else inherited WndProc(Msg);
end;


////////////////////////////////////////////////////////////////////////////////
// TAccessBar
////////////////////////////////////////////////////////////////////////////////

procedure TAccessBar.RegisterAppBar;
var rabd: TAppBarData;
begin
  if gABRegistered then exit;
  // check if we are not in the Delphi IDE
  if not (csDesigning in ComponentState) then
  begin
    // make sure we get the notification messages
    FOwnerOriginalWndProc := TWinControl(Owner).WindowProc;
    TWinControl(Owner).WindowProc := AppBWndProc;

    FillChar(rabd, SizeOf(rabd), 0);
    rabd.cbSize:= SizeOf(rabd);
    rabd.hWnd := FHandle;
    rabd.uCallbackMessage:= APPBAR_CALLBACK;
    // register the application bar within the system
    if SHAppBarMessage(ABM_NEW, rabd) = 0 then
       raise Exception.Create(SysErrorMessage(GetLastError()));

    gABRegistered := TRUE;
  end;
end;

procedure TAccessBar.UnregisterAppBar;
var rabd: TAppBarData;
begin
  if not gABRegistered then exit;
  // check if the form is not being destroyed and not in the Delphi IDE
  if not (csDesigning in ComponentState) then
  begin
    if not (csDestroying in ComponentState) then
       TWinControl(Owner).WindowProc := FOwnerOriginalWndProc;

    FillChar(rabd, SizeOf(rabd), 0);
    rabd.cbSize:= SizeOf(rabd);
    rabd.hWnd := FHandle;
    // remove the application bar
    if SHAppBarMessage(ABM_REMOVE, rabd) = 0 then
       raise Exception.Create(SysErrorMessage(GetLastError()));
    gABRegistered := FALSE;
    FBoundRect := TRect.Empty;
  end;
end;

constructor TAccessBar.Create(AOwner: TComponent);
var I: Cardinal;
begin
  inherited Create(AOwner);
  gABRegistered := FALSE;
  FAutoHide := FALSE;
  // check if we have an owner
  if Assigned(AOwner) then
  begin
    // we could turn everything with a handle into a application-bar, but for
    // for Delphi we only use descendants of TCustomForm
    if (AOwner is TCustomForm) then
    begin
      FHandle := TWinControl(AOwner).Handle;
      ahform := THiddenForm.CreateNew(nil);
      ahform.AccessHandle := FHandle;
      ahform.Show;

      FBoundRect := TRect.Empty;

      // make sure we are the only one
      for I:=0 to AOwner.ComponentCount -1 do
      begin
        if (AOwner.Components[I] is TAccessBar) and (AOwner.Components[I] <> Self) then
           raise Exception.Create('Ooops, you need only *ONE* of these');
      end;
    end
    else
      raise Exception.Create('Sorry, can''t do this only with TCustomForms');
  end
  else
    raise Exception.Create('Sorry, can''t do this without an owner');
end;

constructor TAccessBar.Create2(AOwner: TComponent; iSide: TScreenAlign; iAutoHide: boolean);
begin
  Create(AOwner);
  FSide := iSide;
  FAutoHide := iAutoHide;
end;

destructor TAccessBar.Destroy;
begin
  if Assigned(ahform) then
  begin
    ahform.FAccessHandle := 0;
    ahform.Free;
  end;
  UnregisterAppBar();
  inherited Destroy();
end;

procedure TAccessBar.Loaded;
begin
  RegisterAppBar;
  AppBarQuerySetPos;
end;

procedure TAccessBar.AppBarQuerySetPos;
var
  iHeight, iWidth: Integer;
  rabd: TAppBarData;
begin
  if (csDesigning in ComponentState) then Exit;

  if not InRange(MonitorNum, 0, Screen.MonitorCount-1)
  then MonitorNum := Screen.PrimaryMonitor.MonitorNum;

  FillChar(rabd, SizeOf(rabd), 0);
  rabd.cbSize:= SizeOf(rabd);
  rabd.hWnd:= FHandle;
  rabd.uEdge := ScreenEdgeToEdge(FSide);
  rabd.rc := Screen.Monitors[MonitorNum].BoundsRect;

  if not AutoHide then
  // query the new position
  if SHAppBarMessage(ABM_QUERYPOS, rabd) = 0 then
    raise Exception.Create(SysErrorMessage(GetLastError()));

  iWidth := rabd.rc.Width;
  iHeight := rabd.rc.Height;

  // request the new size
  if Assigned(FQuerySizing)
  then FQuerySizing(Self, Vertical, iWidth, iHeight);

  // calculate the size
  case rabd.uEdge of
    ABE_LEFT:
      begin
        rabd.rc.Right := rabd.rc.Left + iWidth;
      end;
    ABE_RIGHT:
      begin
        rabd.rc.Left:= rabd.rc.Right - iWidth;
      end;
    ABE_TOP:
      begin
        rabd.rc.Bottom:= rabd.rc.Top + iHeight;
      end;
    ABE_BOTTOM:
      begin
        rabd.rc.Top:= rabd.rc.Bottom - iHeight;
      end;
  end;

  // set the new size
  if not AutoHide then
    if SHAppBarMessage(ABM_SETPOS, rabd) = 0 then
      raise Exception.Create(SysErrorMessage(GetLastError()));

  // request the new size
  if Assigned(FQuerySized)
  then FQuerySized(Self, rabd.rc.Left, rabd.rc.Top, rabd.rc.Width, rabd.rc.Height);

  if Assigned(ahform)
  then ahform.SetMonitor(MonitorNum);
end;

procedure TAccessBar.SetSide(const AValue: TScreenAlign);
var  rabd: TAppBarData;
     hr: Cardinal;
begin
  // Unregister autohide
  if AutoHide then
  begin
    FillChar(rabd, SizeOf(rabd), 0);
    rabd.cbSize := SizeOf(rabd);
    rabd.hWnd := FHandle;
    rabd.uEdge := ScreenEdgeToEdge(FSide);
    rabd.lParam := 0;
    // Multi Monitor support for Windows 8
    if IsWindows8OrAbove
    then begin
      rabd.rc := Screen.Monitors[AutoHideMonitorNum].BoundsRect;
      hr := SHAppBarMessage(ABM_SETAUTOHIDEBAREX, rabd);
    end
    else begin
      hr := SHAppBarMessage(ABM_SETAUTOHIDEBAR, rabd);  
    end;
    if hr = 0
    then raise Exception.Create(SysErrorMessage(GetLastError()));
  end;

  FSide := AValue;

  if AutoHide
  then AppBarSetAutoHide(TRUE)
  else AppBarQuerySetPos;
end;

procedure TAccessBar.SetAutoHide(const AValue: boolean);
begin
  if FAutoHide = AValue then exit;
  AppBarSetAutoHide(AValue);
end;

function TAccessBar.GetIsVertical: boolean;
begin
  Result := IsVertical(FSide);
end;

procedure TAccessBar.AppBWndProc(var Msg: TMessage);
var rabd: TAppBarData;
begin
  case Msg.Msg of
    APPBAR_CALLBACK:
      begin
        case Msg.wParam of
          ABN_STATECHANGE, ABN_POSCHANGED:
            AppBarQuerySetPos;
        end;
      end;
    WM_WINDOWPOSCHANGED :
      begin
        FillChar(rabd, SizeOf(rabd), 0);
        rabd.cbSize := SizeOf(rabd);
        rabd.hWnd := FHandle;
        SHAppBarMessage(ABM_WINDOWPOSCHANGED, rabd);
      end;
    WM_ACTIVATE:
      begin
        FillChar(rabd, SizeOf(rabd), 0);
        rabd.cbSize := SizeOf(rabd);
        rabd.hWnd := FHandle;
        SHAppBarMessage(ABM_ACTIVATE, rabd);
        inherited;
      end;
  end;
  // call the original WndProc
  if Assigned(FOwnerOriginalWndProc) then FOwnerOriginalWndProc(Msg);
end;

procedure TAccessBar.AppBarSetAutoHide(AEnabled: Boolean);
var
  td: TTaskDialog;
  rabd: TAppBarData;
  hr: Cardinal;
begin
  if (csDesigning in ComponentState) then Exit;

  FillChar(rabd, SizeOf(rabd), 0);
  rabd.cbSize := SizeOf(rabd);
  rabd.hWnd := FHandle;
  rabd.uEdge := ScreenEdgeToEdge(FSide);
  if AEnabled
  then rabd.lParam:= -1
  else rabd.lParam:= 0;

  if IsWindows8OrAbove
  then begin
    rabd.rc := Screen.Monitors[MonitorNum].BoundsRect;
    hr := SHAppBarMessage(ABM_SETAUTOHIDEBAREX, rabd);
  end
  else begin
    hr := SHAppBarMessage(ABM_SETAUTOHIDEBAR, rabd);  
  end;
  
  if AEnabled and (hr <> 0)
  then begin
    FAutoHide := TRUE;
    AutoHideMonitorNum := MonitorNum;
    UnregisterAppBar;

    if Assigned(FQueryAutoHide) then
      FQueryAutoHide(Self, TRUE);

    SetWindowPos(FHandle, HWND_TOPMOST, 0, 0, 0, 0,
      SWP_NOMOVE or SWP_NOSIZE or SWP_NOACTIVATE or SWP_NOOWNERZORDER);

    AppBarQuerySetPos;
  end else begin
      FAutoHide := FALSE;
      RegisterAppBar;

      SetWindowPos(FHandle, HWND_TOPMOST, 0, 0, 0, 0,
        SWP_NOMOVE or SWP_NOSIZE or SWP_NOACTIVATE or SWP_NOOWNERZORDER);

      AppBarQuerySetPos;
      if Assigned(FQueryAutoHide)
      then FQueryAutoHide(Self, FALSE);
      if AEnabled then
      begin
        td := TTaskDialog.Create(Self.Owner);
        td.MainIcon := tdiInformation;
        td.Caption := APP_NAME_LINKBAR;
        td.Title := '';
        td.text := MUILoadResString(LB_FN_TOOLBAR, LB_RS_TB_AUTOHIDEALREADYEXISTS);
        td.CommonButtons := [tcbOk];
        td.Execute;
        td.Free;
      end;
  end;
end;

procedure TAccessBar.AppBarPosChanged;
begin
   AppBarQuerySetPos;
end;

procedure TAccessBar.AppBarFullScreenApp(AEnabled: Boolean);
var Flags: HWND;
begin
  Flags := HWND_BOTTOM;

  if not AEnabled and AutoHide
  then Flags := HWND_TOPMOST;

  SetWindowPos(FHandle, Flags, 0, 0, 0, 0,
    SWP_NOMOVE or SWP_NOSIZE or SWP_NOACTIVATE or SWP_NOOWNERZORDER);
end;

end.
