{* DelLocXe. LcUnitXe.pas. Serge Gavrilov ( C ) 2005-2012 *************************************** *}

unit LcUnitXE;

{
  DelLocXE (Delphi localization compiler for Xe) for Delphi XE. Interface unit.

  All right reserved. Serge Gavrilov (C) 2005-2012.

  e-mail: s.gav@mail.ru
  icq: 777807
  http://delloc.narod.ru/en.html


  To localize your delphi program You have to make next simple things:
  1. Create with DelLoc the localization file that will
     include translations of the resourcestrings and translations of the form's
     and component's string properties.
  2. Include unit LcUnitXe.pas in your project or make it available in search
     pathes.
  3. In project source: after loading application call function LoadLcf() where
     pass as parameters localization file name and locale identificator (LCID)
     that will be used to translate. You may place the call of LoadLcf() in
     project source file after "begin" keyword or in the initialization section
     of the any project unit.
  4. After creating form which interface and components need to be translatad
     call function TranslateComponent() and pass as parameter the created form.
     You may place call at the body of the overrided constructor after
     "inherited" keyword or in the OnCreate event handler. If you inherites
     all project forms from one base form class you may provide call of the
     TranslateComponent() only for the base form class.

  Unit LcUnitXe.pas includes declaration of the two functions: LoadLcf() and
  TranslateComponent(), and declare one type: TLcCallBack.

  Function LoadLcf() loads localization file and activates translation for
  the passed locale identificator.

    function LoadLcf(
        const sFileName : nstr;
        iLCID : LCID;
        pCallBack : TLcCallBack;
        pUd : pointer
      ) : integer;

  Parameters:
    sFileName - localization file name;
    iLCID - locale identificator to activate. Use Delphi's class TLanguages
            to inspect all available locale identificators and its string
            descriptions.
    pCallBack - pointer to callback function of type TLcCallBack. If this
                parameter is not null then the callback function will be called
                for each locale identificator supported by the localization
                file.
    pUd - used difened pointer. Will be passed as parameter to the callback
          function pCallBack.

  Result:
    1 - localization file was loaded and translation for requeted locale
        was activated;
    0 - localization file was loaded but translation for requeted locale is
        not present in the localization file. Translation will not be make.
    <0 - localization file error loading. Translation will not be make.

  Function TranslateComponent() translate the interface and form's
  components string propertied.

    function TranslateComponent(
        oComponent : TComponent
      ) : boolean;

  Parameters:
    oComponent - Form which interface and components will be localized.
  Result:
    true - localization success;
    false - localization error.

  The type TLcCallBack is a prototype of the callback function which pointer is
  passed into LoadLcf() as parameter. The callback function will be called
  for each locale identificator supported by the localization file.

    type
      TLcCallBack = function(
                        iLCID : integer;
                        pUd : pointer
                      ) : integer; stdcall;

  Parameters:
    iLCID - locale identificator supported in localization file;
    pUd - user defined pointer passed into LoadLcf() as parameter.
  Result:
    0 - stop calling callback for the next locale ids;
    <>0 - continue the callback calls for the next locale ids.

  To switch the langauges at runtime You may use next code:

    var
      i : integer;
    begin
      for i := 0 to Screen.FormCount - 1
      do  TranslateComponent( Screen.Forms[ i ] );
    end;


  THIS UNIT IS DISTRIBUTED "AS IS". NO WARRANTY OF ANY KIND IS EXPRESSED
  OR IMPLIED. YOU USE AT YOUR OWN RISK. THE AUTHOR WILL NOT BE LIABLE
  FOR DATA LOSS, DAMAGES, LOSS OF PROFITS OR ANY OTHER KIND OF LOSS
  WHILE USING OR MISUSING THIS SOFTWARE.

}

interface

uses
  SysUtils, Windows, Classes, StrUtils, TypInfo;

