{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{            Copyright (c) 2010-2017 Asaq               }
{*******************************************************}

unit HotKey;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  Vcl.Controls, Vcl.Forms, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.StdCtrls,
  Vcl.Dialogs, Vcl.Menus;

const
  LB_HOTKEY_ID = 1;

type
  THotkeyInfo = record
  private
    const SSHIFT = 'Shift';
          SCTRL  = 'Ctrl';
          SALT   = 'Alt';
          SWIN   = 'Win';
          SNONE  = 'None';
  public
    Modifiers: Word;                                                            // Winapi.Windows.MOD_...
    KeyCode: Word;                                                              // Virtual Key Code
    constructor Create(const AInteger: Integer);  overload;
    constructor Create(const AString: String);  overload;
    class operator NotEqual(const Lhs, Rhs: THotkeyInfo): Boolean;
    class operator Implicit(A: THotkeyInfo): string;
    class operator Implicit(A: THotkeyInfo): Integer;
    function ToUserString: string;
  end;

  THotkeyEdit = class(TFrame)
    htkKey: THotKey;
    chbWin: TCheckBox;
    chbAlt: TCheckBox;
    chbCtrl: TCheckBox;
    chbShift: TCheckBox;
    Bevel1: TBevel;
    procedure Changed(Sender: TObject);
    procedure FrameResize(Sender: TObject);
  private
    FOnChange: TNotifyEvent;
    procedure SetHotkeyInfo(AHotKeyInfo: THotkeyInfo);
    function GetHotkeyInfo: THotkeyInfo;
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
  public
    constructor Create(AOwner: TComponent); override;
    property HotkeyInfo: THotkeyInfo read GetHotkeyInfo write SetHotkeyInfo;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

  TMyTaskDialog = class(TCustomTaskDialog)
  protected
    function CallbackProc(hwnd: HWND; msg: UINT; wParam: WPARAM;
      lParam: LPARAM; lpRefData: LONG_PTR): HResult; override;
  end;

  function RegisterHotkeyNotify(AWnd: HWND; AHotkeyInfo: THotkeyInfo; AWarnings: Boolean = True): Boolean;
  function UnregisterHotkeyNotify(AWnd: HWND): Boolean;
  function CheckHotkey(AWnd: HWND; AHotkeyInfo: THotkeyInfo): Boolean;

implementation

{$R *.dfm}

uses Linkbar.Consts, Winapi.CommCtrl, Linkbar.Shell;

{ THotKeyInfo }

constructor THotkeyInfo.Create(const AInteger: Integer);
begin
  Self.KeyCode := Word(AInteger);
  Self.Modifiers := HiWord(AInteger);
end;

constructor THotkeyInfo.Create(const AString: String);
begin
  Create( StrToIntDef(AString, 0) );
end;

class operator THotkeyInfo.Implicit(A: THotkeyInfo): string;
begin
  Result := HexDisplayPrefix + IntToHex(A, 8);
end;

class operator THotkeyInfo.Implicit(A: THotkeyInfo): Integer;
begin
  Result := (A.Modifiers shl 16) or A.KeyCode;
end;

class operator THotkeyInfo.NotEqual(const Lhs, Rhs: THotkeyInfo): Boolean;
begin
  Result := (Lhs.KeyCode <> Rhs.KeyCode) or (Lhs.Modifiers <> Rhs.Modifiers);
end;

function THotkeyInfo.ToUserString: string;
begin
  Result := ShortCutToText(KeyCode);
  if Result = ''
  then Result := 'None';

  if (Modifiers and MOD_WIN     > 0) then Result := SWIN   + '+' + Result;
  if (Modifiers and MOD_ALT     > 0) then Result := SALT   + '+' + Result;
  if (Modifiers and MOD_CONTROL > 0) then Result := SCTRL  + '+' + Result;
  if (Modifiers and MOD_SHIFT   > 0) then Result := SSHIFT + '+' + Result;
end;

{ THotKeyEdit }

constructor THotkeyEdit.Create(AOwner: TComponent);
begin
  inherited;
  htkKey.InvalidKeys := [hcNone, hcShift, hcCtrl, hcAlt, hcShiftCtrl, hcShiftAlt, hcCtrlAlt, hcShiftCtrlAlt];
  htkKey.Modifiers := [];
  htkKey.HotKey := 0;
end;

procedure THotkeyEdit.FrameResize(Sender: TObject);
begin
  htkKey.BoundsRect := Bevel1.BoundsRect;
end;

procedure THotkeyEdit.CMEnabledChanged(var Message: TMessage);
begin
  chbShift.Enabled := Enabled;
  chbCtrl.Enabled := Enabled;
  chbAlt.Enabled := Enabled;
  chbWin.Enabled := Enabled;
  htkKey.Enabled := Enabled;
end;

procedure THotkeyEdit.SetHotkeyInfo(AHotKeyInfo: THotKeyInfo);
begin
  htkKey.HotKey := AHotKeyInfo.KeyCode;
  chbShift.Checked := (AHotKeyInfo.Modifiers and MOD_SHIFT) > 0;
  chbCtrl.Checked := (AHotKeyInfo.Modifiers and MOD_CONTROL) > 0;
  chbAlt.Checked := (AHotKeyInfo.Modifiers and MOD_ALT) > 0;
  chbWin.Checked := (AHotKeyInfo.Modifiers and MOD_WIN) > 0;
end;

function THotkeyEdit.GetHotkeyInfo: THotkeyInfo;
begin
  Result.KeyCode := htkKey.HotKey;
  Result.Modifiers := 0;
  if (chbShift.Checked) then Inc(Result.Modifiers, MOD_SHIFT);
  if (chbCtrl.Checked) then Inc(Result.Modifiers, MOD_CONTROL);
  if (chbAlt.Checked) then Inc(Result.Modifiers, MOD_ALT);
  if (chbWin.Checked) then Inc(Result.Modifiers, MOD_WIN);
end;

procedure THotkeyEdit.Changed(Sender: TObject);
begin
  if Assigned(FOnChange)
  then FOnChange(Self);
end;

function RegisterHotkeyNotify(AWnd: HWND; AHotkeyInfo: THotkeyInfo;
  AWarnings: Boolean = True): Boolean;
var err: string;
    td: TMyTaskDialog;
begin
  UnregisterHotkeyNotify(AWnd);

  if (AHotkeyInfo.KeyCode = 0)
  then Exit(False);

  Result := RegisterHotKey(AWnd, LB_HOTKEY_ID, MOD_NOREPEAT or AHotkeyInfo.Modifiers, AHotkeyInfo.KeyCode);

  if (not Result)
     and (AWarnings)
  then begin
    err := SysErrorMessage(GetLastError);
    td := TMyTaskDialog.Create(nil);
    try
      td.Flags := td.Flags + [tfEnableHyperlinks];
      td.Caption := ' ' + APP_NAME_LINKBAR;
      td.MainIcon := tdiNone;
      td.Title := AHotkeyInfo.ToUserString;
      td.Text := err;
      td.ExpandButtonCaption := 'Learn More';
      td.ExpandedText :=
        'Keyboard shortcuts in Windows: ' + #13 +
        '<a href="hotkeys">' + URL_WINDOWS_HOTKEY + '</a>';
      td.CommonButtons := [tcbOk];
      td.DefaultButton := tcbOk;
      td.Execute;
    finally
      td.Free;
    end;
  end;
end;

function UnregisterHotkeyNotify(AWnd: HWND): Boolean;
begin
  Result := UnregisterHotKey(AWnd, LB_HOTKEY_ID);
end;

function CheckHotkey(AWnd: HWND; AHotkeyInfo: THotkeyInfo): Boolean;
begin
  Result := RegisterHotkeyNotify(AWnd, AHotkeyInfo);
  UnregisterHotkeyNotify(AWnd);
end;

{ TMyTaskDialog }

function TMyTaskDialog.CallbackProc(hwnd: HWND; msg: UINT; wParam: WPARAM;
  lParam: LPARAM; lpRefData: LONG_PTR): HResult;
begin
  Result := S_OK;
  if (msg = TDN_HYPERLINK_CLICKED)
  then begin
    if SameText(string(LPCWSTR(lParam)), 'hotkeys')
    then LBShellExecute(hwnd, 'open', URL_WINDOWS_HOTKEY);
    Exit;
  end;
  inherited;
end;

end.
