{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{            Copyright (c) 2010-2017 Asaq               }
{*******************************************************}

unit Linkbar.Newbar;

interface

{$i linkbar.inc}

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ExtCtrls, Vcl.StdCtrls;

type
  TBarCreatorWCl = class(TForm)
    FileOpenDialog_NL: TFileOpenDialog;
    lblWorkDir: TLabel;
    btnSetWorkDir: TButton;
    edtWorkDir: TEdit;
    btnCreate: TButton;
    Label1: TLabel;
    rbAppDir: TRadioButton;
    rbUserDir: TRadioButton;
    Panel1: TPanel;
    Panel2: TPanel;
    btnCancel: TButton;
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure btnCreateClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
  private
    FName: string;
    InitiatedUserDir: string;
    InitiatedAppDir: string;
    FWorkinDirectoryPath: string;
    procedure UpdateThemeStyle;
    function ScaleDimension(const X: Integer): Integer;
    procedure L10n;
  protected
    procedure WMSysColorChanged(var message : TMessage); message WM_SYSCOLORCHANGE;
    procedure WMNCHitTest(var Message: TWMNCHitTest); message WM_NCHITTEST;
  end;

var
  BarCreatorWCl: TBarCreatorWCl;

implementation

{$R *.dfm}

uses ShlObj, System.IniFiles, Vcl.Themes, Linkbar.Common,
     Linkbar.Shell, Linkbar.Consts, Linkbar.L10n, Linkbar.Themes, MyHint;

function GetUserNameEx(NameFormat: DWORD; lpBuffer: LPWSTR; var nSize: DWORD): Boolean;
  stdcall; external 'secur32.dll' Name 'GetUserNameExW';

function GetLoggedOnUserName(out AUserName: String): Boolean;
const NameDisplay = 0;
var buf: array[0..MAX_PATH] of Char;
    len: Cardinal;
begin
  buf[0] := #0;
  len := MAX_PATH;
  { GetUserNameEx always return ERROR_NONE_MAPPED = 1332
    "No mapping between account names and security IDs was done" }
  if GetUserNameEx(NameDisplay, buf, len)
  then AUserName := String(buf)
  else begin
    buf[0] := #0;
    len := MAX_PATH;
    if GetUserName(buf, len)
    then AUserName := String(buf)
    else AUserName := '';
  end;
  Result := AUserName <> '';
end;

function TBarCreatorWCl.ScaleDimension(const X: Integer): Integer;
begin
  Result := MulDiv(X, Self.PixelsPerInch, 96);
end;

procedure TBarCreatorWCl.btnCancelClick(Sender: TObject);
begin
  Close;
end;

procedure TBarCreatorWCl.btnCreateClick(Sender: TObject);
var
  lini: TIniFile;
  lfilename, cmd: string;
begin
  if rbAppDir.Checked
  then begin
    ForceDirectories(InitiatedAppDir);
    lfilename := InitiatedAppDir + FName;
  end;
  if rbUserDir.Checked
  then begin
    ForceDirectories(InitiatedUserDir);
    lfilename := InitiatedUserDir + FName;
  end;

  lini := TIniFile.Create(lfilename);
  lini.WriteString(INI_SECTION_MAIN, INI_DIR_LINKS, FWorkinDirectoryPath);
  lini.Free;

  cmd := LBCreateCommandParam(CLK_FILE, lfilename);
  if (Locale <> '')
  then cmd := LBCreateCommandParam(CLK_LANG, Locale) + cmd;
  LBCreateProcess(ParamStr(0), cmd);

  Close;
end;

procedure TBarCreatorWCl.L10n;
begin
  L10nControl(Self,       'New.Caption');
  L10nControl(Label1,     'New.ToWhom');
  L10nControl(rbAppDir,   'New.ForAll');
  L10nControl(rbUserDir,  'New.ForMe');
  L10nControl(lblWorkDir, 'New.Folder');
  L10nControl(btnCreate,  'New.Create');
  L10nControl(btnCancel,  'New.Cancel');
end;

procedure TBarCreatorWCl.Button1Click(Sender: TObject);
begin
  if FileOpenDialog_NL.Execute
  then begin
    FWorkinDirectoryPath := FileOpenDialog_NL.FileName;
    edtWorkDir.Text := FWorkinDirectoryPath;
    btnCreate.Enabled := True;
  end;
end;

procedure TBarCreatorWCl.FormCreate(Sender: TObject);
var username: string;
begin
  HintWindowClass := TTooltipHintWindow;

  Font.Name := Screen.IconFont.Name;
  L10n;

  ReduceSysMenu(Handle);

  UpdateThemeStyle;

  FileOpenDialog_NL.Title := L10nMui(LB_FN_TOOLBAR, LB_RS_TB_NEWTOOLBAROPENDIALOGTITLE);

  InitiatedAppDir := ExtractFilePath(Application.ExeName) + DN_SHARED_BARS;
  InitiatedUserDir := GetLinkbarRoamingFolderPath + DN_USER_BARS;

  FName := TGuid.NewGuid.ToString + EXT_LBR;

  Application.HintHidePause := 20000;

  btnCreate.Enabled := False;
  edtWorkDir.Color := Self.Color;

  if GetLoggedOnUserName(username)
  then rbUserDir.Caption := Format(rbUserDir.Caption,[username]);

  Label1.ShowHint := True;
  Label1.Hint := RemovePrefix(rbAppDir.Caption)
    + sLineBreak + '    ' + InitiatedAppDir
    + sLineBreak + RemovePrefix(rbUserDir.Caption)
    + sLineBreak + '    ' + InitiatedUserDir;
end;

procedure TBarCreatorWCl.UpdateThemeStyle;
var d: Integer;
begin
  if StyleServices.Enabled
  then begin
    Panel2.Visible := True;
    Self.Color := clWindow;
  end
  else begin
    Panel2.Visible := False;
    Self.Color := clBtnFace;
  end;

  d := ScaleDimension(7);

  Label1.Font := Font;
  GetTitleFont(Label1.Font);
  rbAppDir.Top := Label1.BoundsRect.Bottom + d;
  rbUserDir.Top := rbAppDir.BoundsRect.Bottom + d;
  lblWorkDir.Font := Label1.Font;
  lblWorkDir.Top := rbUserDir.BoundsRect.Bottom + d;
  edtWorkDir.Top := lblWorkDir.BoundsRect.Bottom + d;
  btnSetWorkDir.Top := edtWorkDir.BoundsRect.Top;
  ClientHeight := btnSetWorkDir.BoundsRect.Bottom + 2*d + Panel1.Height;
end;

procedure TBarCreatorWCl.WMNCHitTest(var Message: TWMNCHitTest);
// Disable window resize
begin
  inherited;
  PreventSizing(Message.Result);
end;

procedure TBarCreatorWCl.WMSysColorChanged(var message : TMessage);
begin
  inherited;
  UpdateThemeStyle;
end;

end.