type

  str = AnsiString;
  nstr = string;
  nchr = Char;
  chr = AnsiChar;
  wstr = WideString;
  pchr = PAnsiChar;
  wchr = WideChar;
  pwchr = PWideChar;
  pnchr = PChar;

  TLcCallBack = function( iLCID : integer; pUd : pointer ) : integer; stdcall;
  TLcOnGetRes = function(
    const sResStr : wstr;
    var iLCID : integer;
    var iCPage : integer;
    pUd : pointer ) : integer; stdcall;

  TPLcLoadOpts = ^TLcLoadOpts;
  TLcLoadOpts = record
    iSize : integer;
    iLCID : LCID;
    pCallBack : TLcCallBack;
    pOnGetResStr : TLcOnGetRes;
    pUd : pointer;
  end;

function LoadLcf(
    const sFileName : nstr;
    iLCID : LCID;
    pCallBack : TLcCallBack;
    pUd : pointer
  ) : integer;

function LoadLcfEx(
    const sFileName : nstr;
    pOpts : TPLcLoadOpts
  ) : integer;

function TranslateComponent( oComponent : TComponent ) : boolean;
function TranslateComponentEx(
  oComponent : TComponent;
  iLCID : LCID ) : boolean;



implementation

{* ************************************************************************** *}

const
  LC_OPT_PROJINFO = 1;
  LC_SIGNATURE = 'LCHEADER';
  LC_HEADE3_RESID = 'LCHEADE3';

type

{* ************************************************************************** *}

  TLcHeaderRec = packed record
    aSign : packed array[ 0..Length( LC_SIGNATURE ) - 1 ] of chr;
    iOpts : integer;
    iLCIDCount : integer;
  end;
  TPLcHeaderRec = ^TLcHeaderRec;

{* ************************************************************************** *}

  TLcHeaderResRec = packed record
    rHeader : TLcHeaderRec;
    aLCID : packed array[ 0..0 ] of LCID;
  end;
  TPLcHeaderResRec = ^TLcHeaderResRec;

{* ************************************************************************** *}

  TLcCPages = packed array[ 0..0 ] of UINT;
  TPLcCPages = ^TLcCPages;

{* ************************************************************************** *}

  TLcResItemStr = packed record
    iOffset : integer;
    iLength : integer;
  end;
  TLcResItemRec = packed array[ 0..0 ] of TLcResItemStr;
  TPLcResItemRec = ^TLcResItemRec;

{* ************************************************************************** *}

type

  TProc = class
  private
    aOriginal : packed array[ 0..4 ] of byte;
    pOldProc, pNewProc : pointer;
    pPosition : PByteArray;
  public
    constructor Create( pOldProc, pNewProc : pointer );
    destructor Destroy; override;
  end;

{* ************************************************************************** *}

  TLcf = class
  private
    iLangIndex : integer;
    iPropLangIndex : integer;
    iLibHandle : THANDLE;
    iLCID : LCID;
    iCPage : UINT;
    aProc : array[ 0..0 ] of TProc;
    pUd : pointer;
    pOnGetResStr : TLcOnGetRes;
    pHeader : TPLcHeaderResRec;
    isOldFormat : boolean;
  public
    constructor Create;
    destructor Destroy; override;
    function LoadLib( szFileName : PChar; iLCID : LCID;
      pCallBack : TLcCallBack; pOnGetResStr : TLcOnGetRes;
        pUd : pointer ) : integer;
    function LoadLibEx( szFileName : PChar; pOpts : TPLcLoadOpts ) : integer;
    function GetResString( pResStrRec : PResStringRec ) : nstr;
    function TranslateComponent(
      oComponent : TComponent;
      iLCID : LCID ) : boolean;
    procedure RegProcs( pN1, pO1 : pointer );
    function GetLangIndex( iLCID : LCID;
      pLangIndex : pinteger;
      pPropLangIndex : pinteger;
      var iCPage : UINT ) : boolean;
  end;

{* ************************************************************************** *}

