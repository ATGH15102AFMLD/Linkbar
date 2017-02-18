{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{            Copyright (c) 2010-2017 Asaq               }
{*******************************************************}

unit LBToolbar;

{$i linkbar.inc}

{;$define CHACE_BB_ICON}                                                         // chache Bit Bucket icon

interface

uses Windows, SysUtils, ShlObj, Winapi.CommCtrl, Generics.Collections, Vcl.Graphics;

type
  TLbItem = class
  private
    HBmp: HBITMAP;                                                              // icon
    Shield: Boolean;                                                            // have shild overlay
    BitBucket: Boolean;                                                         // is bitbucket
  public
    Pidl: PItemIDList;
    IconIndex: Integer;
    Rect: TRect;
    Caption: string;
    FileName: string;
    Hash: Cardinal;
    NeedLoad: Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    function LoadFromFile(AFileName: string): Boolean;
  end;

  TLBItemList = class(TObjectList<TLbItem>)
  private
    HBmpShield: HBITMAP;                                                        // Shield overlay icon
{$ifdef CHACE_BB_ICON}
    HBmpBitBucket: HBITMAP;                                                     // BitBucket icon
{$endif}
    FIconSize: Integer;
    procedure SetIconSize(AValue: Integer);
    procedure QuickSort(L, R: Integer);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Draw(AHdc: HDC; AIndex, AX, AY: Integer);
    procedure LoadIcon(AItem: TLbItem);
    procedure BitBucketUpdateIcon;
    procedure Sort;
  public
    property IconSize: Integer read FIconSize write SetIconSize;
  end;

  function StrToHash(AStr: String): Cardinal;

implementation

uses Winapi.ActiveX, Winapi.ShellAPI, System.Win.ComObj, Winapi.KnownFolders,
     Linkbar.OS, Linkbar.Consts, Linkbar.Shell;

const
  ICON_SHIELD_FLAG = $08000; // draw the shield overlay
  ICON_INDEX_MASK  = ICON_SHIELD_FLAG - 1;

var
  FKnownFolderManager: IKnownFolderManager;

function CalcFNVHashFromString(const AData: string; AHash: Cardinal = 2166136261): Cardinal; inline;
var pData: PByte;
    i, l: Integer;
begin
  pData := PByte(PChar(AData));
  l := Length(AData)*SizeOf(Char);
  for i := 1 to l do
  begin
    AHash := (AHash xor pData^) * 16777619;
    Inc(pData);
  end;
  Result := AHash;
end;

function StrToHash(AStr: String): Cardinal;
begin
  Result := CalcFNVHashFromString(AnsiUpperCase(AStr));
end;

function CheckShield(const APidl: PItemIDList): Boolean;
var hr: HRESULT;
    pExtract: IExtractIcon;
    index: Integer;
    flags: UINT;
    location: array[0..MAX_PATH] of Char;
begin
  Result := False;
  if Succeeded( GetUIObjectOfPidl(0, APidl, IExtractIcon, Pointer(pExtract)) )
  then begin
    index := 0;
    flags := 0;
    hr := pExtract.GetIconLocation(GIL_CHECKSHIELD, location, MAX_PATH, index, flags);
    if (hr = S_OK)
    then Result := (flags and GIL_SHIELD) > 0;
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
  if Succeeded( GetUIObjectOfPidl(0, APidl, IShellLink, Pointer(pLink)) )
  then pLink.GetIDList(pidl);
  pLink := nil;

  hr := FKnownFolderManager.FindFolderFromIDList(pidl, pKnownFolder);

  if Assigned(pidl)
     and (pidl <> APidl)
  then CoTaskMemFree(pidl);

  if Succeeded(hr)
  then begin
    if Succeeded( pKnownFolder.GetId(id) )
    then begin
      if (id = FOLDERID_RecycleBinFolder)
      then Result := True;
    end;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
// TLbItem
////////////////////////////////////////////////////////////////////////////////

constructor TLbItem.Create;
begin
  inherited;
  HBmp := 0;
  Pidl := nil;
  FileName := '';
  Caption := 'Unknown name';
  IconIndex := -1;
  Hash := 0;
  Shield := False;
  Rect := TRect.Create(0, 0, 0, 0);
  NeedLoad := False;
  BitBucket := False;
end;

destructor TLbItem.Destroy;
begin
  CoTaskMemFree(Pidl);
  DeleteObject(HBmp);
  inherited;
end;

function TLbItem.LoadFromFile(AFileName: string): Boolean;
var hr: HRESULT;
    ppszName: PChar;
begin
  CoTaskMemFree(Pidl);

  hr := SHParseDisplayName(PChar(AFileName), nil, Pidl, 0, PDWORD(nil)^);
  if Succeeded(hr) then
  begin
    FileName := AFileName;
    Hash := StrToHash(ExtractFileName(FileName));

    if Succeeded( SHGetNameFromIDList(Pidl, SIGDN_NORMALDISPLAY, ppszName) )
    then begin
      Caption := String(ppszName);
      CoTaskMemFree(ppszName);
    end;

    Shield := CheckShield(Pidl);

    BitBucket := CheckBitBucket(Pidl);
  end;

  Result := hr = S_OK;
end;

////////////////////////////////////////////////////////////////////////////////
// TLBItemList
////////////////////////////////////////////////////////////////////////////////

constructor TLBItemList.Create;
begin
  inherited Create(True);
  HBmpShield := 0;
{$ifdef CHACE_BB_ICON}
  HBmpBitBucket := 0;
{$endif}
  CoCreateInstance(CLSID_KnownFolderManager, nil, CLSCTX_ALL, IKnownFolderManager, FKnownFolderManager);
end;

destructor TLBItemList.Destroy;
begin
  FKnownFolderManager := nil;
  DeleteObject(HBmpShield);
{$ifdef CHACE_BB_ICON}
  DeleteObject(HBmpBitBucket);
{$endif}
  inherited;
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

function LoadIconFromPidl(APidl: PItemIDList; AIconSize: Integer): HBITMAP;
var hbmp: HBITMAP;
    hr: HRESULT;
    fileShellItemImage: IShellItemImageFactory;
    NeedUninitialize: Boolean;
begin
  Result := 0;
  NeedUninitialize := SUCCEEDED(CoInitializeEx(nil, COINIT_APARTMENTTHREADED or COINIT_DISABLE_OLE1DDE));
  try
    hr := SHCreateItemFromIDList(APidl, IShellItemImageFactory, fileShellItemImage);
    if Succeeded(hr) then
    begin
      hr := fileShellItemImage.GetImage(TSize.Create(AIconSize, AIconSize),
        SIIGBF_ICONONLY, hbmp);
      if Succeeded(hr)
      then begin
        // Bitmaps for Windows 8.1/10 require premultiply
        if IsWindows8Dot1OrAbove
        then PreMultiply(hbmp);
        Result := hbmp;
      end;
      fileShellItemImage := nil;
    end;
  finally
    if NeedUninitialize
    then CoUninitialize;
  end;
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
		DrawIconEx(AHdc, rc.CenterPoint.X, rc.CenterPoint.Y, ico,
    AIconSize div 2, AIconSize div 2, 0, 0, DI_NORMAL);
		DestroyIcon(ico);
	end;
	SelectObject(AHdc, bmp0);
	Result := bmp;
end;

procedure TLBItemList.BitBucketUpdateIcon;
{$ifdef CHACE_BB_ICON}
var pidl: PItemIDList;
begin
  DeleteObject(HBmpBitBucket); // free old
  HBmpBitBucket := 0;

  pidl := nil;
  if Failed(SHGetKnownFolderIDList(FOLDERID_RecycleBinFolder, 0, 0, pidl))
     or (pidl = nil)
  then Exit;

  HBmpBitBucket := LoadIconFromPidl(pidl, FIconSize);
  CoTaskMemFree(pidl);
end;
{$else}
var item: TLbItem;
begin
  for item in Self do
    if item.BitBucket
    then LoadIcon(item);
end;
{$endif}

procedure TLBItemList.SetIconSize(AValue: Integer);
var dc: HDC;
    sii: TSHStockIconInfo;
    item: TLbItem;
begin
  if (FIconSize = AValue) then Exit;
  FIconSize := AValue;

  { Add shield overlay icon }
  FillChar(sii, SizeOf(sii), 0);
  sii.cbSize := SizeOf(sii);
  dc := CreateCompatibleDC(0);
  SHGetStockIconInfo(SIID_SHIELD, SHGSI_ICONLOCATION, sii);
  DeleteObject(HBmpShield); // free old
  HBmpShield := GetShieldOverlay(dc, sii.szPath, sii.iIcon, FIconSize);
  DeleteDC(dc);

{$ifdef CHACE_BB_ICON}
  { Get bitbucket icon }
  BitBucketUpdateIcon;
{$endif}

  { Update item icons }
  for item in Self do LoadIcon(item);
end;

procedure TLBItemList.LoadIcon(AItem: TLbItem);
begin
  DeleteObject(AItem.HBmp);
  AItem.HBmp := 0;
{$ifdef CHACE_BB_ICON}
  if AItem.BitBucket
  then Exit;
{$endif}
  AItem.HBmp := LoadIconFromPidl(AItem.Pidl, FIconSize);
end;

procedure TLBItemList.Draw(AHdc: HDC; AIndex, AX, AY: Integer);
const bf: TBlendFunction = (BlendOp: AC_SRC_OVER; BlendFlags: 0; SourceConstantAlpha: 255; AlphaFormat: AC_SRC_ALPHA);
var item: TLbItem;
    dc: HDC;
    bmp0: HGDIOBJ;
begin
  item := Self[AIndex];
  dc := CreateCompatibleDC(AHdc);

{$ifdef CHACE_BB_ICON}
  if item.BitBucket
  then bmp0 := SelectObject(dc, HBmpBitBucket)
  else
{$endif}
    bmp0 := SelectObject(dc, item.HBmp);

  // Draw icon
  Windows.AlphaBlend(AHdc, AX, AY, FIconSize, FIconSize, dc,
    0, 0, FIconSize, FIconSize, bf);

  // Draw shield
  if (item.Shield)
  then begin
    SelectObject(dc, HBmpShield);
    Windows.AlphaBlend(AHdc, AX, AY, FIconSize, FIconSize, dc,
      0, 0, FIconSize, FIconSize, bf);
  end;

  SelectObject(dc, bmp0);
  DeleteDC(dc);
end;

function StrCmpLogicalW(psz1, psz2: PWideChar): Integer; stdcall;
  external 'shlwapi.dll';

function SortCompareLogical(List: TLBItemList; Index1, Index2: Integer): Integer;
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
      if I <= J then
      begin
        if I <> J then
          Self.Exchange(I, J);
        if P = I then
          P := J
        else if P = J then
          P := I;
        Inc(I);
        Dec(J);
      end;
    until I > J;
    if L < J then QuickSort(L, J);
    L := I;
  until I >= R;
end;

procedure TLBItemList.Sort;
begin
  QuickSort(0, Count-1);
end;

end.
