{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{   Groups: folder with shortcuts, drop-down on hover   }
{*******************************************************}

{ A group is a sub folder of the linkbar working directory that contains
  the marker file "group.ini". The folder holds shortcuts (.lnk, .url, .website).

  - hover over the group item  -> drop-down list with the shortcuts
  - click on the group item    -> all shortcuts are started (0.5 s apart)
  - group.ini: [Group] icon=<file name of an .ico from the "icons" folder>
    (no icon = the Windows folder icon) }

unit Linkbar.Group;

interface

{$i linkbar.inc}

uses
  Winapi.Windows, System.Types, System.UITypes, LBToolbar, Linkbar.Consts;

const
  GROUP_MARKER  = 'group.ini';
  GROUP_SECTION = 'Group';
  GROUP_INI_ICON = 'icon';

type
  { Where the drop-down opens relative to the linkbar }
  TGroupPopupDir = (gpdDown, gpdUp, gpdRight, gpdLeft);

  { Draws text the same way as the linkbar (glass text) }
  TGroupTextProc = reference to procedure(ADc: HDC; AText: string; ARect: TRect;
    AFlags: Cardinal; AColor: TColor);

  { Look of the linkbar. The drop-down copies it (blur/glass, colors). }
  TGroupStyle = record
    Align: TPanelAlign;
    IsLight: Boolean;
    Transparency: TTransparencyMode;
    BgColor: Cardinal;
    UseTextColor: Boolean;
    TextColor: TColor;
    DrawText: TGroupTextProc;
  end;

  TItemGroup = class(TItemShortcut)
  public
    IconName: string;
  public
    constructor Create; override;
    function LoadFromFile(const AFileName: string): Boolean; override;
    procedure LoadIcon(const AIconSize: Integer); override;
    procedure DoExecute(AHandle: HWND); override;
    function GetDropPart(const APoint: TPoint; const AVertical: Boolean; const ASideOnly: Boolean = False): Integer; override;
  end;

  { Show the drop-down of a group (called when the group item becomes hot) }
  procedure GroupHover(AOwnerWnd: HWND; const AFolder: string;
    const AItemRect, ABarRect: TRect; ADir: TGroupPopupDir; const AStyle: TGroupStyle);

  { Close the drop-down if it is visible }
  procedure GroupClosePopup;

  { Create a new empty group folder in <AWorkDir>, return its full path or '' }
  function GroupCreate(const AWorkDir, ABaseName: string): string;

  { True if <AFolder> is a group folder (has group.ini) }
  function GroupIsFolder(const AFolder: string): Boolean;

implementation

uses
  GdiPlus,
  Winapi.Messages, Winapi.ShlObj, Winapi.ActiveX, Winapi.ShellAPI,
  System.SysUtils, System.Classes, System.IniFiles, System.Generics.Collections,
  System.Math, Vcl.Controls, Vcl.Graphics, Vcl.Forms, Vcl.ExtCtrls, Vcl.Menus,
  Linkbar.Shell, Linkbar.L10n, Linkbar.OS, Linkbar.Graphics, Linkbar.Theme;

const
  HOVER_OPEN_DELAY   = 250;     // ms: how long the cursor must stay on the group item
  WATCH_INTERVAL     = 100;     // ms: polling of the cursor position
  WATCH_LEAVE_TICKS  = 3;       // WATCH_INTERVAL * 3 = 300 ms outside = close
  LAUNCH_DELAY       = 500;     // ms between started shortcuts
  POPUP_MAX_ROWS     = 30;
  POPUP_ICON_SIZE    = 24;

{ Collect shortcut file names (without path) of <AFolder>, sorted by name }
procedure CollectShortcuts(const AFolder: string; AList: TStringList);
var
  sr: TSearchRec;
  folder: string;
begin
  folder := IncludeTrailingPathDelimiter(AFolder);
  AList.Clear;
  AList.CaseSensitive := False;
  for var ext in ES_ARRAY do
  begin
    if (FindFirst(folder + '*' + ext, faAnyFile, sr) = 0)
    then begin
      repeat
        if ((sr.Attr and faDirectory) = 0)
           and SameText(ExtractFileExt(sr.Name), ext)
        then AList.Add(sr.Name);
      until (FindNext(sr) <> 0);
      FindClose(sr);
    end;
  end;
  AList.Sort;
end;

function GroupIsFolder(const AFolder: string): Boolean;
begin
  Result := FileExists(IncludeTrailingPathDelimiter(AFolder) + GROUP_MARKER);
end;

function GroupCreate(const AWorkDir, ABaseName: string): string;
var
  name, folder: string;
  i: Integer;
  ini: TIniFile;
begin
  name := ABaseName;
  i := 1;
  while DirectoryExists(IncludeTrailingPathDelimiter(AWorkDir) + name)
        or FileExists(IncludeTrailingPathDelimiter(AWorkDir) + name)
  do begin
    Inc(i);
    name := ABaseName + ' ' + IntToStr(i);
  end;

  folder := IncludeTrailingPathDelimiter(AWorkDir) + name;
  if not ForceDirectories(folder)
  then Exit('');

  ini := TIniFile.Create(IncludeTrailingPathDelimiter(folder) + GROUP_MARKER);
  try
    ini.WriteString(GROUP_SECTION, GROUP_INI_ICON, '');
  finally
    ini.Free;
  end;
  Result := folder;
end;

////////////////////////////////////////////////////////////////////////////////
// Drop-down window
////////////////////////////////////////////////////////////////////////////////

type
  { Non-activating window with the list of shortcuts of a group }
  TGroupPopup = class(THintWindow)
  private
    FOwnerWnd: HWND;
    FTitle: string;
    FRows: TObjectList<TItemShortcut>;
    FHot: Integer;
    FClosed: Boolean;
    FBusy: Boolean;
    FFolder: string;
    FRowH: Integer;
    FPad: Integer;
    FIconSize: Integer;
    FPopupW: Integer;
    FPopupH: Integer;
    FEmptyText: string;
    FStyle: TGroupStyle;
    function RowTop(const AIndex: Integer): Integer;
    function RowAt(const Y: Integer): Integer;
    function RowCount: Integer;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure Paint; override;
    procedure Render;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure ShowContextMenu(const AIndex: Integer);
    procedure WMNCHitTest(var Message: TWMNCHitTest); message WM_NCHITTEST;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Setup(AOwnerWnd: HWND; const AFolder: string; const AStyle: TGroupStyle);
    procedure ShowAt(const AItemRect, ABarRect: TRect; ADir: TGroupPopupDir);
    property Closed: Boolean read FClosed;
    property Busy: Boolean read FBusy;
  end;

constructor TGroupPopup.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FRows := TObjectList<TItemShortcut>.Create(True);
  FHot := -1;
  FClosed := False;
  FEmptyText := L10NFind('Group.Empty', '(empty)');
end;

destructor TGroupPopup.Destroy;
begin
  FRows.Free;
  inherited;
end;

procedure TGroupPopup.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  // Layered window (like the linkbar) without the system border and shadow
  Params.Style := Params.Style and not WS_BORDER;
  Params.WindowClass.Style := Params.WindowClass.Style and not CS_DROPSHADOW;
  Params.ExStyle := Params.ExStyle or WS_EX_TOOLWINDOW or WS_EX_NOACTIVATE or WS_EX_TOPMOST or WS_EX_LAYERED;
end;

{ THintWindow is transparent for the mouse by default, we need mouse clicks }
procedure TGroupPopup.WMNCHitTest(var Message: TWMNCHitTest);
begin
  Message.Result := HTCLIENT;
end;

procedure TGroupPopup.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  if (FHot <> -1)
  then begin
    FHot := -1;
    Render;
  end;
end;

function TGroupPopup.RowCount: Integer;
begin
  Result := Max(FRows.Count, 1);  // at least one row with the text "(empty)"
end;

{ Row 0 starts under the title row }
function TGroupPopup.RowTop(const AIndex: Integer): Integer;
begin
  Result := FRowH + FPad + AIndex * FRowH;
end;

function TGroupPopup.RowAt(const Y: Integer): Integer;
begin
  Result := (Y - (FRowH + FPad)) div FRowH;
  if (Y < (FRowH + FPad))
     or (Result < 0)
     or (Result >= FRows.Count)
  then Result := -1;
end;

procedure TGroupPopup.Setup(AOwnerWnd: HWND; const AFolder: string; const AStyle: TGroupStyle);
var
  names: TStringList;
  item: TItemShortcut;
  bmp: TBitmap;
  w, maxw: Integer;
  folder: string;
begin
  FOwnerWnd := AOwnerWnd;
  FStyle := AStyle;
  FFolder := IncludeTrailingPathDelimiter(AFolder);
  folder := IncludeTrailingPathDelimiter(AFolder);
  FTitle := ExtractFileName(ExcludeTrailingPathDelimiter(AFolder));

  FPad := MulDiv(4, Screen.PixelsPerInch, 96);
  FIconSize := MulDiv(POPUP_ICON_SIZE, Screen.PixelsPerInch, 96);
  FRowH := FIconSize + 2 * FPad;

  // Load shortcuts
  names := TStringList.Create;
  try
    CollectShortcuts(AFolder, names);
    for var i := 0 to Min(names.Count, POPUP_MAX_ROWS) - 1
    do begin
      item := TItemShortcut.Create;
      if item.LoadFromFile(folder + names[i])
      then begin
        item.LoadIcon(FIconSize);
        FRows.Add(item);
      end
      else item.Free;
    end;
  finally
    names.Free;
  end;

  // Measure
  bmp := TBitmap.Create;
  try
    bmp.Canvas.Font.Assign(Screen.IconFont);
    maxw := bmp.Canvas.TextWidth(FEmptyText);
    for var row in FRows
    do maxw := Max(maxw, bmp.Canvas.TextWidth(row.Caption));
    bmp.Canvas.Font.Style := [fsBold];
    maxw := Max(maxw, bmp.Canvas.TextWidth(FTitle));
  finally
    bmp.Free;
  end;

  w := FPad + FIconSize + FPad + maxw + 3 * FPad;
  FPopupW := Max(MulDiv(180, Screen.PixelsPerInch, 96),
               Min(w, MulDiv(480, Screen.PixelsPerInch, 96)));
  FPopupH := RowTop(RowCount) + FPad;
end;

procedure TGroupPopup.ShowAt(const AItemRect, ABarRect: TRect; ADir: TGroupPopupDir);
var
  x, y: Integer;
  work: TRect;
begin
  // Popup sticks to the edge of the linkbar window
  case ADir of
    gpdDown:
      begin
        x := AItemRect.Left;
        y := ABarRect.Bottom;
      end;
    gpdUp:
      begin
        x := AItemRect.Left;
        y := ABarRect.Top - FPopupH;
      end;
    gpdRight:
      begin
        x := ABarRect.Right;
        y := AItemRect.Top;
      end;
    else // gpdLeft
      begin
        x := ABarRect.Left - FPopupW;
        y := AItemRect.Top;
      end;
  end;

  // Keep the popup inside the monitor
  work := Screen.MonitorFromRect(AItemRect).BoundsRect;
  x := Max(work.Left, Min(x, work.Right - FPopupW));
  y := Max(work.Top, Min(y, work.Bottom - FPopupH));

  SetWindowPos(Handle, HWND_TOPMOST, x, y, FPopupW, FPopupH,
    SWP_NOACTIVATE or SWP_SHOWWINDOW);

  // Blur/glass behind the window, the same as the linkbar has
  if IsWindows10
  then ThemeSetWindowAccentPolicy10(Handle, FStyle.Transparency, FStyle.BgColor)
  else ThemeUpdateBlur(Handle, True);

  Render;
end;

{ The window is layered, it is drawn by Render }
procedure TGroupPopup.Paint;
begin
end;

{ Draw the drop-down into a 32 bit bitmap and show it as a layered window.
  Background, hover and text are drawn by the same functions as in the linkbar. }
procedure TGroupPopup.Render;
const
  bf: TBlendFunction = (BlendOp: AC_SRC_OVER; BlendFlags: 0;
        SourceConstantAlpha: 255; AlphaFormat: AC_SRC_ALPHA);
var
  bmp: THBitmap;
  params: TDrawBackgroundParams;
  gp: IGPGraphics;
  pen: IGPPen;
  fntBold: TFont;
  r, rt: TRect;
  dc, dcIcon: HDC;
  bmp0, fnt0: HGDIOBJ;
  colNormal, colHot, colRgb: TColor;
  ptSrc: TPoint;
  sz: TSize;
  textFlags: Cardinal;
begin
  if (not HandleAllocated)
     or (FPopupW <= 0)
  then Exit;

  bmp := THBitmap.Create(32);
  fntBold := TFont.Create;
  try
    bmp.SetSize(FPopupW, FPopupH);
    // NOTE: every access to bmp.Dc creates a NEW device context and deletes the previous one.
    // So the Theme* functions (they use bmp.Dc) are called first and dc is taken after them.

    // Background (the blur comes from the window accent, as in the linkbar)
    params.Bitmap := bmp;
    params.Align := FStyle.Align;
    params.ClipRect := Rect(0, 0, FPopupW, FPopupH);
    params.IsLight := FStyle.IsLight;
    params.BgColor := FStyle.BgColor;
    ThemeDrawBackground(@params);

    if FStyle.UseTextColor
    then begin
      colNormal := FStyle.TextColor;
      colHot := FStyle.TextColor;
    end
    else begin
      colNormal := ThemeButtonNormalTextColor;
      colHot := ThemeButtonSelectedTextColor;
    end;
    colRgb := ColorToRGB(colNormal);

    // Hot row
    if (FHot >= 0) and (FHot < FRows.Count)
    then begin
      r := Rect(2, RowTop(FHot), FPopupW - 2, RowTop(FHot) + FRowH);
      ThemeDrawHover(bmp, FStyle.Align, r);
    end;

    dc := bmp.Dc;

    // Frame (to be distinguished from the linkbar) and line under the title
    gp := TGPGraphics.Create(dc);
    pen := TGPPen.Create(TGPColor.Create(($A0 shl 24) or SwapRedBlue(Cardinal(colRgb) and $00FFFFFF)), 1);
    gp.DrawRectangle(pen, 0, 0, FPopupW - 1, FPopupH - 1);
    pen := TGPPen.Create(TGPColor.Create(($40 shl 24) or SwapRedBlue(Cardinal(colRgb) and $00FFFFFF)), 1);
    gp.DrawLine(pen, FPad, FRowH + FPad div 2, FPopupW - FPad, FRowH + FPad div 2);
    // GDI+ objects must be released before the bitmap and its dc
    pen := nil;
    gp := nil;

    // Icons
    dcIcon := CreateCompatibleDC(dc);
    try
      for var i := 0 to FRows.Count - 1
      do begin
        if (FRows[i].Bitmap <> 0)
        then begin
          bmp0 := SelectObject(dcIcon, FRows[i].Bitmap);
          Winapi.Windows.AlphaBlend(dc, FPad * 2, RowTop(i) + FPad, FIconSize, FIconSize,
            dcIcon, 0, 0, FIconSize, FIconSize, bf);
          SelectObject(dcIcon, bmp0);
        end;
      end;
    finally
      DeleteDC(dcIcon);
    end;

    // Texts
    if Assigned(FStyle.DrawText)
    then begin
      textFlags := DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS or DT_NOPREFIX;

      // Title (name of the group), bold
      fntBold.Assign(Screen.IconFont);
      fntBold.Style := [fsBold];
      fnt0 := SelectObject(dc, fntBold.Handle);
      rt := Rect(FPad * 2, 0, FPopupW - FPad, FRowH);
      FStyle.DrawText(dc, FTitle, rt, textFlags, colNormal);

      // Rows
      SelectObject(dc, Screen.IconFont.Handle);
      if (FRows.Count = 0)
      then begin
        rt := Rect(FPad * 2, RowTop(0), FPopupW - FPad, RowTop(0) + FRowH);
        FStyle.DrawText(dc, FEmptyText, rt, textFlags, colNormal);
      end
      else begin
        for var i := 0 to FRows.Count - 1
        do begin
          rt := Rect(FPad * 3 + FIconSize, RowTop(i), FPopupW - FPad, RowTop(i) + FRowH);
          if (i = FHot)
          then FStyle.DrawText(dc, FRows[i].Caption, rt, textFlags, colHot)
          else FStyle.DrawText(dc, FRows[i].Caption, rt, textFlags, colNormal);
        end;
      end;
      SelectObject(dc, fnt0);
    end;

    ptSrc := Point(0, 0);
    sz.cx := FPopupW;
    sz.cy := FPopupH;
    UpdateLayeredWindow(Handle, 0, nil, @sz, dc, @ptSrc, 0, @bf, ULW_ALPHA);
  finally
    fntBold.Free;
    bmp.Free;
  end;
end;

procedure TGroupPopup.MouseMove(Shift: TShiftState; X, Y: Integer);
var idx: Integer;
begin
  inherited;
  idx := RowAt(Y);
  if (idx <> FHot)
  then begin
    FHot := idx;
    Render;
  end;
end;

procedure TGroupPopup.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var idx: Integer;
begin
  inherited;
  if (Button = mbRight)
  then begin
    ShowContextMenu(RowAt(Y));
    Exit;
  end;
  if (Button <> mbLeft)
  then Exit;

  idx := RowAt(Y);
  if (idx >= 0)
  then begin
    // Hide first, then start the shortcut
    ShowWindow(Handle, SW_HIDE);
    FClosed := True;
    FRows[idx].DoExecute(FOwnerWnd);
  end;
end;

{ Right click: add a new shortcut into the group, open the folder, remove a shortcut }
procedure TGroupPopup.ShowContextMenu(const AIndex: Integer);
const
  CMD_NEW = 1;
  CMD_OPEN = 2;
  CMD_REMOVE = 3;
var
  menu: HMENU;
  pt: TPoint;
  cmd: Integer;
  fileName: string;
  op: TSHFileOpStruct;
begin
  menu := CreatePopupMenu;
  if (menu = 0)
  then Exit;
  FBusy := True;
  try
    AppendMenu(menu, MF_STRING, CMD_NEW, PChar(StripHotkey(L10NFind('Menu.Shortcut', 'Shortcut'))));
    AppendMenu(menu, MF_STRING, CMD_OPEN, PChar(L10NFind('Group.OpenFolder', 'Open folder')));
    if (AIndex >= 0) and (AIndex < FRows.Count)
    then AppendMenu(menu, MF_STRING, CMD_REMOVE, PChar(L10NFind('Group.Remove', 'Remove')));

    GetCursorPos(pt);
    SetForegroundWindow(FOwnerWnd);
    cmd := Integer(TrackPopupMenu(menu, TPM_RETURNCMD or TPM_RIGHTBUTTON, pt.X, pt.Y, 0, FOwnerWnd, nil));
    PostMessage(FOwnerWnd, WM_NULL, 0, 0);

    case cmd of
      CMD_NEW:
        begin
          NewShortcut(ExcludeTrailingPathDelimiter(FFolder));
          // Hide the list. The next hover loads it again with the new shortcut.
          ShowWindow(Handle, SW_HIDE);
          FClosed := True;
        end;
      CMD_OPEN:
        begin
          ShellExecute(0, 'open', PChar(ExcludeTrailingPathDelimiter(FFolder)), nil, nil, SW_SHOWNORMAL);
          ShowWindow(Handle, SW_HIDE);
          FClosed := True;
        end;
      CMD_REMOVE:
        begin
          fileName := FRows[AIndex].FileName;
          FillChar(op, SizeOf(op), 0);
          op.Wnd := FOwnerWnd;
          op.wFunc := FO_DELETE;
          fileName := fileName + #0;   // double #0 at the end
          op.pFrom := PChar(fileName);
          op.fFlags := FOF_ALLOWUNDO or FOF_NOCONFIRMATION;
          SHFileOperation(op);
          ShowWindow(Handle, SW_HIDE);
          FClosed := True;
        end;
    end;
  finally
    DestroyMenu(menu);
    FBusy := False;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
// Host: hover timers, popup life time, start of the whole group
////////////////////////////////////////////////////////////////////////////////

type
  TGroupHost = class
  private
    FPopup: TGroupPopup;
    FOpenTimer: TTimer;
    FWatchTimer: TTimer;
    FLaunchTimer: TTimer;
    // pending hover
    FHoverWnd: HWND;
    FHoverFolder: string;
    FHoverItemRect: TRect;
    FHoverBarRect: TRect;
    FHoverDir: TGroupPopupDir;
    FHoverStyle: TGroupStyle;
    FLeaveTicks: Integer;
    // start of the whole group
    FLaunchWnd: HWND;
    FLaunchFolder: string;
    FLaunchNames: TStringList;
    FLaunchIndex: Integer;
    procedure OpenTimerTimer(Sender: TObject);
    procedure WatchTimerTimer(Sender: TObject);
    procedure LaunchTimerTimer(Sender: TObject);
    procedure LaunchNext;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Hover(AOwnerWnd: HWND; const AFolder: string;
      const AItemRect, ABarRect: TRect; ADir: TGroupPopupDir; const AStyle: TGroupStyle);
    procedure ClosePopup;
    procedure Launch(AOwnerWnd: HWND; const AFolder: string);
  end;

var
  Host: TGroupHost = nil;

function GetHost: TGroupHost;
begin
  if (Host = nil)
  then Host := TGroupHost.Create;
  Result := Host;
end;

constructor TGroupHost.Create;
begin
  inherited Create;

  FLaunchNames := TStringList.Create;

  FOpenTimer := TTimer.Create(nil);
  FOpenTimer.Enabled := False;
  FOpenTimer.Interval := HOVER_OPEN_DELAY;
  FOpenTimer.OnTimer := OpenTimerTimer;

  FWatchTimer := TTimer.Create(nil);
  FWatchTimer.Enabled := False;
  FWatchTimer.Interval := WATCH_INTERVAL;
  FWatchTimer.OnTimer := WatchTimerTimer;

  FLaunchTimer := TTimer.Create(nil);
  FLaunchTimer.Enabled := False;
  FLaunchTimer.Interval := LAUNCH_DELAY;
  FLaunchTimer.OnTimer := LaunchTimerTimer;
end;

destructor TGroupHost.Destroy;
begin
  FOpenTimer.Free;
  FWatchTimer.Free;
  FLaunchTimer.Free;
  FPopup.Free;
  FLaunchNames.Free;
  inherited;
end;

procedure TGroupHost.ClosePopup;
begin
  FOpenTimer.Enabled := False;
  FWatchTimer.Enabled := False;
  FreeAndNil(FPopup);
end;

procedure TGroupHost.Hover(AOwnerWnd: HWND; const AFolder: string;
  const AItemRect, ABarRect: TRect; ADir: TGroupPopupDir; const AStyle: TGroupStyle);
begin
  // The same group is already open
  if Assigned(FPopup)
     and (not FPopup.Closed)
     and SameText(FHoverFolder, AFolder)
  then Exit;

  ClosePopup;

  FHoverWnd := AOwnerWnd;
  FHoverFolder := AFolder;
  FHoverItemRect := AItemRect;
  FHoverBarRect := ABarRect;
  FHoverDir := ADir;
  FHoverStyle := AStyle;

  FOpenTimer.Enabled := True;
end;

procedure TGroupHost.OpenTimerTimer(Sender: TObject);
var pt: TPoint;
begin
  FOpenTimer.Enabled := False;

  // Open only if the cursor is still on the group item
  if (not GetCursorPos(pt))
     or (not PtInRect(FHoverItemRect, pt))
  then Exit;

  FreeAndNil(FPopup);
  FPopup := TGroupPopup.Create(nil);
  FPopup.Setup(FHoverWnd, FHoverFolder, FHoverStyle);
  FPopup.ShowAt(FHoverItemRect, FHoverBarRect, FHoverDir);

  FLeaveTicks := 0;
  FWatchTimer.Enabled := True;
end;

{ Close the popup when the cursor is outside of the group item and the popup }
procedure TGroupHost.WatchTimerTimer(Sender: TObject);
var
  pt: TPoint;
  r: TRect;
begin
  if (FPopup = nil)
  then begin
    FWatchTimer.Enabled := False;
    Exit;
  end;

  if FPopup.Closed
  then begin
    ClosePopup;
    Exit;
  end;

  // A context menu of the popup is open: keep the popup
  if FPopup.Busy
  then begin
    FLeaveTicks := 0;
    Exit;
  end;

  GetCursorPos(pt);
  GetWindowRect(FPopup.Handle, r);

  if PtInRect(FHoverItemRect, pt) or PtInRect(r, pt)
  then FLeaveTicks := 0
  else Inc(FLeaveTicks);

  if (FLeaveTicks >= WATCH_LEAVE_TICKS)
  then ClosePopup;
end;

procedure TGroupHost.Launch(AOwnerWnd: HWND; const AFolder: string);
begin
  ClosePopup;
  FLaunchTimer.Enabled := False;

  FLaunchWnd := AOwnerWnd;
  FLaunchFolder := IncludeTrailingPathDelimiter(AFolder);
  CollectShortcuts(AFolder, FLaunchNames);
  FLaunchIndex := 0;

  if (FLaunchNames.Count = 0)
  then Exit;

  LaunchNext;   // the first one immediately
  if (FLaunchIndex < FLaunchNames.Count)
  then FLaunchTimer.Enabled := True;
end;

procedure TGroupHost.LaunchNext;
var item: TItemShortcut;
begin
  if (FLaunchIndex >= FLaunchNames.Count)
  then Exit;

  item := TItemShortcut.Create;
  try
    if item.LoadFromFile(FLaunchFolder + FLaunchNames[FLaunchIndex])
    then item.DoExecute(FLaunchWnd);
  finally
    item.Free;
  end;
  Inc(FLaunchIndex);
end;

procedure TGroupHost.LaunchTimerTimer(Sender: TObject);
begin
  LaunchNext;
  if (FLaunchIndex >= FLaunchNames.Count)
  then FLaunchTimer.Enabled := False;
end;

procedure GroupHover(AOwnerWnd: HWND; const AFolder: string;
  const AItemRect, ABarRect: TRect; ADir: TGroupPopupDir; const AStyle: TGroupStyle);
begin
  GetHost.Hover(AOwnerWnd, AFolder, AItemRect, ABarRect, ADir, AStyle);
end;

procedure GroupClosePopup;
begin
  if Assigned(Host)
  then Host.ClosePopup;
end;

////////////////////////////////////////////////////////////////////////////////
// TItemGroup
////////////////////////////////////////////////////////////////////////////////

constructor TItemGroup.Create;
begin
  inherited;
  FKind := TKind.Group;
  IconName := '';
end;

function TItemGroup.LoadFromFile(const AFileName: string): Boolean;
var ini: TIniFile;
begin
  Result := inherited LoadFromFile(AFileName);
  if Result
  then begin
    ini := TIniFile.Create(IncludeTrailingPathDelimiter(AFileName) + GROUP_MARKER);
    try
      IconName := Trim(ini.ReadString(GROUP_SECTION, GROUP_INI_ICON, ''));
    finally
      ini.Free;
    end;
  end;
end;

{ Own icon from the "icons" folder (next to the application) or the Windows folder icon }
procedure TItemGroup.LoadIcon(const AIconSize: Integer);
var
  path: string;
  pidl: PItemIDList;
begin
  DeleteObject(FBitmap);
  FBitmap := 0;

  if (IconName <> '')
  then begin
    path := ExtractFilePath(ParamStr(0)) + DN_ICONS + IconName;
    if FileExists(path)
    then begin
      pidl := nil;
      if (SHParseDisplayName(PChar(path), nil, pidl, 0, PDWORD(nil)^) = S_OK)
      then begin
        FBitmap := LoadIconFromPidl(pidl, AIconSize);
        CoTaskMemFree(pidl);
      end;
    end;
  end;

  if (FBitmap = 0)
  then inherited LoadIcon(AIconSize);
end;

{ Click on the group = start all shortcuts of the group }
procedure TItemGroup.DoExecute(AHandle: HWND);
begin
  GetHost.Launch(AHandle, FileName);
end;

{ Nothing can be dropped "onto" a group (the dropped file would be copied into
  the folder), only before / after it }
function TItemGroup.GetDropPart(const APoint: TPoint; const AVertical: Boolean; const ASideOnly: Boolean): Integer;
begin
  Result := inherited GetDropPart(APoint, AVertical, True);
end;

initialization

finalization
  FreeAndNil(Host);

end.