var

  _oLcf : TLcf = nil;

{* ************************************************************************** *}

{* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ *}
constructor TProc.Create;
var
  iOffset : integer;
  iMemProtect : cardinal;
  i : integer;
begin
  Self.pOldProc := pOldProc;
  Self.pNewProc := pNewProc;

  pPosition := pOldProc;
  iOffset := integer( pNewProc ) - integer( pointer( pPosition ) ) - 5;

  for i := 0 to 4 do aOriginal[ i ] := pPosition^[ i ];

  if not VirtualProtect( pointer( pPosition ), 5, PAGE_EXECUTE_READWRITE, @iMemProtect )
  then  RaiseLastOsError;

  pPosition^[ 0 ] := $E9;
  pPosition^[ 1 ] := byte( iOffset );
  pPosition^[ 2 ] := byte( iOffset shr 8 );
  pPosition^[ 3 ] := byte( iOffset shr 16 );
  pPosition^[ 4 ] := byte( iOffset shr 24 );

end;
{* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ *}
destructor TProc.Destroy;
var
  i : integer;
begin
  for i := 0 to 4 do pPosition^[ i ] := aOriginal[ i ];
  inherited;
end;
{* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ *}

{* ************************************************************************** *}

{* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ *}
constructor TLcf.Create;
begin
  _oLcf := Self;
end;
{* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ *}
destructor TLcf.Destroy;
var
  i : integer;
begin
  _oLcf := nil;
  for i := Low( aProc ) to High( aProc ) do aProc[ i ].Free;
  if iLibHandle <> 0 then FreeLibrary( iLibHandle );
  inherited;
end;
{* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ *}
function LCIDToCodePage( iLCID : LCID ) : UINT;
var
  iResultCode : integer;
  p : array[ 0..6 ] of nchr;
begin
  GetLocaleInfo( iLCID, LOCALE_IDEFAULTANSICODEPAGE, p, Length( p ) );
  Val( p, result, iResultCode );
  if iResultCode <> 0 then result := CP_ACP;
end;
{* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ *}
function TLcf.GetLangIndex;
var
  i : integer;
  pPages : TPLcCPages;
begin

  result := false;
  if pHeader = nil then exit;

  if iLCID = Self.iLCID
  then  begin
        if pLangIndex <> nil then pLangIndex^ := Self.iLangIndex;
        if pPropLangIndex <> nil then pPropLangIndex^ := Self.iPropLangIndex;
        iCPage := Self.iCPage;
        result := true;
        exit;
        end;

  for i := 0 to pHeader^.rHeader.iLCIDCount - 1
  do  if pHeader^.aLCID[ i ] = iLCID
      then  begin
            result := true;
            if pLangIndex <> nil
            then  begin
                  pLangIndex^ := i;
                  if ( pHeader^.rHeader.iOpts and LC_OPT_PROJINFO ) <> 0
                  then  Inc( pLangIndex^ );
                  end;
            if pPropLangIndex <> nil then pPropLangIndex^ := i;
            if not isOldFormat
            then  begin
                  pPages := pointer( integer( pHeader ) +
                    sizeof( TLcHeaderRec ) +
                      pHeader^.rHeader.iLCIDCount * sizeof( LCID ) );
                  iCPage := pPages^[ i ];
                  end
            else  iCPage := LCIDToCodePage( iLCID );
            exit;
            end;
end;
{* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ *}
function TLcf.LoadLib;
var
  iRes : HRSRC;
  iGlobal : HGLOBAL;
  i : integer;
  s : str;
