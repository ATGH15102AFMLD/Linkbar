{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{            Copyright (c) 2010-2018 Asaq               }
{*******************************************************}

unit Linkbar.Common;

{$i linkbar.inc}

interface

uses
  Windows, SysUtils;

  procedure ReduceSysMenu(AWnd: HWND);
  procedure PreventSizing(var AResult: LPARAM);
  function RemovePrefix(A: string): string;

implementation

function RemovePrefix(A: string): string;
begin
  Result := StringReplace(A, '&', '', []);
end;

procedure ReduceSysMenu(AWnd: HWND);
var menu: HMENU;
    i: Integer;
    id: Cardinal;
begin
  menu := GetSystemMenu(AWnd, False);
  if (menu > 0)
  then begin
    i := 0;
    while i < GetMenuItemCount(menu) do
    begin
      id := GetMenuItemID(menu, i);
      if (id = SC_CLOSE) or (id = SC_MOVE)
      then Inc(i)
      else DeleteMenu(menu, id, MF_BYCOMMAND);
    end;
  end;
end;

procedure PreventSizing(var AResult: LPARAM);
begin
  if (AResult = HTCAPTION)
     or (AResult = HTCLOSE)
     or (AResult = HTNOWHERE)
     or (AResult = LPARAM(HTERROR))
  then Exit;

  if (AResult = HTTOP) or (AResult = HTTOPLEFT) or (AResult = HTTOPRIGHT)
  then AResult := HTCAPTION
  else AResult := HTCLIENT;
end;

end.
