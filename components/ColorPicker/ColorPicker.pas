{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{            Copyright (c) 2010-2017 Asaq               }
{*******************************************************}

unit ColorPicker;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, ImgList, StdCtrls, Math, Buttons;

type
  TRGB = packed record
    b, g, r: Byte;
  end;

  PRGBArray = ^TRGBArray;
  TRGBARRAY = array[0..0] of TRGB;

  TARGB = packed record
    B, G, R, A: Byte;
    class function Create(AColor: Cardinal): TARGB; static;
    function ToGdiColor: Cardinal;
  end;

  THSB = packed record
    h, s, b: Word;
  end;

  TfrmColorPicker = class(TForm)
    ilMain: TImageList;
    Panel1: TPanel;
    imgColorBox: TImage;
    imgZBar: TImage;
    imgColor: TImage;
    imgAlpha: TImage;
    editColor: TEdit;
    btnOk: TButton;
    btnCancel: TButton;
    procedure PaintColorPnl;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure imgColorBarMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure imgColorBarMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure imgColorBarMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure imgColorBoxMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure imgColorBoxMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure imgColorBoxMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure imgColorMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure imgAlphaMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure imgAlphaMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure imgAlphaMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure editColor1KeyPress(Sender: TObject; var Key: Char);
    procedure editColor1KeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure editColor1KeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  private
    FOnChanged: TNotifyEvent;
    procedure PaintAlphaBar;
    procedure PaintAlphaColor;
    procedure SetColor2(AColor: TARGB; Update: Boolean);
    procedure SetColor(AColor: Cardinal); overload;
    function GetColor: Cardinal;
    procedure DoChanged;
    procedure CreateMarker;
  private
    HBoxBmp, HBarBmp, ABarBmp, ColorBmp: TBitmap;
    NewColor: TARGB;
    HSBColor: THSB;
    CellMul, CellDiv: Byte;
    DoColor, DoBar, DoVar, DoAlpha: Boolean;
    LUT138: array[0..138] of Byte;
    CTab: array[0..255] of TRGB;
    WebSafeColorLut: array[0..255] of Byte;
    VarIdx: Integer;
    OldColor: TARGB;
    BoxX, BoxY, BarX, BarA: Integer;
    LastHue: Integer;
    TextEnter: Boolean;
    AlpBarHeight: Integer;
    procedure L10n;
  public
    procedure PaintVar;
    procedure PaintColorHue;
    procedure PaintHueBar;
    property Color: Cardinal read GetColor write SetColor;
    property OnChanged: TNotifyEvent read FOnChanged write FOnChanged;
  end;

implementation

{$R *.dfm}

uses
  ColorUtils, GdiPlusHelpers, GdiPlus, Linkbar.L10n;

function TfrmColorPicker.GetColor: Cardinal;
begin
  Result := NewColor.ToGdiColor;
end;

procedure TfrmColorPicker.SetColor(AColor: Cardinal);
begin
  OldColor := TARGB.Create(AColor);
  SetColor2(OldColor, true);
end;

procedure TfrmColorPicker.SetColor2(AColor: TARGB; Update: Boolean);
var h, s, b: Word;
begin
  if not Update
  then OldColor := AColor;

  NewColor := AColor;

  RGBtoHSB(NewColor.R, NewColor.G, NewColor.B, h, s, b);
  BoxX := MulDiv(137, s, 255);
  BoxY := 137 - MulDiv(137, b, 255);
  BarX := MulDiv(imgZBar.Width-1, h, 360);
  BarA := MulDiv(AlpBarHeight, NewColor.A, 255);
  LastHue := -1;
  PaintColorPnl;

  DoChanged;
end;

procedure TfrmColorPicker.PaintVar;
var
  x, y, i, j, k, q, h: Integer;
  col: TColor;
  cell: TRect;
  s: Double;
  mode16: Boolean;
begin
  mode16 := True;
  imgColorBox.Canvas.Brush.Color := clBlack;
  imgColorBox.Canvas.Rectangle(Canvas.ClipRect);
  // 16 or 64 mode ...
  if mode16 then
  begin
    CellMul := 4;
    CellDiv := 34;
    q := 8;
  end
  else
  begin
    CellMul := 8;
    CellDiv := 17;
    q := 32;
  end;
  s := 255 / (q - 1);
  j := (q * 2) - 1;
  h := MulDiv(360, BarX, imgZBar.Width-1);
  for i := 0 to q - 1 do
  begin
    k := Trunc(s * i);
    HSBtoRGB(h, k, 255, CTab[i].r, CTab[i].g, CTab[i].b);
    HSBtoRGB(h, 255, k, CTab[j - i].r, CTab[j - i].g, CTab[j - i].b);
  end;
  HBoxBmp.Canvas.Brush.Style := bsClear;
  HBoxBmp.Canvas.Brush.Color := clBlack;
  HBoxBmp.Canvas.Pen.Color := clBlack;
  HBoxBmp.Canvas.Rectangle(0, 0, 138, 138);
  HBoxBmp.Canvas.Brush.Style := bsSolid;
  for y := 0 to CellMul - 1 do
  begin
    for x := 0 to CellMul - 1 do
    begin
      i := (y * CellMul) + x;
      col := (cTab[i].b shl 16) + (cTab[i].g shl 8) + cTab[i].r;
      HBoxBmp.Canvas.Brush.Color := col;
      HBoxBmp.Canvas.Pen.Color := col;
      cell.Left := 1 + (x * CellDiv);
      cell.Top := 1 + (y * CellDiv);
      Cell.Right := Cell.Left + CellDiv - 2;
      Cell.Bottom := Cell.Top + CellDiv - 2;
      HBoxBmp.Canvas.Rectangle(Cell);
    end;
  end;
  imgColorBox.Canvas.Draw(1, 1, HBoxBmp);
end;

procedure TfrmColorPicker.PaintColorPnl;
begin
  PaintHueBar;

  PaintAlphaBar;

  if DoVar
  then PaintVar
  else PaintColorHue;

  PaintAlphaColor;

  imgColor.Canvas.Pen.Color := clBlack;
  imgColor.Canvas.Brush.Style := bsClear;

  if not TextEnter
  then editColor.Text := IntToHex(Cardinal(NewColor), 8);
end;

procedure TfrmColorPicker.DoChanged;
begin
  if Assigned(FOnChanged)
  then FOnChanged(Self);
end;

procedure TfrmColorPicker.editColor1KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  TextEnter := True;
  if Key = 13 then
  begin
  end;
end;

procedure TfrmColorPicker.editColor1KeyPress(Sender: TObject; var Key: Char);
begin
  if (Key = #8)
  then Exit;
  if not CharInSet(Key, ['a'..'f', 'A'..'F', '0'..'9'])
  then Key := #0;
end;

procedure TfrmColorPicker.editColor1KeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var c: TARGB;
begin
  c := TARGB.Create(StrToInt64Def(HexDisplayPrefix + editColor.Text, 0));
  BarA := MulDiv(AlpBarHeight, NewColor.A, 255);
  SetColor2(c, True);
  TextEnter := False;
end;

procedure TfrmColorPicker.L10n;
begin
  L10nControl(Self, 'Color.Caption');
  L10nControl(btnOk, 'Color.OK');
  L10nControl(btnCancel, 'Color.Cancel');
end;

procedure TfrmColorPicker.FormCreate(Sender: TObject);
const
  Colors: array[0..15] of TColor = (clBlack, clWhite, clGray, clSilver,
    clMaroon, clRed, clGreen, clLime, clOlive, clYellow, clNavy, clBlue,
    clPurple, clFuchsia, clTeal, clAqua);
var
  i: Integer;
begin
  L10n;

  AlpBarHeight := imgAlpha.Height - 1;

  HBoxBmp := TBitmap.Create;
  HBoxBmp.PixelFormat := pf24bit;
  HBoxBmp.Width := 137;
  HBoxBmp.Height := 137;

  HBarBmp := TBitmap.Create;
  HBarBmp.PixelFormat := pf24bit;
  HBarBmp.Width := 192;
  HBarBmp.Height := 1;

  ABarBmp := TBitmap.Create;
  ABarBmp.PixelFormat := pf24bit;
  ABarBmp.Width := imgAlpha.Width;
  ABarBmp.Height := imgAlpha.Height;

  ColorBmp := TBitmap.Create;
  ColorBmp.PixelFormat := pf24bit;
  ColorBmp.Width := imgColor.Width;
  ColorBmp.Height := imgColor.Height;

  CreateMarker;

  for i := 0 to 255 do
    WebSafeColorLut[i] := ((i + $19) div $33) * $33;
  for i := 0 to 137 do
    Lut138[i] := MulDiv(255, i, 137);

  DoColor := False;
  DoBar := False;
  DoVar := False;
  VarIdx := -1;
  LastHue := -1;

  PaintColorPnl;
end;

procedure TfrmColorPicker.FormDestroy(Sender: TObject);
begin
  ColorBmp.Free;
  ABarBmp.Free;
  HBarBmp.Free;
  HBoxBmp.Free;
end;

procedure TfrmColorPicker.imgAlphaMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  DoAlpha := True;
  if y < 0 then
    Y := 0;
  if y > imgAlpha.Height - 1 then
    y := imgAlpha.Height - 1;
  BarA := Y;
  NewColor.A := MulDiv(255, BarA, AlpBarHeight);
  PaintColorPnl;
end;

procedure TfrmColorPicker.imgAlphaMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
begin
  if not DoAlpha then
    Exit;
  if y < 0 then
    y := 0;
  if y > imgAlpha.Height - 1 then
    y := imgAlpha.Height - 1;
  BarA := Y;
  NewColor.A := MulDiv(255, BarA, AlpBarHeight);
  PaintColorPnl;
end;

procedure TfrmColorPicker.imgAlphaMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  DoAlpha := False;
  DoChanged;
end;

procedure TfrmColorPicker.imgColorBarMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  DoBar := True;
  if x < 0 then
    x := 0;
  if x > imgZBar.Width - 1 then
    x := imgZBar.Width - 1;
  BarX := x;
  HSBtoRGB(MulDiv(360, BarX, imgZBar.Width-1), LUT138[BoxX], 255 - LUT138[BoxY],
    NewColor.R, NewColor.G, NewColor.B);
  PaintcolorPnl;
end;

procedure TfrmColorPicker.imgColorBarMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
begin
  if not DoBar then
    Exit;
  if x < 0 then
    x := 0;
  if x > imgZBar.Width - 1 then
    x := imgZBar.Width - 1;
  BarX := x;
  HSBtoRGB(MulDiv(360, BarX, imgZBar.Width-1), LUT138[BoxX], 255 - LUT138[BoxY],
    NewColor.R, NewColor.G, NewColor.B);
  PaintcolorPnl;
end;

procedure TfrmColorPicker.imgColorBarMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  DoBar := False;
  DoChanged;
end;

procedure TfrmColorPicker.imgColorBoxMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if DoVar then
  begin
    VarIdx := ((y div CellDiv) * CellMul) + (x div CellDiv);
    NewColor.R := CTab[VarIdx].r;
    NewColor.G := CTab[VarIdx].g;
    NewColor.B := CTab[VarIdx].b;
    RGBtoHSB(NewColor.R, NewColor.G, NewColor.B, HSBColor.h, HSBColor.s,
      HSBColor.b);
    BoxX := MulDiv(137, HSBColor.s, 255);
    BoxY := 137 - MulDiv(137, HSBColor.b, 255);
    PaintColorPnl;
    Exit;
  end;
  DoColor := True;
  if X < 0 then
    X := 0;
  if X > imgColorBox.Width - 1 then
    X := imgColorBox.Width - 1;
  if Y < 0 then
    Y := 0;
  if Y > imgColorBox.Height - 1 then
    Y := imgColorBox.Height - 1;
  BoxX := MulDiv(HBoxBmp.Width, X, imgColorBox.Width-1);
  BoxY := MulDiv(HBoxBmp.Height, Y, imgColorBox.Height-1);
  HSBtoRGB(MulDiv(360, BarX, imgZBar.Width-1), LUT138[BoxX], 255 - LUT138[BoxY],
    NewColor.R, NewColor.G, NewColor.B);
  PaintcolorPnl;
end;

procedure TfrmColorPicker.imgColorBoxMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
begin
  if not DoColor then
    Exit;
  if x < 0 then
    x := 0;
  if x > imgColorBox.Width - 1 then
    x := imgColorBox.Width - 1;
  if y < 0 then
    y := 0;
  if y > imgColorBox.Height - 1 then
    y := imgColorBox.Height - 1;

  BoxX := MulDiv(HBoxBmp.Width, X, imgColorBox.Width-1);
  BoxY := MulDiv(HBoxBmp.Height, Y, imgColorBox.Height-1);

  HSBtoRGB(MulDiv(360, BarX, imgZBar.Width-1), LUT138[BoxX], 255 - LUT138[BoxY],
    NewColor.R, NewColor.G, NewColor.B);
  PaintColorPnl;
end;

procedure TfrmColorPicker.imgColorBoxMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  DoColor := False;
  DoChanged;
end;

procedure TfrmColorPicker.imgColorMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if y < (imgColor.Height div 2) then
    SetColor2(OldColor, False);
end;

procedure TfrmColorPicker.PaintColorHue;
var
  Row: PRGBArray;
  slMain, slSize, slPtr: Integer;
  x, y, w, h: Integer;
  m1, q1, q2, q3, s1, s2: Integer;
  r, g, b: Byte;
  LUT: array of Byte;
  markerx, markery: Integer;
begin
  h := MulDiv(360, BarX, imgZBar.Width-1);
  if (h <> LastHue)
  then begin // Only update if needed
    LastHue := h;
    HSBtoRGB(h, 255, 255, r, g, b);
    h := HBoxBmp.Height - 1;
    w := HBoxBmp.Width - 1;
    SetLength(LUT, w + 1);
    for x := 0 to w do
      LUT[x] := MulDiv(255, x, w);
    slMain := Integer(HBoxBmp.ScanLine[0]);
    slSize := Integer(HBoxBmp.ScanLine[1]) - slMain;
    slPtr := slMain;
    for y := 0 to h do
    begin
      s1 := LUT[y];
      m1 := s1 * -255 shr 8 + 255;
      q1 := (s1 * -r shr 8 + r) - m1; // Red
      q2 := (s1 * -g shr 8 + g) - m1; // Green
      q3 := (s1 * -b shr 8 + b) - m1; // Blue
      for x := 0 to w do
      begin
        s2 := LUT[x];
        Row := PRGBArray(slPtr);
        Row[x].r := Byte(s2 * q1 shr 8 + m1);
        Row[x].g := Byte(s2 * q2 shr 8 + m1);
        Row[x].b := Byte(s2 * q3 shr 8 + m1);
      end;
      slPtr := slPtr + slSize;
    end;
    LUT := nil;
  end;

  imgColorBox.Canvas.StretchDraw(Rect(0, 0, imgColorBox.Width, imgColorBox.Height), HBoxBmp);
  markerx := MulDiv(BoxX, imgColorBox.Width, HBoxBmp.Width);
  markery := MulDiv(BoxY, imgColorBox.Height, HBoxBmp.Height);
  ilMain.Draw(imgColorBox.Canvas, markerx - ilMain.Width div 2,
    markery - ilMain.Height div 2, 0, True); // Paint Marker
end;

procedure TfrmColorPicker.PaintHueBar;
var
  Row: PRGBArray;
  x: Integer;
begin
  Row := PRGBArray(HBarBmp.ScanLine[0]);
  for x := 0 to HBarBmp.Width - 1 do
    HSBToRGB(MulDiv(360, x, HBarBmp.Width-1), 255, 255, Row[x].r, Row[x].g, Row[x].b);
  imgZBar.Canvas.StretchDraw(Rect(0, 0, imgZBar.Width, imgZBar.Height), HBarBmp);
  ilMain.Draw(imgZBar.Canvas, BarX - ilMain.Width div 2, 0, 0, True); // Paint Marker
end;

procedure TfrmColorPicker.PaintAlphaColor;
var
  Row: PRGBArray;
  RowOff: Integer;
  x, y, a: Integer;
  bool: Boolean;
  c1, c2, c3: TRGB;
begin
  c1.R := 0;
  c1.G := 0;
  c1.B := 0;
  c2.R := 255;
  c2.G := 255;
  c2.B := 255;
  Row := PRGBArray(ColorBmp.ScanLine[0]);
  RowOff := Integer(ColorBmp.ScanLine[1]) - Integer(ColorBmp.ScanLine[0]);
  a := 255 - OldColor.A;
  c3.b := OldColor.B;
  c3.g := OldColor.G;
  c3.r := OldColor.R;
  for y := 0 to ColorBmp.Height - 1 do
  begin
    bool := (y and 4 = 0);
    if y = (imgColor.Height div 2) then
    begin
      a := 255 - NewColor.A;
      c3.r := NewColor.R;
      c3.g := NewColor.G;
      c3.b := NewColor.B;
    end;
    c1.R := a * (0 - c3.r) shr 8 + c3.r;
    c1.G := a * (0 - c3.g) shr 8 + c3.g;
    c1.B := a * (0 - c3.b) shr 8 + c3.b;
    c2.R := a * (255 - c3.r) shr 8 + c3.r;
    c2.G := a * (255 - c3.g) shr 8 + c3.g;
    c2.B := a * (255 - c3.b) shr 8 + c3.b;
    for x := 0 to ColorBmp.Width - 1 do
    begin
      if ((x + 1) mod 4 = 0) then
        bool := not bool;
      if bool then
        Row[x] := c1
      else
        Row[x] := c2;
    end;
    Row := PRGBArray(Integer(Row) + RowOff);
  end;

  imgColor.Canvas.StretchDraw(Rect(0, 0, imgColor.Width, imgColor.Height), ColorBmp);
end;

procedure TfrmColorPicker.PaintAlphaBar;
var
  Row: PRGBArray;
  RowOff: Integer;
  x, y, a: Integer;
  bool: Boolean;
  c1, c2: TRGB;
begin
  c1.R := 0;
  c1.G := 0;
  c1.B := 0;
  c2.R := 255;
  c2.G := 255;
  c2.B := 255;
  Row := PRGBArray(ABarBmp.ScanLine[0]);
  RowOff := Integer(ABarBmp.ScanLine[1]) - Integer(ABarBmp.ScanLine[0]);
  for y := 0 to ABarBmp.Height - 1 do
  begin
    bool := (y and 4 = 0);
    a := 255 - MulDiv(255, y, AlpBarHeight);
    c1.R := a * (0 - NewColor.R) shr 8 + NewColor.r;
    c1.G := a * (0 - NewColor.G) shr 8 + NewColor.g;
    c1.B := a * (0 - NewColor.B) shr 8 + NewColor.b;
    c2.R := a * (255 - NewColor.r) shr 8 + NewColor.r;
    c2.G := a * (255 - NewColor.g) shr 8 + NewColor.g;
    c2.B := a * (255 - NewColor.b) shr 8 + NewColor.b;
    for x := 0 to ABarBmp.Width - 1 do
    begin
      if ((x + 1) mod 4 = 0) then
        bool := not bool;
      if bool then
        Row[x] := c1
      else
        Row[x] := c2;
    end;
    Row := PRGBArray(Integer(Row) + RowOff);
  end;

  imgAlpha.Canvas.StretchDraw(Rect(0, 0, imgAlpha.Width, imgAlpha.Height), ABarBmp);
  ilMain.Draw(imgAlpha.Canvas, 0, BarA - ilMain.Height div 2, 0, True); // Paint Marker
end;

procedure TfrmColorPicker.CreateMarker;
var w, r, dr: Integer;
    bmp: TBitmap;
    drawer: IGPGraphics;
    pen: IGPPen;
    pw: Integer;
begin
  w := imgZBar.Height;

  dr := MulDiv(4, Self.PixelsPerInch, 96);
  r := w div 2 - dr;

  pw := MulDiv(2, Self.PixelsPerInch, 96);

  ilMain.SetSize(w, w);

  bmp := TBitmap.Create;
  bmp.PixelFormat := pf32bit;
  bmp.SetSize(w, w);

  drawer := bmp.ToGPGraphics;
  drawer.SmoothingMode := SmoothingModeAntiAlias;
  drawer.Clear(0);

  pen := TGPPen.Create(TGPColor.Create($ff000000), pw + 1);
  drawer.DrawEllipse(pen, TGPRect.Create(dr, dr - 1, 2*r, 2*r));

  pen.Color := TGPColor.Create($ffffffff);
  pen.Width := pw;
  drawer.DrawEllipse(pen, TGPRect.Create(dr, dr - 1, 2*r, 2*r));

  ilMain.Add(bmp, nil);
  bmp.Free;
end;

{ TARGB }

class function TARGB.Create(AColor: Cardinal): TARGB;
begin
  Result.B := AColor and $ff;
  Result.G := (AColor shr 8) and $ff;
  Result.R := (AColor shr 16) and $ff;
  Result.A := (AColor shr 24) and $ff;
end;

function TARGB.ToGdiColor: Cardinal;
begin
  Result := (Self.A shl 24) or (Self.R shl 16) or (Self.G shl 8) or (Self.B);
end;

end.