begin
  result := -1;
  iLibHandle := LoadLibraryEx( szFileName, 0,
    LOAD_LIBRARY_AS_DATAFILE or DONT_RESOLVE_DLL_REFERENCES );
  if iLibHandle = 0 then exit;
  Self.pUd := pUd;
  Self.pOnGetResStr := pOnGetResStr;
  isOldFormat := true;
  iRes := FindResource( iLibHandle, LC_HEADE3_RESID, RT_RCDATA );
  if iRes = 0 then exit;

  iGlobal := LoadResource( iLibHandle, iRes );
  if iGlobal = 0 then exit;
  if SizeOfResource( iLibHandle, iRes ) < sizeof( TLcHeaderRec ) then exit;
  pHeader := pointer( iGlobal );
  s := LC_SIGNATURE;
  if not CompareMem( @pHeader^.rHeader.aSign[ 0 ], @s[ 1 ], Length( s ) )
  then  begin
        pHeader := nil;
        exit;
        end;
  result := 0;
  if Assigned( pCallBack )
  then  for i := 0 to pHeader^.rHeader.iLCIDCount - 1
        do  if pCallBack( pHeader^.aLCID[ i ], pUd ) = 0 then break;
  if not GetLangIndex( iLCID, @iLangIndex, @iPropLangIndex, iCPage ) then exit;
  Self.iLCID := iLCID;
  result := 1;
end;
{* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ *}
function TLcf.LoadLibEx;
begin
  result := -1;
  if ( pOpts = nil ) or ( pOpts^.iSize <> sizeof( pOpts^ ) ) then exit;
  result := LoadLib( szFileName, pOpts^.iLCID, pOpts^.pCallBack, pOpts^.pOnGetResStr, pOpts^.pUd );
end;
{* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ *}
function TLcf.GetResString;
var
  iDefLen : integer;
  wBuffer : array [ 0..1023 ] of wchr;
  iPrefix : integer;
  iLCID : integer;
  iCPage : UINT;
  iLangIndex : integer;
  iChangedCPage : integer;

  iRes : HRSRC;
  iGlobal : HGLOBAL;
  pResItem : TPLcResItemRec;
  wString : wstr;

  procedure GetDefault;
  begin
    if iDefLen > 0 then exit;
    iDefLen := LoadStringW(
      FindResourceHInstance( pResStrRec.Module^ ),
      pResStrRec.Identifier,
      wBuffer,
      SizeOf( wBuffer ) div SizeOf( wBuffer[ 0 ] ) );
  end;

begin
  iDefLen := 0;
  iPrefix := 0;

  iLCID := Self.iLCID;
  iChangedCPage := 0;

  if Assigned( pOnGetResStr )
  then  begin
        GetDefault;
        if iDefLen > 0
        then  iPrefix := pOnGetResStr( PWideChar( @wBuffer ), iLCID, iChangedCPage, pUd );
        end;

  if not GetLangIndex( iLCID, @iLangIndex, nil, iCPage )
  then  iLCID := 0
  else  if iChangedCPage <> 0 then iCPage := iChangedCPage;

  if iLCID <> 0
  then  begin
        iRes := FindResource( iLibHandle,
                              MAKEINTRESOURCE( IntToStr( pResStrRec^.Identifier ) ), RT_RCDATA );
        if iRes <> 0
        then  begin
              iGlobal := LoadResource( iLibHandle, iRes );
              if iGlobal <> 0
              then  begin
                    pResItem := pointer( iGlobal );
                    if pResItem^[ iLangIndex ].iLength >= 0
                    then  begin
                          SetLength( wString,
                            pResItem^[ iLangIndex ].iLength shr 1 );
                          Move(
                            PByteArray( pResItem )^
                              [ pResItem^[ iLangIndex ].iOffset ],
                            pointer( wString )^,
                              pResItem^[ iLangIndex ].iLength );
                          result := wString;
                          exit;
                          end;
                    end;
              end;
        end;

  GetDefault;
  if iDefLen > 0
  then  begin
        result := pwchr( @wBuffer );
        if iPrefix > 0 then Delete( result, 1, iPrefix );
        end
  else  result := '';
end;
{* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ *}
procedure TLcf.RegProcs;
begin
  if Assigned( pO1 ) and Assigned( pN1 )
  then aProc[ 0 ] := TProc.Create( pO1, pN1 );
