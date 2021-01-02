{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{            Copyright (c) 2010-2021 Asaq               }
{*******************************************************}

// Port JumpLists.h and JumpLists.cpp from the Classic Shell 4.3.1 http://www.classicshell.net
// The sources for Linkbar are distributed under the MIT open source license

unit JumpLists.Api_2;

{$i linkbar.inc}

interface

uses
  Winapi.Windows, System.Types, Winapi.ShlObj, System.Generics.Collections;

const
  FNV_HASH0 = 2166136261;

type
  TJumpItemType = (jiUnknown, jiItem, jiLink, jiSeparator);

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
    Items: TJumpItemList;
  public
    constructor Create;
    destructor Destroy; override;
  end;

  TJumpGroupList = TObjectList<TJumpGroup>;

  TJumplist = class
  public
    Groups: TJumpGroupList;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
  end;

  // Returns the App ID for then APidl. AAppid must be MAX_PATH characters
  function GetAppInfoForLink(const APidl: PItemIDList; AAppId: PChar): Boolean;
  // Returns true if the given app has a non-empty jumplist
  function HasJumplist(const AAppId: PChar): Boolean;
  // Returns the jumplist for the given shortcut
  function GetJumplist(const AAppId: PChar; AList: TJumplist; AMaxCount{, AMaxHeight, ASepHeight, AItemHeight}: Integer): Boolean;
  // Executes the given item using the correct application
  function ExecuteJumpItem(const AItem: TJumpItem; const AWnd: HWND): Boolean;
  // Removes the given item from the jumplist
  procedure RemoveJumpItem(const AAppId: PChar; const AList: TJumplist; const AGroupIdx, AItemIdx: Integer);
  // Pins or unpins the given item from the jumplist
  procedure PinJumpItem(const AAppId: PChar; const AList: TJumplist; const AGroupIdx, AItemIdx: Integer; const APin: Boolean; const APinIndex: Integer);
  // FNV hash algorithm as described here: http://www.isthe.com/chongo/tech/comp/fnv/index.html
  // Calculate FNV hash for a memory buffer
  function CalcFNVHash(const AData; ALength: integer; AHash: Cardinal = FNV_HASH0): Cardinal; overload;
  // Calculate FNV hash for a string
  function CalcFNVHash(const AData: PChar; AHash: Cardinal = FNV_HASH0): Cardinal; overload;
  //
  procedure CreateLinkbarTasksJumplist;

implementation

uses
  System.SysUtils, System.Win.ComObj, Winapi.ActiveX, Winapi.ObjectArray,
  Winapi.ShellAPI, Winapi.PropKey, Winapi.PropSys, Vcl.Consts,
  Linkbar.OS, Linkbar.L10n, Linkbar.Consts, Linkbar.Shell;

const
  { Jumplist list type }
  JL_LT_PINNED   = 0;
  JL_LT_FREQUENT = 1;
  JL_LT_RECENT   = 2;
  { Jumplist category type }
  JL_CT_CUSTOM   = 0;
  JL_CT_NORMAL   = 1;
  JL_CT_TASKS    = 2;

  // In Delphi XE3 the following constants are not defined
  // Name:     System.AppUserModel.PreventPinning -- PKEY_AppUserModel_PreventPinning
  // Type:     Boolean -- VT_BOOL
  // FormatID: {9F4C2855-9F79-4B39-A8D0-E1D42DE1D5F3}, 9
  PKEY_AppUserModel_PreventPinning: TPropertyKey = (fmtid: '{9F4C2855-9F79-4B39-A8D0-E1D42DE1D5F3}'; pid: 9);

  CLSID_ApplicationResolver: TGUID = '{660B90C8-73A9-4B58-8CAE-355B7F55341B}';
  // different IIDs for Win7 and Win8: http://a-whiter.livejournal.com/1266.html
  IID_IApplicationResolverW7: TGUID = '{46A6EEFF-908E-4DC6-92A6-64BE9177B41C}';
  IID_IApplicationResolverW8: TGUID = '{DE25675A-72DE-44B4-9373-05170450C140}';

  IID_IDestinationList:    TGUID = '{03f1eed2-8676-430b-abe1-765c1d8fe147}';
  IID_IDestinationList10a: TGUID = '{febd543d-1f7b-4b38-940b-5933bd2cb21b}'; // 10240
  IID_IDestinationList10b: TGUID = '{507101cd-f6ad-46c8-8e20-eeb9e6bac47f}'; // 10547

  CLSID_AutomaticDestinationList:   TGUID = '{f0ae1542-f497-484b-a175-a20db09144ba}';
  IID_IAutomaticDestinationList:    TGUID = '{bc10dce3-62f2-4bc6-af37-db46ed7873c4}';
  IID_IAutomaticDestinationList10b: TGUID = '{e9c5ef8d-fd41-4f72-ba87-eb03bad5817c}'; // 10547

type
  // http://a-whiter.livejournal.com/1266.html
  IApplicationResolver = interface(IUnknown)
    function GetAppIDForShortcut(psi: IShellItem; var AppID: LPWSTR): HResult; stdcall;
    { ... }
  end;

  APPDESTCATEGORY = record
    eType: NativeInt;
    union: packed record
      case Integer of
        0: (name: PChar);
        1: (subType: NativeInt);
    end;
    count: NativeInt;
    pad: array[0..9] of Integer; // just in case
  end;
  TAppDestCategory = APPDESTCATEGORY;

  IDestinationList = interface(IUnknown)
    function SetMinItems(): HRESULT; stdcall;
    function SetApplicationID(appUserModelId: LPCWSTR): HRESULT; stdcall;
    function GetSlotCount(): HRESULT; stdcall;
    function GetCategoryCount(var pCount: UINT): HRESULT; stdcall;
    function GetCategory(index: UINT; getCatFlags: Integer; var pCategory: TAppDestCategory): HRESULT; stdcall;
    function DeleteCategory(): HRESULT; stdcall;
    function EnumerateCategoryDestinations(index: UINT; const riid: TIID; var ppvObjectT: Pointer): HRESULT; stdcall;
    function RemoveDestination(pItem: IUnknown): HRESULT; stdcall;
    function ResolveDestination(): HRESULT; stdcall;
  end;

  IAutomaticDestinationList = interface(IUnknown)
    function Initialize(appUserModelId: LPCWSTR; lnkPath: LPCWSTR; u: LPCWSTR): HRESULT; stdcall;
    function HasList(var pHasList: BOOL): HRESULT; stdcall;
    function GetList(listType: Integer; maxCount: UINT; const riid: TIID; var ppvObject: Pointer): HRESULT; stdcall;
    function AddUsagePoint(): HRESULT; stdcall;
    function PinItem(pItem: IUnknown; pinIndex: Integer): HRESULT; stdcall; // -1 - pin, -2 - unpin
    function IsPinned(): HRESULT; stdcall;
    function RemoveDestination(pItem: IUnknown): HRESULT; stdcall;
    function SetUsageData(): HRESULT; stdcall;
    function GetUsageData(): HRESULT; stdcall;
    function ResolveDestination(): HRESULT; stdcall;
    function ClearList(listType: Integer): HRESULT; stdcall;
  end;

  // Difference in GetList() new argument - flags
  IAutomaticDestinationList10b = interface(IUnknown)
    function Initialize(appUserModelId: LPCWSTR; lnkPath: LPCWSTR; u: LPCWSTR): HRESULT; stdcall;
    function HasList(var pHasList: BOOL): HRESULT; stdcall;
    function GetList(listType: Integer; maxCount: Cardinal; flags: Cardinal; const riid: TIID; var ppvObject: Pointer): HRESULT; stdcall;
    function AddUsagePoint(): HRESULT; stdcall;
    function PinItem(pItem: IUnknown; pinIndex: Integer): HRESULT; stdcall; // -1 - pin, -2 - unpin
    function IsPinned(): HRESULT; stdcall;
    function RemoveDestination(pItem: IUnknown): HRESULT; stdcall;
    function SetUsageData(): HRESULT; stdcall;
    function GetUsageData(): HRESULT; stdcall;
    function ResolveDestination(): HRESULT; stdcall;
    function ClearList(listType: Integer): HRESULT; stdcall;
  end;

  TAutomaticList = class
  private
    m_pAutoList: IAutomaticDestinationList;
    m_pAutoList10b: IAutomaticDestinationList10b;
  public
    constructor Create(const appid: PWideChar);
    function HasList(): Boolean;
    function GetList(listType: Integer; maxCount: Cardinal): IObjectCollection;
    procedure PinItem(pItem: IUnknown; pinIndex: Integer);
    function RemoveDestination(pItem: IUnknown): Boolean;
  end;

  TShellItemList = TList<IShellItem>;
  TCardinalList = TList<Cardinal>;

  EJumpListItemException = class(Exception);

// In Delphi XE3 the following functions are not defined

function SHLoadIndirectString(pszSource, pszOutBuf: PWideChar; cchOutBuf: UINT; ppvReserved: Pointer): HResult;
  stdcall; external 'shlwapi.dll' name 'SHLoadIndirectString' delayed;

{ TAutomaticList }

constructor TAutomaticList.Create(const appid: PWideChar);
var pAutoListUnk: IUnknown;
    hr: HRESULT;
begin
  pAutoListUnk := CreateComObject(CLSID_AutomaticDestinationList);
  if Assigned(pAutoListUnk)
  then begin
    pAutoListUnk.QueryInterface(IID_IAutomaticDestinationList, m_pAutoList);
    if Assigned(m_pAutoList)
    then begin
      hr := m_pAutoList.Initialize(appid, nil, nil);
      if Failed(hr)
      then m_pAutoList := nil;
    end
    else if IsWindows10OrAbove
    then begin
      pAutoListUnk.QueryInterface(IID_IAutomaticDestinationList10b, m_pAutoList10b);
      if Assigned(m_pAutoList10b)
      then begin
        hr := m_pAutoList10b.Initialize(appid, nil, nil);
        if Failed(hr)
        then m_pAutoList10b := nil;
      end;
    end;
  end;
end;

function TAutomaticList.HasList(): Boolean;
var hasList: BOOL;
    pCollection: IObjectCollection;
    count: Cardinal;
    //
    hr: HRESULT;
begin
  if Assigned(m_pAutoList)
  then begin
    hr := m_pAutoList.HasList(hasList);
    if Failed(hr)
       or (not hasList)
    then Exit(False);
  end
  else if Assigned(m_pAutoList10b)
  then begin
    hr := m_pAutoList10b.HasList(hasList);
    if Failed(hr)
       or (not hasList)
    then Exit(False);
  end
  else Exit(False);

  pCollection := GetList(JL_LT_RECENT, 1);
  if Assigned(pCollection)
     and Succeeded(pCollection.GetCount(count))
     and (count > 0)
  then Exit(True);

  pCollection := GetList(JL_LT_PINNED, 1);
  if Assigned(pCollection)
     and Succeeded(pCollection.GetCount(count))
     and (count > 0)
  then Exit(True);

  Result := False;
end;

function TAutomaticList.GetList(listType: Integer; maxCount: Cardinal): IObjectCollection;
var pCollection: IObjectCollection;
begin
  if Assigned(m_pAutoList)
  then m_pAutoList.GetList(listType, maxCount, IID_IObjectCollection, Pointer(pCollection))
  else if Assigned(m_pAutoList10b)
  then m_pAutoList10b.GetList(listType, maxCount, 1, IID_IObjectCollection, Pointer(pCollection));
  Result := pCollection;
end;

procedure TAutomaticList.PinItem(pItem: IUnknown; pinIndex: Integer);
begin
  if Assigned(m_pAutoList)
  then m_pAutoList.PinItem(pItem, pinIndex)
  else if Assigned(m_pAutoList10b)
  then m_pAutoList10b.PinItem(pItem, pinIndex);
end;

function TAutomaticList.RemoveDestination(pItem: IUnknown): Boolean;
begin
  Result := False;
  if Assigned(m_pAutoList)
  then Result := Succeeded(m_pAutoList.RemoveDestination(pItem))
  else if Assigned(m_pAutoList10b)
  then Result := Succeeded(m_pAutoList10b.RemoveDestination(pItem));
end;

{ TJumpGroup }

constructor TJumpGroup.Create;
begin
  inherited;
  eType := jgRecent;
  Hidden := False;
  Items := TJumpItemList.Create;
end;

destructor TJumpGroup.Destroy;
begin
  Items.Free;
  inherited;
end;

{ TJumpList }

constructor TJumpList.Create;
begin
  inherited;
  Groups := TJumpGroupList.Create;
end;

destructor TJumpList.Destroy;
begin
  Groups.Free;
  inherited;
end;

procedure TJumpList.Clear;
begin
  Groups.Clear;
end;

{ --- }

function GetCustomList(const AAppId: PChar): IDestinationList;
var pCustomListUnk: IUnknown;
    pCustomList: IDestinationList;
begin
  pCustomListUnk := CreateComObject(CLSID_DestinationList);
  if Assigned(pCustomListUnk)
  then begin
    if IsWindows10OrAbove
    then begin
      if Failed(pCustomListUnk.QueryInterface(IID_IDestinationList10a, Pointer(pCustomList)))
      then pCustomListUnk.QueryInterface(IID_IDestinationList10b, Pointer(pCustomList))
    end
    else pCustomListUnk.QueryInterface(IID_IDestinationList, Pointer(pCustomList));

    if Assigned(pCustomList)
       and Succeeded(pCustomList.SetApplicationID(AAppId))
    then Exit(pCustomList)
  end;
  Result := nil;
end;

function HasJumplist(const AAppId: PChar): Boolean;
var pCustomList: IDestinationList;
    count: UINT;
    autoList: TAutomaticList;
    hr: HRESULT;
begin
  pCustomList := GetCustomList(AAppId);
  if Assigned(pCustomList)
  then begin
    hr := pCustomList.GetCategoryCount(count);
    if Succeeded(hr)
       and (count > 0)
    then Exit(True);
  end;

  autoList := TAutomaticList.Create(AAppId);
  Result := autoList.HasList();
  autoList.Free;
end;

function GetPropertyStoreString(AStore: IPropertyStore; AKey: TPropertyKey): string;
var val: TPropVariant;
begin
  Result := '';
  PropVariantInit(val);
  if Succeeded(AStore.GetValue(AKey, val))
  then begin
    if val.vt in [VT_LPWSTR, VT_BSTR]
    then Result := val.pwszVal
      else if (val.vt = VT_LPSTR)
      then Result := string(val.pszVal);
  end;
  PropVariantClear(val);
end;

// FNV hash algorithm as described here: http://www.isthe.com/chongo/tech/comp/fnv/index.html
// Calculate FNV hash for a memory buffer
function CalcFNVHash(const AData; ALength: integer; AHash: Cardinal = FNV_HASH0): Cardinal; overload;
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

// Calculate FNV hash for a string
function CalcFNVHash(const AData: PChar; AHash: Cardinal = FNV_HASH0): Cardinal; overload;
begin
  Result := CalcFNVHash(AData^, StrLen(AData)*SizeOf(Char), AHash);
end;

function CalcLinkHash(pLink: IShellLink): Cardinal;
var pidl: PItemIDList;
    hash: Cardinal;
    pName: LPWSTR;
    pStore: IPropertyStore;
    args: string;
begin
  if Failed(pLink.GetIDList(pidl))
  then Exit(0);

  hash := FNV_HASH0;
  if Succeeded(SHGetNameFromIDList(pidl, Integer(SIGDN_DESKTOPABSOLUTEPARSING), pName))
  then begin
    CharUpper(pName);
    hash := CalcFNVHash(pName);
  end;

  pLink.QueryInterface(IID_IPropertyStore, pStore);
  if Assigned(pStore)
  then begin
    args := GetPropertyStoreString(pStore, PKEY_Link_Arguments);
    if (args <> '')
    then hash := CalcFNVHash(PChar(args), hash);
  end;

  Result := hash;
end;

procedure AddJumpItem(const AGroup: TJumpGroup; const AUnknown: IUnknown; const AIgnoreItems: TShellItemList; const AIgnoreLinks: TCardinalList);
var item: TJumpItem;
    pItem: IShellItem;
    pLink: IShellLink;
    i: Integer;
    order: Integer;
    pName: LPWSTR;
    hash: Cardinal;
    pStore: IPropertyStore;
    val: TPropVariant;
    str, args: string;
    name: array[0..255] of Char;
    pidl: PItemIDList;
begin
  item.eType := jiUnknown;
  item.Item := AUnknown;
  item.Hash := 0;
  item.Hidden := False;
  item.HasArguments := False;

  AUnknown.QueryInterface(IID_IShellItem, pItem);
  if Assigned(pItem)
  then begin
    for i := 0 to AIgnoreItems.Count-1 do
    begin
      if Succeeded(pItem.Compare(AIgnoreItems[i], SICHINT_CANONICAL or SICHINT_TEST_FILESYSPATH_IF_NOT_EQUAL, order))
         and (order = 0)
      then Exit;
    end;

    item.eType := jiItem;
    // SIGDN_NORMALDISPLAY used in original code of ClassicShell;
    // SIGDN_PARENTRELATIVE retur drive name as "Drivename (D:)". Problems - (???) non localized names;
    if Failed(pItem.GetDisplayName(SIGDN_NORMALDISPLAY, pName))
    then Exit;
    item.Name := pName;
    CoTaskMemFree(pName);
    if Succeeded(pItem.GetDisplayName(SIGDN_DESKTOPABSOLUTEPARSING, pName))
    then begin
      CharUpper(pName);
      item.Hash := CalcFNVHash(pName);
      CoTaskMemFree(pName);
    end;
    AGroup.Items.Add(item);
    Exit;
  end;

  AUnknown.QueryInterface(IID_IShellLink, pLink);
  if Assigned(pLink)
  then begin
    hash := CalcLinkHash(pLink);
    for i := 0 to AIgnoreLinks.Count-1 do
    begin
      if (hash = AIgnoreLinks[i])
      then Exit;
    end;

    item.eType := jiLink;
    pLink.QueryInterface(IID_IPropertyStore, pStore);
    if Assigned(pStore)
    then begin
      PropVariantInit(val);
      if (AGroup.eType = jgTasks)
         and Succeeded(pStore.GetValue(PKEY_AppUserModel_IsDestListSeparator, val))
         and (val.vt = VT_BOOL)
         and (val.boolVal)
      then begin
        item.eType := jiSeparator;
        item.Name := '-';
        PropVariantClear(val);
      end
      else begin
        str := GetPropertyStoreString(pStore, PKEY_Title);
        if (str <> '')
        then begin
          SHLoadIndirectString(PChar(str), name, 256, nil);
          item.Name := name;
        end;
      end;
    end;

    if Succeeded(pLink.GetIDList(pidl))
       and (pidl <> nil)
    then begin
      if (item.Name = '')
         and Succeeded(SHGetNameFromIDList(pidl, SIGDN_NORMALDISPLAY, pName))
      then begin
        item.Name := pName;
        CoTaskMemFree(pName);
      end;
      if Succeeded(SHGetNameFromIDList(pidl, Integer(SIGDN_DESKTOPABSOLUTEPARSING), pName))
      then begin
        CharUpper(pName);
        item.Hash := CalcFNVHash(pName);
        CoTaskMemFree(pName);
      end;
      CoTaskMemFree(pidl);

      //pLink.QueryInterface(IID_IPropertyStore, pStore); retrieved above
      if Assigned(pStore)
      then begin
        args := GetPropertyStoreString(pStore, PKEY_Link_Arguments);
        if (args <> '')
        then begin
          item.Hash := CalcFNVHash(PChar(args), item.Hash);
          item.HasArguments := True;
        end;
      end;
    end;

    if (item.Name <> '')
    then AGroup.Items.Add(item);

    Exit;
  end;
end;

procedure AddJumpCollection(const AGroup: TJumpGroup; const ACollection: IObjectCollection;
  const AIgnoreItems: TShellItemList; const AIgnoreLinks: TCardinalList);
var count: UINT;
    i: Integer;
    pUnknown: IUnknown;
begin
  if Succeeded(ACollection.GetCount(count))
  then begin
    for i := 0 to Integer(count-1) do
      if Succeeded(ACollection.GetAt(i, IUnknown, Pointer(pUnknown)))
         and Assigned(pUnknown)
      then AddJumpItem(AGroup, pUnknown, AIgnoreItems, AIgnoreLinks);
  end;
end;

function GetJumplist(const AAppId: PChar; AList: TJumplist; AMaxCount{, AMaxHeight, ASepHeight, AItemHeight}: Integer): Boolean;
var pCustomList: IDestinationList;
    categoryCount: UINT;
    autoList: TAutomaticList;
    ignoreItems: TShellItemList;
    ignoreLinks: TCardinalList;
    pCollection: IObjectCollection;
    i, j, taskIndex, catIndex: Integer;
    group: TJumpGroup;
    item: TJumpItem;
    pShellItem: IShellItem;
    pLink: IShellLink;
    hash: Cardinal;
    category: TAppDestcategory;
    name: array[0..255] of Char;
    //
    hr: HRESULT;
    maxcount: Integer;
begin
  AList.Clear;

  pCustomList := GetCustomList(AAppId);
  if (not Assigned(pCustomList))
     or Failed(pCustomList.GetCategoryCount(categoryCount))
  then categoryCount := 0;

  AList.Groups.Capacity := categoryCount + 2;

  ignoreItems := TShellItemList.Create;
  ignoreLinks := TCardinalList.Create;
  autoList := TAutomaticList.Create(AAppId);
  // Add Pinned
  pCollection := autoList.GetList(JL_LT_PINNED, {AMaxCount}30);
  if Assigned(pCollection)
  then begin
    group := TJumpGroup.Create;
    AList.Groups.Add(group);
    group.eType := jgPinned;
    group.Name := L10NFind('Jumplist.Pinned', 'Pinned');
    AddJumpCollection(group, pCollection, ignoreItems, ignoreLinks);
    for i := 0 to group.Items.Count-1 do
    begin
      item := group.Items[i];
      item.Item.QueryInterface(IID_IShellItem, pShellItem);
      if Assigned(pShellItem)
      then ignoreItems.Add(pShellItem)
      else begin
        item.Item.QueryInterface(IID_IShellLink, pLink);
        if Assigned(pLink)
        then begin
          hash := CalcLinkHash(pLink);
          if (hash <> 0)
          then ignoreLinks.Add(hash);
        end;
      end;
    end;
  end;

  maxcount := AMaxCount + ignoreItems.Count + ignoreLinks.Count;

  // Add Custom, Recent, Frequent
  taskIndex := -1;
  for catIndex := 0 to Integer(categoryCount-1) do
  begin
    FillChar(category, SizeOf(category), 0);
    hr := pCustomList.GetCategory(catIndex, 1, category);
    if Succeeded(hr)
    then begin
      if (AMaxCount > 0)
         and (category.eType = JL_CT_CUSTOM)
      then begin
        // custom group
        if (category.union.name <> nil)
           and (category.union.name <> '')
        then begin
          SHLoadIndirectString(category.union.name, name, 256, nil);
          CoTaskMemFree(category.union.name);
          if Succeeded(pCustomList.EnumerateCategoryDestinations(catIndex, IID_IObjectCollection, Pointer(pCollection)))
             and Assigned(pCollection)
          then begin
            group := TJumpGroup.Create;
            AList.Groups.Add(group);
            group.eType := jgCustom;
            group.Name := name;
            AddJumpCollection(group, pCollection, ignoreItems, ignoreLinks);
          end;
        end;
      end
      else if (category.eType = JL_CT_NORMAL)
      then begin
        // standard group
        if (AMaxCount > 0)
           and (category.union.subType in [JL_LT_RECENT, JL_LT_FREQUENT])
        then begin
          pCollection := autoList.GetList(3 - category.union.subType, maxcount);
          if Assigned(pCollection)
          then begin
            group := TJumpGroup.Create;
            AList.Groups.Add(group);
            if (category.union.subType = JL_LT_FREQUENT)
            then begin
              group.eType := jgFrequent;
              group.Name := L10NFind('Jumplist.Frequent', 'Frequent');
            end
            else begin
              group.eType := jgRecent;
              group.Name := L10NFind('Jumplist.Recent', 'Recent');
            end;
            AddJumpCollection(group, pCollection, ignoreItems, ignoreLinks);
          end;
        end;
      end
      else if (category.eType = JL_CT_TASKS)
              and (taskIndex = -1)
      then begin
        taskIndex := catIndex;
      end;
    end;
  end;

  // Add Tasks
  if (taskIndex <> -1)
     and Succeeded(pCustomList.EnumerateCategoryDestinations(taskIndex, IID_IObjectCollection, Pointer(pCollection)))
     and Assigned(pCollection)
  then begin
    group := TJumpGroup.Create;
    AList.Groups.Add(group);
    group.eType := jgTasks;
    group.Name := L10NFind('Jumplist.Tasks', 'Tasks');
    AddJumpCollection(group, pCollection, ignoreItems, ignoreLinks);
  end;

  if (categoryCount = 0)
     and (AMaxCount > 0)
  then begin
    // Add Recent
    pCollection := autoList.GetList(1, maxcount);
    if Assigned(pCollection)
    then begin
      group := TJumpGroup.Create;
      AList.Groups.Add(group);
      group.eType := jgRecent;
      group.Name := L10NFind('Jumplist.Recent', 'Recent');
      AddJumpCollection(group, pCollection, ignoreItems, ignoreLinks);
    end;
  end;

  ignoreItems.Free;
  ignoreLinks.Free;
  autoList.Free;

  for i := 0 to AList.Groups.Count-1 do
  begin
    group := AList.Groups[i];
    if not (group.eType in [jgTasks, jgPinned])
    then for j := 0 to group.Items.Count-1 do
    begin
      item := group.Items[j];
      item.Hidden := (j >= AMaxCount);
      group.Items[j] := item;
    end;
  end;

  // Hide empty groups
  for i := 0 to AList.Groups.Count-1 do
  begin
    group := AList.Groups[i];
    group.Hidden := True;
    for j := 0 to group.Items.Count-1 do
    begin
      if (not group.Items[j].Hidden)
      then begin
        group.Hidden := False;
        Break;
      end;
    end;
  end;

  Result := True;
end;

function ExecuteJumpItem(const AItem: TJumpItem; const AWnd: HWND): Boolean;
var pItem: IShellItem;
    execute: TShellExecuteInfo;
    pidl: PItemIDList;
    pMenu: IContextMenu;
    Menu: HMENU;
    Id: UINT;
    Info: TCMInvokeCommandInfo;
begin
  Result := False;

  if not Assigned(AItem.Item)
  then Exit(False);

  if (AItem.eType = jiItem)
  then begin
    {$REGION 'Execute ShellItem'}
    AItem.Item.QueryInterface(IID_IShellItem, pItem);
    if not Assigned(pItem)
    then Exit(False);

    // couldn't find a handler, execute the old way
    FillChar(execute, SizeOf(execute), 0);
    execute.cbSize := SizeOf(execute);
    execute.fMask := SEE_MASK_IDLIST or SEE_MASK_FLAG_LOG_USAGE;
    execute.nShow := SW_NORMAL;
    if Succeeded(SHGetIDListFromObject(pItem, pidl))
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
    AItem.Item.QueryInterface(IID_IContextMenu, pMenu);
    if Assigned(pMenu)
    then try
      Menu := CreatePopupMenu;
      if (Menu <> 0)
      then try
        if Succeeded(pMenu.QueryContextMenu(Menu, 0, FCIDM_SHVIEWFIRST, FCIDM_SHVIEWLAST, CMF_DEFAULTONLY))
        then begin
          Id := GetMenuDefaultItem(Menu, 0, 0);
          if ( Id <> UINT(-1) )
          then begin
            FillChar(Info, SizeOf(Info), 0);
            Info.cbSize := SizeOf(Info);
            Info.fMask := CMIC_MASK_FLAG_LOG_USAGE;
            Info.hwnd := AWnd{HWND_DESKTOP};
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
    pCustomList: IDestinationList;
    autoList: TAutomaticList;
    //
    hr: HRESULT;
begin
  group := AList.Groups[AGroupIdx];
  if group.eType in [jgFrequent, jgRecent]
  then begin
    autoList := TAutomaticList.Create(AAppId);
    if autoList.RemoveDestination(group.Items[AItemIdx].Item)
    then group.Items.Delete(AItemIdx);
    autoList.Free;
  end
  else begin
    pCustomList := GetCustomList(AAppId);
    if Assigned(pCustomList)
    then begin
      hr := pCustomList.RemoveDestination(group.Items[AItemIdx].Item);
      if Succeeded(hr)
      then group.Items.Delete(AItemIdx);
    end;
  end;
end;

procedure PinJumpItem(const AAppId: PChar; const AList: TJumplist; const AGroupIdx, AItemIdx: Integer; const APin: Boolean; const APinIndex: Integer);
var item: TJumpItem;
    index: Integer;
    autoList: TAutomaticList;
begin
  item := AList.Groups[AGroupIdx].Items[AItemIdx];
  if (APin)
  then index := APinIndex
  else index := -2;
  autoList := TAutomaticList.Create(AAppId);
  autoList.PinItem(item.Item, index);
  autoList.Free;
end;

var
  g_pAppResolver: IApplicationResolver = nil;
  g_AppResolverTime: Cardinal = 0;

// Creates the app id resolver object
procedure CreateAppResolver;
var t: Cardinal;
begin
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

  if Failed(SHBindToParent(APidl, IID_IShellFolder, Pointer(pFolder), child))
     or Failed(pFolder.GetUIObjectOf(HWND_DESKTOP, 1, child, IID_IShellLink, nil, pLink))
  then Exit;

  pLink.QueryInterface(IPropertyStore, pStore);
  if Assigned(pStore)
  then begin
    // handle explicit appid
    PropVariantInit(val);
    if Succeeded(pStore.GetValue(PKEY_AppUserModel_PreventPinning, val))
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

  if Failed(SHCreateItemFromIDList(APidl, IID_IShellItem, pItem))
  then Exit;

  CreateAppResolver;
  if Failed(g_pAppResolver.GetAppIDForShortcut(pItem, pwc))
  then Exit;

  StrPLCopy(AAppId, pwc, MAX_PATH);
  CoTaskMemFree(pwc);
  Result := True;
end;

{ Create Linkbar jumplist with tasks "New", "Close all" }

procedure CheckError(ErrNo: HRESULT; const Description: string);
begin
  if not Succeeded(ErrNo)
  then raise EJumpListItemException.CreateFmt(SJumplistsItemException, [ErrNo, Description]);
end;

function CreateIShellLink(const AFriendlyName, AArguments, APath, AIcon: string): IShellLink;
var
  LPropertyStore: Winapi.PropSys.IPropertyStore;
  LPropVariant: TPropVariant;
begin
  Result := CreateComObject(CLSID_ShellLink) as IShellLink;

  if (AFriendlyName <> '')
  then begin
    CheckError(Result.QueryInterface(Winapi.PropSys.IPropertyStore, LPropertyStore), SJumplistsItemErrorGetpsi);
    CheckError(InitPropVariantFromString(PWideChar(AFriendlyName), LPropVariant), SJumplistsItemErrorInitializepropvar);
    CheckError(LPropertyStore.SetValue(PKEY_Title, LPropVariant), SJumplistsItemErrorSetps);
    CheckError(LPropertyStore.Commit(), SJumplistsItemErrorCommitps);
    PropVariantClear(LPropVariant);
  end
  else
    raise EJumpListItemException.Create(SJumplistsItemErrorNofriendlyname);

  if (AArguments <> '')
  then CheckError(Result.SetArguments(PWideChar(AArguments)), SJumplistsItemErrorSettingarguments);

  if (APath <> '')
  then CheckError(Result.SetPath(PWideChar(APath)), SJumplistsItemErrorSettingpath)
  else CheckError(Result.SetPath(PWideChar(ParamStr(0))), SJumplistsItemErrorSettingpath);

  if (AIcon <> '')
  then CheckError(Result.SetIconLocation(PWideChar(AIcon), 0), SJumplistsItemErrorSettingicon)
  else CheckError(Result.SetIconLocation(PWideChar(Paramstr(0)), 0), SJumplistsItemErrorSettingicon);
end;

procedure CreateLinkbarTasksJumplist;
var
  destinationList: ICustomDestinationList;
  maxSlots, objects: Cardinal;
  removedTasks, tasksList: IObjectArray;
  objCollection: IObjectCollection;
  shellLink: IShellLink;
  friendlyName: string;
begin
  if (not IsJumplistAvailable)
  then Exit;

  destinationList := CreateComObject(CLSID_DestinationList) as ICustomDestinationList;
  if (destinationList <> nil)
  then begin
    //SetCurrentProcessExplicitAppUserModelID(PWideChar(APP_ID_LINKBAR));

    destinationList.BeginList(maxSlots, IID_IObjectArray, removedTasks);
    try
      if Succeeded(CoCreateInstance(CLSID_EnumerableObjectCollection, nil, CLSCTX_INPROC_SERVER, IID_IObjectCollection, objCollection))
      then begin
        friendlyName := L10NFind('Jumplist.NewLinkbar', 'New linkbar');
        shellLink := CreateIShellLink(friendlyName, LBCreateCommandParam(CLK_NEW), '', '');
        objCollection.AddObject(shellLink);

        friendlyName := L10NFind('Menu.CloseAll', 'Close all');
        shellLink := CreateIShellLink(friendlyName, LBCreateCommandParam(CLK_CLOSEALL), '', '');
        objCollection.AddObject(shellLink);

        objCollection.QueryInterface(IObjectArray, tasksList);
      end;

      if (tasksList <> nil)
         and (tasksList.GetCount(objects) = S_OK)
         and (objects > 0)
      then destinationList.AddUserTasks(tasksList);

      destinationList.CommitList;
    except
      destinationList.AbortList;
      //raise;
    end;
  end;
end;

end.
