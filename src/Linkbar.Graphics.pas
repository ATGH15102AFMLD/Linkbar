{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{            Copyright (c) 2010-2021 Asaq               }
{*******************************************************}

// Using raw bitmap reduces the size of the executable file

unit Linkbar.Graphics;

{$i linkbar.inc}

interface

uses Windows;

type
  THBitmap = class
  private
    FHandle: HBITMAP;
    FWidth: Integer;
    FHeight: Integer;
    FBpp: Integer;
    FBmp0: HGDIOBJ;
    FDc: HDC;
    FBits: Pointer;
    FPitch: Integer;
    procedure NeedDc;
    procedure NeedHandle;
    procedure DeleteDc;
    procedure DeleteHandle;
    function GetDc: HDC;
    function GetBound: TRect;
  public
    constructor Create(ABpp: Integer);
    destructor Destroy; override;
    procedure SetSize(AWidth, AHeight: Integer);
    function Clone: THBitmap;
    procedure Clear;
    procedure Opaque;
    procedure OpaqueRect(ARect: TRect);
    property Handle: HBITMAP read FHandle;
    property Dc: HDC read GetDc;
    property Width: Integer read FWidth;
    property Height: Integer read FHeight;
    property Bound: TRect read GetBound;
  end;

implementation

uses System.Classes;

function BitmapPitch(Width, Bpp: Integer; Align: Integer = 32): Integer;
begin
  Dec(Align);
  Result := (Width * Bpp + Align) and not Align;
  Result := Result div 8;
end;

{ THBitmap }

constructor THBitmap.Create(ABpp: Integer);
begin
  FHandle := 0;
  FDc := 0;
  FBmp0 := 0;
  FWidth := 0;
  FHeight := 0;
  FPitch := 0;
  FBits := nil;
  FBpp := ABpp;
end;

destructor THBitmap.Destroy;
begin
  DeleteDc;
  DeleteHandle;
  inherited;
end;

function THBitmap.Clone: THBitmap;
begin
  Result := THBitmap.Create(FBpp);
  Result.SetSize(FWidth, FHeight);
  BitBlt(Result.GetDc, 0, 0, FWidth, FHeight, Dc, 0, 0, SRCCOPY);
end;

procedure THBitmap.DeleteDc;
begin
  if (FDc <> 0)
  then begin
    SelectObject(FDc, FBmp0);
    Windows.DeleteDC(FDc);
    FDc := 0;
    FBmp0 := 0;
  end;
end;

procedure THBitmap.DeleteHandle;
begin
  if (FHandle <> 0)
  then begin
    DeleteObject(FHandle);
    FHandle := 0;
    FBits := nil;
  end;
end;

procedure THBitmap.NeedHandle;
var bi: TBitmapInfo;
    dc: HDC;
begin
  DeleteDc;
  DeleteHandle;

  if (FWidth = 0)
     or (FHeight = 0)
     or (FBpp = 0)
  then Exit;

  FillChar(bi, SizeOf(bi), 0);
  bi.bmiHeader.biSize := sizeof(TBitmapInfoHeader);
  bi.bmiHeader.biWidth := FWidth;
  bi.bmiHeader.biHeight := -FHeight;
  bi.bmiHeader.biPlanes := 1;
  bi.bmiHeader.biBitCount := FBpp;
  dc := CreateCompatibleDC(0);
  FHandle := CreateDIBSection(dc, bi, DIB_RGB_COLORS, FBits, 0, 0);
  Windows.DeleteDC(dc);

  if (FHandle = 0)
  then FBits := nil;

  FPitch := BitmapPitch(FWidth, FBpp);
end;

function THBitmap.GetBound: TRect;
begin
  Result := Rect(0, 0, FWidth, FHeight);
end;

procedure THBitmap.NeedDc;
begin
  if (FHandle = 0)
  then Exit;

  DeleteDc;

  FDc := CreateCompatibleDC(HWND_DESKTOP);
  FBmp0 := SelectObject(FDc, FHandle);
end;

procedure THBitmap.SetSize(AWidth, AHeight: Integer);
begin
  if (FWidth <> AWidth)
     or (FHeight <> AHeight)
  then begin
    FWidth := AWidth;
    FHeight := AHeight;
    NeedHandle;
  end;
end;

function THBitmap.GetDc: HDC;
begin
  NeedDc;
  Result := FDc;
end;

procedure THBitmap.Clear;
begin
  if (FBits = nil)
  then Exit;
  ZeroMemory(FBits, FPitch * FHeight);
end;

{ Set all pixel opaque. Only for 32-bit bitmap }
procedure THBitmap.Opaque;
var color: PCardinal;
    i: Cardinal;
begin
  if (FBits = nil)
     or (FBpp <> 32)
  then Exit;

  if (FDc <> 0)
  then SelectObject(FDc, FBmp0);

  color := PCardinal(FBits);
  for i := 1 to (FWidth * FHeight) do
  begin
    color^ := $FF000000 or (color^ and $FFFFFF);
    Inc(color);
  end;

  if (FDc <> 0)
  then FBmp0 := SelectObject(FDc, FHandle);
end;

{ Set all pixel opaque within ARect. Only for 32-bit bitmap }
procedure THBitmap.OpaqueRect(ARect: TRect);
var color: PCardinal;
    x, y, w: Integer;
begin
{$IFDEF DEBUG}
  Assert( (ARect.Left >= 0)
          and (ARect.Top >= 0)
          and (ARect.Right <= FWidth)
          and (ARect.Bottom <= Height) );
{$ENDIF}

  if (FBits = nil)
     or (FBpp <> 32)
  then Exit;

  if (FDc <> 0)
  then SelectObject(FDc, FBmp0);

  w := ARect.Width;
  for y := 0 to ARect.Height-1 do
  begin
    color := PCardinal(FBits);
    Inc(color, (ARect.Top + y) * FWidth + ARect.Left);
    for x := 1 to w do
    begin
      color^ := $FF000000 or (color^ and $FFFFFF);
      Inc(color);
    end;
  end;

  if (FDc <> 0)
  then FBmp0 := SelectObject(FDc, FHandle);
end;

end.