end;
{* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ *}

{* ************************************************************************** *}

{* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ *}
function NewLoadResString( ResStringRec : PResStringRec ) : nstr;
const
  MAX_ID = 64 * 1024;
begin
  if ResStringRec = nil then exit;
  if ResStringRec.Identifier >= MAX_ID
  then  result := pnchr( ResStringRec.Identifier )
  else  result := _oLcf.GetResString( ResStringRec );
end;
{* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ *}
function LoadLcf;
begin
  _oLcf.Free;
  _oLcf := TLcf.Create;
  result := _oLcf.LoadLib( PChar( sFileName ), iLCID, pCallBack, nil, pUd );
  if result < 1
  then  begin
        _oLcf.Free; _oLcf := nil;
        exit;
        end;
  _oLcf.RegProcs( @NewLoadResString, @System.LoadResString );
end;
{* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ *}
function LoadLcfEx;
begin
  _oLcf.Free;
  _oLcf := TLcf.Create;
  result := _oLcf.LoadLibEx( pwchr( sFileName ), pOpts );
  if result < 1
  then  begin
        _oLcf.Free; _oLcf := nil;
        exit;
        end;
  _oLcf.RegProcs( @NewLoadResString, @System.LoadResString );
end;
{* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ *}
function TranslateComponent;
begin
  result := false;
  if _oLcf = nil then exit;
  result := _oLcf.TranslateComponent( oComponent, _oLcf.iLCID );
end;
{* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ *}
function TranslateComponentEx;
begin
  result := false;
  if _oLcf = nil then exit;
  result := _oLcf.TranslateComponent( oComponent, iLCID );
end;
{* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ *}

{* ************************************************************************** *}

type

  TProp = class
  private
    oLcf : TLcf;
    sCompName : nstr;
    sPropName : nstr;
    wTranslation : wstr;
    isTranslated : boolean;
  public
    function LoadFromResource( iLangIndex : integer; pRes : PByteArray ) : boolean;
    procedure Translate( iCPage : UINT; oComponent : TComponent );
  end;

{* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ *}

  TProps = class
  private
    oLcf : TLcf;
    oComponent : TComponent;
    oItems : TList;
  public
    constructor Create;
    destructor Destroy; override;
    function LoadFromResource( iLangIndex : integer ) : boolean; overload;
    function LoadFromResource( iLangIndex : integer;
      oClassType : TClass ) : boolean; overload;
  end;

{* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ *}
function TextToChar( const s : nstr; c : nchr; var iPos : integer ) : nstr;
var
  iNextPos : integer;
begin
  iNextPos := PosEx( c, s, iPos );
  if iNextPos = 0
  then  result := Copy( s, iPos, Length( s ) - iPos + 1 )
  else  begin
        result := Copy( s, iPos, iNextPos - iPos );
        Inc( iNextPos );
        if iNextPos > Length( s ) then iNextPos := 0;
        end;
  iPos := iNextPos;
end;
{* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ *}
function TProp.LoadFromResource;
var
  sFullName : nstr;
  pBytes : PByteArray;
  iPos : integer;
  iLength : integer;
  iOffset : integer;
begin
  SetLength( sFullName, TPLcResItemRec( pRes )^[ 0 ].iLength div sizeof( wchr ) );
  pBytes := pRes;
  Move( pBytes^[ TPLcResItemRec( pRes )^[ 0 ].iOffset ],
        sFullName[ 1 ],
        TPLcResItemRec( pRes )^[ 0 ].iLength );
  iPos := 1;
  sCompName := TextToChar( sFullName, '-', iPos );
  sPropName := TextToChar( sFullName, '-', iPos );
  iLength := TPLcResItemRec( pRes )^[ iLangIndex + 1 ].iLength;
  iOffset := TPLcResItemRec( pRes )^[ iLangIndex + 1 ].iOffset;
  isTranslated := iLength >= 0;
  if isTranslated
  then  begin
        SetLength( wTranslation, iLength div sizeof( wchr ) );
        Move( pBytes^[ iOffset ], pointer( wTranslation )^, iLength );
        end;
  result := true;
