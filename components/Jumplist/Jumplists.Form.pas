{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{            Copyright (c) 2010-2017 Asaq               }
{*******************************************************}

unit Jumplists.Form;

{$i linkbar.inc}

interface

uses
	Windows, System.SysUtils, System.Types, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Menus, System.Generics.Collections, System.UITypes,
  Winapi.Messages, Winapi.ShlObj,	Winapi.CommCtrl, JumpLists.Api;

type
  TVtItemStyle = (vtItem, vtGroup, vtSeparator, vtEmpty, vtFooter);

  TVtItem = record
    Style: TVtItemStyle;
    Group: Integer;
    Item: Integer;
    Rect: TRect;
    Icon: Integer;
    IsLatesPinned: Boolean;
    Pinnable: Boolean;
    Caption: string;
  end;

  TVtList = TList<TVtItem>;

  TJumplistAlign = (jaLeft = 0, jaTop = 1, jaRight = 2, jaBottom = 3);

  TIconCache = TDictionary<Cardinal, Integer>;

  TFormJumpList = class(TForm)
  private
    FJumpList: TJumpList;
    FAppId: String;
    FAppExe: PItemIDList;
    FWnd: HWND;
    FMaxCount: Integer;
    FJumpItemIndex: DWORD;
    FPopupMenu: TPopupMenu;
    FIconSize: Integer;
    FX, FY: Integer;
    FAlign: TJumplistAlign;
    FVtList: TVtList;
    FPopupMenuVisible: Boolean;
    oBgBmp: TBitmap;
    oIconCache: TIconCache;
    RectBody: TRect;
    RectFooter: TRect;
    procedure OnFormClick(Sender: TObject);
    procedure OnFormClose(Sender: TObject; var Action: TCloseAction);
    procedure OnFormContextPopup(Sender: TObject; MousePos: TPoint;
      var Handled: Boolean);
    procedure OnFormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure OnFormMouseLeave(Sender: TObject);
    procedure OnFormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure OnFormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    function GetItemIndexAt(AX, AY: Integer): Integer;
    procedure JumpListPopupMenuPopup(const X, Y: Integer);
    procedure OnJumpListPin(Sender: TObject);
    procedure OnJumpListUnPin(Sender: TObject);
    procedure OnJumpListRemove(Sender: TObject);
    procedure OnJumpListExecute(Sender: TObject);
    function ScaleDimension(const X: Integer): Integer;
  private
    hImageList: HIMAGELIST;
    function ExtractIcon(AItem: IUnknown; AItemType: TJumpItemType): Integer;
    function GetIcon(APath: PChar; AIndex: Integer;
      AIconSize: Integer): Integer; overload;
    function GetIcon(AFolder: IShellFolder; AChild: PItemIDList;
      AIconSize: Integer): Integer; overload;
    function UpdateJumpList: Boolean;
  private
    hLvTheme: HTHEME;
    procedure PrepareBackground(const AWidth, AHeight: Integer);
    procedure DrawJumplistItem(const AIndex: Integer; ASelected,
      APinActive: Boolean; ADrawBackground: Boolean = True);
    procedure PaintForm;
  private
    LastPinUnpinHash: Cardinal;
    _FHotIndex: Integer;
    procedure SetHotIndex(AValue: integer);
    procedure AlphaBlendAndClose;
    function PinSelected: boolean; inline;
    function Index: Integer; inline;
  private
    TipHwnd: HWND;
    TipPinText: string;
    TipUnpinText: string;
    TipPosOffset: TPoint;
    TipToolInfo: TToolInfo;
    TipShowTime, TipHideTime: Cardinal;
    TipMonitorRect: TRect;
    SelfBoundsRect: TRect;
    procedure PrepareTooltips;
    function GetDescription(const AItem: TVtItem; const AText: PChar; ASize: Integer): Boolean;
    procedure WMTimer(var Message: TMessage); message WM_TIMER;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure PaintWindow(DC: HDC); override;
    procedure WMNCHitTest(var Message: TWMNCHitTest); message WM_NCHITTEST;
    procedure WMKillFocus(var Message: TWMKillFocus); message WM_KILLFOCUS;
  public
    constructor CreateNew(AOwner: TComponent; Dummy: Integer = 0); override;
    destructor Destroy; override;
    function Popup(AWnd: HWND; AX, AY: Integer; AAlign: TJumplistAlign;
      const AAppId: String; AAppExe: PItemIDList; AMaxCount: Integer): Boolean;
    property HotIndex: Integer read _FHotIndex write SetHotIndex;
  end;

  procedure JumpListClose;

implementation

uses Math, Vcl.Themes, Winapi.Dwmapi, Winapi.ShellAPI, Winapi.ShLwApi,
  Winapi.ActiveX, Winapi.UxTheme, Linkbar.OS, Linkbar.Loc, Linkbar.Shell,
  Jumplists.Themes, ExplorerMenu, System.Win.Registry;

const
  ICI_NONE    = -1;
  ICI_DEFAULT = 0;
  ICI_UNPIN   = 1;
  ICI_PIN     = 2;
  ICI_CLEAR   = 3;

  INDEX_NONE = -1;
  INDEX_PIN  = $8000;
  MASK_PIN   = $7fff;

  TIMER_TOOLTIP_SHOW = 4;
  TIMER_TOOLTIP_HIDE = 5;

var
  _JumpList: TFormJumpList = nil;

  ListWidth: Integer = 0;
  ItemWidth: Integer = 0;
  ItemHeight: Integer = 0;
  ItemSpacing: Integer = 0;
  ItemPadding: Integer = 0;
  ItemMargin: Integer = 0;
  TextOffset: Integer = 0;
  TextGroupOffset: Integer = 0;
  PinButtonWidth: Integer = 0;
  FormOffset: Integer = 0;

  TextColorGroup: TColor;
  TextColorItem: TColor;
  TextColorItemSelected: TColor;
  TextColorItemNew: TColor;

// Macros from windowsx.h:   
// Important  Do not use the LOWORD or HIWORD macros to extract the x- and y-
// coordinates of the cursor position because these macros return incorrect results
// on systems with multiple monitors. Systems with multiple monitors can have
// negative x- and y- coordinates, and LOWORD and HIWORD treat the coordinates
// as unsigned quantities.

function MakePoint(const Param : DWord): TPoint; inline;
Begin
  Result := TPoint.Create(Param and $FFFF, Param shr 16);
End;

procedure JumpListClose;
begin
  if Assigned(_JumpList)
  then _JumpList.AlphaBlendAndClose;
end;

function HighContrastEnabled: Boolean;
var hc: THighContrast;
begin
  FillChar(hc, SizeOf(hc), 0);
  hc.cbSize := SizeOf(THighContrast);
  Result := SystemParametersInfo(SPI_GETHIGHCONTRAST, hc.cbSize, @hc, 0)
            and ((hc.dwFlags and HCF_HIGHCONTRASTON) <> 0)
end;

function AnimationWindowEnabled: Boolean;
var ai: TAnimationInfo;
begin
  FillChar(ai, SizeOf(ai), 0);
  ai.cbSize := SizeOf(ai);
  Result := SystemParametersInfo(SPI_GETANIMATION, SizeOf(ai), @ai, 0)
            and (ai.iMinAnimate <> 0);
end;

function AnimationTaskbarEnabled: Boolean;
const
  ATB_KEY_0 = '\Control Panel\Desktop';
  ATB_PROP_0 = 'UserPreferencesMask';

  ATB_KEY_1 = '\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced';
  ATB_PROP_1 = 'TaskbarAnimations';

var reg: TRegistry;
    buf: array[0..16] of Byte;
begin
  reg := TRegistry.Create;
  try
    // check "Animate controls and elements inside windows"
    reg.RootKey := HKEY_CURRENT_USER;
    Result := reg.OpenKeyReadOnly(ATB_KEY_0)
      and (reg.GetDataType(ATB_PROP_0) = rdBinary)
      and (reg.ReadBinaryData(ATB_PROP_0, buf, SizeOf(buf)) > 0)
      and (buf[4] = $12);

    if (Result)
    then begin
      // check "Taskbar animation"
      Result := reg.OpenKeyReadOnly(ATB_KEY_1)
         and (reg.GetDataType(ATB_PROP_1) = rdInteger)
         and (reg.ReadInteger(ATB_PROP_1) <> 0);
    end;
  finally
    reg.Free;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
// TFormJumpList
////////////////////////////////////////////////////////////////////////////////

{ GetCursorHeightMargin from Vcl.Forms.pas
  Return number of scanlines between the scanline containing cursor hotspot
    and the last scanline included in the cursor mask. }

{$IFDEF CPUX64}
  {$DEFINE PUREPASCAL}
{$ENDIF CPUX64}

function GetCursorHeightMargin: Integer;
var
  IconInfo: TIconInfo;
  BitmapInfoSize, BitmapBitsSize, ImageSize: DWORD;
  Bitmap: PBitmapInfoHeader;
  Bits: Pointer;
  BytesPerScanline: Integer;


    function FindScanline(Source: Pointer; MaxLen: Cardinal;
      Value: Cardinal): Cardinal;
{$IFDEF PUREPASCAL}
    var
      P: PByte;
    begin
      P := Source;
      Result := MaxLen;
      while (Result > 0) and (P^ = Value) do
      begin
        Inc(P);
        Dec(Result);
      end;
    end;
{$ELSE !PUREPASCAL}
{$IFDEF CPUX86}
    asm
            PUSH    ECX
            MOV     ECX,EDX
            MOV     EDX,EDI
            MOV     EDI,EAX
            POP     EAX
            REPE    SCASB
            MOV     EAX,ECX
            MOV     EDI,EDX
    end;
{$ENDIF CPUX86}
{$ENDIF !PUREPASCAL}

begin
  { Default value is entire icon height }
  Result := GetSystemMetrics(SM_CYCURSOR);
  if GetIconInfo(GetCursor, IconInfo) then
  try
    GetDIBSizes(IconInfo.hbmMask, BitmapInfoSize, BitmapBitsSize);
    Bitmap := AllocMem(BitmapInfoSize + BitmapBitsSize);
    try
      Bits := Pointer(PByte(Bitmap) + BitmapInfoSize);
      if GetDIB(IconInfo.hbmMask, 0, Bitmap^, Bits^) and
        (Bitmap^.biBitCount = 1) then
      begin
        { Point Bits to the end of this bottom-up bitmap }
        with Bitmap^ do
        begin
          BytesPerScanline := ((biWidth * biBitCount + 31) and not 31) div 8;
          ImageSize := biWidth * BytesPerScanline;
          Bits := Pointer(PByte(Bits) + BitmapBitsSize - ImageSize);
          { Use the width to determine the height since another mask bitmap
            may immediately follow }
          Result := FindScanline(Bits, ImageSize, $FF);
          { In case the and mask is blank, look for an empty scanline in the
            xor mask. }
          if (Result = 0) and (biHeight >= 2 * biWidth) then
            Result := FindScanline(Pointer(PByte(Bits) - ImageSize),
            ImageSize, $00);
          Result := Result div BytesPerScanline;
        end;
        Dec(Result, IconInfo.yHotSpot);
      end;
    finally
      FreeMem(Bitmap, BitmapInfoSize + BitmapBitsSize);
    end;
  finally
    if IconInfo.hbmColor <> 0 then DeleteObject(IconInfo.hbmColor);
    if IconInfo.hbmMask <> 0 then DeleteObject(IconInfo.hbmMask);
  end;
end;

function TFormJumpList.ScaleDimension(const X: Integer): Integer;
begin
  Result := MulDiv(X, Self.PixelsPerInch, 96);
end;

constructor TFormJumpList.CreateNew(AOwner: TComponent; Dummy: Integer = 0);
var color: Cardinal;
    info: TSHFileInfo;
    hr: HRESULT;
    h: HMODULE;
    icon: HICON;
begin
  inherited;
  _JumpList := Self;
  FormStyle := fsStayOnTop;
  KeyPreview := True;
  Color := clRed;

  _FHotIndex := INDEX_NONE;

  OnClick := OnFormClick;
  OnClose := OnFormClose;
  OnContextPopup := OnFormContextPopup;
  OnKeyDown := OnFormKeyDown;
  OnMouseLeave := OnFormMouseLeave;
  OnMouseMove := OnFormMouseMove;
  OnMouseDown := OnFormMouseDown;

  ThemeJlInit;

  FIconSize := GetSystemMetrics(SM_CXSMICON);

  ListWidth := ScaleDimension(269);

  if (IsWindows10)
  then begin
    ItemMargin := 0;
    ItemPadding := ScaleDimension(6);
    ItemHeight := FIconSize + 2 * ItemPadding;
    ItemSpacing := 0;
    TextGroupOffset := ItemPadding;
    PinButtonWidth := ItemHeight;
    FormOffset := 0;
  end
  else begin
    ItemMargin := 7;
    ItemPadding := 2;
    ItemHeight := FIconSize + 2 * ItemPadding;
    ItemSpacing := 2;
    TextGroupOffset := 0;
    PinButtonWidth := FIconSize + ScaleDimension(10);

    if (DwmCompositionEnabled)
    then FormOffset := ScaleDimension(3)
    else if (StyleServices.Enabled)
         then FormOffset := 0
         else FormOffset := -ScaleDimension(2);
  end;

  ItemWidth := ListWidth - 2 * ItemMargin;
  TextOffset := ItemHeight + ScaleDimension(3);

  hImageList := ImageList_Create(FIconSize, FIconSize, ILC_COLOR32 or ILC_MASK, 8, 8);

  // Add default blank icon (default icon for file with no extension)
  if ( SHGetFileInfo('file', FILE_ATTRIBUTE_NORMAL, info, SizeOf(info),
    SHGFI_USEFILEATTRIBUTES or SHGFI_ICON or SHGFI_SMALLICON) <> 0)
  then begin
    ImageList_AddIcon(hImageList, info.hIcon);
    DestroyIcon(info.hIcon);
  end;
  // Add pin ans unpin icons
  h := LoadLibraryEx(PChar('imageres.dll'), 0, LOAD_LIBRARY_AS_DATAFILE);
  if (h <> 0)
  then begin
    // unpin icon
    icon := LoadImage(h, MakeIntResource(5100), IMAGE_ICON, FIconSize, FIconSize, LR_DEFAULTCOLOR);
    if (icon <> 0)
    then begin
      ImageList_AddIcon(hImageList, icon);
      DestroyIcon(icon);
    end;
    // pin icon
    icon := LoadImage(h, MakeIntResource(5101), IMAGE_ICON, FIconSize, FIconSize, LR_DEFAULTCOLOR);
    if (icon <> 0)
    then begin
      ImageList_AddIcon(hImageList, icon);
      DestroyIcon(icon);
    end;
    FreeLibrary(h);
  end;

  // Get text colors for header and item
  TextColorGroup := clWindowText;
  TextColorItem := clMenuText;
  TextColorItemSelected := clHighlightText;
  TextColorItemNew := clInfoText;

  if (IsWindows10)
  then begin
    // For Windows 10
    TextColorGroup := clWhite;
    TextColorItem := clWhite;
    TextColorItemSelected := clWhite;
    TextColorItemNew := clBlack;
  end
  else begin
    // For Windows 7, 8, 8.1
    if StyleServices.Enabled
    then begin
      hLvTheme := OpenThemeData(Handle, VSCLASS_LISTVIEW);
      if (hLvTheme <> 0)
      then begin
        hr := GetThemeColor(hLvTheme, LVP_GROUPHEADER, LVGH_OPEN, TMT_HEADING1TEXTCOLOR, color);
        if ( hr = S_OK )
        then TextColorGroup := TColorRef(color);
      end;

      TextColorItem := clMenuText;

      if HighContrastEnabled
      then TextColorItemSelected := clHighlightText
      else TextColorItemSelected := clMenuText;

      TextColorItemNew := TextColorItem;
    end;
  end;

  // Get cursor size for tooltip offset
  TipPosOffset.X := 0;
  TipPosOffset.Y := GetCursorHeightMargin;

  // Get tooltip show/hide delay
  TipShowTime := GetDoubleClickTime();
  TipHideTime := TipShowTime * 10;

  // Get pin/unpin button hint text
  TipUnpinText := StripHotkey( MUILoadResString(LB_FN_JUMPLIST, LB_RS_JL_UNPIN) );
  TipPinText := StripHotkey( MUILoadResString(LB_FN_JUMPLIST, LB_RS_JL_PIN) );

  LastPinUnpinHash := 0;
  TipHwnd := 0;

  FJumpList := TJumpList.Create;

  FVtList := TVtList.Create;
  FVtList.Capacity := 16;

  oBgBmp := TBitmap.Create;
  oBgBmp.PixelFormat := pf24bit;

  oIconCache := TIconCache.Create(16);
end;

procedure TFormJumpList.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.Style := WS_POPUP or WS_BORDER;
  if (IsWindows7 and DwmCompositionEnabled)
     or (IsWindows8And8Dot1)
  then Params.Style := Params.Style or WS_THICKFRAME;

  Params.ExStyle := (Params.ExStyle or WS_EX_TOOLWINDOW) and not WS_EX_APPWINDOW;
end;

destructor TFormJumpList.Destroy;
begin
  _JumpList := nil;
  DestroyWindow(TipHwnd);
  ImageList_Destroy(hImageList);
  FJumpList.Free;
  FVtList.Free;
  oBgBmp.Free;
  oIconCache.Free;
  CloseThemeData(hLvTheme);
  ThemeJlDeinit;
  inherited;
end;

function TFormJumpList.PinSelected: boolean;
begin
  Result := (_FHotIndex and INDEX_PIN) <> 0;
end;

function TFormJumpList.Index: Integer;
begin
  if (_FHotIndex = INDEX_NONE)
  then Result := _FHotIndex
  else Result := _FHotIndex and MASK_PIN;
end;

function TFormJumpList.GetIcon(APath: PChar; AIndex: Integer; AIconSize: Integer): Integer;
var res: Integer;
    key: Cardinal;
    icon: HICON;
begin
  //CharUpper(APath); see comment in overloaded GetIcon (below)
  key := CalcFNVHash( APath, CalcFNVHash(AIndex, 4) );
  if not oIconCache.TryGetValue(key, res)
  then begin
    icon := SHExtractIcon(APath, AIndex, AIconSize);
    if (icon <> 0)
    then begin
      res := ImageList_AddIcon(hImageList, icon);
      DestroyIcon(icon);
      oIconCache.Add(key, res);
    end;
  end;
  Result := res;
end;

function TFormJumpList.GetIcon(AFolder: IShellFolder; AChild: PItemIDList;
  AIconSize: Integer): Integer;
var res: Integer;
    hr: HRESULT;
    pExtract: IExtractIcon;
    icon, icon2: HICON;
    location: array[0..MAX_PATH] of Char;
    index: integer;
    flags: UINT;
    key: Cardinal;
    bUseFactory: Boolean;
    icoi: TIconInfo;
    bmpi: Windows.BITMAP;
    pFactory: IShellItemImageFactory;
    hbmp: HBITMAP;
begin
  icon := 0;
  key := 0;
  bUseFactory := False;

  hr := AFolder.GetUIObjectOf(0, 1, AChild, IExtractIcon, nil, pExtract);
  if Succeeded(hr)
  then begin
    location[0] := #0;
    hr := pExtract.GetIconLocation(0, location, MAX_PATH, index, flags);
    if (hr <> S_OK)
    then Exit( ICI_DEFAULT );
    //CharUpper(location); ! Can't get favicon for internet shortcuts with uppercase location
    // check if this location+index is in the cache
    key := CalcFNVHash( location, CalcFNVHash(index, 4) );
    if oIconCache.TryGetValue(key, res)
    then Exit(res);

    if ( flags and GIL_NOTFILENAME = GIL_NOTFILENAME )
    then begin
      icon2 := 0;
      hr := pExtract.Extract(location, index, icon2, icon, MakeLong(AIconSize, AIconSize));
      if Failed(hr)
      then begin
        icon := 0;
        icon2 := 0;
      end
      else begin
        if (icon <> 0)
        then begin
          GetIconInfo(icon, icoi);
          GetObject(icoi.hbmColor, SizeOf(bmpi), @bmpi);
          if (icoi.hbmColor <> 0) then DeleteObject(icoi.hbmColor);
          if (icoi.hbmMask <> 0) then DeleteObject(icoi.hbmMask);
          if (bmpi.bmWidth < AIconSize)
          then begin
            DestroyIcon(icon);
            icon := 0;
            bUseFactory := True;
          end;
        end;
        if (icon2 <> 0)
        then DestroyIcon(icon2);
      end;
      if (hr = S_FALSE)
      then begin
        // we are not supposed to be getting S_FALSE here,
        // but we do (like for EXEs that don't have an icon). fallback to factory
        bUseFactory := True;
      end;
    end;
    if ( flags and GIL_NOTFILENAME = 0 )
    then begin
      // the IExtractIcon object didn't do anything - use ShExtractIcon instead
      if (index = -1)
      then index := 0;
      icon := SHExtractIcon(location, index, AIconSize);
    end;
  end;

  res := ICI_DEFAULT;
  if (bUseFactory)
  then begin
    if Succeeded( SHCreateItemWithParent(nil, AFolder, AChild, IShellItemImageFactory, pFactory) )
       and Assigned(pFactory)
    then begin
      if Succeeded( pFactory.GetImage(TSize.Create(AIconSize, AIconSize), SIIGBF_ICONONLY, hbmp) )
      then begin
        res := ImageList_AddMasked(hImageList, hbmp, CLR_NONE);
        DeleteObject(hbmp);
      end;
    end;
  end;

  // add to the image list
  if (icon <> 0)
  then begin
    res := ImageList_AddIcon(hImageList, icon);
    DestroyIcon(icon);
    oIconCache.AddOrSetValue(key, res);
  end;

  Result := res;
end;

function TFormJumpList.ExtractIcon(AItem: IUnknown; AItemType: TJumpItemType): Integer;
var res: Integer;
    hr: HRESULT;
    pidl: PItemIDList;
    pLink: IShellLink;
    location: array[0..MAX_PATH] of Char;
    index: integer;
    pItem: IShellItem;
    pFolder: IShellFolder;
    child: PItemIDList;
    child2: PItemIDList;
    str: TStrRet;
    name, test: PChar;
begin
  res := ICI_NONE;
  pidl := nil;

  if (AItemType = jiLink)
  then begin
    AItem.QueryInterface(IShellLink, pLink);
    if Assigned(pLink)
    then begin
      pLink.GetIDList(pidl);
      location[0] := #0;
      hr := pLink.GetIconLocation(location, MAX_PATH, index);
      if Succeeded(hr) and (location[0] <> #0)
      then begin
        if (index = -1)
        then index := 0;
        res := GetIcon(location, index, FIconSize);
      end;
    end;
  end;

  if (AItemType = jiItem)
  then begin
    AItem.QueryInterface(IShellItem, pItem);
    if Assigned(pItem)
    then SHGetIDListFromObject(pItem, pidl);
  end;

  if (res = ICI_NONE) and Assigned(pidl)
  then begin
    child := nil;
    hr := SHBindToFolderIDListParent(nil, pidl, IShellFolder, Pointer(pFolder), child);
    if Succeeded( hr )
    then begin
      { next code extract preview from images (and ?) }
      // do some pidl laundering. sometimes the pidls from the jumplists may
      // contain weird hidden data, which affects the icon so do a round-trip
      // convertion of the pidl to a display name
      hr := pFolder.GetDisplayNameOf(child, SHGDN_FORPARSING, str);
      if Succeeded( hr )
      then begin
        //name := StrRetToString(child, str);
        StrRetToStr(@str, child, name);
        child2 := nil;
        test := PathFindFileName(name);
        hr := pFolder.ParseDisplayName(0, nil, test, PULONG(nil)^, child2, PULONG(nil)^);
        if Succeeded( hr )
        then begin
          // make sure child2 points to the same item in the folder
          if ILIsChild(child2)
             and (pFolder.CompareIDs(SHCIDS_CANONICALONLY, child, child2) = 0)
          then res := GetIcon(pFolder, child2, FIconSize);
          CoTaskMemFree(child2);
        end;
        CoTaskMemFree(name);
      end;
      {}
      if (res = ICI_NONE)
      then res := GetIcon(pFolder, child, FIconSize);
    end;
  end;
  CoTaskMemFree(pidl);
  Result := res;
end;

procedure TFormJumpList.OnFormClick(Sender: TObject);
var vi: TVtItem;
    jg: TJumpGroupeType;
begin
  if (Index = INDEX_NONE)
  then Exit;

  vi := FVtList[Index];
  if (vi.Style = vtItem)
  then begin
    FJumpItemIndex := MakeLong(vi.Item, vi.Group);

    jg := FJumpList.Groups[vi.Group].eType;

    if vi.Pinnable
    then begin
      if PinSelected
      then begin
        if ( jg = jgPinned )
        then OnJumpListUnPin(nil)
        else OnJumpListPin(nil);
      end
      else
        OnJumpListExecute(nil);
    end
    else
      OnJumpListExecute(nil);
    Exit;
  end;

  if (vi.Style = vtFooter)
  then begin
    AlphaBlendAndClose;
    ExplorerMenu.OpenByDefaultVerb(FWnd, FAppExe);
  end;
end;

procedure TFormJumpList.OnFormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TFormJumpList.OnFormContextPopup(Sender: TObject; MousePos: TPoint;
  var Handled: Boolean);
var vi: TVtItem;
    shift: Boolean;
begin
  Handled := True;
  if (Index <> INDEX_NONE)
  then begin
    vi := FVtList[Index];
    if (vi.Style = vtItem)
    then begin
      FJumpItemIndex := MakeLong(vi.Item, vi.Group);
      MapWindowPoints(Handle, HWND_DESKTOP, MousePos, 1);
      JumpListPopupMenuPopup(MousePos.X, MousePos.Y);
      Exit;
    end;

    if (vi.Style = vtFooter)
    then begin
      MapWindowPoints(Handle, HWND_DESKTOP, MousePos, 1);
      shift := (GetKeyState(VK_SHIFT) < 0);
      // TODO: may will be need AlphaBlendAndClose and process messages after invokecommand
      FPopupMenuVisible := True;
      ExplorerMenuPopup(FWnd, FAppExe, MousePos, shift, 0);
      FPopupMenuVisible := False;
      Exit;
    end;
  end;
end;

procedure TFormJumpList.OnFormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key = VK_ESCAPE)
  then Close;
end;

procedure TFormJumpList.OnFormMouseLeave(Sender: TObject);
begin
  if (not FPopupMenuVisible)
  then HotIndex := INDEX_NONE;
end;

function TFormJumpList.GetItemIndexAt(AX, AY: Integer): Integer;
var i, res: Integer;
begin
  res := INDEX_NONE;
  for i := 0 to FVtList.Count-1 do
  begin
    if PtInRect(FVtList[i].Rect, Point(AX, AY))
    then begin
      res := i;
      Break;
    end;
  end;
  Result := res;
end;

var TempX: Integer = -1;
    TempY: Integer = -1;

procedure TFormJumpList.OnFormMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
var idx: Integer;
    vi: TVtItem;
begin
  if (TempX = X) and (TempY = Y) then Exit;
  TempX := X; TempY := Y;

  idx := GetItemIndexAt(X, Y);

  if (idx <> INDEX_NONE)
  then begin
    vi := FVtList[idx];
    if (vi.Style in [vtItem, vtFooter])
    then begin
      if (vi.Pinnable) and (X >= (vi.Rect.Right - PinButtonWidth))
      then idx := idx or INDEX_PIN;
    end
    else idx := INDEX_NONE;
  end;

  HotIndex := idx;
end;

procedure TFormJumpList.OnFormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  KillTimer(Handle, TIMER_TOOLTIP_SHOW);
  SendMessage(TipHwnd, TTM_POP, 0, 0);
end;

procedure TFormJumpList.AlphaBlendAndClose;
begin
  // Hack for hide window
  AlphaBlendValue := 0;
  AlphaBlend := True;
  Close;
end;

procedure TFormJumpList.WMKillFocus(var Message: TWMKillFocus);
// Close
begin
  AlphaBlendAndClose;
  Message.Result := 0;
end;

procedure TFormJumpList.WMNCHitTest(var Message: TWMNCHitTest);
// Disable window resize
begin
  Message.Result := HTCLIENT;
end;

procedure TFormJumpList.DrawJumplistItem(const AIndex: Integer;
  ASelected, APinActive: Boolean; ADrawBackground: Boolean = True);
var vi: TVtItem;
    itemrect, pinrect: TRect;
    text: string;
    state, index: Integer;
    jlgt: TJumpGroupeType;
    color: TColor;
begin
  if (AIndex < 0)
     or (AIndex >= FVtList.Count)
  then Assert(False);

  vi := FVtList[AIndex];

  if not (vi.Style in [vtItem, vtFooter])
  then Exit;

  itemrect := vi.Rect;

  if (ADrawBackground)
  then begin
    if (vi.Style = vtFooter)
    then ThemeJlDrawBackground(oBgBmp.Canvas.Handle, LBJL_BGPID_FOOTER, RectFooter, itemrect)
    else ThemeJlDrawBackground(oBgBmp.Canvas.Handle, LBJL_BGPID_BODY, RectBody, itemrect);
  end;

  jlgt := FJumpList.Groups[vi.Group].eType;

  // Draw Button
  if ASelected
  then begin
    if (not vi.Pinnable)
    then begin
      // Main button
      if (vi.Style = vtFooter)
      then ThemeJlDrawButton(oBgBmp.Canvas.Handle, LBJL_ITPID_FOOT, LBJL_ITSID_SELECTED, itemrect)
      else ThemeJlDrawButton(oBgBmp.Canvas.Handle, LBJL_ITPID_BTN, LBJL_ITSID_SELECTED, itemrect);
      // Pin button not needed
    end
    else begin
      itemrect.Right := itemrect.Right - PinButtonWidth;
      // Pin button
      pinrect := Bounds(itemrect.Right, itemrect.Top, PinButtonWidth, itemrect.Height);
      if (APinActive)
      then state := LBJL_ITSID_SELECTED
      else state := LBJL_ITSID_HOT;
      ThemeJlDrawButton(oBgBmp.Canvas.Handle, LBJL_ITPID_PIN, state, pinrect);
      // Pin button icon
      if (jlgt = jgPinned)
      then index := ICI_UNPIN
      else index := ICI_PIN;
      ImageList_Draw(hImageList, index, oBgBmp.Canvas.Handle,
          pinrect.Left + (PinButtonWidth - FIconSize) div 2,
          pinrect.Top + ItemPadding, ILD_IMAGE);
      // Main button
      if (APinActive)
      then state := LBJL_ITSID_HOT
      else state := LBJL_ITSID_SELECTED;
      ThemeJlDrawButton(oBgBmp.Canvas.Handle, LBJL_ITPID_BTN_LFT, state, itemrect);
    end;
  end
  else begin
    // Check and draw justnow pin/unpin item
    if (vi.IsLatesPinned)
    then ThemeJlDrawButton(oBgBmp.Canvas.Handle, LBJL_ITPID_BTN, LBJL_ITSID_NEW, itemrect);
  end;

  // Draw icon
  ImageList_Draw(hImageList, vi.Icon, oBgBmp.Canvas.Handle,
    itemrect.Left + ItemPadding, itemrect.Top + ItemPadding, ILD_IMAGE);

  // Draw caption
  if vi.Style = vtFooter
  then text := vi.Caption
  else text := FJumpList.Groups[vi.Group].Items[vi.Item].Name;

  if ASelected
  then color := TextColorItemSelected
  else begin
    if (vi.IsLatesPinned)
    then color := TextColorItemNew
    else color := TextColorItem;
  end;

  oBgBmp.Canvas.Font.Color := color;
  oBgBmp.Canvas.Brush.Style := bsClear;
  itemrect.Left := itemrect.Left + TextOffset;
  itemrect.Right := itemrect.Right - 1;
  DrawText(oBgBmp.Canvas.Handle, text, -1, itemrect,
    DT_SINGLELINE or DT_VCENTER or DT_END_ELLIPSIS or DT_WORD_ELLIPSIS);
end;

procedure TFormJumpList.PrepareBackground(const AWidth, AHeight: Integer);
var i: Integer;
    vi: TVtItem;
    tr, lr: TRect;
    text: string;
    fs: TFontStyles;
    brush: HBRUSH;
    //
    hcinfo: THighContrast;
begin
  oBgBmp.SetSize(AWidth, AHeight);
  oBgBmp.Canvas.Font := Screen.IconFont;

  { Draw body & footer backgrounds }
  if (FVtList.Last.Style = vtFooter)
  then ThemeJlDrawBackground(oBgBmp.Canvas.Handle, LBJL_BGPID_FOOTER, RectFooter, RectFooter);
  ThemeJlDrawBackground(oBgBmp.Canvas.Handle, LBJL_BGPID_BODY, RectBody, RectBody);

  { Draw body-footer divider if Styles disabled }
  if not StyleServices.Enabled
  then begin
    hcinfo.cbSize := SizeOf(hcinfo);
    SystemParametersInfo(SPI_GETHIGHCONTRAST, hcinfo.cbSize, @hcinfo, 0);
    if ( (hcinfo.dwFlags and HCF_HIGHCONTRASTON) <> 0 )
    then begin
      lr := Rect(ItemMargin, RectBody.Bottom, RectBody.Right-ItemMargin, RectBody.Bottom + 1);
      brush := GetSysColorBrush(COLOR_WINDOWTEXT);
      FillRect(oBgBmp.Canvas.Handle, lr, brush);
    end
    else begin
      lr := Rect(ItemMargin, RectBody.Bottom, RectBody.Right-ItemMargin, RectBody.Bottom + 2{3});
      DrawEdge(oBgBmp.Canvas.Handle, lr, BDR_RAISEDINNER, BF_RECT);
    end;
  end; {}

  { Draw items }
  for i := 0 to FVtList.Count-1 do
  begin
    vi := FVtList[i];

    case vi.Style of
      //-----------------------------------------------------------------------
      vtEmpty: Continue;
      //-----------------------------------------------------------------------
      vtItem, vtFooter:
      begin
        // Draw Item
        DrawJumplistItem(i, False, False, False);
      end;
      //-----------------------------------------------------------------------
      vtGroup:
      begin
        // Draw Group
        text := FJumpList.Groups[vi.Group].Name;
        if (IsWindows10)
        then begin
          lr := Rect(vi.Rect.Left + ItemPadding, vi.Rect.Bottom-ScaleDimension(1),
            vi.Rect.Right - ItemPadding, vi.Rect.Bottom);
          brush := CreateSolidBrush($555555);
          FillRect(oBgBmp.Canvas.Handle, lr, brush);
          DeleteObject(brush);
        end
        else begin
          // calc text rect
          tr := vi.Rect;
          DrawText(oBgBmp.Canvas.Handle, text, -1, tr,
            DT_CALCRECT or DT_SINGLELINE or DT_VCENTER);
          // calc and darw group header line
          lr := Rect(tr.Right + ItemSpacing*2, vi.Rect.CenterPoint.Y, vi.Rect.Right, vi.Rect.CenterPoint.Y+1);
          DrawThemeBackground(hLvTheme, oBgBmp.Canvas.Handle, LVP_GROUPHEADERLINE,
            LVGHL_OPEN, lr, @lr);
        end;

        // darw caption
        oBgBmp.Canvas.Brush.Style := bsClear;
        oBgBmp.Canvas.Font.Color := TextColorGroup;
        fs := oBgBmp.Canvas.Font.Style;
        if not StyleServices.Enabled
        then oBgBmp.Canvas.Font.Style := [fsBold];
        tr := vi.Rect;
        tr.Left := tr.Left + TextGroupOffset;
        DrawText(oBgBmp.Canvas.Handle, text, -1, tr,
          DT_SINGLELINE or DT_VCENTER or DT_END_ELLIPSIS or DT_WORD_ELLIPSIS);
        oBgBmp.Canvas.Font.Style := fs;
      end;
      //-----------------------------------------------------------------------
      vtSeparator:
      begin
        if (IsWindows10)
        then begin
          lr := Bounds(vi.Rect.Left + ItemPadding, vi.Rect.CenterPoint.Y,
            vi.Rect.Width - ItemPadding*2, ScaleDimension(1));
          brush := CreateSolidBrush($555555);
          FillRect(oBgBmp.Canvas.Handle, lr, brush);
          DeleteObject(brush);
        end
        else begin
          // calc and darw separator line
          lr := Bounds(vi.Rect.Left, vi.Rect.CenterPoint.Y-1, vi.Rect.Width, ScaleDimension(1));
          DrawThemeBackground(hLvTheme, oBgBmp.Canvas.Handle, LVP_GROUPHEADERLINE,
            LVGHL_OPEN, lr, @lr);
        end;
      end;
      //-----------------------------------------------------------------------
    end;
  end;
end;

function CheckFileDrive(const FileName: string): Boolean;
begin
  if (FileName.Length >= 2) and (FileName.Chars[1] = DriveDelim)
  then Exit(True)
  else if (FileName.Length >= 2)
    and (FileName.Chars[0] = PathDelim)
    and (FileName.Chars[1] = PathDelim)
  then Exit(True);
  Result := False;
end;

procedure GetShellDescription(APidl: PItemIDList; AText: PChar; ASize: Integer);
var pFolder: IShellFolder;
    child: PItemIDList;
    pQueryInfo: IQueryInfo;
    pTip: PChar;
begin
  if Succeeded(SHBindToParent(APidl, IShellFolder, Pointer(pFolder), child))
  then begin
    if Succeeded(pFolder.GetUIObjectOf(0, 1, child, IQueryInfo, nil, pQueryInfo))
    then begin
      pTip := nil;
      if Succeeded( pQueryInfo.GetInfoTip(QITIPF_DEFAULT, pTip) )
         and (pTip <> nil)
      then begin
        StrPLCopy(AText, pTip, ASize);
        CoTaskMemFree(pTip);
      end;
    end;
  end;
end;

function TFormJumpList.GetDescription(const AItem: TVtItem; const AText: PChar;
  ASize: Integer): Boolean;
var ji: TJumpItem;
    pItem: IShellItem;
    pQueryInfo: IQueryInfo;
    pTip: PChar;
    pLink: IShellLink;
    pidl: PItemIDList;
    args: array[0..MAX_PATH] of Char;
    fn: string;
begin
  if (AItem.Style = vtFooter)
  then begin
    AText[0] := #0;
    GetShellDescription(FAppExe, AText, ASize);
    Exit(AText[0] <> #0);
  end;

  pidl := nil;

  ji := FJumpList.Groups[AItem.Group].Items[AItem.Item];

  if (ji.eType = jiItem)
  then begin
    ji.Item.QueryInterface(IID_IShellItem, pItem);
    if Assigned(pItem)
    then begin
      if Succeeded( pItem.GetDisplayName(SIGDN_DESKTOPABSOLUTEEDITING, pTip) )
      then begin
        { tip: FILENAME }
        fn := pTip; CoTaskMemFree(pTip);
        if CheckFileDrive(fn)
        then begin
          { tip: NAME (PATH) // simulate explorer tip
            TODO: need upgrade for Drives
          fn := ExtractFileName(fn) + ' (' + ExcludeTrailingPathDelimiter(ExtractFilePath(fn)) + ')'; {}
          StrPLCopy(AText, PChar(fn), ASize);
          Exit(True);
        end;
      end;

      { get queryinfo default tip }
      if Succeeded( pItem.BindToHandler(nil, BHID_SFUIObject, IQueryInfo, pQueryInfo) )
      then begin
        pTip := nil;
        if Failed( pQueryInfo.GetInfoTip(QITIPF_DEFAULT, pTip) )
           or (pTip = nil)
        then Exit(False);
        StrPLCopy(AText, pTip, ASize);
        CoTaskMemFree(pTip);
        Exit(True);
      end;
      // get pidl for shell tip getter (see. below)
      SHGetIDListFromObject(pItem, pidl);
    end;
  end;

  if (ji.eType = jiLink)
  then begin
    ji.Item.QueryInterface(IID_IShellLink, pLink);
    if Assigned(pLink)
    then begin
      AText[0] := #0;
      if Succeeded( pLink.GetDescription(AText, ASize) )
         and (AText[0] <> #0)
      then Exit(True);
      { get arguments }
      args[0] := #0;
      if Succeeded( pLink.GetArguments(args, MAX_PATH) )
         and (args[0] <> #0)
      then begin
        { don't use default tip for items with arguments
        s := ji.Name + sLineBreak + 'cmd: ' + args;
        StrPLCopy(AText, PChar(s), ASize); {}
        { tip: ITEM NAME }
        StrPLCopy(AText, PChar(ji.Name), ASize); {}
        Exit(True);
      end;
      { tip: FILENAME }
      if (pLink.GetPath(AText, ASize, PWin32FindData(nil)^, 0) = S_OK)
      then Exit(True); {}

      // get pidl for shell tip getter (see. below)
      pLink.GetIDList(pidl);
    end;
  end;

  { get the tip from the shell }
  if Assigned(pidl)
  then begin
    AText[0] := #0;
    GetShellDescription(pidl, AText, ASize);
    CoTaskMemFree(pidl);
    Exit( AText[0] <> #0 );
  end;

  Result := False;
end;

procedure TFormJumpList.PrepareTooltips;
var margin: TRect;
    m: Integer;
begin
  if (TipHwnd <> 0)
  then DestroyWindow(TipHwnd);

  // NOTE:
  // A tooltip control always has the WS_POPUP and WS_EX_TOOLWINDOW window styles,
  // regardless of whether you specify them when creating the control.
  TipHwnd := CreateWindowEx(WS_EX_TOPMOST or WS_EX_TRANSPARENT,
    TOOLTIPS_CLASS, nil, TTS_NOPREFIX or TTS_ALWAYSTIP,
    0, 0, 0, 0, Handle, 0, HInstance, nil);

  if (TipHwnd <> 0)
  then begin
    SendMessage(TipHwnd, TTM_SETMAXTIPWIDTH, 0 , 400);

    // Windows 7, classic themes, jumplist, tooltip have non-default margins (4,4,4,4) and font
    if not StyleServices.Enabled
    then begin
      m := ScaleDimension(4);
      margin := Rect(m,m,m,m);
      SendMessage(TipHwnd, TTM_SETMARGIN, 0, LParam(@margin));
      SendMessage(TipHwnd, WM_SETFONT, Wparam(Screen.IconFont.Handle), 0);
    end;

    FillChar(TipToolInfo, SizeOf(TipToolInfo), 0);
    TipToolInfo.cbSize := SizeOf(TipToolInfo);
    TipToolInfo.uFlags := TTF_TRACK or TTF_ABSOLUTE or TTF_TRANSPARENT;
    TipToolInfo.uId := 1;
    SendMessage(TipHwnd, TTM_ADDTOOL, 0, LParam(@TipToolInfo));
  end;
end;

function FitTipRect(const r1, r2: TRect): TPoint;
var tr: TRect;
begin
  if PtInRect(r2, r1.TopLeft)
     and PtInRect(r2, r1.BottomRight)
  then Exit(r1.TopLeft);

  tr := r1;

  if tr.Right > r2.Right then tr.Left := r2.Right - r1.Width;
  if tr.Bottom > r2.Bottom  then tr.Top := r2.Bottom - r1.Height;

  if tr.Left < r2.Left then tr.Left := r2.Left;
  if tr.Top < r2.Top then tr.Top := r2.Top;

  Result := tr.TopLeft;
end;

procedure TFormJumpList.WMTimer(var Message: TMessage);
var pt: TPoint;
    vi: TVtItem;
    tip: array[0..1024] of Char;
    jgt: TJumpGroupeType;
    tr: TRect;
    npt: TPoint;
    i: Integer;
begin
  if (Message.WParam = TIMER_TOOLTIP_SHOW)
  then begin
    KillTimer(Handle, TIMER_TOOLTIP_SHOW);

    if FPopupMenuVisible
    then Exit;

    i := Index;
    if (i = INDEX_NONE) or (i >= FVtList.Count)
    then Exit;

    vi := FVtList[i];

    if not (vi.Style in [vtItem])
    then Exit;

    jgt := FJumpList.Groups[vi.Group].eType;

    if (not vi.Pinnable)
       or (not PinSelected)
    then begin
      tip[0] := #0;
      if not GetDescription(vi, tip, Length(tip))
      then Exit;
      TipToolInfo.lpszText := tip;
    end
    else begin
      if (jgt = jgPinned)
      then TipToolInfo.lpszText := PChar(TipUnpinText)
      else TipToolInfo.lpszText := PChar(TipPinText);
    end;

    pt := MakePoint(GetMessagePos);
    if (WindowFromPoint(pt) <> Handle)
    then Exit;

    pt.Offset(TipPosOffset);

		SendMessage(TipHwnd, TTM_UPDATETIPTEXT, 0, LParam(@TipToolInfo));
		SendMessage(TipHwnd, TTM_TRACKPOSITION, 0, MakeLParam(pt.X, pt.Y));
		SendMessage(TipHwnd, TTM_TRACKACTIVATE, WParam(True), LParam(@TipToolInfo));

    GetWindowRect(TipHwnd, tr);
    npt := FitTipRect(tr, TipMonitorRect);
    if (npt <> pt)
    then SendMessage(TipHwnd, TTM_TRACKPOSITION, 0, MakeLParam(npt.X, npt.Y));

    SetTimer(Handle, TIMER_TOOLTIP_HIDE, TipHideTime, nil);

    Exit;
  end;

  if (Message.WParam = TIMER_TOOLTIP_HIDE)
  then begin
    SendMessage(TipHwnd, TTM_TRACKACTIVATE, WParam(False), LParam(@TipToolInfo));
    KillTimer(Handle, TIMER_TOOLTIP_HIDE);
    Exit;
  end;
end;

function TFormJumpList.UpdateJumpList: Boolean;
var NeedUninitialize: Boolean;
    g, i: Integer;
    jg: TJumpGroup;
    ji: TJumpItem;
    vi: TVtItem;
    vr: TRect;
    r: TRect;
    monrect: TRect;
    L, T, W, H: Integer;
    pItem: IShellItem;
    ppszName: PChar;
begin
  Result := False;
  if GetJumplist(PChar(FAppId), FJumpList, FMaxCount)
  then begin
    FVtList.Clear;
    vr := TRect.Empty;
    // CoInitializeEx used for GetIcon
    NeedUninitialize := SUCCEEDED(CoInitializeEx(nil, COINIT_APARTMENTTHREADED or COINIT_DISABLE_OLE1DDE));
    try
      for g := 0 to FJumpList.Groups.Count-1 do
      begin
        jg := FJumpList.Groups[g];
        if jg.Hidden
        then Continue;
        // Add group
        vi.Style := vtGroup;
        vi.Group := g;
        if vr.IsEmpty
        then vr := Bounds(ItemMargin, ItemSpacing, ItemWidth, ItemHeight)
        else vr.Offset(0, ItemHeight + ItemSpacing);
        vi.Rect := vr;
        FVtList.Add(vi);

        for i := 0 to jg.Items.Count-1 do
        begin
          ji := jg.Items[i];
          if ji.Hidden
          then Continue;
          // Add separator
          if ji.eType = jiSeparator
          then begin
            vi.Style := vtSeparator;
            vr.Offset(0, ItemHeight + ItemSpacing);
            vi.Rect := vr;
            FVtList.Add(vi);
            Continue;
          end;
          // Add item
          vi.Style := vtItem;
          vi.Group := g;
          vi.Item := i;
          vi.Icon := ExtractIcon(ji.Item, ji.eType);
          vr.Offset(0, ItemHeight + ItemSpacing);
          vi.Rect := vr;
          vi.IsLatesPinned := (LastPinUnpinHash = ji.Hash);
          vi.Pinnable := jg.eType <> jgTasks;
          FVtList.Add(vi);
        end;
      end;

      { Add footer items }
      if (FVtList.Count > 0)
      then begin
        RectBody := Bounds(0, 0, ListWidth, vr.Bottom + ItemMargin);
        RectFooter := Bounds(0, RectBody.Bottom, ListWidth,
          ItemSpacing + ItemMargin
          + 1*ItemHeight + 0*ItemSpacing
          + ItemMargin{ + 1});

        { Add parent shortcut item }
        vr.Location := Point(ItemMargin, RectFooter.Top + ItemSpacing + ItemMargin{ + 1});
        FillChar(vi, SizeOf(vi), 0);
        vi.Style := vtFooter;
        vi.Rect := vr;
        vi.Icon := ICI_DEFAULT;
        vi.Caption := '???';
        // name & icon
        if Succeeded( SHCreateItemFromIDList(FAppExe, IShellItem, pItem) )
        then begin
          vi.Icon := ExtractIcon(pItem, jiItem);
          if Succeeded(pItem.GetDisplayName(SIGDN_PARENTRELATIVEEDITING, ppszName))
          then begin
            vi.Caption := ppszName;
            CoTaskMemFree(ppszName);
          end;
        end;
        FVtList.Add(vi);
      end;

    finally
      if NeedUninitialize
      then CoUninitialize;
    end;

    if (FVtList.Count > 0)
    then begin
      _FHotIndex := INDEX_NONE;

      r := Rect(0, 0, ListWidth, RectFooter.Bottom);

      PrepareBackground(r.Width, r.Height);

      PrepareTooltips;

      AdjustWindowRectEx(r, GetWindowLong(Handle, GWL_STYLE), False,
        GetWindowLong(Handle, GWL_EXSTYLE));

      L := 0;
      T := 0;
      W := r.Width;
      H := r.Height;

      case FAlign of
        jaLeft: begin
          L := FX + FormOffset;
          T := FY - H;
        end;
        jaTop: begin
          L := FX - (W div 2);
          T := FY + FormOffset;
        end;
        jaRight: begin
          L := FX - W - FormOffset;
          T := FY - H;
        end;
        jaBottom: begin
          L := FX - (W div 2);
          T := FY - H - FormOffset;
        end;
      end;
      monrect := Screen.MonitorFromPoint( Point(FX, FY) ).BoundsRect;
      // correct lefttop
      if (L + W) > (monrect.Right)
      then L := monrect.Right - W;
      L := Max(L, monrect.Left);

      if (T + H) > (monrect.Bottom)
      then T := monrect.Bottom - H;
      T := Max(T, monrect.Top);
      SelfBoundsRect := Bounds(L, T, W, H);

      PaintForm;

      { Check window animation }
      if (not IsWindowVisible(Handle))
         and AnimationTaskbarEnabled
      then begin
        // show with blend animation
        SetWindowPos(Handle, 0, L, T, W, H, SWP_HIDEWINDOW);
        AnimateWindow(Handle, 100, AW_BLEND);
      end
      else begin
        // show
        SetWindowPos(Handle, 0, L, T, W, H, SWP_SHOWWINDOW);
      end;
      Invalidate;
      Result := True;
    end
    else Close;
  end;
end;

procedure TFormJumpList.PaintWindow(DC: HDC);
begin
  BitBlt(DC, 0, 0, oBgBmp.Width, oBgBmp.Height,
    oBgBmp.Canvas.Handle, 0, 0, SRCCOPY);
end;

procedure TFormJumpList.PaintForm;
begin
  BitBlt(Canvas.Handle, 0, 0, oBgBmp.Width, oBgBmp.Height,
    oBgBmp.Canvas.Handle, 0, 0, SRCCOPY);
end;

procedure TFormJumpList.SetHotIndex(AValue: integer);
begin
  if (_FHotIndex = AValue)
  then Exit;

  SendMessage(TipHwnd, TTM_TRACKACTIVATE, WParam(False), LParam(@TipToolInfo));

  // Clear previous hot item
  if (_FHotIndex <> INDEX_NONE)
  then DrawJumplistItem(Index, False, False);

  _FHotIndex := AValue;

  if (_FHotIndex <> INDEX_NONE)
  then begin
    DrawJumplistItem(Index, True, PinSelected);
    SetTimer(Handle, TIMER_TOOLTIP_SHOW, TipShowTime, nil);
  end;

  PaintForm;
end;

function TFormJumpList.Popup(AWnd: HWND; AX, AY: Integer; AAlign: TJumplistAlign;
  const AAppId: String; AAppExe: PItemIDList; AMaxCount: Integer): Boolean;
begin
  FAppId := AAppId;
  FAppExe := AAppExe;
  FMaxCount := AMaxCount;
  FX := AX;
  FY := AY;
  FAlign := AAlign;
  FWnd := AWnd;
  Result := UpdateJumpList;
  // Get current monitor rect
  TipMonitorRect := Screen.MonitorFromPoint(Point(AX, AY)).BoundsRect;
end;

procedure TFormJumpList.OnJumpListPin(Sender: TObject);
var g, i: Integer;
begin
  g := HiWord(FJumpItemIndex);
  i := WORD(FJumpItemIndex);
  LastPinUnpinHash := FJumpList.Groups[g].Items[i].Hash;
  PinJumpItem(PChar(FAppId), FJumpList, g, i, True);
  UpdateJumpList;
end;

procedure TFormJumpList.OnJumpListUnPin(Sender: TObject);
var g, i: Integer;
begin
  g := HiWord(FJumpItemIndex);
  i := WORD(FJumpItemIndex);
  LastPinUnpinHash := FJumpList.Groups[g].Items[i].Hash;
  PinJumpItem(PChar(FAppId), FJumpList, g, i, False);
  UpdateJumpList;
end;

procedure TFormJumpList.OnJumpListRemove(Sender: TObject);
var g, i: Integer;
begin
  g := HiWord(FJumpItemIndex);
  i := WORD(FJumpItemIndex);
  RemoveJumpItem(PChar(FAppId), FJumpList, g, i);
  UpdateJumpList;
end;

procedure TFormJumpList.OnJumpListExecute(Sender: TObject);
var g, i: Integer;
begin
  g := HiWord(FJumpItemIndex);
  i := WORD(FJumpItemIndex);
  // Some Execute close inactive windows (e.g. Steam client)
  // and our window did not receive the message WM_KILLFOCUS
  AlphaBlendAndClose;
  ExecuteJumpItem(PChar(FAppId), FAppExe, FJumpList.Groups[g].Items[i]{, FWnd});
end;

procedure TFormJumpList.JumpListPopupMenuPopup(const X, Y: Integer);
var mi: TMenuItem;
    g: Integer;
begin
  if Assigned(FPopupMenu)
  then FreeAndNil(FPopupMenu);

  FPopupMenu := TPopupMenu.Create(Self);

  // Open
  mi := FPopupMenu.CreateMenuItem;
  mi.Caption := MUILoadResString(shell32, LB_RS_JL_OPEN);
  mi.Default := True;
  mi.OnClick := OnJumpListExecute;
  FPopupMenu.Items.Add(mi);
  // Separator
  mi := FPopupMenu.CreateMenuItem;
  mi.Caption := cLineCaption;
  FPopupMenu.Items.Add(mi);

  g := HiWord(FJumpItemIndex);
  case FJumpList.Groups[g].eType of
    jgPinned:
      begin
        // Unpin
        mi := FPopupMenu.CreateMenuItem;
        mi.Caption := MUILoadResString(LB_FN_JUMPLIST, LB_RS_JL_UNPIN);
        mi.OnClick := OnJumpListUnPin;
        FPopupMenu.Items.Add(mi);
      end;
    jgRecent, jgFrequent, jgCustom:
      begin
        // Pin
        mi := FPopupMenu.CreateMenuItem;
        mi.Caption := MUILoadResString(LB_FN_JUMPLIST, LB_RS_JL_PIN);
        mi.OnClick := OnJumpListPin;
        FPopupMenu.Items.Add(mi);
        // Remove
        mi := FPopupMenu.CreateMenuItem;
        mi.Caption := MUILoadResString(LB_FN_JUMPLIST, LB_RS_JL_REMOVE);
        mi.OnClick := OnJumpListRemove;
        FPopupMenu.Items.Add(mi);
      end;
    else;
  end;
  FPopupMenu.Items.RethinkHotkeys;
  FPopupMenuVisible := True;
  FPopupMenu.Popup(X, Y);
  FPopupMenuVisible := False;
end;

end.
