{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{            Copyright (c) 2010-2021 Asaq               }
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
    rbLocalDir: TRadioButton;
    rbAppDir: TRadioButton;
    rbUserDir: TRadioButton;
    Panel1: TPanel;
    Panel2: TPanel;
    btnCancel: TButton;
    procedure FormCreate(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure btnCreateClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure rbModeClick(Sender: TObject);
    procedure edtWorkDirChange(Sender: TObject);
  private
    FName: string;
    InitiatedUserDir: string;
    InitiatedAppDir: string;
    InitiatedLocalDir: string;
    FWorkinDirectoryPath: string;
    FLocalName: string;                                                         // Name (= folder) of the local bar
    FCaptionName: string;
    FCaptionFolder: string;
    FUpdating: Boolean;
    function GetDefaultLocalName: string;
    procedure UpdateMode;
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

uses Winapi.ShlObj, System.IniFiles, Vcl.Themes, Linkbar.Common,
     Linkbar.Shell, Linkbar.Consts, Linkbar.L10n, Linkbar.Theme, MyHint;

function GetUserNameEx(NameFormat: DWORD; lpBuffer: LPWSTR; var nSize: DWORD): Boolean;
  stdcall; external 'secur32.dll' Name 'GetUserNameExW';

function GetLoggedOnUserName(out AUserName: string): Boolean;
const NameDisplay = 0;
var buf: array[0..MAX_PATH] of Char;
    len: Cardinal;
begin
  buf[0] := #0;
  len := MAX_PATH;
  { GetUserNameEx always return ERROR_NONE_MAPPED = 1332
    "No mapping between account names and security IDs was done" }
  if GetUserNameEx(NameDisplay, buf, len)
  then AUserName := string(buf)
  else begin
    buf[0] := #0;
    len := MAX_PATH;
    if GetUserName(buf, len)
    then AUserName := string(buf)
    else AUserName := '';
  end;
  Result := AUserName <> '';
{$ifdef DEBUG}
  AUserName := 'User Name'
{$endif}
end;

{ Name of a local bar is used as a folder name }
function IsValidBarName(const AName: string): Boolean;
const BAD_CHARS = '\/:*?"<>|';
var i: Integer;
begin
  Result := (AName <> '')
            and (Length(AName) <= 100)
            and (AName[Length(AName)] <> '.');
  if not Result then Exit;
  for i := 1 to Length(AName) do
    if (Pos(AName[i], BAD_CHARS) > 0) or (AName[i] < ' ')
    then Exit(False);
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
  ini: TIniFile;
  filename, cmd, barDir: string;
begin
  if rbLocalDir.Checked
  then begin
    // Portable bar: <application folder>\linkbars\<name>\bar.lbr
    barDir := InitiatedLocalDir + Trim(edtWorkDir.Text) + PathDelim;
    filename := barDir + FN_LOCAL_BAR;
    if FileExists(filename)
    then begin
      MessageDlg(L10NFind('New.Exists', 'A linkbar with this name already exists.'),
        mtWarning, [mbOK], 0);
      Exit;
    end;
    if not ForceDirectories(barDir)
    then begin
      MessageDlg(Format(L10NFind('New.CreateFailed', 'Cannot create the folder: %s'), [barDir]),
        mtError, [mbOK], 0);
      Exit;
    end;
  end;
  if rbAppDir.Checked
  then begin
    ForceDirectories(InitiatedAppDir);
    filename := InitiatedAppDir + FName;
  end;
  if rbUserDir.Checked
  then begin
    ForceDirectories(InitiatedUserDir);
    filename := InitiatedUserDir + FName;
  end;

  ini := TIniFile.Create(filename);
  if rbLocalDir.Checked
  then ini.WriteBool(INI_SECTION_MAIN, INI_LOCAL_BAR, True)
  else ini.WriteString(INI_SECTION_MAIN, INI_DIR_LINKS, FWorkinDirectoryPath);
  ini.Free;

  cmd := LBCreateCommandParam(CLK_FILE, filename);
  if (Locale <> '')
  then cmd := LBCreateCommandParam(CLK_LANG, Locale) + cmd;
  LBCreateProcess(ParamStr(0), cmd);

  Close;
end;

procedure TBarCreatorWCl.L10n;
begin
  L10nControl(Self,       'New.Caption');
  L10nControl(Label1,     'New.ToWhom');
  L10nControl(rbLocalDir, 'New.Local');
  L10nControl(rbAppDir,   'New.ForAll');
  L10nControl(rbUserDir,  'New.ForMe');
  L10nControl(lblWorkDir, 'New.Folder');
  // Label above the edit box has two meanings: folder (all/me) or name (local)
  FCaptionFolder := lblWorkDir.Caption;
  FCaptionName := L10NFind('New.Name', 'Name of the linkbar:');
  L10nControl(btnCreate,  'New.Create');
  L10nControl(btnCancel,  'Button.Cancel');
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

{ First free name: Linkbar, Linkbar 2, Linkbar 3, ... }
function TBarCreatorWCl.GetDefaultLocalName: string;
var i: Integer;
begin
  Result := 'Linkbar';
  i := 1;
  while FileExists(InitiatedLocalDir + Result + PathDelim + FN_LOCAL_BAR)
  do begin
    Inc(i);
    Result := 'Linkbar ' + IntToStr(i);
  end;
end;

{ Switch between local bar (name) and all users / only me (folder) }
procedure TBarCreatorWCl.UpdateMode;
begin
  FUpdating := True;
  try
    if rbLocalDir.Checked
    then begin
      lblWorkDir.Caption := FCaptionName;
      edtWorkDir.Enabled := True;
      edtWorkDir.ReadOnly := False;
      edtWorkDir.TabStop := True;
      edtWorkDir.Color := clWindow;
      edtWorkDir.Text := FLocalName;
      btnSetWorkDir.Visible := False;
      btnCreate.Enabled := IsValidBarName(Trim(FLocalName));
    end
    else begin
      lblWorkDir.Caption := FCaptionFolder;
      edtWorkDir.Enabled := False;
      edtWorkDir.ReadOnly := True;
      edtWorkDir.TabStop := False;
      edtWorkDir.Color := Self.Color;
      edtWorkDir.Text := FWorkinDirectoryPath;
      btnSetWorkDir.Visible := True;
      btnCreate.Enabled := (FWorkinDirectoryPath <> '');
    end;
  finally
    FUpdating := False;
  end;
end;

procedure TBarCreatorWCl.rbModeClick(Sender: TObject);
begin
  UpdateMode;
end;

procedure TBarCreatorWCl.edtWorkDirChange(Sender: TObject);
begin
  if FUpdating or (not rbLocalDir.Checked) then Exit;
  FLocalName := Trim(edtWorkDir.Text);
  btnCreate.Enabled := IsValidBarName(FLocalName);
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
  InitiatedLocalDir := ExtractFilePath(Application.ExeName) + DN_LOCAL_BARS;
  FLocalName := GetDefaultLocalName;

  FName := TGuid.NewGuid.ToString + EXT_LBR;

  Application.HintHidePause := 20000;

  btnCreate.Enabled := False;
  edtWorkDir.Color := Self.Color;

  if GetLoggedOnUserName(username)
  then rbUserDir.Caption := Format(rbUserDir.Caption,[username]);

  Label1.ShowHint := True;
  Label1.Hint := RemovePrefix(rbLocalDir.Caption)
    + sLineBreak + '    ' + InitiatedLocalDir
    + sLineBreak + RemovePrefix(rbAppDir.Caption)
    + sLineBreak + '    ' + InitiatedAppDir
    + sLineBreak + RemovePrefix(rbUserDir.Caption)
    + sLineBreak + '    ' + InitiatedUserDir;

  UpdateMode;
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
  rbLocalDir.Top := Label1.BoundsRect.Bottom + d;
  rbAppDir.Top := rbLocalDir.BoundsRect.Bottom + d;
  rbUserDir.Top := rbAppDir.BoundsRect.Bottom + d;
  lblWorkDir.Font := Label1.Font;
  lblWorkDir.Top := rbUserDir.BoundsRect.Bottom + d;
  edtWorkDir.Top := lblWorkDir.BoundsRect.Bottom + d;
  btnSetWorkDir.Top := edtWorkDir.BoundsRect.Top;
  ClientHeight := btnSetWorkDir.BoundsRect.Bottom + 2*d + Panel1.Height;
end;

{ Prevent window resizing }
procedure TBarCreatorWCl.WMNCHitTest(var Message: TWMNCHitTest);
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
