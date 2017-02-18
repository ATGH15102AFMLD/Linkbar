{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{            Copyright (c) 2010-2017 Asaq               }
{*******************************************************}

unit Linkbar.Loc;

{$i linkbar.inc}

interface

uses Windows, SysUtils, Classes, LcUnitXe;

const
  // explorerframe.dll.mui
  LB_FN_TOOLBAR = 'explorerframe.dll';
  LB_RS_TB_AUTOHIDEALREADYEXISTS     = 28676;
  LB_RS_TB_NEWTOOLBAROPENDIALOGTITLE = 12387;

  // New shortcut
  // shell32.dll.mui - String table - ?
  LB_FN_NEWSHORTCUT  = 'shell32.dll';
	LB_RS_NSC_FILENAME = 30397;

  // Jumplists
  // explorer.exe.mui - String table - 21
  LB_FN_JUMPLIST    = 'explorer.exe';
  LB_RS_JL_PINNED   = 326;
  LB_RS_JL_RECENT   = 327;
  LB_RS_JL_FREQUENT = 328;
  LB_RS_JL_TASKS    = 329;
  LB_RS_JL_UNPIN    = 330;   // En: Unpin from this list
  LB_RS_JL_PIN      = 331;   // En: Pin to this list
  LB_RS_JL_REMOVE   = 8225;  // En: Remove from this list

  // Invalid file name symbols
  // shell32.dll.mui - String table - 257, 793
  LB_FN_INVALIDFILENAMECHARS = 'shell32.dll';
  LB_RS_IFNC_HINT = 4109;

  // Rename dialog need file name
  LB_FN_NEEDFILENAME = 'shell32.dll';
  LB_RS_NFN_CUE = 4123;
  // and "Open"
  LB_RS_JL_OPEN     = 12850;

  function MUILoadResString(const AModuleName: String; const AStringID: Cardinal): String; overload;
  function MUILoadResString(const AModule: HINST; const AStringID: Cardinal): String; overload;

  function LbTranslateInit(ALCID: LCID): Integer;
  function LbTranslateComponent(AComponent: TComponent): Boolean;
  function LbLongLang: Boolean;

var
  LbLangID: LCID = 0;

implementation

uses Linkbar.Consts;

function MUILoadResString(const AModule: HINST; const AStringID: Cardinal): String;
var p: PChar;
begin
  if (AModule <> 0) and (AStringID < 65536)
  then SetString(Result, p, LoadString(AModule, AStringID, @p, 0))
  else Result := 'resource_string_not_found';
end;

function MUILoadResString(const AModuleName: String; const AStringID: Cardinal): String;
var h: THandle;
begin
  h := LoadLibraryEx(PChar(AModuleName), 0, LOAD_LIBRARY_AS_DATAFILE);
  Result := MUILoadResString(h, AStringID);
  if (h <> 0)
  then FreeLibrary(h);
end;

function LCIDTo36LanguageID(ALCID: LCID): LCID;
begin
  if (ALCID = 0)
  then ALCID := TLanguages.UserDefaultLocale;
  case Lo(ALCID) of
    LANG_ENGLISH : Result := $0409;  // English   (US)
    LANG_FRENCH  : Result := $040C;  // French
    LANG_JAPANESE: Result := $0411;  // Japanese
    LANG_RUSSIAN : Result := $0419;  // Russian
    LANG_GERMAN  : Result := $0407;  // German    (Germany)
    else Result := ALCID;  // Use default language English-US
  end;
end;

function LbTranslateInit(ALCID: LCID): Integer;
begin
  LbLangID := LCIDTo36LanguageID(ALCID);
  Result := LcUnitXe.LoadLcf( ExtractFilePath(ParamStr(0)) + FN_LOCALIZATION, LbLangID, nil, nil );
end;

function LbTranslateComponent(AComponent: TComponent): Boolean;
begin
  Result := LcUnitXe.TranslateComponent(AComponent);
end;

function LbLongLang: Boolean;
begin
  Result := (LbLangID = $040C);
end;

end.
