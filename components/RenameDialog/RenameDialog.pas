{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{            Copyright (c) 2010-2017 Asaq               }
{*******************************************************}

unit RenameDialog;

{$i linkbar.inc}

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, Vcl.Controls, Vcl.Forms,
  Vcl.StdCtrls, Winapi.CommCtrl, WinApi.Messages, Winapi.ShlObj, Winapi.ActiveX;

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
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure WMNCHitTest(var Message: TWMNCHitTest); message WM_NCHITTEST;
  public
    property Pidl: PItemIDList write SetPidl;
  end;

implementation

{$R *.dfm}

uses Vcl.Clipbrd, Linkbar.Loc, Linkbar.Shell, Linkbar.Common;

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

procedure TRenamingWCl.FormCreate(Sender: TObject);
var cue: String;
begin
  Font.Name := Screen.IconFont.Name;
  LbTranslateComponent(Self);

  ReduceSysMenu(Handle);

  edtFileName.MaxLength := MAX_PATH;

  FInvalidFileNameChars := TCharArray.Create('"', '*', '/', ':', '<', '>', '?', '\', '|');
  FInvalidFileNameCharsHintText :=
    MUILoadResString(GetModuleHandle(LB_FN_INVALIDFILENAMECHARS), LB_RS_IFNC_HINT);

  cue := MUILoadResString(GetModuleHandle(LB_FN_NEEDFILENAME), LB_RS_NFN_CUE);
  f_Edit_SetCueBannerText(edtFileName.Handle, PChar(cue));

  btnOk.ModalResult := mrNone;
end;

procedure TRenamingWCl.SetPidl(APidl: PItemIDList);
var ppszName: PChar;
begin
  FPidl := APidl;
  if Succeeded(SHGetNameFromIDList(FPidl, SIGDN_NORMALDISPLAY, ppszName))
  then begin
    edtFileName.Text := String(ppszName);
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
  if (RightIdx >= 0) and (AnArray[LeftIdx] <= AChar) and (AChar <= AnArray[RightIdx]) then
    repeat
      MidIdx := LeftIdx + (RightIdx - LeftIdx) div 2;
      MidChar := AnArray[MidIdx];
      if AChar < MidChar then
        RightIdx := MidIdx - 1
      else
        if AChar > MidChar then
          LeftIdx := MidIdx + 1
        else
          Result := True;
    until (Result) or (LeftIdx > RightIdx);
end;

function IsValidFileNameChar(const AChar: Char): Boolean;
begin
  Result := not IsCharInOrderedArray(AChar, FInvalidFileNameChars);
end;

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
  btnOk.Enabled := (Trim(edtFileName.Text) <> '');
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
    if not IsCharInOrderedArray(Key, FInvalidFileNameChars)
    then Exit;
  end;
  Key := #0;
  ShowBalloonTip(FInvalidFileNameCharsHintText);
end;

procedure TRenamingWCl.ShowBalloonTip(const AText: String);
var ebt: TEditBalloonTip;
begin
  ebt.cbStruct := SizeOf(ebt);
  ebt.pszTitle := nil;
  ebt.pszText := Pointer(AText);
  ebt.ttiIcon := 0;
  Edit_ShowBalloonTip(edtFileName.Handle, ebt);
  MessageBeep(0);
end;

procedure TRenamingWCl.WMNCHitTest(var Message: TWMNCHitTest);
// Disable window resize
begin
  inherited;
  PreventSizing(Message.Result);
end;

end.
