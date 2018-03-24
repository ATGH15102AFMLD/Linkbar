{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{            Copyright (c) 2010-2018 Asaq               }
{*******************************************************}

// Port JumpLists.h and JumpLists.cpp from the Classic Shell 3.6.8 http://www.classicshell.net
// The sources for Linkbar are distributed under the MIT open source license

unit Jumplists.Api;

{$i linkbar.inc}

interface

uses
  Windows, Types, SysUtils, Winapi.ActiveX, ShellApi, ShlObj, ComObj, System.Generics.Collections;

const
  LB_JUMLIST_MAX_COUNT = 60;

type
  TJumpItemType = (jiUnknown, jiItem, jiLink, jiSeparator);

  TJumpGroup = class;

  PJumpItem = ^TJumpItem;
  TJumpItem = record
    eType: TJumpItemType;
    Hash: Cardinal;
    Hidden: Boolean;
    HasArguments: Boolean;
    Name: string;
    Item: IUnknown;
  end;

  TJumpItemList = TList<TJumpItem>;

  TJumpGroupeType = (jgRecent, jgFrequent, jgTasks, jgCustom, jgPinned);

  TJumpGroup = class
  public
    eType: TJumpGroupeType;
    Hidden: Boolean;
    Name: string;
    Name0: string;
    Items: TJumpItemList;
  public
    constructor Create;
    destructor Destroy; override;
  end;

  TJumpGroupList = TObjectList<TJumpGroup>;

  TJumplist = class
  public
    reserved: DWORD;
    Groups: TJumpGroupList;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
  end;

  // Creates the app id resolver object
  procedure CreateAppResolver;
  // Returns the App ID and the target exe for the given shortcut
  // AAppId must be _MAX_PATH characters
  function GetAppInfoForLink(const APidl: PItemIDList; AAppId: PChar): Boolean;
  // Returns the jumplist for the given shortcut
  function GetJumplist(const AAppId: PChar; AList: TJumplist; AMaxCount: Integer): Boolean;
  // Returns true if the given shortcut has a jumplist (it may be empty)
  function HasJumpList(const AAppId: PChar): Boolean;
  // Executes the given item using the correct application
  function ExecuteJumpItem(const AAppId: PChar; AAppExe: PItemIDList; const AItem: TJumpItem): Boolean;
  // Removes the given item from the jumplist
  procedure RemoveJumpItem(const AAppId: PChar; const AList: TJumplist; const AGroupIdx, AItemIdx: Integer);
  // Pins or unpins the given item from the jumplist
  procedure PinJumpItem(const AAppId: PChar; const AList: TJumplist; const AGroupIdx, AItemIdx: Integer; const APin: Boolean);

  // FNV hash algorithm as described here: http://www.isthe.com/chongo/tech/comp/fnv/index.html
  // Calculate FNV hash for a memory buffer
  function CalcFNVHash(const AData; ALength: integer; AHash: Cardinal = 2166136261): Cardinal; overload;
  function CalcFNVHash(const AData: PChar; AHash: Cardinal = 2166136261): Cardinal; overload;

implementation

uses Winapi.PropSys, Winapi.PropKey, Winapi.KnownFolders, Winapi.ShLwApi,
     Winapi.ObjectArray, Winapi.CommCtrl,
     System.Win.Registry,
     Linkbar.OS, Linkbar.L10n;

const
// In Delphi XE3 the following constants are not defined

//  Name:     System.AppUserModel.PreventPinning -- PKEY_AppUserModel_PreventPinning
//  Type:     Boolean -- VT_BOOL
//  FormatID: {9F4C2855-9F79-4B39-A8D0-E1D42DE1D5F3}, 9
  PKEY_AppUserModel_PreventPinning: TPropertyKey = (fmtid: '{9F4C2855-9F79-4B39-A8D0-E1D42DE1D5F3}'; pid: 9);

  CLSID_ApplicationResolver: TGUID = '{660B90C8-73A9-4B58-8CAE-355B7F55341B}';
  // different IIDs for Win7 and Win8: http://a-whiter.livejournal.com/1266.html
  IID_IApplicationResolverW7: TGUID = '{46A6EEFF-908E-4DC6-92A6-64BE9177B41C}';
  IID_IApplicationResolverW8: TGUID = '{DE25675A-72DE-44B4-9373-05170450C140}';

  STGFMT_STORAGE = 0;

type

{$IFDEF VER300}
  TLbStorageSeek = UInt64;
{$ELSE}
  TLbStorageSeek = Int64;
{$IFEND}

  // http://a-whiter.livejournal.com/1266.html
  IApplicationResolver = interface(IUnknown)
    function GetAppIDForShortcut(psi: IShellItem; var AppID: LPWSTR): HResult; stdcall;
    {...}
  end;

  TJumplistDestListHeader = packed record
    itype: Integer; // 1
    count: Integer;
    pinCount: Integer;
    reserved1: Integer;
    lastStream: Integer;
    reserved2: Integer;
    writeCount: Integer;
    reserved3: Integer;
  end;

  TJumplistDestListItemHeader = packed record
    crc: UInt64;
    pad1: array[0..79] of Byte;
    stream: Integer;
    pad2: Integer;
    useCount: Single;
    timestamp: TFileTime;
    pinIdx: Integer;
  end;

  TJumplistDestListItem = packed record
    header: TJumplistDestListItemHeader;
    name: string;
  end;

  TJumplistDestListItemList = TList<TJumplistDestListItem>;

  TJumplistCustomListHeader = packed record
    iType: Integer;
    iGroupCount: Integer;
    iReserved: Integer;
  end;

var
  g_pAppResolver: IApplicationResolver = nil;
  g_AppResolverTime: Cardinal = 0;
  g_CRCTable: array[0..255] of UInt64;

// In Delphi XE3 the following functions are not defined

function SHLoadIndirectString(pszSource, pszOutBuf: PWideChar; cchOutBuf: UINT;
  ppvReserved: Pointer): HResult;
  stdcall; external 'shlwapi.dll' name 'SHLoadIndirectString' delayed;

function StgOpenStorageEx(const pwcsName: POleStr; grfMode: Longint;
  stgfmt: DWORD; grfAttrs: DWORD; pStgOptions: Pointer; reserved2: Pointer;
  const riid: TIID; out ppv): HResult;
  stdcall; external 'ole32.dll' name 'StgOpenStorageEx' delayed;

function StgCreateStorageEx(const pwcsName: POleStr; grfMode: Longint;
  stgfmt: Longint; grfAttrs: Longint; pStgOptions: Pointer;
  pSecurityDescriptor: Pointer; const riid: TIID; out ppv): HResult;
  stdcall; external 'ole32.dll' name 'StgCreateStorageEx' delayed;

////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
// TJumpGroup
////////////////////////////////////////////////////////////////////////////////

constructor TJumpGroup.Create;
begin
  inherited;
  Items := TJumpItemList.Create;
end;

destructor TJumpGroup.Destroy;
begin
  Items.Free;
  inherited;
end;

////////////////////////////////////////////////////////////////////////////////
// TJumplist
////////////////////////////////////////////////////////////////////////////////

procedure TJumplist.Clear;
begin
  reserved := 0;
  Groups.Clear;
end;

constructor TJumplist.Create;
begin
  inherited;
  Groups := TJumpGroupList.Create;
end;

destructor TJumplist.Destroy;
begin
  Groups.Free;
  inherited;
end;

// Creates the app id resolver object
procedure CreateAppResolver;
var t: Cardinal;
begin
	if (not IsJumplistAvailable)
  then Exit;

  t := GetTickCount;
  if not Assigned(g_pAppResolver)
     or ( Abs(t-g_AppResolverTime) > 60000 )
  then begin
    // recreate the app resolver at most once per minute, as it may need to read lots of data from disk
    g_AppResolverTime := t;
    g_pAppResolver := nil;
    if IsWindows8OrAbove
    then CoCreateInstance(CLSID_ApplicationResolver, nil, CLSCTX_ALL, IID_IApplicationResolverW8, g_pAppResolver)
    else CoCreateInstance(CLSID_ApplicationResolver, nil, CLSCTX_ALL, IID_IApplicationResolverW7, g_pAppResolver);
  end;
end;

// Calculate FNV hash for a memory buffer
function CalcFNVHash(const AData; ALength: integer; AHash: Cardinal = 2166136261): Cardinal;
var pData: PByte;
    i: Integer;
begin
  pData := PByte(@AData);
  for i := 1 to ALength do
  begin
    AHash := (AHash xor pData^) * 16777619;
    Inc(pData);
  end;
  Result := AHash;
end;

function CalcFNVHash(const AData: PChar; AHash: Cardinal = 2166136261): Cardinal;
begin
  Result := CalcFNVHash(AData^, StrLen(AData)*SizeOf(Char), AHash);
end;

// 8-byte CRC as described here: http://msdn.microsoft.com/en-us/library/hh554834(v=prot.10).aspx
function CalcCRC64(const AData; ALength: integer; ACrc: UInt64 = $FFFFFFFFFFFFFFFF): UInt64;
var i, j: Integer;
    val: UInt64;
    pData: PByte;
begin
  if (g_CRCTable[1] = 0)
  then begin
    for i := 0 to 255 do
    begin
      val := i;
      for j := 1 to 8 do
        val := (val shr 1) xor ( (val and 1) * $92C64265D32139A4 );
      g_CRCTable[i] := val;
    end;
  end;

  pData := PByte(@AData);

  for i := 1 to ALength do
  begin
    ACrc := g_CRCTable[ (ACrc xor pData^) and $FF ] xor (ACrc shr 8);
    Inc(pData);
  end;

  Result := ACrc;
end;

function GetPropertyStoreString(AStore: IPropertyStore; AKey: TPropertyKey): string;
var val: TPropVariant;
begin
  Result := '';
	FillChar(val, SizeOf(val), 0);
	if Succeeded( AStore.GetValue(AKey, val) )
	then begin
		if (val.vt = VT_LPWSTR) or (val.vt = VT_BSTR)
    then Result := val.pwszVal
      else if (val.vt = VT_LPSTR)
		  then Result := String(val.pszVal);
	end;
	PropVariantClear(val);
end;

// Returns true if the given shortcut has a jumplist (it may be empty)
function HasJumpList(const AAppId: PChar): Boolean;
var id: array[0..MAX_PATH] of Char;
    crc: UInt64;
    pszRecent: PChar;
    appkey, path1, path2: string;
begin
  Result := False;
  if (not IsJumplistAvailable)
  then Exit;
  // the jumplist is stored in a file in the CustomDestinations folder as described here:
	// http://www.4n6k.com/2011/09/jump-list-forensics-appids-part-1.html

  if Failed( SHGetKnownFolderPath(FOLDERID_Recent, KF_FLAG_DEFAULT, 0, pszRecent) )
  then Exit(false);

  FillChar(id, SizeOf(id), 0);
  StrLCopy(id, AAppId, MAX_PATH);
  CharUpper(id);
  crc := CalcCRC64(id, StrLen(id)*SizeOf(Char));

  appkey := IntToHex(crc, 0);
  path1 := Format('%s\CustomDestinations\%s.customDestinations-ms', [pszRecent, appkey]);
  path2 := Format('%s\AutomaticDestinations\%s.automaticDestinations-ms', [pszRecent, appkey]);

  CoTaskMemFree(pszRecent);

  Result := ( GetFileAttributes(PChar(path1)) <> INVALID_FILE_ATTRIBUTES )
    or ( GetFileAttributes(PChar(path2)) <> INVALID_FILE_ATTRIBUTES );
end;

// Returns the App ID and the target exe for the given shortcut
// AAppid must be MAX_PATH characters
function GetAppInfoForLink(const APidl: PItemIDList; AAppId: PChar): Boolean;
var pFolder: IShellFolder;
    child: PItemIDList;
    pLink: IShellLink;
    pStore: IPropertyStore;
    val: TPropVariant;
    str: string;
    pItem: IShellItem;
    pwc: LPWSTR;
begin
  Result := False;
  if (not IsJumplistAvailable)
  then Exit;

  if Failed( SHBindToParent(APidl, IID_IShellFolder, Pointer(pFolder), child) )
  then Exit;

  if Failed( pFolder.GetUIObjectOf(0, 1, child, IID_IShellLink, nil, pLink) )
  then Exit;

  pLink.QueryInterface(IPropertyStore, pStore);
  if Assigned(pStore)
  then begin
    // handle explicit appid
    FillChar(val, SizeOf(val), 0);
    if Succeeded( pStore.GetValue(PKEY_AppUserModel_PreventPinning, val) )
       and (val.vt = VT_BOOL)
       and (val.boolVal)
    then begin
      PropVariantClear(val);
      Exit;
    end;
    PropVariantClear(val);

    str := GetPropertyStoreString(pStore, PKEY_AppUserModel_ID);
    if (str <> '')
    then begin
      StrPLCopy(AAppId, str, MAX_PATH);
      Result := True;
      Exit;
    end;
  end;

  if Failed( SHCreateItemFromIDList(APidl, IID_IShellItem, pItem) )
  then Exit;

  CreateAppResolver;
  if Failed( g_pAppResolver.GetAppIDForShortcut(pItem, pwc) )
  then Exit;

  StrPLCopy(AAppId, pwc, MAX_PATH);
  CoTaskMemFree(pwc);
  Result := True;
end;

procedure AddJumpItem(AGroup: TJumpGroup; AUnknown: IUnknown);
var oItem: TJumpItem;
    pItem: IShellItem;
    pLink: IShellLink;
    ppszName: LPWSTR;
    pStore: IPropertyStore;
    val: TPropVariant;
    str, args: string;
    name: array[0..255] of Char;
    pidl: PItemIDList;
begin
  oItem.eType := jiUnknown;
  oItem.Item := AUnknown;
  oItem.Hash := 0;
  oItem.Hidden := False;
  oItem.HasArguments := false;

  AUnknown.QueryInterface(IID_IShellLink, pLink);
  if Assigned(pLink)
  then begin
    oItem.eType := jiLink;
    pLink.QueryInterface(IID_IPropertyStore, pStore);
    if Assigned(pStore)
    then begin
      FillChar(val, SizeOf(val), 0);
      if (AGroup.eType = jgTasks)
         and Succeeded( pStore.GetValue(PKEY_AppUserModel_IsDestListSeparator, val) )
         and (val.vt = VT_BOOL)
         and (val.boolVal)
      then begin
        oItem.eType := jiSeparator;
        PropVariantClear(val);
      end
      else begin
        str := GetPropertyStoreString(pStore, PKEY_Title);
        if (str <> '')
        then begin
          SHLoadIndirectString(PChar(str), name, 256, nil);
          oItem.Name := name;
        end;
      end;
    end;

    if Succeeded( pLink.GetIDList(pidl) )
    then begin
      if (oItem.Name = '')
         and Succeeded( SHGetNameFromIDList(pidl, SIGDN_NORMALDISPLAY, ppszName) )
      then begin
        oItem.Name := ppszName;
        CoTaskMemFree(ppszName);
      end;
      if Succeeded( SHGetNameFromIDList(pidl, Integer(SIGDN_DESKTOPABSOLUTEPARSING), ppszName) )
      then begin
        CharUpper(ppszName);
        oItem.Hash := CalcFNVHash(ppszName);
        CoTaskMemFree(ppszName);
      end;
      CoTaskMemFree(pidl);

      if Assigned(pStore)
      then begin
        args := GetPropertyStoreString(pStore, PKEY_Link_Arguments);
        if (args <> '')
        then begin
          oItem.Hash := CalcFNVHash(PChar(args), oItem.Hash);
          oItem.HasArguments := True;
        end;
      end;
    end;

    if (oItem.eType = jiSeparator) or (oItem.Name <> '')
    then AGroup.Items.Add(oItem);
    Exit;
  end;

  AUnknown.QueryInterface(IID_IShellItem, pItem);
  if Assigned(pItem)
  then begin
    oItem.eType := jiItem;
    // SIGDN_PARENTRELATIVEEDITING used in original code ClassicShell;
    // SIGDN_PARENTRELATIVE retur drive name as "Drivename (D:)". Problems - (???) non localized names;
    if Failed( pItem.GetDisplayName(SIGDN_PARENTRELATIVE, ppszName) )
    then Exit;
    oItem.Name := ppszName;
    CoTaskMemFree(ppszName);
    if Succeeded( pItem.GetDisplayName(SIGDN_DESKTOPABSOLUTEPARSING, ppszName) )
    then begin
      CharUpper(ppszName);
      oItem.Hash := CalcFNVHash(ppszName);
      CoTaskMemFree(ppszName);
    end;
    AGroup.Items.Add(oItem);
    Exit;
  end;
end;

function CalcLinkStreamHash(AStorage: IStorage; AStream: Integer): Cardinal;
var pLink: IShellLink;
    streamName: string;
    pStream: IStream;
    pPersist: IPersistStream;
    pidl: PItemIDList;
    hash: Cardinal;
    pName: PChar;
    pStore: IPropertyStore;
    args: string;
begin
  hash := 0;
  pLink := CreateComObject(CLSID_ShellLink) as IShellLink;
  if not Assigned(pLink)
  then Exit(0);
  streamName := IntToHex(AStream, 0);
  if Failed( AStorage.OpenStream(PChar(streamName), nil, STGM_READ or STGM_SHARE_EXCLUSIVE, 0, pStream) )
  then Exit(0);
  pLink.QueryInterface(IPersistStream, pPersist);
  if not Assigned(pPersist)
     or Failed( pPersist.Load(pStream) )
  then Exit(0);

  if Failed( pLink.GetIDList(pidl) )
  then Exit(0);

  if Succeeded( SHGetNameFromIDList(pidl,  Integer(SIGDN_DESKTOPABSOLUTEPARSING), pName) )
  then begin
    CharUpper(pName);
    hash := CalcFNVHash(pName);
    CoTaskMemFree(pName);
  end;
  CoTaskMemFree(pidl);

  pLink.QueryInterface(IPropertyStore, pStore);
  if Assigned(pStore)
  then begin
    args := GetPropertyStoreString(pStore, PKEY_Link_Arguments);
    if (args <> '')
    then hash := CalcFNVHash(PChar(args), hash);
  end;
  Result := hash;
end;

procedure GetKnownCategory(const AAppId: PChar; AGroup: TJumpGroup;
  AListtype: Integer);
var pDocList: IApplicationDocumentLists;
    pArray: IObjectArray;
    iCount: Cardinal;
    i: integer;
    pUnknown: IUnknown;
begin
  pDocList := CreateComObject(CLSID_ApplicationDocumentLists) as IApplicationDocumentLists;
  if Assigned(pDocList)
  then begin
    pDocList.SetAppID(AAppId);
    if Succeeded( pDocList.GetList(AListtype, LB_JUMLIST_MAX_COUNT, IID_IObjectArray, pArray) )
    then begin
      pArray.GetCount(iCount);
      for i := 0 to iCount-1 do
      begin
        if Succeeded( pArray.GetAt(i, IUnknown, pUnknown) )
        then AddJumpItem(AGroup, pUnknown);
      end;
    end;
  end;
end;

function StreamRead(const AStream: IStream; const AData: Pointer; const ASize: Longint): Boolean;
var read: Longint;
begin
  read := 0;
  Result := (AStream.Read(AData, ASize, @read) = S_OK) and (ASize = read);
end;

function GetJumplist(const AAppId: PChar; AList: TJumplist; AMaxCount: Integer): Boolean;
var id: array[0..MAX_PATH] of Char;
    crc: UInt64;
    pszRecent: PChar;
    appkey, path1, path2: string;
    pStream: IStream;
    customheader: TJumplistCustomListHeader;
    bHasTasks: Boolean;
    groupIdx, i, j, g, iType, count: integer;
    oGroup, oGroupPinned: TJumpGroup;
    oItem: TJumpItem;
    cookie: DWORD;
    len: Word;
    str, name: array[0..255] of Char;
    clsid: TGUID;
    pPersist: IPersistStream;
    pStorage: IStorage;
    destheader: TJumplistDestListHeader;
    pinStreams: TIntegerDynArray;
    itemheader: TJumplistDestListItemHeader;
    seek, dummy: TLbStorageSeek;
    streamName: string;
    bReplaced: Boolean;
    hash: Cardinal;
    hr: HRESULT;
begin
  Result := False;
  if (not IsJumplistAvailable)
  then Exit;
  AList.Clear;

  if Failed( SHGetKnownFolderPath(FOLDERID_Recent, KF_FLAG_DEFAULT, 0, pszRecent) )
  then Exit;

  FillChar(id, SizeOf(id), 0);
  StrLCopy(id, AAppId, MAX_PATH);
  CharUpper(id);
  crc := CalcCRC64(id, StrLen(id)*SizeOf(Char));

  appkey := IntToHex(crc, 0);
  path1 := Format('%s\CustomDestinations\%s.customDestinations-ms', [pszRecent, appkey]);
  path2 := Format('%s\AutomaticDestinations\%s.automaticDestinations-ms', [pszRecent, appkey]);
  CoTaskMemFree(pszRecent);

  if Succeeded( SHCreateStreamOnFile(PChar(path1), STGM_READ, pStream) )
  then begin
    {$REGION ' Read custom destinations '}
    //if Failed( pStream.Read(@customheader, SizeOf(customheader), nil) )
    if not StreamRead(pStream, @customheader, SizeOf(customheader))
    then Exit;
    AList.reserved := customheader.iReserved;
    AList.Groups.Capacity := customheader.iGroupCount + 1;

    for i := 1 to AList.Groups.Capacity do
      AList.Groups.Add( TJumpGroup.Create );

    bHasTasks := False;
    groupIdx := 1;
    while groupIdx <= customheader.iGroupCount do
    begin
      //if Failed( pStream.Read(@iType, 4, nil) )
      if not StreamRead(pStream, @iType, 4)
      then Exit;
      oGroup := AList.Groups[groupIdx];

      if (iType = 1)
      then begin
        // known category
        //if Failed( pStream.Read(@iType, 4, nil) )
        if not StreamRead(pStream, @iType, 4)
        then Exit;
        if (iType = 1)
        then begin
          oGroup.eType := jgFrequent;
          oGroup.Name := L10NFind('Jumplist.Frequent', 'Frequent');
          GetKnownCategory(AAppId, oGroup, ADLT_FREQUENT);
        end
        else if (iType = 2)
        then begin
          oGroup.eType := jgRecent;
          oGroup.Name := L10NFind('Jumplist.Recent', 'Recent');
          GetKnownCategory(AAppId, oGroup, ADLT_RECENT);
        end;
      end
      else begin
        if (iType = 0)
        then begin
          //if Failed( pStream.Read(@len, 2, nil) )
          //   or Failed( pStream.Read(@str[0], len*2, nil) )
          if (not StreamRead(pStream, @len, 2))
             or (not StreamRead(pStream, @str[0], len*2))
          then Exit;
          str[len] := #0;
          oGroup.Name0 := str;
          SHLoadIndirectString(str, name, 256, nil);
          oGroup.Name := name;
          oGroup.eType := jgCustom;
        end
        else begin
          if not bHasTasks
          then begin
            bHasTasks := True;
            Dec(customheader.iGroupCount);
            Dec(groupIdx);
            oGroup := AList.Groups[customheader.iGroupCount+1];
          end;
          oGroup.Name := L10NFind('Jumplist.Tasks', 'Tasks');
          oGroup.eType := jgTasks;
        end;

        //if Failed( pStream.Read(@count, 4, nil) )
        if not StreamRead(pStream, @count, 4)
        then Exit;

        for i := 0 to count-1 do
        begin
          //if Failed( pStream.Read(@clsid, SizeOf(clsid), nil) )
          if not StreamRead(pStream, @clsid, SizeOf(clsid))
          then Exit;
          pPersist := CreateComObject(clsid) as IPersistStream;
          if not Assigned(pPersist) or Failed( pPersist.Load(pStream) )
          then Exit;
          AddJumpItem(oGroup, pPersist);
        end;
      end;
      oGroup.Hidden := False;
      //if Failed( pStream.Read(@cookie, 4, nil) ) or (cookie <> $BABFFBAB)
      if (not StreamRead(pStream, @cookie, 4)) or (cookie <> $BABFFBAB)
      then Exit;

      Inc(groupIdx);
    end;
    {$ENDREGION}
  end
  else begin
    oGroup := TJumpGroup.Create;
    AList.Groups.Add(oGroup);
    oGroup := TJumpGroup.Create;
    oGroup.eType := jgRecent;
    oGroup.Name := L10NFind('Jumplist.Recent', 'Recent');
    GetKnownCategory(AAppId, oGroup, ADLT_RECENT);
    AList.Groups.Add(oGroup);
  end;

  // update pinned items
  oGroupPinned := AList.Groups[0];
  oGroupPinned.eType := jgPinned;
  oGroupPinned.Name := L10NFind('Jumplist.Pinned', 'Pinned');

  // read the DestList stream as described here: http://www.forensicswiki.org/wiki/Jump_Lists
  pStorage := nil;
  hr := StgOpenStorageEx(PChar(path2), STGM_READ or STGM_TRANSACTED,
    STGFMT_STORAGE, 0, nil, nil, IStorage, pStorage);

	if Succeeded( hr )
  then begin
    if Succeeded( pStorage.OpenStream('DestList', nil, STGM_READ or STGM_SHARE_EXCLUSIVE, 0, pStream) )
    then begin
      if StreamRead(pStream, @destheader, SizeOf(destheader))
      then begin
        SetLength(pinStreams, destheader.pinCount);
        for i := 0 to High(pinStreams) do
          pinStreams[i] := -1;

        for i := 0 to destheader.count-1 do
        begin
          //if Failed( pStream.Read(@itemheader, SizeOf(itemheader), nil) )
          if not StreamRead(pStream, @itemheader, SizeOf(itemheader))
          then Break;
          crc := itemheader.crc;
          itemheader.crc := 0;
          if CalcCRC64(itemheader, SizeOf(itemheader)) <> crc
          then Break;

          if IsWindows10
          then begin
            seek := 16;
            if Failed( pStream.Seek(seek, STREAM_SEEK_CUR, dummy) )
            then Break;
          end;

          //if Failed( pStream.Read(@len, 2, nil) )
          if not StreamRead(pStream, @len, 2)
          then Break;
          seek := len*2;

          if IsWindows10 then seek := seek + 4;

          if Failed( pStream.Seek(seek, STREAM_SEEK_CUR, dummy) )
          then Break;
          if (itemheader.pinIdx >= 0) and (itemheader.pinIdx < destheader.pinCount)
          then pinStreams[itemheader.pinIdx] := itemheader.stream;
        end;
      end;
    end;
  end;

  // read pinned streams
  for i := Low(pinStreams) to High(pinStreams) do
  begin
    streamName := IntToHex(pinStreams[i], 0);
    if Succeeded( pStorage.OpenStream(PChar(streamName), nil, STGM_READ or STGM_SHARE_EXCLUSIVE, 0, pStream) )
    then begin
      pPersist := CreateComObject(CLSID_ShellLink) as IPersistStream;
      if Assigned(pPersist) and Succeeded( pPersist.Load(pStream) )
      then AddJumpItem(oGroupPinned, pPersist);
    end;
  end;

  // remove pinned items from the other groups
  for i := 0 to oGroupPinned.Items.Count-1 do
  begin
    hash := oGroupPinned.Items[i].Hash;
    bReplaced := false;
    for g := 1 to AList.Groups.Count-1 do
    begin
      if (hash = 0)
      then Break;
      oGroup := AList.Groups[g];
      for j := 0 to oGroup.Items.Count-1 do
      begin
        oItem := oGroup.Items[j];
        if (oItem.Hash = hash)
        then begin
          if not bReplaced
          then begin
            // replace the pinned item with the found item. there is a better chance for it to be valid
            // for example Chrome's pinned links may have expired icons, but the custom category links have valid icons
            //oItem.Group := oGroupPinned;
            oGroupPinned.Items[i] := oItem;
            bReplaced := True;
          end;
          oItem.Hidden := True;
          oGroup.Items[j] := oItem;
        end;
      end;
    end;
  end;

  // limit the item count (not tasks or pinned)
  for i := 0 to AList.Groups.Count-1 do
  begin
    oGroup := AList.Groups[i];
    if oGroup.eType in [jgTasks, jgPinned]
    then Continue;
    for j := 0 to oGroup.Items.Count-1 do
    begin
      if not oGroup.Items[j].Hidden
      then begin
        oItem := oGroup.Items[j];
        oItem.Hidden := (AMaxCount <= 0);
        oGroup.Items[j] := oItem;
        Dec(AMaxCount);
      end;
    end;
  end;

  // hide empty groups
  for i := 0 to AList.Groups.Count-1 do
  begin
    oGroup := AList.Groups[i];
    oGroup.Hidden := True;
    for j := 0 to oGroup.Items.Count-1 do
    begin
      if not oGroup.Items[j].Hidden
      then begin
        oGroup.Hidden := False;
        Break;
      end;
    end;
  end;

  Result := True;
end;

function ExecuteJumpItem(const AAppId: PChar; AAppExe: PItemIDList; const AItem: TJumpItem{; AWnd: HWND}): Boolean;
var pItem: IShellItem;
    ppszName: LPWSTR;
    ext: string;
    pEnumHandlers: IEnumAssocHandlers;
    pHandler: IAssocHandler;
    count: Cardinal;
    pObject: IObjectWithAppUserModelID;
    ppszAppID: LPWSTR;
    pDataObject: IDataObject;
    pFolder: IShellFolder;
    child, target, pidl: PItemIDList;
    pLink: IShellLink;
    exe: array[0..MAX_PATH] of Char;
    hr: Boolean;
    pExe: LPWSTR;
    execute: TShellExecuteInfo;
    pMenu: IContextMenu;
    Menu: HMENU;
    Id: UINT;
    Info: TCMInvokeCommandInfo;
begin
  Result := False;
  if (not IsJumplistAvailable)
  then Exit;

  if not Assigned(AItem.Item) then Exit;
  if (AItem.eType = jiItem)
  then begin
    {$REGION 'Execute ShellItem'}
    pItem := AItem.Item as IShellItem;
    if not Assigned(pItem)
    then Exit;
    if Failed( pItem.GetDisplayName(SIGDN_DESKTOPABSOLUTEPARSING, ppszName) )
    then Exit;
    ext := ExtractFileExt(ppszName);
    CoTaskMemFree(ppszName);

    // find the correct association handler by appid and invoke it on the item
    if (ext <> '')
       and Succeeded( SHAssocEnumHandlers(PChar(ext), ASSOC_FILTER_RECOMMENDED, pEnumHandlers) )
    then begin

      while Succeeded( pEnumHandlers.Next(1, pHandler, count) )
            and (count = 1)
      do begin
        pHandler.QueryInterface(IID_IObjectWithAppUserModelID, pObject);
        if Assigned(pObject)
        then begin
          if Succeeded (pObject.GetAppID(ppszAppID) )
          then begin
            // found explicit appid
            if SameText(AAppId, ppszAppID)
            then begin
              CoTaskMemFree(ppszAppID);
              if Succeeded( pItem.BindToHandler(nil, BHID_DataObject, IDataObject, pDataObject) )
                 and Succeeded( pHandler.Invoke(pDataObject) )
              then Exit(True);
              Break;
            end;
            CoTaskMemFree(ppszAppID);
          end;
        end;
        pHandler := nil;
      end;
      pEnumHandlers := nil;

      // find the correct association handler by exe name and invoke it on the item
      if Succeeded( SHAssocEnumHandlers(PChar(ext), ASSOC_FILTER_RECOMMENDED, pEnumHandlers) )
         and Succeeded( SHBindToParent(AAppexe, IID_IShellFolder, Pointer(pFolder), child) )
         and Succeeded( pFolder.GetUIObjectOf(0, 1, child, IID_IShellLink, nil, pLink) )
      then begin
        if Succeeded( pLink.Resolve(0, SLR_INVOKE_MSI or SLR_NO_UI or SLR_NOUPDATE) )
           and Succeeded( pLink.GetIDList(target) )
        then begin
          FillChar(exe, SizeOf(exe), 0);
          hr := SHGetPathFromIDList(target, exe);
          CoTaskMemFree(target);
          if hr
          then begin
            while Succeeded( pEnumHandlers.Next(1, pHandler, count) )
                  and (count = 1)
            do begin
              if Succeeded( pHandler.GetName(pExe) )
              then begin
                if SameText(exe, pExe)
                then begin
                  CoTaskMemFree(pExe);
                  if Succeeded( pItem.BindToHandler(nil, BHID_DataObject, IDataObject, pDataObject) )
                     and Succeeded( pHandler.Invoke(pDataObject) )
                  then Exit(True);
                  Break;
                end;
                CoTaskMemFree(pExe);
              end;
              pHandler := nil;
            end;
          end;
        end;
      end;
    end;

    // couldn't find a handler, execute the old way
    FillChar(execute, SizeOf(execute), 0);
    execute.cbSize := SizeOf(execute);
    execute.fMask := SEE_MASK_IDLIST or SEE_MASK_FLAG_LOG_USAGE;
    execute.nShow := SW_NORMAL;
    if Succeeded( SHGetIDListFromObject(pItem, pidl) )
    then begin
      execute.lpIDList := pidl;
      ShellExecuteEx(@execute);
      CoTaskMemFree(pidl);
    end;

    Exit(True);
    {$ENDREGION}
  end;

  if (AItem.eType = jiLink)
  then begin
    {$REGION 'Execute ShellLink'}
    // invoke the link through its context menu
    if Succeeded( AItem.Item.QueryInterface(IID_IContextMenu, pMenu) )
    then try
      Menu := CreatePopupMenu;
      if (Menu <> 0)
      then try
        if Succeeded( pMenu.QueryContextMenu(Menu, 0, FCIDM_SHVIEWFIRST,
          FCIDM_SHVIEWLAST, CMF_DEFAULTONLY) )
        then begin
          Id := GetMenuDefaultItem(Menu, 0, 0);
          if ( Id <> UINT(-1) )
          then begin
            FillChar(Info, SizeOf(Info), 0);
            Info.cbSize := SizeOf(Info);
            Info.fMask := CMIC_MASK_FLAG_LOG_USAGE;
            Info.hwnd := HWND_DESKTOP;
            Info.nShow := SW_NORMAL;
            Info.lpVerb := MakeIntResourceA(Id - FCIDM_SHVIEWFIRST);
            pMenu.InvokeCommand(Info);
          end;
        end;
      finally
        DestroyMenu(Menu);
      end;
    finally
      pMenu := nil;
    end;
    Exit(True);
    {$ENDREGION}
  end;
end;

procedure RemoveJumpItem(const AAppId: PChar; const AList: TJumplist; const AGroupIdx, AItemIdx: Integer);
var group: TJumpGroup;
    pDestinations: IApplicationDestinations;
    pszRecent: PChar;
    id: array[0..MAX_PATH] of Char;
    crc: UInt64;
    appkey, path1, path2: string;
    pStream: IStream;
    customheader: TJumplistCustomListHeader;
    i, j: integer;
    val: DWORD;
    pPersist: IPersistStream;
    clsid: TGUID;
    cookie: DWORD;
label
    err;
begin
  if (not IsJumplistAvailable)
  then Exit;

  group := AList.Groups[AGroupIdx];
  if (group.eType = jgFrequent) or (group.eType = jgRecent)
  then begin
    {$REGION ' Frequent/Recent '}
    // removing from the standard lists is easy
    if Succeeded( CoCreateInstance(CLSID_ApplicationDestinations, nil, CLSCTX_ALL,
      IID_IApplicationDestinations, pDestinations) )
    then begin
      pDestinations.SetAppID(AAppId);
      pDestinations.RemoveDestination(group.Items[AItemIdx].Item);
    end;
    group.Items.Delete(AItemIdx);
    {$ENDREGION}
  end
  else if (group.eType = jgCustom)
  then begin
    {$REGION 'Remove from custom group'}
    group.Items.Delete(AItemIdx);
    // write out the list
    if Failed( SHGetKnownFolderPath(FOLDERID_Recent, KF_FLAG_DEFAULT, 0, pszRecent) )
    then Exit;
    StrLCopy(id, AAppId, MAX_PATH);
    CharUpper(id);
    crc := CalcCRC64(id, StrLen(id)*SizeOf(Char));
    appkey := IntToHex(crc, 0);
    path1 := Format('%s\CustomDestinations\%s.tmp', [pszRecent, appkey]);
    path2 := Format('%s\CustomDestinations\%s.customDestinations-ms', [pszRecent, appkey]);
    CoTaskMemFree(pszRecent);
    if Failed( SHCreateStreamOnFile(PChar(path1), STGM_WRITE or STGM_CREATE, pStream) )
    then Exit;

    customheader.iType := 2;
    customheader.iGroupCount := AList.Groups.Count - 1;
    customheader.iReserved := AList.reserved;
    if Failed( pStream.Write(@customheader, SizeOf(customheader), nil) )
    then goto err;

    // first write tasks
    for i := 0 to AList.Groups.Count-1 do
    begin
      group := AList.Groups[i];
      if (group.eType <> jgTasks)
      then Continue;
      val := 2;
      if Failed( pStream.Write(@val, 4, nil) )
      then goto err;
      val := group.Items.Count;
      if Failed( pStream.Write(@val, 4, nil) )
      then goto err;
      for j := 0 to group.Items.Count-1 do
      begin
        group.Items[j].Item.QueryInterface(IPersistStream, pPersist);
        if not Assigned(pPersist)
           or Failed( pPersist.GetClassID(clsid) )
        then goto err;
        if Failed( pStream.Write(@clsid, SizeOf(clsid), nil) )
           or Failed( pPersist.Save(pStream, True) )
        then goto err;
      end;
      cookie := $BABFFBAB;
      if Failed( pStream.Write(@cookie, 4, nil) )
      then goto err;
    end;

    // write custom and known groups
    for i := 0 to AList.Groups.Count-1 do
    begin
      group := AList.Groups[i];
      case (group.eType) of
        jgRecent:
          begin
            val := 1;
            if Failed( pStream.Write(@val, 4, nil) )
            then goto err;
            val := 2;
            if Failed( pStream.Write(@val, 4, nil) )
            then goto err;
          end;
        jgFrequent:
          begin
            val := 1;
            if Failed( pStream.Write(@val, 4, nil) )
            then goto err;
            val := 1;
            if Failed( pStream.Write(@val, 4, nil) )
            then goto err;
          end;
        jgCustom:
          begin
            val := 0;
            if Failed( pStream.Write(@val, 4, nil) )
            then goto err;
            val := Length(group.Name0);
            if Failed( pStream.Write(@val, 2, nil) )
               or Failed( pStream.Write(PChar(group.Name0), val*SizeOf(Char), nil) )
            then goto err;
            val := group.Items.Count;
            if Failed( pStream.Write(@val, 4, nil) )
            then goto err;
            for j := 0 to group.Items.Count-1 do
            begin
              group.Items[j].Item.QueryInterface(IPersistStream, pPersist);
              if not Assigned(pPersist)
                 or Failed( pPersist.GetClassID(clsid) )
              then goto err;
              if Failed( pStream.Write(@clsid, SizeOf(clsid), nil) )
                 or Failed( pPersist.Save(pStream, True) )
              then goto err;
            end;
          end;
        jgTasks, jgPinned: Continue;
      end;
      cookie := $BABFFBAB;
      if Failed( pStream.Write(@cookie, 4, nil) )
      then goto err;
    end;
    pStream := nil;
    if MoveFileEx( PChar(path1), PChar(path2), MOVEFILE_REPLACE_EXISTING )
    then Exit;
    err:
      DeleteFile(path1);
    {$ENDREGION}
  end;
end;

procedure PinJumpItem(const AAppId: PChar; const AList: TJumplist; const AGroupIdx, AItemIdx: Integer; const APin: Boolean);
var pszRecent: PChar;
    id: array[0..MAX_PATH] of Char;
    crc: UInt64;
    appkey, path: string;
    groupType: TJumpGroupeType;
    jumpItem: TJumpItem;
    pStorage: IStorage;
    autoheader: TJumplistDestListHeader;
    foundIndex: Integer;
    pStream: IStream;
    pinCount: Integer;
    items: TJumplistDestListItemList;
    i: Integer;
    item: TJumplistDestListItem;
    len: Word;
    name: array[0..1024] of Char;
    bNewStorage: Boolean;
    maxStream: Integer;
    streamName: String;
    pLink: IShellLink;
    text: array[0..INFOTIPSIZE] of Char;
    pStore: IPropertyStore;
    args, str: String;
    pidl: PItemIDList;
    pName: PChar;
    pItem: IShellItem;
    pPersist: IPersistStream;
    bUsed: Boolean;
    reg: TRegistry;
    //
    seek, newpos: TLbStorageSeek;
    dummy: array[0..15] of Byte;
label
  over;
begin
  if (not IsJumplistAvailable)
  then Exit;

  if Failed( SHGetKnownFolderPath(FOLDERID_Recent, KF_FLAG_DEFAULT, 0, pszRecent) )
  then Exit;
  StrLCopy(id, AAppId, MAX_PATH);
  CharUpper(id);
  crc := CalcCRC64(id, StrLen(id)*SizeOf(Char));
  appkey := IntToHex(crc, 0);
  path := Format('%s\AutomaticDestinations\%s.automaticDestinations-ms', [pszRecent, appkey]);
  CoTaskMemFree(pszRecent);

  groupType := AList.Groups[AGroupIdx].eType;
  jumpItem := AList.Groups[AGroupIdx].Items[AItemIdx];

  // open the jumplist file
	if Failed( StgOpenStorageEx(PChar(path), STGM_READWRITE or STGM_TRANSACTED,
    STGFMT_STORAGE, 0, nil, nil, IStorage, pStorage) )
  then pStorage := nil;

  foundIndex := -1;
  items := TJumplistDestListItemList.Create;
  try
    items.Capacity := 8;
    if Assigned(pStorage)
    then begin
      // read DestList
      pinCount := 0;
      if Succeeded( pStorage.OpenStream('DestList', nil, STGM_READ or STGM_SHARE_EXCLUSIVE, 0, pStream) )
      then begin
        //if Failed( pStream.Read(@autoheader, SizeOf(autoheader), nil) )
        if not StreamRead(pStream, @autoheader, SizeOf(autoheader))
        then Exit;

        for i := 0 to autoheader.count-1 do
        begin
          //if Failed( pStream.Read(@(item.header), SizeOf(item.header), nil) )
          if not StreamRead(pStream, @item.header, SizeOf(item.header))
          then Exit;

          if IsWindows10
          then begin
            seek := 16;
            if Failed( pStream.Seek(seek, STREAM_SEEK_CUR, newpos) )
            then Break;
          end;

          //if Failed( pStream.Read(@len, 2, nil) )
          if not StreamRead(pStream, @len, 2)
          then Exit;
          if (len >= Length(name))
          then Exit;
          //if Failed( pStream.Read(@name[0], len*2, nil) )
          if not StreamRead(pStream, @name[0], len*2)
          then Exit;
          name[len] := #0;
          item.name := name;
          items.Add(item);
          if (item.header.pinIdx >= 0)
          then Inc(pinCount);
          if (foundIndex = -1)
          then begin
            if ( CalcLinkStreamHash(pStorage, item.header.stream) = jumpItem.Hash )
            then foundIndex := i;
          end;

          if IsWindows10
          then begin
            seek := 4;
            if Failed( pStream.Seek(seek, STREAM_SEEK_CUR, newpos) )
            then Break;
          end;

        end;
        if (autoheader.pinCount <> pinCount)
        then Exit;
      end;
    end;

    bNewStorage := false;
    if (groupType = jgCustom)
    then begin
      {$REGION 'jgCustom'}
      Assert(APin);
      // pin a custom item
      if (foundIndex <> -1)
      then Exit; // already pinned

      // add new named stream
      if not Assigned(pStorage)
      then begin
        // create the file if it doesn't exist
        if Failed( StgCreateStorageEx(PChar(path), STGM_READWRITE or STGM_CREATE or STGM_TRANSACTED,
          STGFMT_STORAGE, 0, nil, nil, IStorage, pStorage) )
        then Exit;
        bNewStorage := True;
        FillChar(autoheader, SizeOf(autoheader), 0);
        autoheader.itype := 1;
      end;
      maxStream := 0;
      for i := 0 to items.Count-1 do
      begin
        item := items[i];
        if (maxStream < item.header.stream)
        then maxStream := item.header.stream;
      end;

      FillChar(item.header, SizeOf(item.header), 0);
      item.name := '';

      item.header.stream := maxStream + 1;
      item.header.pinIdx := autoheader.pinCount;
      item.header.crc := CalcCRC64(item.header, SizeOf(item.header));
      streamName := IntToHex(item.header.stream, 0);

      pStream := nil;
      if Failed( pStorage.CreateStream(PChar(streamName), STGM_WRITE or STGM_CREATE or STGM_SHARE_EXCLUSIVE,
        0, 0, pStream) )
      then goto over;

      jumpItem.Item.QueryInterface(IShellLink, pLink);
      if Assigned(pLink)
      then begin
        if ( pLink.GetPath(text, Length(text), PWin32FindDataW(nil)^, SLGP_RAWPATH) = S_OK )
        then begin
          // for links with a valid path the name is a crc of the path, arguments, and title
          CharUpper(text);
          crc := CalcCRC64(text, StrLen(text)*SizeOf(Char));
          pLink.QueryInterface(IPropertyStore, pStore);
          if Assigned(pStore)
          then begin
            args := GetPropertyStoreString(pStore, PKEY_Link_Arguments);
            crc := CalcCRC64(args, Length(args)*SizeOf(Char), crc);
            str := GetPropertyStoreString(pStore, PKEY_Title);
            SHLoadIndirectString(PChar(str), text, Length(text), nil);
            CharUpper(text);
            crc := CalcCRC64(text, StrLen(text)*SizeOf(Char), crc);
          end;
          item.name := IntToHex(crc, 0);
        end
        else begin
          // for links with no path (like IE) the name is generated from the pidl
          if Failed( pLink.GetIDList(pidl) )
          then goto over;
          pName := nil;
          if Succeeded( SHGetNameFromIDList(pidl, Integer(SIGDN_DESKTOPABSOLUTEPARSING), pName) )
          then begin
            item.name := pName;
            CoTaskMemFree(pName);
            CoTaskMemFree(pidl);
          end
          else begin
            CoTaskMemFree(pidl);
            goto over;
          end;
        end;
      end
      else begin
        pName := nil;
        jumpItem.Item.QueryInterface(IShellItem, pItem);
        if not Assigned(pItem)
           or Failed( pItem.GetDisplayName(SIGDN_DESKTOPABSOLUTEPARSING, pName) )
        then begin
          //CoTaskMemFree(pName);
          goto over;
        end;

        item.name := pName;
        CoTaskMemFree(pName);

        pLink := nil;
        if Failed( CoCreateInstance(CLSID_ShellLink, nil, CLSCTX_ALL, IID_IShellLink, pLink) )
           //or not Assigned(pLink)
           or Failed( pLink.SetPath( PChar(item.name) ) )    // pName
        then goto over;

      end;

      pLink.QueryInterface(IPersistStream, pPersist);
      if not Assigned(pPersist)
         or Failed( pPersist.Save(pStream, False) )
      then goto over;
      items.Add(item);
      autoheader.lastStream := item.header.stream;
      Inc(autoheader.count);
      Inc(autoheader.pinCount);
      {$ENDREGION}
    end
    else if (groupType = jgFrequent) or (groupType = jgRecent)
    then begin
      {$REGION 'jgFrequent and jgRecent'}
      Assert(APin);
      // pin a standard item (set pinIndex in DestList)
      if (foundIndex = -1)
      then Exit; // not in DestList, bad
      if ( items[foundIndex].header.pinIdx >= 0 )
      then Exit; // already pinned
      item := items[foundIndex];
      item.header.pinIdx := autoheader.pinCount;
      items[foundIndex] := item;
      inc(autoheader.pinCount);
      {$ENDREGION}
    end
    else if (groupType = jgPinned)
    then begin
      {$REGION 'jgPinned'}
      // unpin
      if (foundIndex = -1)
      then Exit; // not in DestList, bad
      for i := 0 to items.Count-1 do
      begin
        item := items[i];
        if (item.header.pinIdx > items[foundIndex].header.pinIdx)
        then begin
          Dec(item.header.pinIdx);
          items[i] := item;
        end;
      end;
      bUsed := items[foundIndex].header.useCount > 0;
      if (bUsed)
      then begin
        // if recent history is disabled, also consider the item unused
        reg := TRegistry.Create;
        try
          reg.RootKey := HKEY_CURRENT_USER;
          if reg.OpenKeyReadOnly('Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced')
          then bUsed := (reg.GetDataType('Start_TrackDocs') <> rdInteger)
                     or (reg.ReadInteger('Start_TrackDocs') > 0);
        finally
          reg.Free;
        end;
      end;
      if (bUsed)
      then begin
        // unpin used item - just clear pinIdx
        if (items[foundIndex].header.pinIdx < 0)
        then Exit; // already unpinned
        item := items[foundIndex];
        item.header.pinIdx := -1;
        items[foundIndex] := item;
      end
      else begin
        // unpin unused item - delete stream and remove from DestList
        streamName := IntToHex(items[foundIndex].header.stream, 0);
        if Failed( pStorage.DestroyElement(PChar(streamName)) )
        then Exit;
        items.Delete(foundIndex);
        Dec(autoheader.count);
      end;
      Dec(autoheader.pinCount);
      {$ENDREGION}
    end
    else Exit; // not supported

    // update CRC
    for i := 0 to items.Count-1 do
    begin
      item := items[i];
      item.header.crc := 0;
      item.header.crc := CalcCRC64(item.header, SizeOf(item.header));
      items[i] := item;
    end;

    if Assigned(pStorage)
    then begin
      // write DestList
      pStream := nil;
      if Failed( pStorage.CreateStream('DestList', STGM_WRITE or STGM_CREATE or STGM_SHARE_EXCLUSIVE,
        0, 0, pStream) )
      then goto over;

      Inc(autoheader.writeCount);
      if Failed( pStream.Write(@autoheader, SizeOf(autoheader), nil) )
      then goto over;

      FillChar(dummy, SizeOf(dummy), 0);
      for i := 0 to items.Count-1 do
      begin
        item := items[i];
        if Failed( pStream.Write(@(item.header), SizeOf(item.header), nil) )
        then goto over;

        if (IsWindows10) //w10
           and Failed( pStream.Write(@dummy[0], 16, nil) )
        then goto over;

        len := Length(item.name);
        if Failed( pStream.Write(@len, 2, nil) )
        then goto over;
        if Failed( pStream.Write(PChar(item.name), len*2, nil) )
        then goto over;

        if (IsWindows10) //w10
           and Failed( pStream.Write(@dummy[0], 4, nil) )
        then goto over;
      end;
      pStorage.Commit(STGC_DEFAULT);
    end;

    Exit;

    over: begin
      if (bNewStorage)
      then begin
        pStorage.Revert;
        pStorage := nil;
        DeleteFile(path);
      end;
    end;

  finally
    items.Free;
  end;
end;

end.
