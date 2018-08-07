{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{            Copyright (c) 2010-2018 Asaq               }
{*******************************************************}

unit Linkbar.Settings;

interface

uses System.IniFiles;

type
  TSettings = record
  private
    FIni: TMemIniFile;
  public
    procedure Open(const FileName: String);
    procedure Update;
    procedure Close;
    function Read(const Ident, Default: string): string; overload;
    function Read(const Ident: string; Default: Boolean): Boolean; overload;
    function Read(const Ident: string; Default: Integer): Integer; overload;
    function Read(const Ident: string; Default, Min, Max: Integer): Integer; overload;
    function Read<TEnum:record>(const Ident: string; Default: Integer): TEnum; overload;
    procedure Write(const Ident, Value: String); overload;
    procedure Write(const Ident: string; Value: Boolean); overload;
    procedure Write(const Ident: string; Value: Integer); overload;
  public
    class function IsValid(const FileName: String): Boolean; static;
    class procedure Write(const FileName, Ident: string; Value: Boolean); overload; static;
    class procedure Write(const FileName, Ident: string; Value: Integer); overload; static;
  end;

implementation

uses System.SysUtils, System.TypInfo, Linkbar.Consts;

{ Return True if <FileName> is valid = Working direcrory exists }
class function TSettings.IsValid(const FileName: String): Boolean;
var s: TSettings;
begin
  s.Open(FileName);
  Result := DirectoryExists( s.Read(INI_DIR_LINKS, DEF_DIR_LINKS) );
  s.Close;
end;

{ Write Boolean <Value> to settings file <FileName> }
class procedure TSettings.Write(const FileName, Ident: string; Value: Boolean);
var s: TSettings;
begin
  s.Open(FileName);
  s.Write(Ident, Value);
  s.Update;
  s.Close;
end;

{ Write Integer <Value> to settings file <FileName> }
class procedure TSettings.Write(const FileName, Ident: string; Value: Integer);
var s: TSettings;
begin
  s.Open(FileName);
  s.Write(Ident, Value);
  s.Update;
  s.Close;
end;

{ TSettings }

procedure TSettings.Open(const FileName: String);
begin
  FIni := TMemIniFile.Create(FileName);
end;

procedure TSettings.Update;
begin
  FIni.UpdateFile;
end;

procedure TSettings.Close;
begin
  FIni.Free;
end;

function TSettings.Read(const Ident, Default: string): string;
begin
  Result := FIni.ReadString(INI_SECTION_MAIN, Ident, Default);
end;

function TSettings.Read(const Ident: string; Default: Boolean): Boolean;
begin
  Result := FIni.ReadBool(INI_SECTION_MAIN, Ident, Default);
end;

function TSettings.Read(const Ident: string; Default: Integer): Integer;
begin
  Result := FIni.ReadInteger(INI_SECTION_MAIN, Ident, Default);
end;

function TSettings.Read(const Ident: string; Default, Min, Max: Integer): Integer;
begin
  Result := Read(Ident, Default);
  if (Result > Max) or (Result < Min)
  then Result := Default;
end;

{ Read enum }
function TSettings.Read<TEnum>(const Ident: string; Default: Integer): TEnum;
var info: PTypeInfo;
    data: PTypeData;
    value: Integer;
begin
  info := PTypeInfo(TypeInfo(TEnum));
{$IFDEF DEBUG}
  if (info = nil) or (info^.Kind <> tkEnumeration)
  then raise Exception.Create('Not an enumeration type');
{$ENDIF}
  data := GetTypeData(info);
  value := Read(Ident, Default, data^.MinValue, data^.MaxValue);
  case Sizeof(TEnum) of
    1: PByte(@Result)^ := value;
    2: PWord(@Result)^ := value;
    4: PCardinal(@Result)^ := value;
  end;
end;

procedure TSettings.Write(const Ident, Value: String);
begin
  FIni.WriteString(INI_SECTION_MAIN, Ident, Value);
end;

procedure TSettings.Write(const Ident: string; Value: Boolean);
begin
  FIni.WriteBool(INI_SECTION_MAIN, Ident, Value);
end;

procedure TSettings.Write(const Ident: string; Value: Integer);
begin
  FIni.WriteInteger(INI_SECTION_MAIN, Ident, Value);
end;

end.
