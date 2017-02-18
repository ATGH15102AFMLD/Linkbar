{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{            Copyright (c) 2010-2017 Asaq               }
{*******************************************************}

unit mUnit;

{$i linkbar.inc}

interface

uses
  GdiPlus, GdiPlusHelpers,
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  System.UITypes, IniFiles, Menus, Vcl.ExtCtrls, Winapi.ShlObj,
  DDForms, Cromis.DirectoryWatch,
  AccessBar, LBToolbar, Linkbar.Consts, Linkbar.Hint, Linkbar.Taskbar;

type

  TLinkbarWcl = class(TLinkbarCustomFrom)
    pMenu: TPopupMenu;
    imClose: TMenuItem;
    imProperties: TMenuItem;
    imAddBar: TMenuItem;
    imRemoveBar: TMenuItem;
    N1: TMenuItem;
    N2: TMenuItem;
    imNewShortcut: TMenuItem;
    tmrUpdate: TTimer;
    imCloseAll: TMenuItem;
    imOpenWorkdir: TMenuItem;
    imLockBar: TMenuItem;
    N3: TMenuItem;
    imSortAlphabetically: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure FormMouseLeave(Sender: TObject);
    procedure FormMouseEnter(Sender: TObject);
    procedure imPropertiesClick(Sender: TObject);
    procedure imRemoveBarClick(Sender: TObject);
    procedure imCloseClick(Sender: TObject);
    procedure imAddBarClick(Sender: TObject);
    procedure imNewShortcutClick(Sender: TObject);
    procedure tmrUpdateTimer(Sender: TObject);
    procedure imCloseAllClick(Sender: TObject);
    procedure imOpenWorkdirClick(Sender: TObject);
    procedure imLockBarClick(Sender: TObject);
    procedure FormContextPopup(Sender: TObject; MousePos: TPoint;
      var Handled: Boolean);
    procedure imSortAlphabeticallyClick(Sender: TObject);
  private
    CBmpSelectedItem: TBitmap;
    CBmpDropPosition: TBitmap;
    BmpBtn: TBitmap;
    BmpMain: TBitmap;
    Items: TLBItemList;
    oAppBar : TAccessBar;
    oHint: TTooltip32;
    FHotIndex: Integer;
    FItemPressed: Integer;
    FMousePosDown: TPoint;
    FMousePosUp: TPoint;
    FMouseLeftDown: Boolean;
    FMouseDragLinkbar: Boolean;
    FMouseDragItem: Boolean;
    FBeforeDragBounds: TRect;
    FDragingItem: Boolean;
    FAutoHide: Boolean;
    FAutoHideTransparency: Boolean;
    FAutoShowMode: TAutoShowMode;
    FButtonSize: TSize;
    FButtonCenter: TPoint;
    FGripSize: Integer;
    FHintShow: Boolean;
    FItemMargin: TSize;
    FIconSize: Integer;
    FIsLightStyle: Boolean;
    FItemOrder: TItemOrder;
    FLockLinkbar: Boolean;
    FLockHotIndex: Boolean;
    FSortAlphabetically: Boolean;
    FBkgColor: Cardinal;
    FTxtColor: Cardinal;
    FUseBkgColor: Boolean;
    FUseTxtColor: Boolean;
    FGlowSize: Integer;
    FScreenEdge: TScreenAlign;
    FTextWidth: Integer;
    FTextOffset: Integer;
    FTextLayout: TTextLayout;
    FTextHeight: Integer;
    FIconOffset: TPoint;
    FTextRect: TRect;
    procedure UpdateWindowSize;
    procedure SetScreenAlign(AValue: TScreenAlign);
    procedure SetAutoHide(AValue: Boolean);
    procedure SetItemOrder(AValue: TItemOrder);
    procedure SetPressedIndex(AValue: integer);
    procedure SetHotIndex(AValue: integer);
    procedure SetButtonSize(AValue: TSize);
    procedure SetIconSize(AValue: integer);
    procedure SetIsLightStyle(AValue: Boolean);
    procedure SetItemMargin(AValue: TSize);
    procedure SetTextLayout(AValue: TTextLayout);
    procedure SetTextOffset(AValue: Integer);
    procedure SetTextWidth(AValue: Integer);
    procedure SetSortAlphabetically(AValue: Boolean);
    function GetScreenAlign: TScreenAlign;
    procedure DrawBackground(const ABitmap: TBitmap; const AClipRect: TRect);
    procedure DrawCaption(const ABitmap: TBitmap; const AIndex: Integer;
      const ADrawForDrag: Boolean = False);
    procedure DrawItem(ABitmap: TBitmap; AIndex: integer; ASelected,
      APressed: Boolean; ADrawBg: Boolean = True; ADrawForDrag: Boolean = False);
    procedure DrawItems;
    procedure RecreateMainBitmap(const AWidth, AHeight: integer);
    procedure RecreateButtonBitmap(const AWidth, AHeight: integer);
    procedure UpdateWindow(const AWnd: HWND; const ABounds: TRect;
      const AScreenEdge: TScreenAlign; const ABitmap: TBitmap);
    procedure UpdateBlur;
    function ItemIndexByPoint(const APt: TPoint;
      const ALastIndex: integer = ITEM_NONE): Integer;
    function CheckItem(AIndex: Integer): Boolean;
    function ScaleDimension(const X: Integer): Integer; inline;
  private
    procedure LoadProperties(const AFileName: string);
    procedure SaveProperties;
  private
    BitBucketNotify: Cardinal;
    procedure UpdateBitBuckets;
  private
    FDragScreenEdge: TScreenAlign;
    FMonitorNum: Integer;
    FDragMonitorNum: Integer;
    FItemPopup: Integer;
    FDragIndex: Integer;
    MonitorsWorkareaWoTaskbar: TDynRectArray;
    procedure DoExecuteItem(const AIndex: Integer);
    procedure DoClickItem(X, Y: Integer);
    procedure DoRenameItem(AIndex: Integer);
    procedure DoDragLinkbar(X, Y: Integer);
    procedure DoPopupMenu(APt: TPoint; AShift: Boolean);
    procedure DoPopupJumplist(APt: TPoint; AShift: Boolean);
    procedure DoDragItem(X, Y: Integer);
    procedure GetOrCreateFilesList(filename: string);
    procedure QuerySizingEvent(Sender: TObject; AVertical: Boolean;
      var AWidth, AHeight: Integer);
    procedure QuerySizedEvent(Sender: TObject; const AX, AY, AWidth, AHeight: Integer);
    procedure QueryHideEvent(Sender: TObject; AEnabled: boolean);
  private
    FRemoved: boolean;
    procedure DoPopupMenuItemExecute(const ACmd: Integer);
  protected
    // Drag&Drop functions
    FItemDropPosition: Integer;
    FPidl: PItemIDList;
    procedure SetDropPosition(AValue: TPoint);
    procedure DoDragEnter(const pt: TPoint); override;
    procedure DoDragOver(const pt: TPoint; var ppidl: PItemIDList); override;
    procedure DoDragLeave; override;
    procedure DoDrop(const pt: TPoint); override;
    procedure QueryDragImage(out ABitmap: TBitmap; out AOffset: TPoint); override;
  protected
    // Dir watch
    procedure DirWatchChange(const Sender: TObject; const AAction: TWatchAction;
      const AFileName: string); override;
    procedure DirWatchError(const Sender: TObject; const ErrorCode: Integer;
      const ErrorMessage: string); override;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure CreateWnd; override;
    procedure WndProc(var Msg: TMessage); override;
  protected
    FAutoHiden: Boolean;
    FCanAutoHide: Boolean;
    FLockAutoHide: Boolean;
    FBeforeAutoHideBound: TRect;
    FAfterAutoHideBound: TRect;
    FAutoShowDelay: Integer;
    procedure DoAutoHide;
    procedure _DoAutoShow;
    procedure _DoDelayedAutoShow;
    procedure OnFormJumplistDestroy(Sender: TObject);
  public
    procedure UpdateItemSizes;
    procedure PropertiesFormDestroyed;
    property AutoHide: Boolean read FAutoHide write SetAutoHide;
    property AutoHideTransparency: Boolean read FAutoHideTransparency write FAutoHideTransparency;
    property AutoShowMode: TAutoShowMode read FAutoShowMode write FAutoShowMode;
    property ButtonSize: TSize read FButtonSize write SetButtonSize;
    property ItemMargin: TSize read FItemMargin write SetItemMargin;
    property IconSize: Integer read FIconSize write SetIconSize;
    property IsLightStyle: Boolean read FIsLightStyle write SetIsLightStyle;
    property ItemOrder: TItemOrder read FItemOrder write SetItemOrder;
    property TextLayout: TTextLayout read FTextLayout write SetTextLayout;
    property TextOffset: Integer read FTextOffset write SetTextOffset;
    property TextWidth: Integer read FTextWidth write SetTextWidth;
    property HintShow: Boolean read FHintShow write FHintShow;
    property AutoShowDelay: Integer read FAutoShowDelay write FAutoShowDelay;
    property PressedIndex: Integer read FItemPressed write SetPressedIndex;
    property HotIndex: Integer read FHotIndex write SetHotIndex;
    property ScreenAlign: TScreenAlign read GetScreenAlign write SetScreenAlign;
    property SortAlphabetically: Boolean read FSortAlphabetically write SetSortAlphabetically;
    property BkgColor: Cardinal read FBkgColor write FBkgColor;
    property TxtColor: Cardinal read FTxtColor write FTxtColor;
    property UseBkgColor: Boolean read FUseBkgColor write FUseBkgColor;
    property UseTxtColor: Boolean read FUseTxtColor write FUseTxtColor;
    property GlowSize: Integer read FGlowSize write FGlowSize;
  private
    FEnableAeroGlass: Boolean;
    procedure SetEnableAeroGlass(AValue: Boolean);
  public
    property EnableAeroGlass: Boolean read FEnableAeroGlass write SetEnableAeroGlass;
  end;

  function IsValidPreferenceFile(const AFileName: string): Boolean;

var
  LinkbarWcl: TLinkbarWcl;
  IconsInLine,
  IconLinesCount: integer;
  FPreferencesFileName: string;

implementation

{$R *.dfm}

uses Types, Math, Dialogs, StrUtils,
  ExplorerMenu, Linkbar.Settings, Linkbar.Shell, Linkbar.Themes,
  Linkbar.OS, JumpLists.Api, JumpLists.Form,
  Linkbar.ResStr, Linkbar.Loc, RenameDialog,
  Themes;

const
  bf: TBlendFunction = (BlendOp: AC_SRC_OVER; BlendFlags: 0;
      SourceConstantAlpha: $FF; AlphaFormat: AC_SRC_ALPHA);

  WM_LB_SHELLNOTIFY = WM_USER + 88;
  TIMER_AUTO_SHOW = 15;

function IsValidPreferenceFile(const AFileName: string): Boolean;
var ini: TMemIniFile;
    wd: string;
begin
  wd := '';
  if FileExists(AFileName)
  then begin
    ini := TMemIniFile.Create(AFileName);
    try
      wd := ini.ReadString(INI_SECTION_MAIN, INI_DIR_LINKS, DEF_DIR_LINKS);
    finally
      ini.Free;
    end;
  end;
  Result := DirectoryExists(wd);
end;

function FindinSL(sl: TStringList; s: String; var index: integer): boolean;
var i: integer;
begin
  index := -1;
  for i := 0 to sl.Count-1 do
  begin
    if CompareText(sl[i], s) = 0
    then begin
      index := i;
      Break;
    end;
  end;
  Result := (index >= 0);
end;

procedure TLinkbarWcl.GetOrCreateFilesList(filename: string);
var list: TStringList;
    templist: TStringList;
    sr: TSearchRec;
    i, j : integer;
    ext: string;
    oItem: TLBItem;
begin
  if not Assigned(Items) then Items := TLBItemList.Create;
  Items.Clear;

  // Load last ordered items list
  list := TStringList.Create;
  if FileExists(filename) then
    list.LoadFromFile(filename, TEncoding.UTF8);

  templist := TStringList.Create;
  templist.CaseSensitive := False;
  //templist.Duplicates := dupIgnore;
  templist.Sorted := False;

  // Find supperted files in working directory
  for ext in ES_ARRAY do
  begin
    if ( FindFirst( WorkDir + '*' + ext, faAnyFile, sr) = 0 )
    then repeat
      templist.Add(sr.Name);
    until (FindNext(sr) <> 0);
    FindClose(sr);
  end;

  templist.Sort;

  // Ordering founded items
  i := 0;
  while i < list.Count do
  begin
    if templist.Find(list[i], j)
    then begin
      templist.Delete(j);
      Inc(i);
    end
    else list.Delete(i);
  end;

  // New item move to end
  if (templist.Count > 0)
  then list.AddStrings(templist);
  templist.Free;

  // Create linkbar items
  Items.Capacity := list.Count;
  for i := 0 to list.Count-1 do
  begin
    oItem := TLBItem.Create;
    if oItem.LoadFromFile(WorkDir + list.Strings[i])
    then Items.Add(oItem)
    else oItem.Free;
  end;
  list.Free;

  if FSortAlphabetically
  then Items.Sort;

  Items.IconSize := IconSize;
end;

function TLinkbarWcl.GetScreenAlign: TScreenAlign;
begin
  if FMouseDragLinkbar then Result := FDragScreenEdge
  else Result := FScreenEdge;
end;

function TLinkbarWcl.CheckItem(AIndex: Integer): Boolean;
var fn: string;
begin
  fn := Items[AIndex].FileName;
  Result := FileExists(fn);
  if not Result
  then begin
    if MessageDlg( RS_FILENOTFOUND + #13 + fn + #13 + RS_Q_DELETELINK,
        mtConfirmation, [mbOK, mbCancel], 0, mbCancel) = mrOk
    then begin
      Items.Delete(AIndex);
      UpdateWindowSize;
    end;
  end;
end;

procedure TLinkbarWcl.DrawBackground(const ABitmap: TBitmap;
  const AClipRect: TRect);
var params: TDrawBackgroundParams;
begin
  params.Bitmap := ABitmap;
  params.Align := ScreenAlign;
  params.ClipRect := AClipRect;
  params.IsLight := IsLightStyle;

  if (UseBkgColor)
  then params.BgColor := FBkgColor
  else params.BgColor := 0;

  ThemeDrawBackground(@params);
end;

procedure TLinkbarWcl.DrawCaption(const ABitmap: TBitmap; const AIndex: Integer;
  const ADrawForDrag: Boolean = False);
var
  bmp: TBitmap;                   // buffer bitmap
  i: Integer;
  LText: string;
  LTextRect: TRect;
  LTextFlags: Cardinal;
  LGlowSize: Integer;
  LPosBounds, LTxtBounds: TRect;  // buffer bitmap position and size
  LFromItem, LToItem: Integer;
  LTextColor: TColor;
  drawer: IGPGraphics;
begin
  // Optimization Hell !

  if (TextLayout = tlNone) then Exit;

  if AIndex = ITEM_ALL then
  begin // all items
    LFromItem := 0;
    LToItem := Items.Count-1;
    LPosBounds := Rect(0, 0, ABitmap.Width, ABitmap.Height);
  end
  else begin // AIndex item
    LFromItem := AIndex;
    LToItem := AIndex;
    LPosBounds := Items[AIndex].Rect;
    if ADrawForDrag
    then LPosBounds.Location := Point(0,0);

    LTxtBounds := FTextRect;
    if AIndex = PressedIndex
    then LTxtBounds.Offset(1,1);
  end;

  LTextFlags := TEXTALIGN[TextLayout] or DT_END_ELLIPSIS or DT_SINGLELINE
    or DT_NOPREFIX or DT_NOCLIP;

  if StyleServices.Enabled
  then begin // use DrawGlassText
    bmp := TBitmap.Create;
    bmp.PixelFormat := pf32bit;
    bmp.Canvas.Brush.Style := bsClear;
    bmp.SetSize(LPosBounds.Width, -LPosBounds.Height); // '-' need for DrawGlassText
    bmp.Canvas.Font := Screen.IconFont;

    if (UseTxtColor)
    then LTextColor := TGPColor.Create(FTxtColor).ColorRef
    else begin
      // Automatic text color
      if (StyleServices.Enabled)
      then begin
        if (IsWindowsVista)
        then LTextColor := clWhite
        else if (IsWindows8OrAbove)
             then LTextColor := clWhite
             else LTextColor := clBtnText;
      end
      else LTextColor := clBtnText;
    end;

    LGlowSize := FGlowSize;

    for i := LFromItem to LToItem do
    begin
      LText := Items[i].Caption;

      if AIndex = ITEM_ALL
      then begin
        LTextRect := FTextRect;
        LTextRect.Offset(Items[i].Rect.Left, Items[i].Rect.Top)
      end
      else LTextRect := LTxtBounds;

      LTextRect.Inflate(-TEXT_BORDER, -TEXT_BORDER, -TEXT_BORDER, -TEXT_BORDER);

      DrawGlassText(bmp.Canvas.Handle, LText, LTextRect, LTextFlags,
        LGlowSize, LTextColor);
    end;

    Windows.AlphaBlend(ABitmap.Canvas.Handle,
      LPosBounds.Left, LPosBounds.Top, LPosBounds.Width, LPosBounds.Height,
      bmp.Canvas.Handle,
      0, 0, bmp.Width, bmp.Height,
      bf);
    bmp.Free;
  end
  else begin // DrawThemeText/DrawThemeTextEx not work in Classic theme
    bmp := TBitmap.Create;
    bmp.PixelFormat := pf24bit;
    bmp.Canvas.Brush.Color := clBtnFace;
    bmp.SetSize(LPosBounds.Width, LPosBounds.Height);
    bmp.Canvas.Font := Screen.IconFont;
    bmp.Canvas.Font.Color := clBtnText;

    for i := LFromItem to LToItem do
    begin
      LText := Items[i].Caption;

      if AIndex = ITEM_ALL
      then begin
        LTextRect := FTextRect;
        LTextRect.Offset(Items[i].Rect.Left, Items[i].Rect.Top)
      end
      else LTextRect := LTxtBounds;

      LTextRect.Inflate(-TEXT_BORDER, -TEXT_BORDER, -TEXT_BORDER, -TEXT_BORDER);
      DrawText(bmp.Canvas.Handle, LText, -1, LTextRect, LTextFlags);
    end;

    drawer := ABitmap.ToGPGraphics;
    drawer.DrawImage(bmp.ToGPBitmap,
      LPosBounds.Left+TEXT_BORDER, LPosBounds.Top+TEXT_BORDER,
      TEXT_BORDER, TEXT_BORDER,
      LPosBounds.Width-2*TEXT_BORDER, LPosBounds.Height-2*TEXT_BORDER,
      UnitPixel);
    drawer := nil;

    bmp.Free;
  end;
end;

procedure TLinkbarWcl.DrawItem(ABitmap: TBitmap; AIndex: integer; ASelected,
  APressed: Boolean; ADrawBg: Boolean; ADrawForDrag: Boolean);
var r: TRect;
    d: Integer;
begin
  if AIndex = ITEM_NONE then Exit;

  r := Items[AIndex].Rect;

  // Classic themes have opaque background and button
  if ADrawBg
     and StyleServices.Enabled
  then DrawBackground(ABitmap, r);

  // For darg not need draw background
  if ADrawForDrag
  then r.Location := Point(0, 0);

  if APressed
  then ThemeDrawButton(ABitmap, r, True)
  else if ASelected
       then begin
         Windows.AlphaBlend(ABitmap.Canvas.Handle, r.Left, r.Top, r.Width, r.Height,
           BmpBtn.Canvas.Handle, 0, 0, r.Width, r.Height, bf);
       end;

  if APressed
  then d := 1
  else d := 0;

  // draw text
  DrawCaption(ABitmap, AIndex, ADrawForDrag);

  Items.Draw(ABitmap.Canvas.Handle, AIndex,
    r.Left + FIconOffset.X + d, r.Top + FIconOffset.Y + d);
end;

procedure TLinkbarWcl.DrawItems;
var i, iX, iY: Integer;
begin
  if IsVertical(ScreenAlign) then
  begin
    iX := 0;
    iY := FGripSize;
  end else
  begin
    iX := FGripSize;
    iY := 0;
  end;
  // calc items bounds
  for i := 0 to Items.Count - 1 do
  begin
    Items[i].Rect := Bounds(iX, iY, ButtonSize.Width, ButtonSize.Height);
    // calc next item position
    case ItemOrder of
      ioLeftToRight:
        begin
          Inc(iX, ButtonSize.Width);
          if (iX + ButtonSize.Width) > BmpMain.Width
          then begin
            if IsVertical(ScreenAlign)
            then iX := 0
            else iX := FGripSize;
            Inc(iY, ButtonSize.Height);
          end;
        end;
      ioUpToDown:
        begin
          Inc(iY, ButtonSize.Height);
          if (iY + ButtonSize.Height) > BmpMain.Height
          then begin
            if IsVertical(ScreenAlign)
            then iY := FGripSize
            else iY := 0;
            Inc(iX, ButtonSize.Width);
          end;
        end;
    end;
  end;
  // Draw captions
  DrawCaption(BmpMain, ITEM_ALL);
  // Draw icons
  for i := 0 to Items.Count - 1 do
  begin
    Items.Draw(BmpMain.Canvas.Handle, i,
      Items[i].Rect.Left + FIconOffset.X, Items[i].Rect.Top + FIconOffset.Y);
  end;
end;

procedure TLinkbarWcl.RecreateMainBitmap(const AWidth, AHeight: integer);
begin
  if Assigned(BmpMain) then BmpMain.Free;
  // Create clear bitmap
  BmpMain := TBitmap.Create;
  BmpMain.PixelFormat := pf32bit;
  BmpMain.Canvas.Brush.Style := bsClear;
  BmpMain.SetSize(AWidth, AHeight);
  // Draw background
  DrawBackground(BmpMain, BmpMain.Canvas.ClipRect);
  // Draw items
  DrawItems;
end;

procedure TLinkbarWcl.RecreateButtonBitmap(const AWidth, AHeight: integer);
begin
  // Create clear bitmap
  if Assigned(BmpBtn) then BmpBtn.Free;
  BmpBtn := TBitMap.Create;
  BmpBtn.PixelFormat := pf32bit;
  BmpBtn.Canvas.Brush.Style := bsClear;
  BmpBtn.SetSize(AWidth, AHeight);

  // test hover texture
  ThemeDrawButton(BmpBtn, Rect(0, 0, AWidth, AHeight), False);

  // Buffer for selections
  if not Assigned(CBmpSelectedItem)
  then begin
    CBmpSelectedItem := TBitmap.Create;
    CBmpSelectedItem.PixelFormat := pf32bit;
  end;
  CBmpSelectedItem.SetSize(AWidth, AHeight);

  // Buffer for drop
  if not Assigned(CBmpDropPosition)
  then begin
    CBmpDropPosition := TBitmap.Create;
    CBmpDropPosition.PixelFormat := pf32bit;
  end;
  CBmpDropPosition.SetSize(AWidth, AHeight);
end;

procedure TLinkbarWcl.UpdateWindow(const AWnd: HWND; const ABounds: TRect;
  const AScreenEdge: TScreenAlign; const ABitmap: TBitmap);
var
  Pt1, Pt2: TPoint;
  Sz: TSize;
  bmp: TBitmap;
  gpDrawer: IGPGraphics;
begin
  // NOTE: we can't set TBlendFunction.SourceConstantAlpha = $01 because after
  // combined with any per-pixel alpha values in the hdcSrc we can get fully
  // transparent pixels
  // Insted use new bitmap filled black color with alpha $01
  if (FAutoHiden and FAutoHideTransparency)
  then begin
    Pt1 := ABounds.Location;
    Pt2 := Point(0,0);

    bmp := TBitmap.Create;
    bmp.PixelFormat := pf32bit;
    bmp.Canvas.Brush.Style := bsClear;
    bmp.SetSize(ABounds.Width, ABounds.Height);
    gpDrawer := bmp.ToGPGraphics;
    gpDrawer.Clear( $01000000 );

    Sz := TSize.Create(ABounds.Width, ABounds.Height);

    UpdateLayeredWindow(AWnd, 0, @Pt1, @Sz,
      bmp.Canvas.Handle, @Pt2, 0, @bf, ULW_ALPHA);

    bmp.Free;
  end
  else begin
    Pt1 := ABounds.Location;

    case AScreenEdge of
      saLeft:   Pt2 := Point(ABitmap.Width - ABounds.Width, 0);
      saTop:    Pt2 := Point(0, ABitmap.Height - ABounds.Height);
      saRight:  Pt2 := Point(0, 0);
      saBottom: Pt2 := Point(0, 0);
    end;

    Sz := TSize.Create(ABounds.Width, ABounds.Height);

    UpdateLayeredWindow(AWnd, 0, @Pt1, @Sz,
      ABitmap.Canvas.Handle, @Pt2, 0, @bf, ULW_ALPHA); {}
  end;
end;

procedure TLinkbarWcl.UpdateBlur;
begin
  ThemeUpdateBlur(Handle, not (FAutoHiden and FAutoHideTransparency) );
end;

procedure TLinkbarWcl.LoadProperties(const AFileName: string);
var IniFile: TMemIniFile;
begin
  if FileExists(AFileName) then
  begin // Load values
    IniFile := TMemIniFile.Create(AFileName);
    try
      WorkDir := IniFile.ReadString(INI_SECTION_MAIN, INI_DIR_LINKS, DEF_DIR_LINKS);

      FMonitorNum := IniFile.ReadInteger(INI_SECTION_MAIN, INI_MONITORNUM, -1);
      FScreenEdge := TScreenAlign(IniFile.ReadInteger(INI_SECTION_MAIN, INI_EDGE, DEF_EDGE));
      FAutoHide := IniFile.ReadBool(INI_SECTION_MAIN, INI_AUTOHIDE, DEF_AUTOHIDE);
      FAutoHideTransparency := IniFile.ReadBool(INI_SECTION_MAIN, INI_AUTOHIDE_TRANSPARENCY,
        DEF_AUTOHIDE_TRANSPARENCY);
      FAutoShowMode := TAutoShowMode(IniFile.ReadInteger(INI_SECTION_MAIN, INI_AUTOHIDE_SHOWMODE,
        DEF_AUTOHIDE_SHOWMODE));
      FIconSize := IniFile.ReadInteger(INI_SECTION_MAIN, INI_ICON_SIZE, DEF_ICON_SIZE);
      FItemMargin.cx := IniFile.ReadInteger(INI_SECTION_MAIN, INI_MARGINX, DEF_MARGINX);
      FItemMargin.cy := IniFile.ReadInteger(INI_SECTION_MAIN, INI_MARGINY, DEF_MARGINY);

      FTextLayout := TTextLayout(IniFile.ReadInteger(INI_SECTION_MAIN, INI_TEXT_LAYOUT, DEF_TEXT_LAYOUT));
      FTextOffset := IniFile.ReadInteger(INI_SECTION_MAIN, INI_TEXT_OFFSET, DEF_TEXT_OFFSET);
      FTextWidth := IniFile.ReadInteger(INI_SECTION_MAIN, INI_TEXT_WIDTH, DEF_TEXT_WIDTH);

      FItemOrder := TItemOrder(IniFile.ReadInteger(INI_SECTION_MAIN, INI_ITEM_ORDER, DEF_ITEM_ORDER));
      FLockLinkbar := IniFile.ReadBool(INI_SECTION_MAIN, INI_LOCK_BAR, DEF_LOCK_BAR);

      FIsLightStyle := IniFile.ReadBool(INI_SECTION_MAIN, INI_ISLIGHT, DEF_ISLIGHT);
      FEnableAeroGlass := IniFile.ReadBool(INI_SECTION_MAIN, INI_ENABLE_AG, DEF_ENABLE_AG);

      FAutoShowDelay := IniFile.ReadInteger(INI_SECTION_MAIN, INI_AUTOSHOW_DELAY, DEF_AUTOSHOW_DELAY);
      FSortAlphabetically := IniFile.ReadBool(INI_SECTION_MAIN, INI_SORT_AB, DEF_SORT_AB);

      FUseBkgColor := IniFile.ReadBool(INI_SECTION_MAIN, INI_USEBKGCOLOR, DEF_USECOLOR);
      FBkgColor := IniFile.ReadInteger(INI_SECTION_MAIN, INI_BKGCOLOR, DEF_BKGCOLOR);
      FUseTxtColor := IniFile.ReadBool(INI_SECTION_MAIN, INI_USETXTCOLOR, DEF_USECOLOR);
      FTxtColor := IniFile.ReadInteger(INI_SECTION_MAIN, INI_TXTCOLOR, DEF_TXTCOLOR);

      FGlowSize := IniFile.ReadInteger(INI_SECTION_MAIN, INI_GLOWSIZE, DEF_GLOWSIZE);

      FHintShow := IniFile.ReadBool(INI_SECTION_DEV, INI_HINT_SHOW, DEF_HINT_SHOW);
    finally
      IniFile.Free;
    end;
  end
  else begin // Default values
    FMonitorNum := Screen.PrimaryMonitor.MonitorNum;
    FScreenEdge := TScreenAlign(DEF_EDGE);
    FAutoHide := DEF_AUTOHIDE;
    FAutoHideTransparency := DEF_AUTOHIDE_TRANSPARENCY;
    FAutoShowMode := TAutoShowMode(DEF_AUTOHIDE_SHOWMODE);
    FIconSize  := DEF_ICON_SIZE;
    FItemMargin := TSize.Create(DEF_MARGINX, DEF_MARGINY);

    FTextLayout := TTextLayout(DEF_TEXT_LAYOUT);
    FTextOffset := DEF_TEXT_OFFSET;
    FTextWidth := DEF_TEXT_WIDTH;

    FItemOrder := TItemOrder(DEF_ITEM_ORDER);
    FLockLinkbar := DEF_LOCK_BAR;

    FIsLightStyle := DEF_ISLIGHT;
    FEnableAeroGlass := DEF_ENABLE_AG;

    FGlowSize := DEF_GLOWSIZE;

    FHintShow := DEF_HINT_SHOW;

    FAutoShowDelay := DEF_AUTOSHOW_DELAY;
    FSortAlphabetically := DEF_SORT_AB;
  end;

  { Check values }
  // Autohide mode
  if ( FAutoShowMode < Low(TAutoShowMode) ) or ( FAutoShowMode > High(TAutoShowMode) )
  then FAutoShowMode := TAutoShowMode(DEF_AUTOHIDE_SHOWMODE);
  // Monitor number
  if not InRange(FMonitorNum, 0, Screen.MonitorCount-1)
  then FMonitorNum := Screen.PrimaryMonitor.MonitorNum;
  // Screen edge
  if ( FScreenEdge < Low(TScreenAlign) ) or ( FScreenEdge > High(TScreenAlign) )
  then FScreenEdge := TScreenAlign(DEF_EDGE);

  FIconSize := EnsureRange(FIconSize, ICON_SIZE_MIN, ICON_SIZE_MAX);
  FItemMargin.cx := EnsureRange(FItemMargin.cx, MARGIN_MIN, MARGIN_MAX);
  FItemMargin.cy := EnsureRange(FItemMargin.cy, MARGIN_MIN, MARGIN_MAX);
  // Text layout
  if ( FTextLayout < Low(TTextLayout) ) or ( FTextLayout > High(TTextLayout) )
  then FTextLayout := TTextLayout(DEF_TEXT_LAYOUT);

  FTextOffset := EnsureRange(FTextOffset, TEXT_OFFSET_MIN, TEXT_OFFSET_MAX);
  FTextWidth := EnsureRange(FTextWidth, TEXT_WIDTH_MIN, TEXT_WIDTH_MAX);

  if ( FItemOrder < Low(TItemOrder) ) or ( FItemOrder > High(TItemOrder) )
  then FItemOrder := TItemOrder(DEF_ITEM_ORDER);

  if (FAutoShowDelay < 0) then FAutoShowDelay := 0;

  FGlowSize := EnsureRange(FGlowSize, GLOW_SIZE_MIN, GLOW_SIZE_MAX);

  { Set other values }
  FGripSize := GRIP_SIZE;
  FHotIndex := ITEM_NONE;
  FItemPressed := ITEM_NONE;
  FItemDropPosition := ITEM_NONE;
  FItemPopup := ITEM_NONE;
  FDragIndex := ITEM_NONE;
  FMouseLeftDown := False;
  FMouseDragLinkbar := False;
  FMouseDragItem := False;
  FDragingItem := False;

  ExpAeroGlassEnabled := FEnableAeroGlass;
end;

procedure TLinkbarWcl.SaveProperties;
var IniFile: TMemIniFile;
    sl: TStringList;
    i: integer;
    sv: Boolean;
begin
  try
    if DirectoryExists(WorkDir)
    then sv := True
    else sv := ForceDirectories(WorkDir);

    if sv
    then begin
      sl := TStringList.Create;
      try
        for i := 0 to Items.Count-1 do
          sl.Add( ExtractFileName(Items[i].FileName) );
        sl.SaveToFile(WorkDir + LINKSLIST_FILE_NAME, TEncoding.UTF8);
      finally
        sl.Free;
      end;
    end;

    if DirectoryExists(ExtractFilePath(FPreferencesFileName))
    then sv := True
    else sv := ForceDirectories(ExtractFilePath(FPreferencesFileName));

    if sv
    then begin
      IniFile := TMemIniFile.Create(FPreferencesFileName);
      try
        IniFile.WriteInteger(INI_SECTION_MAIN, INI_MONITORNUM, FMonitorNum);
        i := Integer(ScreenAlign);
        IniFile.WriteInteger(INI_SECTION_MAIN, INI_EDGE, i);
        IniFile.WriteBool(INI_SECTION_MAIN, INI_AUTOHIDE, AutoHide);
        IniFile.WriteBool(INI_SECTION_MAIN, INI_AUTOHIDE_TRANSPARENCY, FAutoHideTransparency);
        IniFile.WriteInteger(INI_SECTION_MAIN, INI_AUTOHIDE_SHOWMODE, Integer(AutoShowMode));

        IniFile.WriteInteger(INI_SECTION_MAIN, INI_ICON_SIZE, IconSize);
        IniFile.WriteInteger(INI_SECTION_MAIN, INI_MARGINX, ItemMargin.cx);
        IniFile.WriteInteger(INI_SECTION_MAIN, INI_MARGINY, ItemMargin.cy);

        IniFile.WriteInteger(INI_SECTION_MAIN, INI_TEXT_LAYOUT, Integer(TextLayout));
        IniFile.WriteInteger(INI_SECTION_MAIN, INI_TEXT_OFFSET, TextOffset);
        IniFile.WriteInteger(INI_SECTION_MAIN, INI_TEXT_WIDTH, TextWidth);

        IniFile.WriteInteger(INI_SECTION_MAIN, INI_ITEM_ORDER, Integer(ItemOrder));
        IniFile.WriteBool(INI_SECTION_MAIN, INI_LOCK_BAR, FLockLinkbar);

        IniFile.WriteBool(INI_SECTION_MAIN, INI_ISLIGHT, FIsLightStyle);
        IniFile.WriteBool(INI_SECTION_MAIN, INI_ENABLE_AG, FEnableAeroGlass);
        // Dev don't save
        //IniFile.WriteBool(INI_DEV, INI_HINT_SHOW, HintShow);

        IniFile.WriteInteger(INI_SECTION_MAIN, INI_AUTOSHOW_DELAY, FAutoShowDelay);
        IniFile.WriteBool(INI_SECTION_MAIN, INI_SORT_AB, FSortAlphabetically);

        // Custom background and text colors
        IniFile.WriteBool(INI_SECTION_MAIN, INI_USEBKGCOLOR, FUseBkgColor);
        IniFile.WriteString(INI_SECTION_MAIN, INI_BKGCOLOR, HexDisplayPrefix + IntToHex(FBkgColor, 8));
        IniFile.WriteBool(INI_SECTION_MAIN, INI_USETXTCOLOR, FUseTxtColor);
        IniFile.WriteString(INI_SECTION_MAIN, INI_TXTCOLOR, HexDisplayPrefix + IntToHex(FTxtColor, 6));

        IniFile.WriteInteger(INI_SECTION_MAIN, INI_GLOWSIZE, FGlowSize);

        IniFile.UpdateFile;
      finally
        IniFile.Free;
      end;
    end;
  except
  end;
end;

procedure TLinkbarWcl.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.Style := WS_POPUP;
  Params.ExStyle := (Params.ExStyle or WS_EX_TOOLWINDOW) and not WS_EX_APPWINDOW;
end;

procedure TLinkbarWcl.CreateWnd;
begin
  inherited CreateWnd;
  // Set layered window style
  if SetWindowLong(Handle, GWL_EXSTYLE, GetWindowLong(Handle, GWL_EXSTYLE) or WS_EX_LAYERED) = 0
  then MessageBox(Handle, PChar(SysErrorMessage(GetLastError)), 'Error', MB_ICONWARNING or MB_OK);
end;

procedure TLinkbarWcl.FormCreate(Sender: TObject);
begin
  LbTranslateComponent(Self);

  pMenu.Items.RethinkHotkeys;

  Color := 0;

  FrmProperties := nil;
  FLockAutoHide := False;
  FCanAutoHide := True;

  LoadProperties(FPreferencesFileName);

  ThemeSetWindowAttribute(Handle);

  ThemeInitData(Handle, FIsLightStyle);

  GetOrCreateFilesList(WorkDir + LINKSLIST_FILE_NAME);

  oHint := TTooltip32.Create(Handle);

  UpdateItemSizes;

  oAppBar := TAccessBar.Create2(self, FScreenEdge, FALSE);
  oAppBar.MonitorNum := FMonitorNum;
  oAppBar.QuerySizing := QuerySizingEvent;
  oAppBar.QuerySized := QuerySizedEvent;
  oAppBar.QueryAutoHide := QueryHideEvent;

  if not AutoHide then oAppBar.Loaded
  else AutoHide := TRUE;

  BitBucketNotify := RegisterBitBucketNotify(Handle, WM_LB_SHELLNOTIFY);
end;

procedure TLinkbarWcl.FormDestroy(Sender: TObject);
begin
  StopDirWatch;
  DeregisterBitBucketNotify(BitBucketNotify);
  if not FRemoved
  then SaveProperties;
  ThemeCloseData;
  if Assigned(oHint) then oHint.Free;
  if Assigned(BmpMain) then BmpMain.Free;
  if Assigned(BmpBtn) then BmpBtn.Free;
  if Assigned(CBmpSelectedItem) then CBmpSelectedItem.Free;
  if Assigned(CBmpDropPosition) then CBmpDropPosition.Free;
  if Assigned(Items) then Items.Free;
end;

function TLinkbarWcl.ItemIndexByPoint(const APt: TPoint;
  const ALastIndex: integer = ITEM_NONE): Integer;
var
  i: Integer;
begin
  if (APt.X < 0) or (APt.Y < 0)
  then Exit(ITEM_NONE);

  if (ALastIndex <> ITEM_NONE)
     and InRange(ALastIndex+1, 0, Items.Count)
     and PtInRect(Items[ALastIndex].Rect, APt)
  then Exit(ALastIndex);

  Result := ITEM_NONE;

  for i := 0 to Items.Count-1 do
  begin
    if PtInRect(Items[i].Rect, APt)
    then Exit(i);
  end;
end;

procedure TLinkbarWcl.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if AutoHide and FAutoHiden
  then Exit;

  FMousePosDown := Point(X, Y);

  case Button of
    mbLeft:
      begin
        FMouseLeftDown := True;
        PressedIndex := ItemIndexByPoint( Point(X, Y) );
      end
    else Exit;
  end;
end;

procedure TLinkbarWcl.FormMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
  if FAutoHiden then Exit;

  if Self.IsDragDrop then Exit;
  if FItemDropPosition <> ITEM_NONE then Exit;

  if not FMouseLeftDown then
  begin
    HotIndex := ItemIndexByPoint( Point(X, Y), HotIndex );
  end;

  if FMouseLeftDown
  then begin
    if FMouseDragLinkbar
    then DoDragLinkbar(X, Y)
    else if FMouseDragItem
    then begin
      if not FDragingItem
      then begin
        FDragingItem := True;
        DoDragItem(FMousePosDown.X, FMousePosDown.Y);
      end;
    end
    else if (not FLockLinkbar)
    then begin
      if (FItemPressed = ITEM_NONE)
      then begin
        if ( TPoint.Create(X,Y).Distance(FMousePosDown) > MOUSE_THRESHOLD )
        then begin
          FMouseDragLinkbar := True;
          FMouseDragItem := False;
          GetUserWorkArea(MonitorsWorkareaWoTaskbar);
          FBeforeDragBounds := BoundsRect;
          FDragMonitorNum := FMonitorNum;
        end;
      end
      else begin
        // If cursor leave item rect then start DragItem
        // This is done by MS for TaskBand items
        if ( not PtInRect(Items[FItemPressed].Rect, TPoint.Create(X, Y)) )
        then begin
          FMouseDragItem := True;
          FMouseDragLinkbar := False;
        end;
      end;

    end;
  end;
end;

procedure TLinkbarWcl.FormMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if FAutoHiden
  then begin
    if ( (AutoShowMode =  smMouseClickLeft) and (Button =  mbLeft) )
       or
       ( (AutoShowMode = smMouseClickRight) and (Button = mbRight) )
    then begin
      if PtInRect(Rect(0,0,Width,Height), Point(X, Y))
      then _DoAutoShow;
    end;
    Exit;
  end;

  FMousePosUp := Point(X, Y);
  case Button of
    mbLeft:
      begin
        FMouseLeftDown := False;
        // drag linkbar end
        if FMouseDragLinkbar then
        begin
          FMouseDragLinkbar := False;
          FMonitorNum := FDragMonitorNum;
          ScreenAlign := FDragScreenEdge;
        end
        else if FMouseDragItem
        then begin // drag item end
          FMouseDragItem := False;
          FDragingItem := False;
          FDragIndex := ITEM_NONE;
        end
        else if (PressedIndex <> ITEM_NONE)
        then begin // click
          // If during the execute shortcut will be a modal window with the error
          // should be reset PressedIndex before
          PressedIndex := ITEM_NONE;
          DoClickItem(X, Y);
        end;
        PressedIndex := ITEM_NONE;
      end
    else Exit;
  end;
end;

procedure TLinkbarWcl.DoDragItem(X, Y: Integer);
begin
  FDragIndex := ItemIndexByPoint( Point(X, Y) );
  if (FDragIndex <> ITEM_NONE)
  then begin
    HotIndex := ITEM_NONE;
    DragFile(Items[FDragIndex].FileName);
    FormMouseUp(Self, mbLeft, [], -1, -1);
  end;
end;

procedure TLinkbarWcl.DoExecuteItem(const AIndex: Integer);
begin
  if AIndex <> ITEM_NONE
  then begin
    if CheckItem(AIndex)
    then OpenByDefaultVerb(Handle, Items[AIndex].Pidl);
  end;
end;

procedure TLinkbarWcl.DoClickItem(X, Y: Integer);
var iIndex: Integer;
begin
  iIndex := ItemIndexByPoint( Point(X, Y) );
  DoExecuteItem(iIndex);
end;

procedure TLinkbarWcl.DoRenameItem(AIndex: Integer);
var dlg: TRenamingWCl;
begin
  FLockAutoHide := True;
  dlg := TRenamingWCl.Create(Self);
  dlg.Pidl := Items[AIndex].Pidl;
  dlg.ShowModal;
  dlg.Free;
  FLockAutoHide := False;
end;

procedure TLinkbarWcl.DoDragLinkbar(X, Y: Integer);
var Pt: TPoint;
   mon: TMonitor;
   k: Double;
   e: TScreenAlign;
   r: TRect;
   w, h: Integer;
begin
  Pt := Point(X,Y);
  MapWindowPoints(Handle, HWND_DESKTOP, Pt, 1);
  mon := Screen.MonitorFromPoint(Pt);
  // translate to monitor coordinates
  Pt.Offset(-mon.Left, -mon.Top);
  // calc edge
  k := mon.Width/mon.Height;
  if Pt.X < Pt.Y*k then
  begin // left/bottom
    if Pt.X < (mon.Height-Pt.Y)*k
    then e := saLeft
    else e := saBottom;
  end else
  begin // top/right
    if (mon.Width-Pt.X) < Pt.Y*k
    then e := saRight
    else e := saTop;
  end;

  if (e = FDragScreenEdge)
     and (mon.MonitorNum = FDragMonitorNum)
  then Exit;

  FDragScreenEdge := e;
  FDragMonitorNum := mon.MonitorNum;

  if (FDragScreenEdge = FScreenEdge)
     and (FDragMonitorNum = FMonitorNum)
  then begin // it's position before drag
    r := FBeforeDragBounds;
  end
  else begin
    if AutoHide
    then
      r := mon.BoundsRect
    else begin
      r := mon.WorkareaRect;

      if IsHorizontal(FDragScreenEdge)
      then begin
        r.Left := MonitorsWorkareaWoTaskbar[FDragMonitorNum].Left;
        r.Right := MonitorsWorkareaWoTaskbar[FDragMonitorNum].Right;
      end;

      // Correct new rect
      if (FDragMonitorNum = FMonitorNum)
         and IsVertical(FDragScreenEdge)
      then begin
        case FScreenEdge of
          saTop: r.Top := r.Top - FBeforeDragBounds.Height;
          saBottom: r.Bottom := r.Bottom + FBeforeDragBounds.Height;
        end;
      end;
    end;

    w := r.Width;
    h := r.Height;

    QuerySizingEvent(nil, IsVertical(e), w, h);
    case FDragScreenEdge of
      saRight: r.Left := r.Right - w;
      saBottom: r.Top := r.Bottom - h;
    end;
    r.Width := w;
    r.Height := h;
  end;
  QuerySizedEvent(nil, r.Left, r.Top, r.Width, r.Height);
end;

procedure TLinkbarWcl.DoPopupMenu(APt: TPoint; AShift: Boolean);
var
  FPopupMenu: HMENU;
  i: Integer;
  Flags: Integer;
  mii: TMenuItemInfo;
  mi: TMenuInfo;
  iconsize: Integer;
  hIco: HICON;
  hBmp: HBITMAP;
  command: LongBool;
begin
  if (FItemPopup <> ITEM_NONE)
     and not CheckItem(FItemPopup)
  then Exit;

  FPopupMenu := CreatePopupMenu;
  if (FPopupMenu = 0)
  then Exit;

  for i := 0 to pMenu.Items.Count-1 do
  begin
    // extended menu item
    if (AShift)
    then begin
      if (pMenu.Items[i] = imClose) then Continue;
    end
    else begin
      if (pMenu.Items[i] = imCloseAll) then Continue;
      if (pMenu.Items[i] = imOpenWorkdir) then Continue;
    end;

    Flags := MF_BYCOMMAND;
    if (pMenu.Items[i].Caption = cLineCaption)
    then Flags := Flags or MF_SEPARATOR
    else Flags := Flags or MF_STRING;

    if (pMenu.Items[i] = imLockBar)
       and (FLockLinkbar)
    then Flags := Flags or MF_CHECKED;

    if (pMenu.Items[i] = imSortAlphabetically)
       and (FSortAlphabetically)
    then Flags := Flags or MF_CHECKED;

    AppendMenu(FPopupMenu, Flags, pMenu.Items[i].Command,
      PChar(pMenu.Items[i].Caption));
  end;

  // Set icon&default for "Close" or "Close All" menu item
  FillChar(mii, SizeOf(mii), 0);
  mii.cbSize := SizeOf(mii);
  mii.fMask := MIIM_BITMAP or MIIM_STATE;
  mii.fState := MFS_DEFAULT;
  mii.hbmpItem := HBMMENU_POPUP_CLOSE;
  if (AShift)
  then SetMenuItemInfo(FPopupMenu, imCloseAll.Command, False, mii)
  else SetMenuItemInfo(FPopupMenu, imClose.Command, False, mii);

  { Set icon for "New shortcut" menu item }
  iconsize := GetSystemMetrics(SM_CXSMICON);
  hIco := LoadImage(GetModuleHandle('shell32.dll'), MakeIntResource(16769), IMAGE_ICON,
    iconsize, iconsize, LR_DEFAULTCOLOR);
  hBmp := BitmapFromIcon(hIco, iconsize);
  DestroyIcon(hIco);
  FillChar(mii, SizeOf(mii), 0);
  mii.cbSize := SizeOf(mii);
  mii.fMask := MIIM_BITMAP;
  mii.hbmpItem := hBmp;
  SetMenuItemInfo(FPopupMenu, imNewShortcut.Command, False, mii);
  {}

  FillChar(mi, SizeOf(mi), 0);
  mi.cbSize := SizeOf(mi);
  mi.fMask := MIM_STYLE;
  mi.dwStyle := MNS_CHECKORBMP;
  SetMenuInfo(FPopupMenu, mi);

  MapWindowPoints(Handle, HWND_DESKTOP, APt, 1);

  FLockHotIndex := True;
  FLockAutoHide := True;
  try
    oHint.Cancel;
    if (FItemPopup = ITEM_NONE)
    then begin
      // Execute Linkbar context menu
      command := TrackPopupMenuEx(FPopupMenu, TPM_RETURNCMD or TPM_RIGHTBUTTON
        or TPM_NONOTIFY, APt.X, APt.Y, Handle, nil);
      DestroyMenu(FPopupMenu);
      if (command)
      then PostMessage(Handle, SCMI_LB_ITEMS, 0, Integer(command));
    end
    else begin
      // Execute Shell context menu + Linkbar context menu as submenu
      // FPopupMenu will be destroyed automatically
      ExplorerMenuPopup(Handle, Items[FItemPopup].Pidl, APt, AShift, FPopupMenu);
    end;
  finally
    FLockHotIndex := False;
    FLockAutoHide := False;
    HotIndex := ITEM_NONE;
  end;

  DeleteObject(hBmp);
end;

procedure TLinkbarWcl.OnFormJumplistDestroy(Sender: TObject);
begin
  FLockHotIndex := False;
  HotIndex := ITEM_NONE;
  FLockAutoHide := False;
  DoAutoHide;
end;

procedure TLinkbarWcl.DoPopupJumplist(APt: TPoint; AShift: Boolean);
const JUMPLIST_ALIGN: array[TScreenAlign] of TJumplistAlign = (jaLeft, jaTop, jaRight, jaBottom);
var item: TLbItem;
    appid: array[0..MAX_PATH] of Char;
    pt: TPoint;
    r: TRect;
    fjl: TFormJumpList;
    maxcount: Integer;
begin
  item := Items[FItemPopup];

  { Check and show Jumplist }
  maxcount := GetJumpListMaxCount;
  if (maxcount > 0)
     and GetAppInfoForLink(item.Pidl, appid)
     and HasJumpList(appid)
  then begin
    oHint.Cancel;
    r := item.Rect;
    case ScreenAlign of
      saLeft:   pt := Point(r.Right, r.Bottom);
      saRight:  pt := Point(r.Left, r.Bottom);
      saTop:    pt := Point(r.CenterPoint.X, r.Bottom);
      saBottom: pt := Point(r.CenterPoint.X, r.Top);
    end;
    MapWindowPoints(Handle, 0, pt, 1);
    fjl := TFormJumpList.CreateNew(Self);
    fjl.OnDestroy := OnFormJumplistDestroy;
    if fjl.Popup(Handle, pt.X, pt.Y, JUMPLIST_ALIGN[ScreenAlign], appid,
      item.Pidl, maxcount)
    then begin
      FLockHotIndex := True;
      FLockAutoHide := True;
      Exit;
    end;
  end;

  { Show shell context menu }
  DoPopupMenu(APt, AShift);
end;

procedure TLinkbarWcl.FormContextPopup(Sender: TObject; MousePos: TPoint;
  var Handled: Boolean);
var pt: TPoint;
    shift: Boolean;
begin
  Handled := True;

  if FAutoHiden then Exit;

  pt := MousePos;
  if (pt.X = -1) and (pt.Y = -1)
  then begin
    // Pressed keyboard key "Menu"
    pt := Point(0, 0);
    FItemPopup := ITEM_NONE;
  end
  else
    FItemPopup := ItemIndexByPoint(pt);

  shift := GetKeyState(VK_SHIFT) < 0;

  if (FItemPopup = ITEM_NONE)
     or (shift) // show extended contextmenu for item with jumplist
  then DoPopupMenu(pt, shift)
  else DoPopupJumplist(pt, shift);
end;

procedure TLinkbarWcl.SetAutoHide(AValue: Boolean);
begin
  oAppBar.AutoHide := AValue;
  FAutoHide := oAppBar.AutoHide;
end;

procedure TLinkbarWcl.SetButtonSize(AValue: TSize);
begin
  if AValue = FButtonSize then Exit;
  FButtonSize := AValue;
  FButtonCenter := Point(FButtonSize.Width div 2, FButtonSize.Height div 2);
  RecreateButtonBitmap(FButtonSize.Width, FButtonSize.Height);
end;

procedure TLinkbarWcl.UpdateItemSizes;
var
  r: TRect;
  w, h: Integer;
begin
  // Calc text height
  if TextLayout = tlNone
  then FTextHeight := 0
  else FTextHeight := DrawText(Canvas.Handle, 'Wp', 2, r, DT_SINGLELINE or DT_NOCLIP or DT_CALCRECT);
  Inc(FTextHeight, 2*TEXT_BORDER);

  // Calc margin, icon offset & button size
  case TextLayout of
  tlLeft, tlRight:
    begin
      // button size
      w := FItemMargin.cx + FIconSize + FTextOffset + FTextWidth + FItemMargin.cx;
      h := FItemMargin.cy + Max(FIconSize, FTextHeight) + FItemMargin.cy;
      // icon offset
      if TextLayout = tlRight
      then FIconOffset.X := FItemMargin.cx
      else FIconOffset.X := FItemMargin.cx + FTextWidth + FTextOffset;
      FIconOffset.Y := (h - FIconSize) div 2;
      // text rect
      if TextLayout = tlRight
      then FTextRect := Bounds( FItemMargin.cx + FIconSize + FTextOffset,
        (h - FTextHeight) div 2, FTextWidth, FTextHeight )
      else FTextRect := Bounds( FItemMargin.cx, (h - FTextHeight) div 2,
        FTextWidth, FTextHeight );
    end;
  tlTop, tlBottom:
    begin
      // button size
      w := FItemMargin.cx + Max(FIconSize, FTextWidth) + FItemMargin.cx;
      h := FItemMargin.cy + FIconSize + FTextOffset + FTextHeight + FItemMargin.cy;
      // icon offset
      FIconOffset.X := (w - FIconSize) div 2;
      if textlayout = tlBottom
      then FIconOffset.Y := FItemMargin.cy
      else FIconOffset.Y := FItemMargin.cy + FTextHeight + FTextOffset;
      // text rect
      if textlayout = tlBottom
      then FTextRect := Bounds( FTextOffset, FItemMargin.cy + FIconSize + FTextOffset,
        w - 2*FTextOffset, FTextHeight )
      else FTextRect := Bounds( FTextOffset, FItemMargin.cy,
        w - 2*FTextOffset, FTextHeight );
    end;
  else
    begin
      w := FItemMargin.cx + FIconSize + FItemMargin.cx;
      h := FItemMargin.cy + FIconSize + FItemMargin.cy;
      FIconOffset := Point(FItemMargin.cx, FItemMargin.cy);
    end;
  end;

  ButtonSize := TSize.Create(w, h);
end;

procedure TLinkbarWcl.SetIconSize(AValue: integer);
begin
  if AValue = FIconSize then Exit;
  FIconSize := EnsureRange(AValue, ICON_SIZE_MIN, ICON_SIZE_MAX);
  Items.IconSize := FIconSize;
end;

procedure TLinkbarWcl.SetIsLightStyle(AValue: Boolean);
begin
  if AValue = FIsLightStyle then Exit;
  FIsLightStyle := AValue;
  if IsWindows8OrAbove then FIsLightStyle := False;
  ThemeInitData(Handle, FIsLightStyle);
end;

procedure TLinkbarWcl.SetItemMargin(AValue: TSize);
begin
  if AValue = FItemMargin then Exit;
  FItemMargin := AValue;
end;

procedure TLinkbarWcl.SetTextLayout(AValue: TTextLayout);
begin
  if AValue = FTextLayout then Exit;
  FTextLayout := AValue;
end;

procedure TLinkbarWcl.SetTextOffset(AValue: Integer);
begin
  if AValue = FTextOffset then Exit;
  FTextOffset := AValue;
end;

procedure TLinkbarWcl.SetTextWidth(AValue: Integer);
begin
  if AValue = FTextWidth then Exit;
  FTextWidth := AValue;
end;

procedure TLinkbarWcl.SetItemOrder(AValue: TItemOrder);
begin
  if AValue = FItemOrder then Exit;
  FItemOrder := AValue;
end;

procedure TLinkbarWcl.SetPressedIndex(AValue: integer);
begin
  if AValue = FItemPressed then Exit;
  oHint.Cancel;
  FItemPressed := AValue;
  DrawItem(BmpMain, FHotIndex, True, FItemPressed <> ITEM_NONE);
  UpdateWindow(Handle, BoundsRect, ScreenAlign, BmpMain);
end;

procedure TLinkbarWcl.SetHotIndex(AValue: integer);
var 
  r: TRect;
  Pt: TPoint;
  HA: TAlignment;
  VA: TVerticalAlignment;
begin
  if (FLockHotIndex)
     or (AValue = FHotIndex)
  then Exit;

  if FHotIndex >= 0
  then begin // restore pred selected item
    r := Items[FHotIndex].Rect;
    BitBlt(BmpMain.Canvas.Handle, r.Left, r.Top, r.Width, r.Height,
      CBmpSelectedItem.Canvas.Handle, 0, 0, SRCCOPY);
  end;
  FHotIndex := AValue;
  if FHotIndex >= 0 then
  begin // store current item
    r := Items[FHotIndex].Rect;
    BitBlt(CBmpSelectedItem.Canvas.Handle, 0, 0, r.Width, r.Height,
      BmpMain.Canvas.Handle, r.Left, r.Top, SRCCOPY);
  end;

  DrawItem(BmpMain, FHotIndex, True, False); // draw current selected item

  UpdateWindow(Handle, BoundsRect, ScreenAlign, BmpMain);

  // show hint
  if FHintShow and (FHotIndex >= 0)
  then begin
    case ScreenAlign of
      saLeft:
        begin
          Pt.X := Items[FHotIndex].Rect.Right + TOOLTIP_OFFSET;
          Pt.Y := Items[FHotIndex].Rect.CenterPoint.Y;
          VA := taVerticalCenter;
          HA := taLeftJustify;
        end;
      saTop:
        begin
          Pt.X := Items[FHotIndex].Rect.CenterPoint.X;
          Pt.Y := Items[FHotIndex].Rect.Bottom + TOOLTIP_OFFSET;
          VA := taAlignBottom;
          HA := taCenter;        
        end;
      saRight:
        begin
          Pt.X := Items[FHotIndex].Rect.Left - TOOLTIP_OFFSET;
          Pt.Y := Items[FHotIndex].Rect.CenterPoint.Y;
          VA := taVerticalCenter;
          HA := taRightJustify;
        end;
      saBottom:
        begin
          Pt.X := Items[FHotIndex].Rect.CenterPoint.X;
          Pt.Y := Items[FHotIndex].Rect.Top - TOOLTIP_OFFSET;
          VA := taAlignTop;
          HA := taCenter;          
        end
      else begin
        HA := taLeftJustify;
        VA := taAlignBottom;
      end;
    end;
    MapWindowPoints(Handle, HWND_DESKTOP, Pt, 1);
    oHint.Activate(Pt, Items[FHotIndex].Caption, HA, VA);
  end
  else begin
    oHint.Cancel;
  end;
end;

procedure TLinkbarWcl.SetScreenAlign(AValue: TScreenAlign);
begin
  FScreenEdge := AValue;
  FDragScreenEdge := FScreenEdge;
  oAppBar.MonitorNum := FMonitorNum;
  oAppBar.Side := AValue;
end;

procedure TLinkbarWcl.SetSortAlphabetically(AValue: Boolean);
begin
  FSortAlphabetically := AValue;
  if FSortAlphabetically
  then begin
    Items.Sort;
    oAppBar.AppBarPosChanged;
  end;
end;

procedure TLinkbarWcl.QuerySizingEvent(Sender: TObject; AVertical: Boolean;
  var AWidth, AHeight: Integer);
begin
  if AVertical
  then IconsInLine := (AHeight - FGripSize) div ButtonSize.Height
  else IconsInLine := (AWidth - FGripSize) div ButtonSize.Width;
  if (IconsInLine = 0) then IconsInLine := 1;

  IconLinesCount := Ceil(Items.Count/IconsInLine);
  if (IconLinesCount = 0) then IconLinesCount := 1;

  if AVertical
  then AWidth := ButtonSize.Width * IconLinesCount
  else AHeight := ButtonSize.Height * IconLinesCount
end;

procedure TLinkbarWcl.QuerySizedEvent(Sender: TObject; const AX, AY, AWidth,
  AHeight: Integer);
var r: TRect;
begin
  FBeforeAutoHideBound := Bounds(AX, AY, AWidth, AHeight);
  RecreateMainBitmap(AWidth, AHeight);

  if AutoHide and FAutoHiden
  then r := FAfterAutoHideBound
  else r := FBeforeAutoHideBound;

  MoveWindow(Handle, r.Left, r.Top, r.Width, r.Height, False);
  UpdateWindow(Handle, r, ScreenAlign, BmpMain);
end;

procedure TLinkbarWcl.QueryHideEvent(Sender: TObject; AEnabled: boolean);
begin
  FAutoHide := AEnabled;
end;

procedure TLinkbarWcl.UpdateWindowSize;
var iT, iL, iW, iH: Integer;
begin
  iT := Top;
  iL := Left;
  iW := Width;
  iH := Height;

  if IsVertical(ScreenAlign) then
  begin
    IconsInLine := (iH - FGripSize) div ButtonSize.Height;
    IconLinesCount := Ceil(Items.Count/IconsInLine);
    if IconLinesCount = 0 then IconLinesCount := 1;
    iW := ButtonSize.Width * IconLinesCount;
    if ScreenAlign = saRight then
      iL := Left + Width - iW;
  end else
  begin
    IconsInLine := (iW - FGripSize) div ButtonSize.Width;
    IconLinesCount := Ceil(Items.Count/IconsInLine);
    if IconLinesCount = 0 then IconLinesCount := 1;
    iH := ButtonSize.Height * IconLinesCount;
    if ScreenAlign = saBottom then
      iT := Top + Height - iH;
  end;

  RecreateMainBitmap(iW, iH);
  MoveWindow(Self.Handle, iL, iT, iW, iH, FALSE);
  UpdateWindow(Handle, Bounds(iL, iT, iW, iH), ScreenAlign, BmpMain);
end;

// Important  Do not use the LOWORD or HIWORD macros to extract the x- and y-
// coordinates of the cursor position because these macros return incorrect results
// on systems with multiple monitors. Systems with multiple monitors can have
// negative x- and y- coordinates, and LOWORD and HIWORD treat the coordinates
// as unsigned quantities.

// Macros from windowsx.h

function GET_X_LPARAM(const uLParam: LPARAM): Integer;
begin
  Result := Integer(uLParam and $FFFF);
end;

function GET_Y_LPARAM(const uLParam: LPARAM): integer;
begin
  Result := Integer((uLParam shr 16) and $FFFF);
end;

procedure TLinkbarWcl.WndProc(var Msg: TMessage);
var i: Integer;
begin
  case Msg.Msg of
    CUSTOM_ABN_FULLSCREENAPP:
      begin
        oAppBar.AppBarFullScreenApp(Msg.LParam <> 0);
      end;
    // DWM Messaages
    WM_THEMECHANGED:
      begin
        Msg.Result := 0;
        ThemeInitData(Handle, IsLightStyle);
        UpdateItemSizes;
      end;
    WM_DWMCOLORIZATIONCOLORCHANGED, WM_SYSCOLORCHANGE:
      begin
        Msg.Result := 0;
        // In Windows 8+ theme color may changed smoothly
        i := HotIndex;
        FHotIndex := ITEM_NONE;
        RecreateMainBitmap(BmpMain.Width, BmpMain.Height);
        RecreateButtonBitmap(ButtonSize.Width, ButtonSize.Height);
        if i = ITEM_NONE
        then UpdateWindow(Handle, BoundsRect, ScreenAlign, BmpMain)
        else HotIndex := i;
      end;
    WM_DWMCOMPOSITIONCHANGED:
      // NOTE: As of Windows 8, DWM composition is always enabled, so this message is
      // not sent regardless of video mode changes.
      begin
        Msg.Result := 0;
        ThemeInitData(Handle, IsLightStyle);
        UpdateItemSizes;
        UpdateBlur;
      end;
    { TODO: Provide this message for Windows Vista
    WM_DWMWINDOWMAXIMIZE: {}
    WM_SIZE:
      begin
        Msg.Result := 0;
        UpdateBlur;
      end;
    WM_SETFOCUS:
      begin
        Msg.Result := 0;
        FCanAutoHide := False;
      end;
    WM_KILLFOCUS:
      begin
        Msg.Result := 0;
        FCanAutoHide := not Assigned(FrmProperties);
        DoAutoHide;
      end;
    { Display stste changed (count/size/rotate) }
    WM_DISPLAYCHANGE:
    begin
      Msg.Result := 0;
      // force update Screen
      FMonitorNum := Self.Monitor.MonitorNum; // or Screen.MonitorFromWindow(0, mdNull);
      oAppBar.MonitorNum := FMonitorNum;
      oAppBar.AppBarPosChanged;
    end;
    { Messages from ShellContextMenu }
    SCMI_SH_RENAME:
      begin
        DoRenameItem(FItemPopup);
        Exit;
      end;
    SCMI_LB_ITEMS:
      begin
        DoPopupMenuItemExecute(Msg.LParam);
        Exit;
      end;
    SCMI_LB_INVOKE:
      begin
        JumpListClose;
        Exit;
      end;
    { WatchDir stop }
    WM_STOPDIRWATCH:
      begin
        StopDirWatch;
        Exit;
      end;
    { Bit Bucket image changed }
    WM_LB_SHELLNOTIFY:
    begin
      UpdateBitBuckets;
      Exit;
    end;
    { Delayed auto show (timer) }
    WM_TIMER:
    begin
      if (Msg.WParam = TIMER_AUTO_SHOW)
      then begin
        KillTimer(Handle, TIMER_AUTO_SHOW);
        _DoAutoShow;
        Exit;
      end;
    end
  else
    inherited WndProc(Msg);
  end;
end;

procedure TLinkbarWcl.UpdateBitBuckets;
begin
  Items.BitBucketUpdateIcon;
  if FAutoHiden
  then RecreateMainBitmap(FBeforeAutoHideBound.Width, FBeforeAutoHideBound.Height)
  else begin
    RecreateMainBitmap(Width, Height);
    UpdateWindow(Handle, BoundsRect, ScreenAlign, BmpMain);
  end;
end;

procedure TLinkbarWcl.DoPopupMenuItemExecute(const ACmd: Integer);
var mi: TMenuItem;
begin
  mi := pMenu.FindItem(ACmd, fkCommand);
  if Assigned(mi)
  then mi.Click;
end;

procedure TLinkbarWcl.PropertiesFormDestroyed;
begin
  DoAutoHide;
end;

procedure TLinkbarWcl.imPropertiesClick(Sender: TObject);
begin
  if Assigned(FrmProperties)
  then FrmProperties.BringToFront
  else
  begin
    FrmProperties := TFrmProperties.Create(Self);
    FrmProperties.Caption := APP_NAME_LINKBAR + ' - ' + PanelName;
    FrmProperties.Show;
  end;
end;

function EnumWindowProcStopDirWatch(wnd: HWND; lParam: LPARAM): BOOL; stdcall;
var buf: array[0..MAX_PATH] of Char;
begin
  Result := True;
  if ( GetClassName(wnd, buf, Length(buf)) > 0 )
     and (buf = TLinkbarWcl.ClassName)
  then PostMessage(wnd, WM_STOPDIRWATCH, 0, 0);
end;

function EnumWindowProcClose(wnd: HWND; lParam: LPARAM): BOOL; stdcall;
var buf: array[0..MAX_PATH] of Char;
begin
  Result := True;
  if ( GetClassName(wnd, buf, Length(buf)) > 0 )
     and (buf = TLinkbarWcl.ClassName)
  then PostMessage(wnd, WM_CLOSE, 0, 0);
end;

procedure TLinkbarWcl.imCloseAllClick(Sender: TObject);
begin
  EnumWindows(@EnumWindowProcStopDirWatch, 0);
  EnumWindows(@EnumWindowProcClose, 0);
end;

procedure TLinkbarWcl.imCloseClick(Sender: TObject);
begin
  StopDirWatch;
  Close;
end;

procedure TLinkbarWcl.imLockBarClick(Sender: TObject);
begin
  FLockLinkbar := not FLockLinkbar;
end;

procedure TLinkbarWcl.imAddBarClick(Sender: TObject);
begin
  LBCreateProcess( ParamStr(0), LBCreateCommandParam(CLK_NEW, '')
    + LBCreateCommandParam(CLK_LANG, IntToStr(LbLangID)) );
end;

procedure TLinkbarWcl.imNewShortcutClick(Sender: TObject);
begin
  NewShortcut(WorkDir);
end;

procedure TLinkbarWcl.imOpenWorkdirClick(Sender: TObject);
begin
  OpenDirectoryByName(WorkDir);
end;

procedure TLinkbarWcl.imRemoveBarClick(Sender: TObject);
var td: TTaskDialog;
begin
  td := TTaskDialog.Create(Self);
  FLockAutoHide := True;
  try
    td.Caption := ' ' + APP_NAME_LINKBAR;
    td.MainIcon := tdiNone;
    td.Title := Format(RS_REMDLG_TITLE, [PanelName]);
    td.Text := Format(RS_REMDLG_TEXT, [WorkDir]);
    td.VerificationText := RS_REMDLG_VERIFICATIONTEXT + Format('%*s', [24, ' ']);
    td.CommonButtons := [tcbOk, tcbCancel];
    td.DefaultButton := tcbCancel;

    if (td.Execute)
       and (td.ModalResult = mrOk)
    then begin
      FRemoved := True;
      DeleteFile(FPreferencesFileName);
      if (tfVerificationFlagChecked in td.Flags)
      then begin
        StopDirWatch;
        SHDeleteOp(Handle, WorkDir, True);
      end;
      PostQuitMessage(0);
    end;
  finally
    FLockAutoHide := False;
    td.Free;
  end;
end;

procedure TLinkbarWcl.imSortAlphabeticallyClick(Sender: TObject);
begin
  SortAlphabetically := not SortAlphabetically;
end;

////////////////////////////////////////////////////////////////////////////////
// Autohide
////////////////////////////////////////////////////////////////////////////////

function TLinkbarWcl.ScaleDimension(const X: Integer): Integer;
begin
  Result := MulDiv(X, Self.PixelsPerInch, 96);
end;

function MakePoint(const Param : DWord): TPoint; inline;
Begin
  Result := TPoint.Create(Param and $FFFF, Param shr 16);
End;

procedure TLinkbarWcl.DoAutoHide;
var r: TRect;
begin
  if (not AutoHide)
     or FLockAutoHide
     or ( WindowFromPoint(MakePoint(GetMessagePos)) = Handle )
  then Exit;

  if FCanAutoHide and not FAutoHiden
  then begin

    FAutoHiden := True;
    r := FBeforeAutoHideBound;
    case ScreenAlign of
      saTop: r.Bottom := r.Top + ScaleDimension(AUTOHIDE_SIZE);
      saLeft: r.Right := r.Left + ScaleDimension(AUTOHIDE_SIZE);
      saRight: r.Left := r.Right - ScaleDimension(AUTOHIDE_SIZE);
      saBottom: r.Top := r.Bottom - ScaleDimension(AUTOHIDE_SIZE);
    end;
    FAfterAutoHideBound := r;
    MoveWindow(Handle, r.Left, r.Top, r.Width, r.Height, False);
    UpdateWindow(Handle, FAfterAutoHideBound, ScreenAlign, BmpMain);
    Self.OnContextPopup := nil;
  end;
end;

procedure TLinkbarWcl._DoAutoShow;
begin
  if (not AutoHide)
  then Exit;

  if ( WindowFromPoint(MakePoint(GetMessagePos)) <> Handle )
  then Exit;

  if FAutoHiden
  then begin
    FAutoHiden := False;
    MoveWindow(Handle, FBeforeAutoHideBound.Left, FBeforeAutoHideBound.Top,
      FBeforeAutoHideBound.Width, FBeforeAutoHideBound.Height, False);
    UpdateWindow(Handle, FBeforeAutoHideBound, ScreenAlign, BmpMain);
    Self.OnContextPopup :=  FormContextPopup;
  end;
end;

procedure TLinkbarWcl._DoDelayedAutoShow;
begin
  if (not AutoHide)
  then Exit;

  if (FAutoShowDelay = 0)
  then _DoAutoShow
  else SetTimer(Handle, TIMER_AUTO_SHOW, FAutoShowDelay, nil);
end;

procedure TLinkbarWcl.FormMouseEnter(Sender: TObject);
begin
  if AutoHide
     and FAutoHiden
     and (FAutoShowMode = smMouseHover)
  then _DoDelayedAutoShow;
end;

procedure TLinkbarWcl.FormMouseLeave(Sender: TObject);
begin
  HotIndex := -1;
  if (FAutoShowMode = smMouseHover) or FCanAutoHide
  then DoAutoHide;
end;

////////////////////////////////////////////////////////////////////////////////
// Drag&Drop
////////////////////////////////////////////////////////////////////////////////

var _FLastDropRect: TRect;
    _FPart: Integer;

procedure TLinkbarWcl.SetDropPosition(AValue: TPoint);

  function GetItemDropRect(const AIndex, APart: Integer): TRect;
  var r: TRect;
  begin
    r := Items[AIndex].Rect;

    case APart of
      -1: begin
        if IsVertical(ScreenAlign)
        then begin
          r.Top := r.Top - DROP_INDICATOR_SIZE div 2;
          r.Left := r.Left + r.Width div DROP_INDICATOR_PADDING_DIV;
          r.Right := r.Right - r.Width div DROP_INDICATOR_PADDING_DIV;
          r.Height := DROP_INDICATOR_SIZE;
        end
        else begin
          r.Left := r.Left - DROP_INDICATOR_SIZE div 2;
          r.Top := r.Top + r.Height div DROP_INDICATOR_PADDING_DIV;
          r.Bottom := r.Bottom - r.Height div DROP_INDICATOR_PADDING_DIV;
          r.Width := DROP_INDICATOR_SIZE;
        end;
      end;
      1: begin
        if IsVertical(ScreenAlign)
        then begin
          r.Top := r.Bottom - DROP_INDICATOR_SIZE div 2;
          r.Left := r.Left + r.Width div DROP_INDICATOR_PADDING_DIV;
          r.Right := r.Right - r.Width div DROP_INDICATOR_PADDING_DIV;
          r.Height := DROP_INDICATOR_SIZE;
        end
        else begin
          r.Left := r.Right - DROP_INDICATOR_SIZE div 2;
          r.Top := r.Top + r.Height div DROP_INDICATOR_PADDING_DIV;
          r.Bottom := r.Bottom - r.Height div DROP_INDICATOR_PADDING_DIV;
          r.Width := DROP_INDICATOR_SIZE;
        end;
      end;
    end;

    Result := r;
  end;

var
  r: TRect;
  index: Integer;
  gpDrawer: IGPGraphics;
  gpBrush: IGPSolidBrush;
  part, pd: Integer;
begin
  index := ItemIndexByPoint( Point(AValue.X, AValue.Y) );

  if (index = ITEM_NONE) or FDragingItem
  then part := -1
  else begin
    r := Items[index].Rect;
    if IsVertical(ScreenAlign)
    then begin
      pd := ButtonSize.cy div 6;
      if ( AValue.Y < (r.Top+pd) )
      then part := -1
        else if ( AValue.Y > (r.Bottom-pd) )
        then part := 1
          else part := 0;
    end
    else begin
      pd := ButtonSize.cx div 6;
      if ( AValue.X < (r.Left+pd) )
      then part := -1
        else if ( AValue.X > (r.Right-pd) )
        then part := 1
          else part := 0;
    end;
    if (part = 1) and (index <> FDragIndex)
    then begin index := index + 1; part := -1; end;
    if index > (Items.Count-1)
    then index := ITEM_NONE;
  end;

  if FDragingItem or (index = ITEM_NONE) or (part <> 0)
  then FPidl := WorkDirPidl
  else FPidl := Items[index].Pidl;

  if (index = FItemDropPosition) and (part = _FPart) then Exit;
  _FPart := part;

  if (FItemDropPosition <> ITEM_NONE) then
  begin
    r := _FLastDropRect;
    BitBlt(BmpMain.Canvas.Handle, r.Left, r.Top, r.Width, r.Height,
      CBmpDropPosition.Canvas.Handle, 0, 0, SRCCOPY);
  end;

  FItemDropPosition := index;

  if (FItemDropPosition <> ITEM_NONE) then
  begin
    r := GetItemDropRect(FItemDropPosition, part);
    _FLastDropRect := r;

    BitBlt(CBmpDropPosition.Canvas.Handle, 0, 0, r.Width, r.Height,
      BmpMain.Canvas.Handle, r.Left, r.Top, SRCCOPY);

    if (part = 0)
    then begin
      DrawBackground(BmpMain, r);
      ThemeDrawHover(BmpMain, ScreenAlign, r);
      DrawItem(BmpMain, FItemDropPosition, False, False, False);
    end
    else begin
      gpDrawer := BmpMain.ToGPGraphics;
      gpBrush := TGPSolidBrush.Create(TGPColor.Create($ff000000));
      gpDrawer.FillRectangle(gpBrush, TGPRect.Create(r));
      gpBrush.Color := TGPColor.Create($ffffffff);
      r.Inflate(-1,-1,-1,-1);
      gpDrawer.FillRectangle(gpBrush, TGPRect.Create(r));
    end;
  end;

  UpdateWindow(Handle, BoundsRect, ScreenAlign, BmpMain);
end;

procedure TLinkbarWcl.DoDragEnter(const pt: TPoint);
begin
  if AutoHide
     and FAutoHiden
  then begin
    FCanAutoHide := False;
    _DoAutoShow;
  end;
end;

procedure TLinkbarWcl.DoDragOver(const pt: TPoint; var ppidl: PItemIDList);
begin
  if AutoHide
     and FAutoHiden
  then Exit;
  SetDropPosition(pt);
  ppidl := FPidl;
end;

procedure TLinkbarWcl.DoDragLeave;
begin
  SetDropPosition( Point(-1, -1) );
  if AutoHide and not Active
  then begin
    FCanAutoHide := True;
    DoAutoHide;
  end;
end;

procedure TLinkbarWcl.DoDrop(const pt: TPoint);
begin
  if AutoHide and not Active
  then begin
    FCanAutoHide := True;
  end;

  if FDragingItem
  then begin
    FSortAlphabetically := False;
    if FItemDropPosition = ITEM_NONE
    then Items.Move(FDragIndex, Items.Count-1)
    else Items.Move(FDragIndex, FItemDropPosition);
    SetDropPosition( Point(-1, -1) );
    UpdateWindowSize;
  end
  else tmrUpdate.Enabled := True;
end;

procedure TLinkbarWcl.QueryDragImage(out ABitmap: TBitmap; out AOffset: TPoint);
begin
  ABitmap := TBitmap.Create;
  ABitmap.PixelFormat := pf32bit;
  ABitmap.Canvas.Brush.Style := bsClear;
  ABitmap.SetSize(ButtonSize.cx, ButtonSize.cy);

  DrawItem(ABitmap, FDragIndex, False, True, False, True);

  AOffset := Point(FMousePosDown.X - Items[FDragIndex].Rect.Left,
    FMousePosDown.Y - Items[FDragIndex].Rect.Top);
end;

var
  _LastModifiedItemHash: Cardinal = 0;
  _RenamedOldItemHash: Cardinal = 0;

procedure TLinkbarWcl.DirWatchChange(const Sender: TObject;
  const AAction: TWatchAction; const AFileName: string);

  function FindItemByHash(const AHash: Cardinal): Integer;
  var i: Integer;
  begin
    for i := 0 to Items.Count-1 do
      if Items[i].Hash = AHash
      then Exit(i);
    Result := ITEM_NONE;
  end;

var ext: string;
    hash: Cardinal;
    i: integer;
    item: TLbItem;
begin
  inherited;
  // Skip unsupported files
  ext := ExtractFileExt(AFileName);
  if not MatchText(ext, ES_ARRAY) then Exit;

  tmrUpdate.Enabled := False;

  case AAction of
  waAdded:
  begin
    item := TLbItem.Create;
    item.Hash := StrToHash(AFileName);
    item.FileName := WorkDir + AFileName;
    item.NeedLoad := True;
    if (FItemDropPosition = ITEM_NONE)
    then Items.Add(item)
    else Items.Insert(FItemDropPosition, item);
  end;
  waRemoved:
  begin
    i := FindItemByHash(StrToHash(AFileName));
    if (i <> ITEM_NONE)
    then Items.Delete(i);
  end;
  waModified:
  begin
    hash := StrToHash(AFileName);
    if (_LastModifiedItemHash <> hash)
    then begin
      _LastModifiedItemHash := hash;
      i := FindItemByHash(hash);
      if (i <> ITEM_NONE)
      then Items[i].NeedLoad := True;
    end;
  end;
  waRenamedOld:
  begin
    _RenamedOldItemHash := StrToHash(AFileName);
  end;
  waRenamedNew:
  begin
    i := FindItemByHash(_RenamedOldItemHash);
    if (i <> ITEM_NONE)
    then begin
      item := Items[i];
      item.FileName := WorkDir + AFileName;
      item.NeedLoad := True;
      _RenamedOldItemHash := 0;
    end;
  end;
  end;

  tmrUpdate.Enabled := True;
end;

procedure TLinkbarWcl.tmrUpdateTimer(Sender: TObject);
var i: Integer;
    item: TLbItem;
begin
  tmrUpdate.Enabled := False;

  i := 0;
  while (i < Items.Count) do
  begin
    item := Items[i];
    if item.NeedLoad
    then begin
      if item.LoadFromFile(item.FileName)
      then begin
        Items.LoadIcon(item);
        Inc(i);
      end
      else Items.Delete(i);
    end
    else Inc(i);
  end;

  if FSortAlphabetically
  then Items.Sort;

  _LastModifiedItemHash := 0;
  _RenamedOldItemHash := 0;

  SetDropPosition( Point(-1, -1) );
  oAppBar.AppBarPosChanged;
end;

procedure TLinkbarWcl.DirWatchError(const Sender: TObject;
  const ErrorCode: Integer; const ErrorMessage: string);
begin
  if (ErrorCode > 0)
  then begin
    StopDirWatch;
    Sleep(100);
    if not DirectoryExists(WorkDir)
    then begin
      FRemoved := True;
      DeleteFile(FPreferencesFileName);
      Close;
    end;
  end;
end;

procedure TLinkbarWcl.SetEnableAeroGlass(AValue: Boolean);
begin
  if not IsWindows8And8Dot1
  then Exit;

  if (AValue = FEnableAeroGlass)
  then Exit;
  FEnableAeroGlass := AValue;
  ExpAeroGlassEnabled := FEnableAeroGlass;
  ThemeSetWindowAttribute(Handle);
  UpdateBlur;
end;

end.
