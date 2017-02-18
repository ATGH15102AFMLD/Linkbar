{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{            Copyright (c) 2010-2017 Asaq               }
{*******************************************************}

unit ColorUtils;

interface

uses
  Graphics;

  procedure RGBtoHSB (const cRed, cGreen, cBlue: Byte; var H,S,B: Word);
  procedure HSBtoRGB (const H,S,B: Word; var cRed, cGreen, cBlue : Byte);

implementation

procedure MinMax(const i,j,k: Byte; var min: Integer; var max: Word); Inline;
begin
  if i > j then begin
    if i > k then max := i else max := k;
    if j < k then min := j else min := k
  end else begin
    if j > k then max := j else max := k;
    if i < k then min := i else min := k
  end;
end;

procedure RGBtoHSB (const cRed, cGreen, cBlue: Byte; var H, S, B: Word);
var
  Delta, MinValue, tmpH: Integer;
begin
  tmpH:= 0;
  MinMax(cRed, cGreen, cBlue, MinValue, B);
  Delta := B - MinValue;
  if B = 0 then S := 0 else S := (255 * Delta) div B;
  if S = 0 then tmpH := 0
  else begin
    if cRed = B then tmpH := (60 * (cGreen - cBlue)) div Delta
      else
    if cGreen = B then tmpH := 120 + (60 * (cBlue - cRed)) div Delta
      else
    if cBlue = B then tmpH := 240 + (60 * (cRed - cGreen)) div Delta;
    if tmpH < 0 then tmpH := tmpH + 360;
  end;
  H := tmpH;
end;

procedure HSBtoRGB (const H, S, B: Word; var cRed, cGreen, cBlue : Byte);
const
  divisor:  Integer = 255*60;
var
  f    :  Integer;
  hTemp:  Integer;
  p,q,t:  Integer;
  VS   :  Integer;
begin
  if s = 0 then begin
    cRed:= B;
    cGreen:= B;
    cBlue:= B;
  end else begin
    if H = 360 then hTemp:= 0 else hTemp:= H;
    f:= hTemp mod 60;
    VS:= B*S;
    p:= B - VS div 255;
    q:= B - (VS*f) div divisor;
    t:= B - (VS*(60 - f)) div divisor;
    hTemp:= hTemp div 60;
    case hTemp of
      0:  begin  cRed := B;   cGreen := t;   cBlue := p  end;
      1:  begin  cRed := q;   cGreen := B;   cBlue := p  end;
      2:  begin  cRed := p;   cGreen := B;   cBlue := t  end;
      3:  begin  cRed := p;   cGreen := q;   cBlue := B  end;
      4:  begin  cRed := t;   cGreen := p;   cBlue := B  end;
      5:  begin  cRed := B;   cGreen := p;   cBlue := q  end;
    end;
  end;
end;

end.