end;
{* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ *}
procedure TProp.Translate;

  function FindObject( const sName : nstr ) : TObject;
  begin
    if SameText( sName, oComponent.Name )
    then  begin
          result := oComponent;
          exit;
          end;
    result := oComponent.FindComponent( sName );
  end;

type
  TPropTypeFromName = ( ptfnGeneral, ptfnList, ptfnCollection );

const
  AS_ENDS : array[ TPropTypeFromName ] of nchr = ( ' ', ')', '>' );

  function ExtractPropName(
    const sPropName : nstr;
    var iType : TPropTypeFromName;
    var iCollListIndex : integer ) : nstr;
  var
    iPos : integer;
  begin
    iType := ptfnGeneral;
    iCollListIndex := 0;
    iPos := Pos( '<', sPropName );
    if iPos >= 1
    then  begin
          iType := ptfnCollection;
          end
    else  begin
          iPos := Pos( '(', sPropName );
          if iPos >= 1
          then  begin
                iType := ptfnList;
                end
          else  begin
                result := sPropName;
                exit;
                end;
          end;
    result := Copy( sPropName, 1, iPos - 1 );
    Inc( iPos );
    iCollListIndex := StrToInt( TextToChar( sPropName, AS_ENDS[ iType ],
      iPos ) );
  end;

  function FindPropInfo(
      var oObject : TObject;
      oPropNames : TStrings;
      iIndex : integer;
      var iTypeFromName : TPropTypeFromName;
      var iCollListIndex : integer
    ) : PPropInfo;
  var
    sPropName : nstr;
  begin
    sPropName := ExtractPropName( oPropNames[ iIndex ],
      iTypeFromName,
        iCollListIndex );

    result := GetPropInfo( oObject.ClassInfo, sPropName );

    if ( result <> nil )
      and ( iIndex < oPropNames.Count - 1 )
    then  begin
          if ( result^.PropType^.Kind = tkClass )
          then  begin
                oObject := GetObjectProp( oObject, sPropName );
                case iTypeFromName of
                  ptfnList :
                    begin
                    result := nil;
                    end;
                  ptfnCollection :
                    begin
                    oObject := ( oObject as TCollection ).Items
                      [ iCollListIndex ];
                    if oObject <> nil
                    then  result := FindPropInfo( oObject,
                            oPropNames,
                              iIndex + 1,
                                iTypeFromName,
                                  iCollListIndex );
                    end;
                else
                  if oObject <> nil
                  then  result := FindPropInfo( oObject,
                    oPropNames,
                      iIndex + 1,
                        iTypeFromName,
                          iCollListIndex )
                  else  result := nil;
                end;
                end
          else  result := nil;
          end;
  end;

var
  oObject : TObject;
  iPos : integer;
  oPropNames : TStrings;
  pProp : PPropInfo;
  wOldTranslation : wstr;
  iTypeFromName : TPropTypeFromName;
  iCollListIndex : integer;
