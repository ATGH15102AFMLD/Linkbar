{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{            Copyright (c) 2010-2018 Asaq               }
{*******************************************************}

unit Linkbar.Settings;

{$i linkbar.inc}

interface

uses System.Types, System.IniFiles, Linkbar.Consts, System.Generics.Collections;

type
  TSettingsFile = record
  private
    FIni: TMemIniFile;
  public
    procedure Open(const FileName: string);
    procedure Close;
    function Read(const Ident, Default: string): string; overload;
    function Read(const Ident: string; Default: Boolean): Boolean; overload;
    function Read(const Ident: string; Default: Integer): Integer; overload;
    function Read(const Ident: string; Default, Min, Max: Integer): Integer; overload;
    function Read<TEnum:record>(const Ident: string; const Default: TEnum): TEnum; overload;
    procedure Write(const Ident, Value: string); overload;
    procedure Write(const Ident: string; Value: Boolean); overload;
    procedure Write(const Ident: string; Value: Integer); overload;
  public
    class function IsValid(const FileName: string): Boolean; static;
    class procedure Write(const FileName, Ident: string; Value: Boolean); overload; static;
    class procedure Write(const FileName, Ident: string; Value: Integer); overload; static;
  end;

implementation

uses System.SysUtils, System.TypInfo, System.Variants, System.Math;

{ Return True if <FileName> is valid = Working direcrory exists }
class function TSettingsFile.IsValid(const FileName: string): Boolean;
var s: TSettingsFile;
begin
  s.Open(FileName);
  Result := DirectoryExists( s.Read(INI_DIR_LINKS, DEF_DIR_LINKS) );
  s.Close;
end;

{ Write Boolean <Value> to settings file <FileName> }
class procedure TSettingsFile.Write(const FileName, Ident: string; Value: Boolean);
var s: TSettingsFile;
begin
  s.Open(FileName);
  s.Write(Ident, Value);
  s.Close;
end;

{ Write Integer <Value> to settings file <FileName> }
class procedure TSettingsFile.Write(const FileName, Ident: string; Value: Integer);
var s: TSettingsFile;
begin
  s.Open(FileName);
  s.Write(Ident, Value);
  s.Close;
end;

{ TSettingsFile }

procedure TSettingsFile.Open(const FileName: string);
begin
  FIni := TMemIniFile.Create(FileName);
  FIni.AutoSave := True;
end;

procedure TSettingsFile.Close;
begin
  if Assigned(FIni)
  then FIni.Free;
end;

function TSettingsFile.Read(const Ident, Default: string): string;
begin
  Result := FIni.ReadString(INI_SECTION_MAIN, Ident, Default);
end;

function TSettingsFile.Read(const Ident: string; Default: Boolean): Boolean;
begin
  Result := FIni.ReadBool(INI_SECTION_MAIN, Ident, Default);
end;

function TSettingsFile.Read(const Ident: string; Default: Integer): Integer;
begin
  Result := FIni.ReadInteger(INI_SECTION_MAIN, Ident, Default);
end;

function TSettingsFile.Read(const Ident: string; Default, Min, Max: Integer): Integer;
begin
  Result := Read(Ident, Default);
  if (Result > Max) or (Result < Min)
  then Result := Default;
end;

{ Read enum }
function TSettingsFile.Read<TEnum>(const Ident: string; const Default: TEnum): TEnum;
var info: PTypeInfo;
    data: PTypeData;
    value: Integer;
    def: Integer;
begin
  info := PTypeInfo(TypeInfo(TEnum));
{$IFDEF DEBUG}
  if (info = nil) or (info^.Kind <> tkEnumeration)
  then raise Exception.Create('Not an enumeration type');
{$ENDIF}
  case Sizeof(TEnum) of
    1: def := PByte(@Default)^;
    2: def := PWord(@Default)^;
    4: def := PCardinal(@Default)^;
  end;
  data := GetTypeData(info);
  value := Read(Ident, def, data^.MinValue, data^.MaxValue);
  case Sizeof(TEnum) of
    1: PByte(@Result)^ := value;
    2: PWord(@Result)^ := value;
    4: PCardinal(@Result)^ := value;
  end;
end;

procedure TSettingsFile.Write(const Ident, Value: string);
begin
  FIni.WriteString(INI_SECTION_MAIN, Ident, Value);
end;

procedure TSettingsFile.Write(const Ident: string; Value: Boolean);
begin
  FIni.WriteBool(INI_SECTION_MAIN, Ident, Value);
end;

procedure TSettingsFile.Write(const Ident: string; Value: Integer);
begin
  FIni.WriteInteger(INI_SECTION_MAIN, Ident, Value);
end;

end.
