{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{            Copyright (c) 2010-2021 Asaq               }
{*******************************************************}

unit LBToolbar;

{$i linkbar.inc}

{;$define CHACE_BB_ICON}                                                        // Chache Bit Bucket icon.
                                                                                // However, if the user changes the icon of the Bit Bucket, this is incorrect.
interface

uses
  Winapi.Windows, Winapi.ShlObj,
  System.SysUtils, Vcl.Graphics, Generics.Collections,
  Linkbar.Consts;

type
  TItemBase = class
  public type
     TKind = (None, Shortcut, Separator, Group);
  protected
    FKind: TKind;
    FBitmap: HBITMAP;                                                           // Shortcut icon
  private
    Shield: Boolean;                                                            // Have shild overlay
    BitBucket: Boolean;                                                         // Is bitbucket
  public
    Pidl: PItemIDList;
    FileName: string;
    Caption: string;
    Rect: TRect;
    Hash: Cardinal;
    NeedLoad: Boolean;
    Align: TItemAlign;                                                          // Own alignment (iaAuto = global)
    Hidden: Boolean;                                                            // Does not fit in the bar (overflow), see the » menu
    LinkState: TLinkState;                                                      // Result of the last link check
    LinkCheckTick: UInt64;                                                      // When the last check was requested
  public
    property Kind: TKind read FKind;
    property Bitmap: HBITMAP read FBitmap;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure DoExecute(AHandle: HWND); virtual;
    procedure DoPopupMenu(AHandle: HWND; const APoint: TPoint; AShift: Boolean = False; ASubMenu: HMENU = 0); virtual;
    function LoadFromFile(const AFileName: string): Boolean; virtual;
    procedure LoadIcon(const AIconSize: Integer); virtual;
    function GetDropPart(const APoint: TPoint; const AVertical: Boolean; const ASideOnly: Boolean = False): Integer; virtual;
  end;

  TItemShortcut = class(TItemBase)
  public var
    Size: TSize;
  public
    constructor Create; override;
    procedure DoExecute(AHandle: HWND); override;
    procedure DoPopupMenu(AHandle: HWND; const APoint: TPoint; AShift: Boolean = False; ASubMenu: HMENU = 0); override;
    function LoadFromFile(const AFileName: string): Boolean; override;
    procedure LoadIcon(const AIconSize: Integer); override;
    function GetDropPart(const APoint: TPoint; const AVertical: Boolean; const ASideOnly: Boolean = False): Integer; override;
  end;

  TItemSeparator = class(TItemBase)
  private const
    SEPARATOR_CAPTION: string = '|';
  public var
    Size: Integer;
  public
    class function IsSeparator(const AFileName: string): Boolean; inline;
  public
    constructor Create; override;
    procedure DoPopupMenu(AHandle: HWND; const APoint: TPoint; AShift: Boolean = False; ASubMenu: HMENU = 0); override;
  end;

  TPanelSizes = record
    Button: TSize;
    Separator: Integer;
    Margin: Integer;
    Overflow: Boolean;
  end;

  TLBItemList = class(TObjectList<TItemBase>)
  private
    BitmapShield: HBITMAP;                                                        // Shield overlay icon
{$ifdef CHACE_BB_ICON}
    BitmapBitBucket: HBITMAP;                                                     // <desktop>\Recycle Bin icon
{$endif}
    FIconSize: Integer;
    FLineWidth: Integer;
    FZonesActive: Boolean;
    procedure SetIconSize(const AValue: Integer);
    procedure QuickSort(L, R: Integer);
  public
    Lines: TList<Integer>;
    Sizes: TPanelSizes;
    Boundaries: TList<TRect>;                                                   // Visible boundaries between alignment zones
    OverflowRect: TRect;                                                        // Button "»" (empty when nothing is hidden)
    HiddenCount: Integer;                                                       // Number of hidden items (without separators)
  public
    function ZoneOf(const AItem: TItemBase): TItemAlign;
    procedure NormalizeZones;
    procedure ZoneRange(const AZone: TItemAlign; out AFirst, ALast: Integer);
    property ZonesActive: Boolean read FZonesActive;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Draw(AHdc: HDC;  const AItem: TItemBase; AX, AY: Integer);
    procedure LoadIcon(const AItem: TItemBase); inline;
    procedure BitBucketUpdateIcon;
    procedure Sort;
    procedure UpdateLines(const AVertical: Boolean; const AWidth, AHeight: Integer);
    function GetLineIndex(const AItemIndex: Integer): Integer;
  public
    property IconSize: Integer read FIconSize write SetIconSize;
    property LineWidth: Integer read FLineWidth;
  public
    class function IsSeparator(const AItem: TItemBase): Boolean; inline;
  end;

  function StrToHash(const AStr: string): Cardinal;

  { Icon of the shell item (premultiplied 32 bit bitmap), caller owns the bitmap }
  function LoadIconFromPidl(const APidl: PItemIDList; const AIconSize: Integer): HBITMAP;


implementation

uses
  Winapi.ActiveX, Winapi.ShellAPI, Winapi.KnownFolders,
  System.Win.ComObj, System.Types, System.Math,
  Linkbar.OS, Linkbar.Shell, ExplorerMenu;

var FKnownFolderManager: IKnownFolderManager;

function CalcFNVHashFromString(const AData: string; AHash: Cardinal = 2166136261): Cardinal; inline;
var pData: PByte;
    count: Integer;
begin
  count := Length(AData) * SizeOf(Char);

  pData := PByte(PChar(AData));
  for var i := 1 to count do
  begin
    AHash := (AHash xor pData^) * 16777619;
    Inc(pData);
  end;
  Result := AHash;
end;

function StrToHash(const AStr: string): Cardinal;
begin
  Result := CalcFNVHashFromString(AnsiUpperCase(AStr));
end;

function CheckShield(const APidl: PItemIDList): Boolean;
var pExtract: IExtractIcon;
    location: array[0..MAX_PATH] of Char;
begin
  Result := False;
  if Succeeded(GetUIObjectOfPidl(0, APidl, IExtractIcon, Pointer(pExtract)))
  then begin
    var index := 0;
    var flags: UINT := 0;
    if (pExtract.GetIconLocation(GIL_CHECKSHIELD, location, MAX_PATH, index, flags) = S_OK)
    then Result := ((flags and GIL_SHIELD) > 0) and ((flags and GIL_FORCENOSHIELD) = 0);
    pExtract := nil;
  end;
end;

function CheckBitBucket(const APidl: PItemIDList): Boolean;
var pKnownFolder: IKnownFolder;
    id: KNOWNFOLDERID;
    hr: HRESULT;
    pidl: PItemIDList;
    pLink: IShellLink;
begin
  Result := False;

  if not Assigned(FKnownFolderManager)
  then Exit;

  pidl := APidl;

  // resolve link
  if Succeeded(GetUIObjectOfPidl(0, APidl, IShellLink, Pointer(pLink)))
  then pLink.GetIDList(pidl);
  pLink := nil;

  hr := FKnownFolderManager.FindFolderFromIDList(pidl, pKnownFolder);

  if Assigned(pidl)
     and (pidl <> APidl)
  then CoTaskMemFree(pidl);

  Result := Succeeded(hr)
            and Assigned(pKnownFolder)
            and Succeeded(pKnownFolder.GetId(id))
            and (id = FOLDERID_RecycleBinFolder);
end;

procedure PreMultiply(const ABitmap: HBITMAP);
type
  TRGBAQuad = array[0..3] of Byte;
  PRGBAQuad = ^TRGBAQuad;
var bi: TBitmapInfo;
    dc: HDC;
    p: PByte;
    i, c: Integer;
    px: PRGBAQuad;
    alpha: Byte;
begin
  FillChar(bi, SizeOf(bi), 0);
  bi.bmiHeader.biSize := SizeOf(bi.bmiHeader);

  dc := CreateCompatibleDC(0);
  SelectObject(dc, ABitmap);

  // Get the BITMAPINFO structure from the bitmap
  if (GetDIBits(dc, ABitmap, 0, 0, nil, bi, DIB_RGB_COLORS) <> 0)
  then begin
    // create the pixel buffer
    p := GetMemory(bi.bmiHeader.biSizeImage);

    // We'll change the received BITMAPINFOHEADER to request the data in a
    // 32 bit RGB format (and not upside-down) so that we can iterate over
    // the pixels easily.

    // requesting a 32 bit image means that no stride/padding will be necessary,
    // although it always contains an (possibly unused) alpha channel
    bi.bmiHeader.biBitCount := 32;
    bi.bmiHeader.biCompression := BI_RGB;  // no compression -> easier to use
    // correct the bottom-up ordering of lines (abs is in cstdblib and stdlib.h)
    bi.bmiHeader.biHeight := abs(bi.bmiHeader.biHeight);

    // Call GetDIBits a second time, this time to (format and) store the actual
    // bitmap data (the "pixels") in the buffer p
    if(GetDIBits(dc, ABitmap, 0, bi.bmiHeader.biHeight, p, bi, DIB_RGB_COLORS) <> 0)
    then begin
      px := Pointer(UIntPtr(p));
      c := bi.bmiHeader.biHeight * bi.bmiHeader.biWidth;
      for i := 0 to c-1 do
      begin
        alpha := px[3];
        px[0] := MulDiv(px[0], alpha, 255);
        px[1] := MulDiv(px[1], alpha, 255);
        px[2] := MulDiv(px[2], alpha, 255);
        Inc(px);
      end;
      SetDIBits(dc, ABitmap, 0, bi.bmiHeader.biHeight, p, bi, DIB_RGB_COLORS);
    end;

    // clean up: deselect bitmap from device context, close handles, delete buffer
    FreeMemory(p);
  end;
  DeleteDC(dc);
end;

function LoadIconFromPidl(const APidl: PItemIDList; const AIconSize: Integer): HBITMAP;
var
  fileShellItemImage: IShellItemImageFactory;
begin
  Result := 0;
  var needUninitialize := Succeeded(CoInitializeEx(nil, COINIT_APARTMENTTHREADED or COINIT_DISABLE_OLE1DDE));
  try
    var hr := SHCreateItemFromIDList(APidl, IShellItemImageFactory, fileShellItemImage);
    if Succeeded(hr)
    then begin
      hr := fileShellItemImage.GetImage(TSize.Create(AIconSize, AIconSize),
        SIIGBF_ICONONLY or SIIGBF_BIGGERSIZEOK, Result);
      if Succeeded(hr)
      then begin
        // Bitmaps for Windows 8.1/10 require premultiply
        if IsWindows8Dot1OrAbove
        then PreMultiply(Result);
      end;
      fileShellItemImage := nil;
    end;
  finally
    if needUninitialize
    then CoUninitialize;
  end;
end;


{ TItemBase }

constructor TItemBase.Create;
begin
  FKind := TKind.None;

  FBitmap := 0;
  Shield := False;
  BitBucket := False;

  Pidl := nil;
  FileName := '';
  Caption := '';
  Rect := TRect.Empty;
  Hash := 0;
  NeedLoad := False;
end;

destructor TItemBase.Destroy;
begin
  CoTaskMemFree(Pidl);
  DeleteObject(FBitmap);
  inherited;
end;

procedure TItemBase.DoExecute(AHandle: HWND);
begin
end;

procedure TItemBase.DoPopupMenu(AHandle: HWND; const APoint: TPoint; AShift: Boolean = False; ASubMenu: HMENU = 0);
begin
end;

function TItemBase.LoadFromFile(const AFileName: string): Boolean;
begin
  Result := False;
end;

procedure TItemBase.LoadIcon(const AIconSize: Integer);
begin
end;

function TItemBase.GetDropPart(const APoint: TPoint; const AVertical: Boolean; const ASideOnly: Boolean): Integer;
begin
  if AVertical
  then begin
    if (APoint.Y < Rect.CenterPoint.Y)
    then Result := -1
    else Result :=  1;
  end
  else begin
    if (APoint.X < Rect.CenterPoint.X)
    then Result := -1
    else Result :=  1;
  end;
end;


{ TItemShortcut }

constructor TItemShortcut.Create;
begin
  inherited;
  FKind := TKind.Shortcut;
end;

function TItemShortcut.LoadFromFile(const AFileName: string): Boolean;
begin
  CoTaskMemFree(Pidl);

  if SHParseDisplayName(PChar(AFileName), nil, Pidl, 0, PDWORD(nil)^) = S_OK
  then begin
    FileName := AFileName;
    Hash := StrToHash(ExtractFileName(FileName));

    var ppszName: PChar := nil;
    if Succeeded(SHGetNameFromIDList(Pidl, SIGDN_NORMALDISPLAY, ppszName))
    then begin
      Caption := string(ppszName);
      CoTaskMemFree(ppszName);
    end;

    Shield := CheckShield(Pidl);

    BitBucket := CheckBitBucket(Pidl);

    Exit(True);
  end;

  Result := False;
end;

procedure TItemShortcut.LoadIcon(const AIconSize: Integer);
begin
  DeleteObject(FBitmap);
  FBitmap := 0;
{$ifdef CHACE_BB_ICON}
  if BitBucket
  then Exit;
{$endif}
  FBitmap := LoadIconFromPidl(Pidl, AIconSize);
end;

procedure TItemShortcut.DoExecute(AHandle: HWND);
begin
  OpenByDefaultVerb(AHandle, Pidl);
end;

procedure TItemShortcut.DoPopupMenu(AHandle: HWND; const APoint: TPoint; AShift: Boolean = False; ASubMenu: HMENU = 0);
begin
  ExplorerMenuPopup(AHandle, Pidl, APoint, AShift, ASubMenu);
end;


function TItemShortcut.GetDropPart(const APoint: TPoint; const AVertical: Boolean; const ASideOnly: Boolean): Integer;
var
  part0sz, part1sz: Integer;
begin
  if ASideOnly
  then begin
    Result := inherited GetDropPart(APoint, AVertical, ASideOnly);
    Exit;
  end;

  Result := 0;

  if AVertical
  then begin
    part0sz := (Rect.Height div 3) * 2;
    part1sz := (Rect.Height - part0sz) div 2;

    if (APoint.Y < (Rect.Top + part1sz))
    then Result := -1
    else if (APoint.Y >= (Rect.Top + part1sz + part0sz))
         then Result := 1
  end
  else begin
    part0sz := (Rect.Width div 3) * 2;
    part1sz := (Rect.Width - part0sz) div 2;

    if (APoint.X < (Rect.Left + part1sz))
    then Result := -1
    else if (APoint.X >= (Rect.Left + part1sz + part0sz))
         then Result := 1
  end;
end;

{ TItemSeparator }

constructor TItemSeparator.Create;
begin
  inherited;
  FKind := TKind.Separator;
  Caption := SEPARATOR_CAPTION;
  FileName := SEPARATOR_CAPTION;
end;

procedure TItemSeparator.DoPopupMenu(AHandle: HWND; const APoint: TPoint; AShift: Boolean = False; ASubMenu: HMENU = 0);
begin
  var menu := CreatePopupMenu;
  try
    var Flags: UINT := MF_BYCOMMAND or MF_STRING;
    AppendMenu(menu, Flags, 1, 'Delete');

    var command := TrackPopupMenuEx(menu, TPM_RETURNCMD or TPM_RIGHTBUTTON or TPM_NONOTIFY, APoint.X, APoint.Y, AHandle, nil);

    if (command)
    then PostMessage(AHandle, LM_CM_DELETE, 0, 0);
  finally
    DestroyMenu(menu);
  end;
end;

class function TItemSeparator.IsSeparator(const AFileName: string): Boolean;
begin
  Result := SameText(AFileName, TItemSeparator.SEPARATOR_CAPTION);
end;

////////////////////////////////////////////////////////////////////////////////
// TLBItemList
////////////////////////////////////////////////////////////////////////////////

class function TLBItemList.IsSeparator(const AItem: TItemBase): Boolean;
begin
  Result := (AItem.Kind = TItemBase.TKind.Separator);
end;

constructor TLBItemList.Create;
begin
  inherited Create(True);
  BitmapShield := 0;
{$ifdef CHACE_BB_ICON}
  BitmapBitBucket := 0;
{$endif}
  CoCreateInstance(CLSID_KnownFolderManager, nil, CLSCTX_ALL, IKnownFolderManager, FKnownFolderManager);
  Lines := TList<Integer>.Create;
  Lines.Capacity := 16;
  Boundaries := TList<TRect>.Create;
  FZonesActive := False;
end;

destructor TLBItemList.Destroy;
begin
  DeleteObject(BitmapShield);
{$ifdef CHACE_BB_ICON}
  DeleteObject(BitmapBitBucket);
{$endif}
  FKnownFolderManager := nil;
  Lines.Free;
  Boundaries.Free;
  inherited;
end;

{ Effective zone of the item: iaAuto follows the global option (old behavior:
  only "Center" was honored, "Right" behaves like "Left") }
function TLBItemList.ZoneOf(const AItem: TItemBase): TItemAlign;
begin
  Result := AItem.Align;
  if (Result = iaAuto)
  then begin
    if (GlobalLayout = EPanelLayoutCenter)
    then Result := iaCenter
    else Result := iaStart;
  end;
end;

{ Items of one zone must be neighbours in the list (start, center, end).
  Stable insertion sort, does nothing when the list is already in order. }
procedure TLBItemList.NormalizeZones;
var j: Integer;
begin
  for var i := 1 to Self.Count-1
  do begin
    j := i;
    while (j > 0)
          and (Ord(ZoneOf(Self[j-1])) > Ord(ZoneOf(Self[j])))
    do begin
      Self.Exchange(j-1, j);
      Dec(j);
    end;
  end;
end;

{ Index range of the zone. When items are wrapped to more lines, zones are
  not used and the whole list is one zone. }
procedure TLBItemList.ZoneRange(const AZone: TItemAlign; out AFirst, ALast: Integer);
begin
  AFirst := 0;
  ALast := Self.Count-1;
  if (not FZonesActive)
  then Exit;

  AFirst := ITEM_NONE;
  for var i := 0 to Self.Count-1
  do begin
    if (ZoneOf(Self[i]) = AZone)
    then begin
      if (AFirst = ITEM_NONE)
      then AFirst := i;
      ALast := i;
    end;
  end;
  if (AFirst = ITEM_NONE)
  then begin
    AFirst := 0;
    ALast := Self.Count-1;
  end;
end;

procedure TLBItemList.UpdateLines(const AVertical: Boolean; const AWidth, AHeight: Integer);
var
  count, x, y, margin: Integer;
  offset: TPoint;
  r: TRect;
  z, prevZone: TItemAlign;
  firstIdx, lastIdx: array[TItemAlign] of Integer;
  offs: array[TItemAlign] of Integer;
  total, bs, be, cs, target, startLimit, endLimit, gapS, gapE, mid: Integer;
  need, endSum, used, cw: Integer;
  full: Boolean;

  function AxStart(const ARect: TRect): Integer;
  begin
    if AVertical then Result := ARect.Top else Result := ARect.Left;
  end;

  function AxEnd(const ARect: TRect): Integer;
  begin
    if AVertical then Result := ARect.Bottom else Result := ARect.Right;
  end;

  function AxLen(const ARect: TRect): Integer;
  begin
    if AVertical then Result := ARect.Height else Result := ARect.Width;
  end;

begin
  NormalizeZones;

  // Set item width and height
  for var item in Self
  do begin
    item.Rect := TRect.Empty;
    if IsSeparator(item)
    then begin
      if (AVertical)
      then item.Rect.BottomRight := TPoint.Create(Sizes.Button.cx, Sizes.Separator)
      else item.Rect.BottomRight := TPoint.Create(Sizes.Separator, Sizes.Button.cy);
    end
    else item.Rect.BottomRight := TPoint.Create(Sizes.Button.cx, Sizes.Button.cy);
  end;

  margin := Sizes.Margin;

  // Overflow: one row/column only. Items that do not fit are hidden and listed
  // in the menu of the button "»". The end zone and the button have priority.
  OverflowRect := TRect.Empty;
  HiddenCount := 0;
  for var item in Self
  do item.Hidden := False;

  if Sizes.Overflow
  then begin
    if AVertical then total := AHeight else total := AWidth;
    need := margin;
    endSum := 0;
    for var item in Self
    do begin
      need := need + AxLen(item.Rect);
      if (ZoneOf(item) = iaEnd)
      then endSum := endSum + AxLen(item.Rect);
    end;

    if (need > total)
    then begin
      if AVertical then cw := Sizes.Button.cy else cw := Sizes.Button.cx;
      used := margin + endSum + cw;
      full := False;
      for var item in Self
      do begin
        if (ZoneOf(item) = iaEnd)
        then Continue;
        if (not full)
           and (used + AxLen(item.Rect) <= total)
        then used := used + AxLen(item.Rect)
        else begin
          full := True;
          item.Hidden := True;
          if (not IsSeparator(item))
          then Inc(HiddenCount);
        end;
      end;
    end;
  end;

  if (AVertical)
  then begin
    x := 0;
    y := margin;
  end else
  begin
    x := margin;
    y := 0;
  end;

  count := 0;
  Lines.Clear;

  for var i := 0 to Self.Count-1
  do begin
    Inc(count);

    if Self[i].Hidden
    then begin
      // Move far away from the panel: not drawn, not hit by the mouse
      Self[i].Rect.Offset(ITEM_HIDDEN_OFFSET, ITEM_HIDDEN_OFFSET);
      Continue;
    end;

    r := Self[i].Rect;

    // Calc item bounds
    r.Offset(x, y);  // because TopLeft = (0, 0)

    // Calc next item position
    if (AVertical)
    then begin
      Inc(y, r.Height);
      if (i < (Self.Count - 1))
         and (not Sizes.Overflow)
         and ((y + Self[i+1].Rect.Height) > AHeight)
      then begin
        y := margin;
        Inc(x, r.Width);

        Lines.Add(count);
        count := 0;
      end;
    end
    else begin
      Inc(x, r.Width);
      if (i < (Self.Count - 1))
         and (not Sizes.Overflow)
         and ((x + Self[i+1].Rect.Width) > AWidth)
      then begin
        x := margin;
        Inc(y, r.Height);

        Lines.Add(count);
        count := 0;
      end
    end;

    Self[i].Rect := r;
  end;

  if (count > 0)
  then Lines.Add(count);

  if (Lines.Count = 0)
  then Lines.Add(0);

  // Calc first line width
  if (Lines[0] = 0)
  then
    FLineWidth := 0
  else begin
    if (AVertical)
    then FLineWidth := Self[Lines[0]-1].Rect.Bottom - Self[0].Rect.Top
    else FLineWidth := Self[Lines[0]-1].Rect.Right - Self[0].Rect.Left;
  end;

  // Align items to zones: start / center / end (only when all items are in
  // one row/column). With only auto items it is the same as the old behavior.
  FZonesActive := (Lines.Count = 1);
  Boundaries.Clear;

  if FZonesActive
     and (Self.Count > 0)
  then begin
    if AVertical
    then total := AHeight
    else total := AWidth;

    for z := Low(TItemAlign) to High(TItemAlign)
    do begin
      firstIdx[z] := ITEM_NONE;
      lastIdx[z] := ITEM_NONE;
      offs[z] := 0;
    end;

    for var i := 0 to Self.Count-1
    do begin
      if Self[i].Hidden
      then Continue;
      z := ZoneOf(Self[i]);
      if (firstIdx[z] = ITEM_NONE)
      then firstIdx[z] := i;
      lastIdx[z] := i;
    end;

    // End zone sticks to the end edge (never moves back over the previous items)
    if (firstIdx[iaEnd] <> ITEM_NONE)
    then begin
      bs := AxStart(Self[firstIdx[iaEnd]].Rect);
      be := AxEnd(Self[lastIdx[iaEnd]].Rect);
      offs[iaEnd] := Max(0, (total - margin - (be - bs)) - bs);
      endLimit := bs + offs[iaEnd];
    end
    else endLimit := total - margin;

    // Button "»" sits in front of the end zone
    if (HiddenCount > 0)
    then begin
      if AVertical then cw := Sizes.Button.cy else cw := Sizes.Button.cx;
      endLimit := endLimit - cw;
      if AVertical
      then OverflowRect := TRect.Create(0, endLimit, Sizes.Button.cx, endLimit + cw)
      else OverflowRect := TRect.Create(endLimit, 0, endLimit + cw, Sizes.Button.cy);
    end;

    if (firstIdx[iaStart] <> ITEM_NONE)
    then startLimit := AxEnd(Self[lastIdx[iaStart]].Rect)
    else startLimit := margin;

    // Center zone: in the middle of the bar, but never over the other zones
    if (firstIdx[iaCenter] <> ITEM_NONE)
    then begin
      bs := AxStart(Self[firstIdx[iaCenter]].Rect);
      be := AxEnd(Self[lastIdx[iaCenter]].Rect);
      cs := be - bs;
      target := (total - cs) div 2;
      target := Min(target, endLimit - cs);
      target := Max(target, startLimit);
      offs[iaCenter] := target - bs;
    end;

    for var i := 0 to Self.Count-1
    do begin
      z := ZoneOf(Self[i]);
      if (offs[z] <> 0)
         and (not Self[i].Hidden)
      then begin
        if AVertical
        then Self[i].Rect.Offset(0, offs[z])
        else Self[i].Rect.Offset(offs[z], 0);
      end;
    end;

    // Visible boundary between two used zones, but only when they are close
    // to each other (less than one icon of free space between them)
    if AVertical then cw := Sizes.Button.cy else cw := Sizes.Button.cx;
    prevZone := iaAuto;
    for z := iaStart to iaEnd
    do begin
      if (firstIdx[z] = ITEM_NONE)
      then Continue;

      if (prevZone <> iaAuto)
      then begin
        gapS := AxEnd(Self[lastIdx[prevZone]].Rect);
        gapE := AxStart(Self[firstIdx[z]].Rect);
        if (gapE - gapS < cw)
        then begin
          mid := (gapS + gapE) div 2 - Sizes.Separator div 2;
          if AVertical
          then Boundaries.Add(TRect.Create(0, mid, Sizes.Button.cx, mid + Sizes.Separator))
          else Boundaries.Add(TRect.Create(mid, 0, mid + Sizes.Separator, Sizes.Button.cy));
        end;
      end;
      prevZone := z;
    end;
  end;
end;

function TLBItemList.GetLineIndex(const AItemIndex: Integer): Integer;
var temp: Integer;
begin
  temp := 0;
  for var i := 0 to Lines.Count-1
  do begin
    Inc(temp, Lines[i]);
    if AItemIndex < temp
    then Exit(i);
  end;
  Result := 0;
end;

// Creates a shield icon in the bottom/right corner
function GetShieldOverlay(AHdc: HDC; const APath: PChar; AIndex, AIconSize: Integer): HBITMAP; inline;
var bi: TBitmapInfo;
    rc: TRect;
    bits: Pointer;
    bmp: HBITMAP;
    bmp0: HGDIOBJ;
    ico: HICON;
begin
  FillChar(bi, SizeOf(bi), 0);
  bi.bmiHeader.biSize := sizeof(BITMAPINFOHEADER);
  bi.bmiHeader.biWidth := AIconSize;
  bi.bmiHeader.biHeight := AIconSize;
  bi.bmiHeader.biPlanes := 1;
  bi.bmiHeader.biBitCount := 32;
  rc := TRect.Create(0, 0, AIconSize, AIconSize);

  bmp := CreateDIBSection(AHdc, &bi, DIB_RGB_COLORS, bits, 0, 0);
  bmp0 := SelectObject(AHdc, bmp);
  FillRect(AHdc, rc, GetStockObject(BLACK_BRUSH));
  ico := ShExtractIcon(APath, AIndex, AIconSize div 2);
  if (ico > 0)
  then begin
    DrawIconEx(AHdc, rc.CenterPoint.X, rc.CenterPoint.Y, ico, AIconSize div 2, AIconSize div 2, 0, 0, DI_NORMAL);
    DestroyIcon(ico);
  end;
  SelectObject(AHdc, bmp0);
  Result := bmp;
end;

procedure TLBItemList.BitBucketUpdateIcon;
begin
{$ifdef CHACE_BB_ICON}
  DeleteObject(BitmapBitBucket); // free old
  BitmapBitBucket := 0;

  var pidl: PItemIDList := nil;
  if Failed(SHGetKnownFolderIDList(FOLDERID_RecycleBinFolder, 0, 0, pidl))
     or (pidl = nil)
  then Exit;

  BitmapBitBucket := LoadIconFromPidl(pidl, FIconSize);
  CoTaskMemFree(pidl);
{$else}
  for var item in Self do
  begin
    if item.BitBucket
    then LoadIcon(item);
  end;
{$endif}
end;

procedure TLBItemList.SetIconSize(const AValue: Integer);
begin
  if (FIconSize = AValue)
  then Exit;

  FIconSize := AValue;

  { Add shield overlay icon }
  var sii: TSHStockIconInfo := Default(TSHStockIconInfo);
  sii.cbSize := SizeOf(sii);
  var dc := CreateCompatibleDC(0);
  SHGetStockIconInfo(SIID_SHIELD, SHGSI_ICONLOCATION, sii);
  DeleteObject(BitmapShield); // free old
  BitmapShield := GetShieldOverlay(dc, sii.szPath, sii.iIcon, FIconSize);
  DeleteDC(dc);

{$ifdef CHACE_BB_ICON}
  { Get bitbucket icon }
  BitBucketUpdateIcon;
{$endif}

  { Update item icons }
  for var item in Self do LoadIcon(item);
end;

procedure TLBItemList.LoadIcon(const AItem: TItemBase);
begin
  AItem.LoadIcon(FIconSize);
end;

procedure TLBItemList.Draw(AHdc: HDC; const AItem: TItemBase; AX, AY: Integer);
const bf: TBlendFunction = (BlendOp: AC_SRC_OVER; BlendFlags: 0; SourceConstantAlpha: 255; AlphaFormat: AC_SRC_ALPHA);
var
  bmp0: HGDIOBJ;
begin
  var dc := CreateCompatibleDC(AHdc);

{$ifdef CHACE_BB_ICON}
  if AItem.BitBucket
  then bmp0 := SelectObject(dc, BitmapBitBucket) else
{$endif}
  bmp0 := SelectObject(dc, AItem.Bitmap);

  // Draw icon
  Winapi.Windows.AlphaBlend(AHdc, AX, AY, FIconSize, FIconSize, dc, 0, 0, FIconSize, FIconSize, bf);
  SelectObject(dc, bmp0);

  // Draw shield
  if (AItem.Shield)
  then begin
    bmp0 := SelectObject(dc, BitmapShield);
    Winapi.Windows.AlphaBlend(AHdc, AX, AY, FIconSize, FIconSize, dc, 0, 0, FIconSize, FIconSize, bf);
    SelectObject(dc, bmp0);
  end;

  DeleteDC(dc);
end;

function StrCmpLogicalW(psz1, psz2: PWideChar): Integer; stdcall; external 'shlwapi.dll';

function SortCompareLogical(const List: TLBItemList; Index1, Index2: Integer): Integer; inline;
begin
  Result := StrCmpLogicalW(PChar(List[Index1].Caption), PChar(List[Index2].Caption));
end;

procedure TLBItemList.QuickSort(L, R: Integer);
var
  I, J, P: Integer;
begin
  repeat
    I := L;
    J := R;
    P := (L + R) shr 1;
    repeat
      while SortCompareLogical(Self, I, P) < 0 do Inc(I);
      while SortCompareLogical(Self, J, P) > 0 do Dec(J);
      if (I <= J)
      then begin
        if (I <> J)
        then Self.Exchange(I, J);
        if (P = I)
        then P := J
        else if (P = J)
             then P := I;
        Inc(I);
        Dec(J);
      end;
    until I > J;
    if (L < J)
    then QuickSort(L, J);
    L := I;
  until I >= R;
end;

procedure TLBItemList.Sort;
var
  separators: Tlist<Integer>;
begin
  // Collect separated groups
  // 2 virtual first and last seperators
  separators := Tlist<Integer>.Create;
  separators.Capacity := Self.Count + 2;
  separators.Add(-1);

  for var i := 0 to Self.Count-1
  do begin
    if IsSeparator(Self[i])
    then separators.Add(i);
  end;

  separators.Add(Self.Count);

  // Sort groups
  for var i := 0 to separators.Count-2
  do begin
    const l = separators[i] + 1;
    const r = separators[i+1] - 1;
    if (r - l) >= 2
    then QuickSort(l, r);
  end;

  separators.Free;
end;

end.
