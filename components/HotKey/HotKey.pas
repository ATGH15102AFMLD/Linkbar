{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{            Copyright (c) 2010-2018 Asaq               }
{*******************************************************}

unit HotKey;

interface

uses
  System.SysUtils, System.Classes, Winapi.Windows, Winapi.Messages,
  Vcl.Controls, Vcl.Forms, Vcl.ExtCtrls, Vcl.ComCtrls, Vcl.Dialogs, Vcl.Menus, Vcl.Buttons;

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
    class operator NotEqual(const Lhs, Rhs: THotkeyInfo): Boolean;
    class operator Implicit(const A: THotkeyInfo): string;
    class operator Implicit(const A: THotkeyInfo): Integer;
    class operator Implicit(const A: string): THotkeyInfo;
    class operator Implicit(const A: Integer): THotkeyInfo;
    function ToUserString: string;
  end;

  THotkeyEdit = class(TFrame)
    htkKey: THotKey;
    Bevel1: TBevel;
    btnShift: TSpeedButton;
    btnWin: TSpeedButton;
    btnAlt: TSpeedButton;
    btnCtrl: TSpeedButton;
    Bevel2: TBevel;
    Bevel3: TBevel;
    Bevel4: TBevel;
    Bevel5: TBevel;
    pnlButtons: TPanel;
    procedure Changed(Sender: TObject);
    procedure FrameResize(Sender: TObject);
    procedure btnShiftClick(Sender: TObject);
  private
    FOnChange: TNotifyEvent;
    procedure SetHotkeyInfo(AHotKeyInfo: THotkeyInfo);
    function GetHotkeyInfo: THotkeyInfo;
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
    procedure UpdatePixelsPerInch;
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

  function RegisterHotkeyNotify(AWnd: HWND; AHotkeyInfo: THotkeyInfo; AWarnings:
    Boolean = True): Boolean;
  function UnregisterHotkeyNotify(AWnd: HWND): Boolean;
  function CheckHotkey(AWnd: HWND; const AHotkeyInfo: THotkeyInfo): Boolean;

implementation

{$R *.dfm}

uses Linkbar.Consts, Winapi.CommCtrl, Linkbar.Shell;

{ THotKeyInfo }

class operator THotkeyInfo.Implicit(const A: THotkeyInfo): string;
begin
  Result := HexDisplayPrefix + IntToHex(Integer(A), 8);
end;

class operator THotkeyInfo.Implicit(const A: THotkeyInfo): Integer;
begin
  Result := (A.Modifiers shl 16) or A.KeyCode;
end;

class operator THotkeyInfo.Implicit(const A: string): THotkeyInfo;
begin
  Result := StrToIntDef(A, 0);
end;

class operator THotkeyInfo.Implicit(const A: Integer): THotkeyInfo;
begin
  Result.KeyCode := Word(A);
  Result.Modifiers := HiWord(A);
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

  UpdatePixelsPerInch;
end;

procedure THotkeyEdit.UpdatePixelsPerInch;
var ppi: Integer;

  function ScaleDimension(const X: Integer): Integer;
  begin
    Result := MulDiv(X, ppi, 96);
  end;

begin
  ppi := Screen.PixelsPerInch;
  Bevel1.Width := ScaleDimension(Bevel1.Width);
  Bevel2.Width := ScaleDimension(Bevel2.Width);
  btnWin.Width := ScaleDimension(btnWin.Width);
  Bevel3.Width := ScaleDimension(Bevel3.Width);
  btnAlt.Width := ScaleDimension(btnAlt.Width);
  Bevel4.Width := ScaleDimension(Bevel4.Width);
  btnCtrl.Width := ScaleDimension(btnCtrl.Width);
  Bevel5.Width := ScaleDimension(Bevel5.Width);
  btnShift.Width := ScaleDimension(btnShift.Width);
  pnlButtons.Width := 4 * Bevel2.Width + 4 * btnWin.Width;
  pnlButtons.Left := Bevel1.Left - pnlButtons.Width;
end;

procedure THotkeyEdit.FrameResize(Sender: TObject);
var r: TRect;
begin
  r := Bevel1.BoundsRect;
  r.Inflate(-2, -1);
  htkKey.BoundsRect := r;
end;

procedure THotkeyEdit.CMEnabledChanged(var Message: TMessage);
begin
  btnShift.Enabled := Enabled;
  btnCtrl.Enabled := Enabled;
  btnAlt.Enabled := Enabled;
  btnWin.Enabled := Enabled;
  htkKey.Enabled := Enabled;
end;

procedure THotkeyEdit.SetHotkeyInfo(AHotKeyInfo: THotKeyInfo);
begin
  htkKey.HotKey := AHotKeyInfo.KeyCode;
  btnShift.Down := (AHotKeyInfo.Modifiers and MOD_SHIFT) > 0;
  btnCtrl.Down := (AHotKeyInfo.Modifiers and MOD_CONTROL) > 0;
  btnAlt.Down := (AHotKeyInfo.Modifiers and MOD_ALT) > 0;
  btnWin.Down := (AHotKeyInfo.Modifiers and MOD_WIN) > 0;
end;

function THotkeyEdit.GetHotkeyInfo: THotkeyInfo;
begin
  Result.KeyCode := htkKey.HotKey;
  Result.Modifiers := 0;
  if (btnShift.Down) then Inc(Result.Modifiers, MOD_SHIFT);
  if (btnCtrl.Down) then Inc(Result.Modifiers, MOD_CONTROL);
  if (btnAlt.Down) then Inc(Result.Modifiers, MOD_ALT);
  if (btnWin.Down) then Inc(Result.Modifiers, MOD_WIN);
end;

procedure THotkeyEdit.btnShiftClick(Sender: TObject);
begin
  Changed(Self);
end;

procedure THotkeyEdit.Changed(Sender: TObject);
begin
  if Assigned(FOnChange)
  then FOnChange(Self);
end;

{ ... }

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

function CheckHotkey(AWnd: HWND; const AHotkeyInfo: THotkeyInfo): Boolean;
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
