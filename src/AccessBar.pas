{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{            Copyright (c) 2010-2018 Asaq               }
{*******************************************************}

unit AccessBar;

{$i linkbar.inc}

interface

uses
  Windows,
  Messages, SysUtils, Classes, Controls, Forms,
  ShellApi, Vcl.Dialogs, Linkbar.Consts, Linkbar.OS;

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
    const
      HWND_STYLE: array[Boolean] of HWND = (HWND_NOTOPMOST, HWND_TOPMOST);
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
    FStayOnTop: Boolean;
    // special form for autohide
    ahform: THiddenForm;
    FTaskbarCreated: DWORD;
    procedure SetAutoHide(AValue: boolean);
    procedure SetSide(AValue: TScreenAlign);
    procedure SetStayOnTop(AValue: Boolean);
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
    property StayOnTop: Boolean read FStayOnTop write SetStayOnTop;
    property AutoHide: boolean read FAutoHide write SetAutoHide;
    property Side: TScreenAlign read FSide write SetSide default saTop;
    property QuerySizing: TQuerySizingEvent read FQuerySizing write FQuerySizing;
    property QuerySized: TQuerySizedEvent read FQuerySized write FQuerySized;
    property QueryAutoHide: TQueryHideEvent read FQueryAutoHide write FQueryAutoHide;
  end;

  function IsVertical(const AEdge: TScreenAlign): Boolean; inline;
  function IsHorizontal(const AEdge: TScreenAlign): Boolean; inline;

implementation

uses Types, Math, Linkbar.L10n;

const
  LM_AB_CALLBACK       =  WM_USER + 1;
  LM_AB_FULLSCREENAPP  =  WM_USER + 2;
  LM_AB_TASKBARSTARTED =  WM_USER + 3;

  // Multi Monitor support, introduced in Windows 8
  ABM_GETAUTOHIDEBAREX = $0000000b;
  ABM_SETAUTOHIDEBAREX = $0000000c;

procedure ChangeWindowMessageFilterEx(const AWnd: HWND; const AMessage: UINT);
const MSGFLT_ALLOW = 1;
type
{$REGION '  Original from msdn '}
(* BOOL WINAPI ChangeWindowMessageFilterEx(
  _In_        HWND                hWnd,
  _In_        UINT                message,
  _In_        DWORD               action,
  _Inout_opt_ PCHANGEFILTERSTRUCT pChangeFilterStruct
);
typedef struct tagCHANGEFILTERSTRUCT {
  DWORD cbSize;
  DWORD ExtStatus;
} CHANGEFILTERSTRUCT, *PCHANGEFILTERSTRUCT; *)
{$ENDREGION}
  CHANGEFILTERSTRUCT = packed record
    cbSize: DWORD;
    ExtStatus: DWORD;
  end;
  TChangeFilterStruct = CHANGEFILTERSTRUCT;
  PChangeFilterStruct = ^TChangeFilterStruct;

  TChangeWindowMessageFilter   = function (hWnd: HWND; Message: UINT; Action: DWORD): BOOL; stdcall;
  TChangeWindowMessageFilterEx = function (hWnd: HWND; Message: UINT; Action: DWORD; pChangeFilterStruct: PChangeFilterStruct): BOOL; stdcall;

var proc: TChangeWindowMessageFilter;
    procEx: TChangeWindowMessageFilterEx;
begin
  @procEx := GetProcAddress(GetModuleHandle(user32), 'ChangeWindowMessageFilterEx');
  if Assigned(procEx)
  then begin
    if not procEx(AWnd, AMessage, MSGFLT_ALLOW, nil)
    then MessageBox(0, PChar(SysErrorMessage(GetLastError)), nil, MB_OK);
  end
  else begin
    @proc := GetProcAddress(GetModuleHandle(user32), 'ChangeWindowMessageFilter');
    if Assigned(proc)
    then begin
      if not proc(AWnd, AMessage, MSGFLT_ALLOW)
      then MessageBox(0, PChar(SysErrorMessage(GetLastError)), nil, MB_OK);
    end;
  end;
end;

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
  rabd.uCallbackMessage := LM_AB_CALLBACK;
  FAccessHandle := 0;
  if SHAppBarMessage(ABM_NEW, rabd) = 0
  then raise Exception.Create(SysErrorMessage(GetLastError()));
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
  if SHAppBarMessage(ABM_REMOVE, rabd) = 0
  then raise Exception.Create(SysErrorMessage(GetLastError()));
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
  if SHAppBarMessage(ABM_SETPOS, rabd) = 0
  then raise Exception.Create(SysErrorMessage(GetLastError()));

  MoveWindow(Handle, rabd.rc.Left, rabd.rc.Top, 0, 0, False);
end;

procedure THiddenForm.WndProc(var Msg: TMessage);
begin
  if Msg.Msg = LM_AB_CALLBACK
  then begin
    if (Msg.wParam = ABN_FULLSCREENAPP) and IsWindow(FAccessHandle)
    then SendMessage(FAccessHandle, LM_AB_FULLSCREENAPP, 0, Msg.lParam);
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

  // make sure we get the notification messages
  // NOTE: moved to constructor
  //FOwnerOriginalWndProc := TWinControl(Owner).WindowProc;
  //TWinControl(Owner).WindowProc := AppBWndProc;

  FillChar(rabd, SizeOf(rabd), 0);
  rabd.cbSize:= SizeOf(rabd);
  rabd.hWnd := FHandle;
  rabd.uCallbackMessage:= LM_AB_CALLBACK;
  // register the application bar within the system
  if SHAppBarMessage(ABM_NEW, rabd) = 0
  then raise Exception.Create(SysErrorMessage(GetLastError()));

  gABRegistered := TRUE;
end;

procedure TAccessBar.UnregisterAppBar;
var rabd: TAppBarData;
begin
  if not gABRegistered then exit;

  // check if the form is not being destroyed
  // NOTE: moved to destructor
  //if not (csDestroying in ComponentState)
  //then TWinControl(Owner).WindowProc := FOwnerOriginalWndProc;

  FillChar(rabd, SizeOf(rabd), 0);
  rabd.cbSize:= SizeOf(rabd);
  rabd.hWnd := FHandle;
  // remove the application bar
  if SHAppBarMessage(ABM_REMOVE, rabd) = 0
  then raise Exception.Create(SysErrorMessage(GetLastError()));
  gABRegistered := FALSE;
  FBoundRect := TRect.Empty;
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
      // make sure we are the only one
      for I:=0 to AOwner.ComponentCount -1 do
      begin
        if (AOwner.Components[I] is TAccessBar) and (AOwner.Components[I] <> Self)
        then raise Exception.Create('Ooops, you need only *ONE* of these');
      end;

      FOwnerOriginalWndProc := TWinControl(Owner).WindowProc;
      TWinControl(Owner).WindowProc := AppBWndProc;

      FHandle := TWinControl(AOwner).Handle;
      ahform := THiddenForm.CreateNew(nil);
      ahform.AccessHandle := FHandle;
      ahform.Show;

      FBoundRect := TRect.Empty;

      FTaskbarCreated := RegisterWindowMessage('TaskbarCreated');
      if (FTaskbarCreated = 0)
      then raise Exception.Create(SysErrorMessage(GetLastError));
      ChangeWindowMessageFilterEx(FHandle, FTaskbarCreated);
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
  TWinControl(Owner).WindowProc := FOwnerOriginalWndProc;

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
  //if (csDesigning in ComponentState) then Exit;

  if not InRange(MonitorNum, 0, Screen.MonitorCount-1)
  then MonitorNum := Screen.PrimaryMonitor.MonitorNum;

  FillChar(rabd, SizeOf(rabd), 0);
  rabd.cbSize:= SizeOf(rabd);
  rabd.hWnd:= FHandle;
  rabd.uEdge := ScreenEdgeToEdge(FSide);
  rabd.rc := Screen.Monitors[MonitorNum].BoundsRect;

  if not AutoHide then
  // query the new position
  if SHAppBarMessage(ABM_QUERYPOS, rabd) = 0
  then raise Exception.Create(SysErrorMessage(GetLastError()));

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
  if (not AutoHide)
     and (SHAppBarMessage(ABM_SETPOS, rabd) = 0)
  then raise Exception.Create(SysErrorMessage(GetLastError()));

  // request the new size
  if Assigned(FQuerySized)
  then FQuerySized(Self, rabd.rc.Left, rabd.rc.Top, rabd.rc.Width, rabd.rc.Height);

  if Assigned(ahform)
  then ahform.SetMonitor(MonitorNum);
end;

procedure TAccessBar.SetSide(AValue: TScreenAlign);
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

procedure TAccessBar.SetAutoHide(AValue: boolean);
begin
  if FAutoHide = AValue then exit;
  AppBarSetAutoHide(AValue);
end;

procedure TAccessBar.SetStayOnTop(AValue: Boolean);
var desktop: HWND;
begin
  FStayOnTop := AValue;
  // Set Desktop window as Parent for prevent hide Linkbar by "Show desktop"
  // if "Always on Top" disabled
  if (FStayOnTop)
  then desktop := 0
  else desktop := FindWindowEx(FindWindow('Progman', 'Program Manager'), 0, 'SHELLDLL_DefView', '');
  SetWindowLong(FHandle, GWL_HWNDPARENT, desktop);
end;

function TAccessBar.GetIsVertical: boolean;
begin
  Result := IsVertical(FSide);
end;

procedure TAccessBar.AppBWndProc(var Msg: TMessage);
var rabd: TAppBarData;
begin
  case Msg.Msg of
    LM_AB_TASKBARSTARTED:
      begin
        if (AutoHide)
        then
          SetSide(FSide)
        else begin
          UnregisterAppBar;
          RegisterAppBar;
        end;
        StayOnTop := FStayOnTop;
        Exit;
      end;
    LM_AB_FULLSCREENAPP:
      begin
        Self.AppBarFullScreenApp(Msg.LParam <> 0);
        Exit;
      end;
    LM_AB_CALLBACK:
      begin
        case Msg.wParam of
          ABN_STATECHANGE, ABN_POSCHANGED:
            AppBarQuerySetPos;
        end;
        Exit;
      end;
    WM_WINDOWPOSCHANGED:
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
        //inherited;
      end;
    else begin
      if (Msg.Msg = FTaskbarCreated)
      then begin
        PostMessage(FHandle, LM_AB_TASKBARSTARTED, 0, 0);
        Exit;
      end;
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
  //if (csDesigning in ComponentState) then Exit;

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

    SetWindowPos(FHandle, HWND_STYLE[FStayOnTop], 0, 0, 0, 0,
      SWP_NOMOVE or SWP_NOSIZE or SWP_NOACTIVATE or SWP_NOOWNERZORDER);

    AppBarQuerySetPos;
  end
  else begin
    FAutoHide := FALSE;
    RegisterAppBar;

    SetWindowPos(FHandle, HWND_STYLE[FStayOnTop], 0, 0, 0, 0,
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
      td.text := L10nMui(LB_FN_TOOLBAR, LB_RS_TB_AUTOHIDEALREADYEXISTS);
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
  if AEnabled
  then Flags := HWND_BOTTOM
  else Flags := HWND_STYLE[FStayOnTop];

  SetWindowPos(FHandle, Flags, 0, 0, 0, 0,
    SWP_NOMOVE or SWP_NOSIZE or SWP_NOACTIVATE or SWP_NOOWNERZORDER);
end;

end.