begin
  oObject := FindObject( sCompName );
  if oObject = nil then exit;
  iPos := 1;
  oPropNames := TStringList.Create;
  try
    while iPos > 0
    do  begin
        oPropNames.Add( TextToChar( sPropName, '.', iPos ) );
        end;
    pProp := FindPropInfo( oObject, oPropNames, 0,
      iTypeFromName,
        iCollListIndex );
    if ( pProp <> nil )
    then  begin
          if pProp^.PropType^.Kind in [ tkString, tkLString, tkWString, tkUString ]
          then  begin
                {asaq GetWideStrProp depricated {/asaq}
                wOldTranslation := GetStrProp( oObject, nstr( pProp^.Name ) );
                if ( pProp^.SetProc <> nil ) and ( wOldTranslation <> wTranslation )
                then  begin
                      SetWideStrProp( oObject, pProp, wTranslation );
                      end;
                end;
          end
    else  begin
          if oObject = nil then exit;
          if ( oObject is TStrings ) and ( iTypeFromName = ptfnList )
          then  begin
                if ( iCollListIndex < ( oObject as TStrings ).Count )
                then  begin
                      wOldTranslation := ( oObject as TStrings )[ iCollListIndex ];
                      if wOldTranslation <> wTranslation
                      then  begin
                            ( oObject as TStrings )[ iCollListIndex ] := wTranslation;
                            end;
                      end;
                exit;
                end;
          if oObject is TCollection
          then  begin
                exit;
                end;
          end;
  finally
    oPropNames.Free;
  end;
end;
{* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ *}
constructor TProps.Create;
begin
  oItems := TList.Create;
end;
{* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ *}
destructor TProps.Destroy;
var
  i : integer;
begin
  for i := 0 to oItems.Count - 1 do TObject( oItems[ i ] ).Free;
  oItems.Free;
  inherited;
end;
{* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ *}
function TProps.LoadFromResource( iLangIndex : integer ) : boolean;
begin
  result := LoadFromResource( iLangIndex, oComponent.ClassType );
end;
{* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ *}
function TProps.LoadFromResource( iLangIndex : integer;
  oClassType : TClass ) : boolean;
var
  iRes : HRSRC;
  iGlobal : HGLOBAL;
  iPropCount : integer;
  oProp : TProp;
  sClassName : wstr;
  oClassParent : TClass;
  n : integer;
begin
  result := false;
  oClassParent := oClassType.ClassParent;
  if Assigned( oClassParent ) and oClassParent.InheritsFrom( TComponent )
  then  LoadFromResource( iLangIndex, oClassParent );
  iRes := FindResource( oLcf.iLibHandle, pwchr( UpperCase( oClassType.ClassName ) ), RT_RCDATA );
  if iRes = 0 then exit;
  iGlobal := LoadResource( oLcf.iLibHandle, iRes );
  if iGlobal = 0 then exit;
  n := integer( pointer( iGlobal )^ );
  SetLength( sClassName, n div sizeof( wchr ) );
  Inc( iGlobal, sizeof( integer ) );
  Move( pointer( iGlobal )^, sClassName[ 1 ], n );
  Inc( iGlobal, n );
  iPropCount := integer( pointer( iGlobal )^ );
  Inc( iGlobal, sizeof( integer ) );
  while iPropCount > 0
  do  begin
      Dec( iPropCount );
      oProp := TProp.Create;
      oProp.oLcf := oLcf;
      if not oProp.LoadFromResource( iLangIndex, pointer( iGlobal +
        Cardinal( TPLcResItemRec( pointer( iGlobal ) )^[ iPropCount ].
          iOffset ) ) )
      then  oProp.Free
      else  oItems.Add( oProp );
  end;
  result := true;
end;
{* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ *}
function TLcf.TranslateComponent;
var
  oProps : TProps;
  oProp : TProp;
  i : integer;
  iPropLangIndex : integer;
  iCPage : UINT;
begin
  result := false;
  if not GetLangIndex( iLCID, nil, @iPropLangIndex, iCPage ) then exit;
  oProps := TProps.Create;
  oProps.oLcf := Self;
  oProps.oComponent := oComponent;
  try
    result := oProps.LoadFromResource( iPropLangIndex );
    if not result then exit;
    for i := 0 to oProps.oItems.Count - 1
    do  begin
        oProp := oProps.oItems[ i ];
        if oProp.isTranslated then oProp.Translate( iCPage, oComponent );
        end;
  finally
    oProps.Free;
  end;
end;
{* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ *}

{* ************************************************************************** *}

initialization

finalization

  _oLcf.Free;

end.



