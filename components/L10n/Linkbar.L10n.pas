{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{            Copyright (c) 2010-2018 Asaq               }
{*******************************************************}

unit Linkbar.L10n;

{$i linkbar.inc}

interface

uses
  Winapi.Windows, System.Classes, Vcl.StdCtrls, Vcl.ComCtrls, Vcl.Menus, Vcl.Forms;

const
  // MUI

  // New shortcut file name
  // shell32.dll.mui - String table - ?
  LB_FN_NEWSHORTCUT  = 'shell32.dll';
	LB_RS_NSC_FILENAME = 30397;

  // Autohide fail message
  // explorerframe.dll.mui
  LB_FN_TOOLBAR = 'explorerframe.dll';
  LB_RS_TB_AUTOHIDEALREADYEXISTS     = 28676;
  LB_RS_TB_NEWTOOLBAROPENDIALOGTITLE = 12387;

  // Invalid file name symbols
  // shell32.dll.mui - String table - 257, 793
  LB_FN_INVALIDFILENAMECHARS = 'shell32.dll';
  LB_RS_IFNC_HINT = 4109;

  // Rename dialog need file name message
  LB_FN_NEEDFILENAME = 'shell32.dll';
  LB_RS_NFN_CUE = 4123;


  procedure L10nLoad(const APath: string; const AForcedLocale: string = '');
  function  L10NFind(const AName: string; const ADefault: string = ''): string;
  function  L10nMui(const AModuleName: String; const AStringID: Cardinal): String; overload;
  function  L10nMui(const AModule: HINST; const AStringID: Cardinal): String; overload;
  procedure L10nControl(AControl: TForm;        const AName: String); overload;
  procedure L10nControl(AControl: TMenuItem;    const AName: String); overload;
  procedure L10nControl(AControl: TLabel;       const AName: String); overload;
  procedure L10nControl(AControl: TCheckbox;    const AName: String); overload;
  procedure L10nControl(AControl: TRadioButton; const AName: String); overload;
  procedure L10nControl(AControl: TButton;      const AName: String); overload;
  procedure L10nControl(AControl: TTabSheet;    const AName: String); overload;
  procedure L10nControl(AControl: TComboBox;    const ANames: array of String); overload;

var
  Locale: string = '';

implementation

 uses
  System.SysUtils, System.Types, System.StrUtils, System.Generics.Collections;

type
  TTranslations = class
  private
    type TTr = TDictionary<string, string>;
  private
    class var tr: TTr;
    class destructor Destroy;
  public
    constructor Create;
    destructor Destroy; override;
    procedure LoadFromFile(const AFileName, ALocaleName: string);
    procedure LoadFromPath(const APath, ALocales: string);
    function Find(const AName: string; ADefault: string = ''): string;
    procedure Clear;
  end;

{ Return localized string by ModuleInstance and StringID }
function L10nMui(const AModule: HINST; const AStringID: Cardinal): String;
var p: PChar;
begin
  if (AModule <> 0)
     and (AStringID < 65536)
  then SetString(Result, p, LoadString(AModule, AStringID, @p, 0))
  else Result := 'resource_string_not_found';
end;

{ Return localized string by ModuleName and StringID }
function L10nMui(const AModuleName: String; const AStringID: Cardinal): String;
var h: THandle;
begin
  h := LoadLibraryEx(PChar(AModuleName), 0, LOAD_LIBRARY_AS_DATAFILE);
  Result := L10nMui(h, AStringID);
  if (h <> 0)
  then FreeLibrary(h);
end;

procedure L10nControl(AControl: TForm; const AName: String); overload;
begin
  AControl.Caption := L10NFind(AName, AControl.Caption);
end;

procedure L10nControl(AControl: TMenuItem; const AName: String); overload;
begin
  AControl.Caption := L10NFind(AName, AControl.Caption);
end;

procedure L10nControl(AControl: TLabel; const AName: String); overload;
begin
  AControl.Caption := L10NFind(AName, AControl.Caption);
end;

procedure L10nControl(AControl: TCheckbox; const AName: String); overload;
begin
  AControl.Caption := L10NFind(AName, AControl.Caption);
end;

procedure L10nControl(AControl: TRadioButton; const AName: String); overload;
begin
  AControl.Caption := L10NFind(AName, AControl.Caption);
end;

procedure L10nControl(AControl: TButton; const AName: String); overload;
begin
  AControl.Caption := L10NFind(AName, AControl.Caption);
end;

procedure L10nControl(AControl: TTabSheet; const AName: String); overload;
begin
  AControl.Caption := L10NFind(AName, AControl.Caption);
end;

procedure L10nControl(AControl: TComboBox; const ANames: array of String); overload;
var i: Integer;
begin
{$IFDEF DEBUG}
  Assert(AControl.Items.Count = Length(ANames));
{$ENDIF}
  for i := 0 to AControl.Items.Count-1 do
  begin
    AControl.Items[i] := L10NFind(ANames[i], AControl.Items[i]);
  end;
end;

var FTranslations: TTranslations;

function Translations: TTranslations;
begin
  if (FTranslations = nil)
  then FTranslations := TTranslations.Create;
  Result := FTranslations;
end;

{ TTranslations }

constructor TTranslations.Create;
begin
  tr := TTr.Create(78);
end;

destructor TTranslations.Destroy;
begin
  tr.Free;
  inherited;
end;

class destructor TTranslations.Destroy;
begin
  FreeAndNil(FTranslations);
end;

procedure TTranslations.LoadFromFile(const AFileName, ALocaleName: string);
var list: TStringList;
    i, ii, j: Integer;
    s, key, value: string;
begin
  list := TStringList.Create;
  try
    list.LoadFromFile(AFileName);
    // Find section
    ii := list.Count;
    for i := 0 to list.Count-1 do
    begin
      s := Copy(list[i], 2, Length(ALocaleName));
      if SameText(s, ALocaleName)
      then begin
        ii := i + 1;
        Break;
      end;
    end;

    // Read translations
    for i := ii to list.Count-1 do
    begin
      s := list[i];

      if (Length(s) = 0) or (s[1] = '[')
      then Break;

      j := Pos('=', s, 1);
      if (j > 1)
      then begin
        key := LowerCase( Trim( Copy(s, 1, j - 1) ) );
        value := TrimLeft( Copy(s, j + 1, Length(s)) );
        if (key <> '')
           and (value <> '')
        then tr.AddOrSetValue(key, value);
      end;
    end;
  finally
    list.Free;
  end;
end;

procedure TTranslations.LoadFromPath(const APath, ALocales: string);
var sda: TStringDynArray;
    i: Integer;
    fn: string;
begin
  sda := SplitString(ALocales, ',');
  for i := Length(sda)-1 downto 0 do
  begin
    fn := APath + sda[i] + '.ini';
    if FileExists(fn)
    then Self.LoadFromFile(fn, sda[i]);
  end;
end;

procedure TTranslations.Clear;
begin
  tr.Clear;
end;

function TTranslations.Find(const AName: string; ADefault: string): string;
begin
  if not tr.TryGetValue(LowerCase(AName), Result)
  then begin
    Result := ADefault;
  {$IFDEF DEBUG}
    MessageBox(0, PChar(Format('Key not found: "%s"'#13'Default value: "%s"', [AName, ADefault])),
      PChar('Linkbar - L10n'), MB_OK or MB_ICONEXCLAMATION);
  {$ENDIF}
  end;
end;

function GetLocaleNameFromLocaleID(ID: TLocaleID): string;
var i: Integer;
begin
  Result := '';
  i := Languages.IndexOf(ID);
  if (i <> - 1)
  then Result := Languages.LocaleName[i];
end;

procedure L10nLoad(const APath: string; const AForcedLocale: string = '');
var languages: string;
    localeId: Integer;
begin
  Translations.Clear;
  Locale := AForcedLocale;

  if (Locale = '')
  then languages := PreferredUILanguages
  else begin
    // Convert to LocaleName if needed
    localeId := StrToIntDef(Locale, -1);
    if (localeId = -1)
    then languages := Locale
    else languages := GetLocaleNameFromLocaleID(localeId);
  end;

  Translations.LoadFromPath(APath, languages);
end;

function L10NFind(const AName: string; const ADefault: string = ''): string;
begin
  Result := Translations.Find(AName, ADefault);
  // Prevent exception in Format()
  if (Pos('%s', ADefault) > 0)
     and (Pos('%s', AnsiLowerCase(Result)) = 0)
  then Result := ADefault;
end;

end.