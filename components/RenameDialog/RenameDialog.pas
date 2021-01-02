{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{            Copyright (c) 2010-2021 Asaq               }
{*******************************************************}

unit RenameDialog;

{$i linkbar.inc}

interface

uses
  System.SysUtils, System.Classes,
  Winapi.Windows, WinApi.Messages, Winapi.CommCtrl, Winapi.ShlObj, Winapi.ActiveX,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls;

type
  TRenamingWCl = class(TForm)
    edtFileName: TEdit;
    btnOk: TButton;
    btnCancel: TButton;
    procedure edtFileNameKeyPress(Sender: TObject; var Key: Char);
    procedure btnOkClick(Sender: TObject);
    procedure edtFileNameChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    FPidl: PItemIDList;
    FInvalidFileNameCharsHintText: string;
    procedure SetPidl(APidl: PItemIDList);
    procedure ShowBalloonTip(const AText: string);
    procedure L10n;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure WMNCHitTest(var Message: TWMNCHitTest); message WM_NCHITTEST;
  public
    destructor Destroy; override;
    property Pidl: PItemIDList write SetPidl;
  end;

implementation

{$R *.dfm}

uses Vcl.Clipbrd, Linkbar.Shell, Linkbar.Common, Linkbar.L10n, Linkbar.Consts;

var FInvalidFileNameChars: TCharArray;

function f_Edit_SetCueBannerText(hwnd: HWND; lpwText: LPCWSTR): BOOL; inline;
begin
  Result := BOOL(SendMessage(hwnd, EM_SETCUEBANNER, wParam(1), lParam(lpwText)));
end;

procedure TRenamingWCl.CreateParams(var Params: TCreateParams);
begin
  inherited;
  Params.ExStyle := Params.ExStyle or WS_EX_APPWINDOW;
end;

destructor TRenamingWCl.Destroy;
begin
{$IFDEF DEBUG}
  Assert(TWinControl(Owner) <> nil);
{$ENDIF}
  PostMessage(TWinControl(Owner).Handle, LM_DOAUTOHIDE, 0, 0);
  inherited;
end;

procedure TRenamingWCl.FormCreate(Sender: TObject);
var cue: string;
begin
  Font.Name := Screen.IconFont.Name;

  L10n;

  ReduceSysMenu(Handle);

  edtFileName.MaxLength := MAX_PATH;

  FInvalidFileNameChars := TCharArray.Create('"', '*', '/', ':', '<', '>', '?', '\', '|');
  FInvalidFileNameCharsHintText := L10nMui(GetModuleHandle(LB_FN_INVALIDFILENAMECHARS), LB_RS_IFNC_HINT);

  cue := L10nMui(GetModuleHandle(LB_FN_NEEDFILENAME), LB_RS_NFN_CUE);
  f_Edit_SetCueBannerText(edtFileName.Handle, PChar(cue));

  btnOk.ModalResult := mrNone;
end;

procedure TRenamingWCl.L10n;
begin
  L10nControl(Self,      'Rename.Caption');
  L10nControl(btnOk,     'Button.OK');
  L10nControl(btnCancel, 'Button.Cancel');
end;

procedure TRenamingWCl.SetPidl(APidl: PItemIDList);
var ppszName: PChar;
begin
  FPidl := APidl;
  if Succeeded(SHGetNameFromIDList(FPidl, SIGDN_NORMALDISPLAY, ppszName))
  then begin
    edtFileName.Text := string(ppszName);
    CoTaskMemFree(ppszName);
  end;
  edtFileName.SelectAll;
end;

{ System.IOUtils - TPath }
function IsCharInOrderedArray(const AChar: Char; const AnArray: TCharArray): Boolean;
var
  LeftIdx, RightIdx: Integer;
  MidIdx: Integer;
  MidChar: Char;
begin
  // suppose AChar is not present in AnArray
  Result := False;
  // the code point of AChar is in the range of the chars bounding the string;
  // use divide-et-impera to search AChar in AnArray
  LeftIdx := 0;
  RightIdx := Length(AnArray) - 1;
  if (RightIdx >= 0)
     and (AnArray[LeftIdx] <= AChar)
     and (AChar <= AnArray[RightIdx])
  then repeat
    MidIdx := LeftIdx + (RightIdx - LeftIdx) div 2;
    MidChar := AnArray[MidIdx];
    if AChar < MidChar
    then RightIdx := MidIdx - 1
    else begin
      if AChar > MidChar
      then LeftIdx := MidIdx + 1
      else Result := True;
    end;
  until (Result) or (LeftIdx > RightIdx);
end;

function IsValidFileNameChar(const AChar: Char): Boolean;
begin
  Result := not IsCharInOrderedArray(AChar, FInvalidFileNameChars);
end;

function HasInvalidFileNameCharsFix(var AFileName: string): Boolean;
var pname: PChar;
    len, i, j: Integer;
begin
  pname := PChar(AFileName);
  len := Length(AFileName);
  j := 0;
  for i := 0 to len - 1 do
  begin
    pname[j] := pname[i];
    if IsValidFileNameChar(pname[i])
    then Inc(j);
  end;
  //Assert( (j >= 0) and (j <= len) );
  SetLength(AFileName, j);
  Result := j <> len;
end;

procedure TRenamingWCl.btnOkClick(Sender: TObject);
begin
  if Succeeded(SHRaname(Handle, FPidl, edtFileName.Text))
  then begin
    ModalResult := mrOk;
    CloseModal;
  end
  else edtFileName.SelectAll;
end;

procedure TRenamingWCl.edtFileNameChange(Sender: TObject);
begin
  btnOk.Enabled := Trim(edtFileName.Text) <> '';
end;

procedure TRenamingWCl.edtFileNameKeyPress(Sender: TObject; var Key: Char);
var str: string;
begin
  // Ctrl+V
  if (Key = #$16)
  then begin
    Key := #0;
    str := Clipboard.AsText;
    if HasInvalidFileNameCharsFix(str)
    then ShowBalloonTip(FInvalidFileNameCharsHintText);
    edtFileName.SetSelText(str);
    Exit;
  end;
  // Other Keys
  if not IsValidFileNameChar(Key)
  then begin
    Key := #0;
    ShowBalloonTip(FInvalidFileNameCharsHintText);
  end;
end;

{ Original

function HasValidFileNameChars(const FileName: string): Boolean;
var
  PFileName: PChar;
  FileNameLen: Integer;
  Ch: Char;
  I: Integer;
begin
  // Result will become True if an invalid file name char is found
  I := 0;
  PFileName := PChar(FileName);
  FileNameLen := Length(FileName);
  Result := False;
  while (not Result) and (I < FileNameLen) do
  begin
    Ch := PFileName[I];
    if not IsValidFileNameChar(Ch)
    then Result := True
    else Inc(I);
  end;
  Result := not Result;
end;

procedure TRenamingWCl.edtFileNameKeyPress(Sender: TObject; var Key: Char);
begin
  if (Key = #$16)
  then begin
    if Clipboard.HasFormat(CF_TEXT)
       and HasValidFileNameChars(Clipboard.AsText)
    then Exit;
  end
  else begin
    if IsValidFileNameChar(Key)
    then Exit;
  end;
  Key := #0;
  ShowBalloonTip(FInvalidFileNameCharsHintText);
end; }

procedure TRenamingWCl.ShowBalloonTip(const AText: string);
var ebt: TEditBalloonTip;
begin
  FillChar(ebt, SizeOf(ebt), 0);
  ebt.cbStruct := SizeOf(ebt);
  ebt.pszTitle := nil;
  ebt.pszText := Pointer(AText);
  ebt.ttiIcon := 0;
  Edit_ShowBalloonTip(edtFileName.Handle, ebt);
  MessageBeep(0);
end;

{ Prevent window resizing }
procedure TRenamingWCl.WMNCHitTest(var Message: TWMNCHitTest);
begin
  inherited;
  PreventSizing(Message.Result);
end;

end.
