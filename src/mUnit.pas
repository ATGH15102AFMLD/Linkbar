{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{            Copyright (c) 2010-2018 Asaq               }
{*******************************************************}

unit mUnit;

{$i linkbar.inc}

interface

uses
  GdiPlus,
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  System.UITypes, Menus, Vcl.ExtCtrls, Winapi.ShlObj,
  DDForms, Cromis.DirectoryWatch,
  AccessBar, LBToolbar, Linkbar.Consts, Linkbar.Hint, Linkbar.Taskbar, HotKey,
  Linkbar.Graphics;

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
    imSortAlphabet: TMenuItem;
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
    procedure imSortAlphabetClick(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormResize(Sender: TObject);
  private
    CBmpSelectedItem: THBitmap;
    CBmpDropPosition: THBitmap;
    BmpBtn: THBitmap;
    BmpMain: THBitmap;
    Items: TLBItemList;
    oAppBar : TAccessBar;
    oHint: TTooltip32;
    FCreated: Boolean;
    FHotIndex: Integer;
    FPressedIndex: Integer;
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
    FEnableAeroGlass: Boolean;
    FGripSize: Integer;
    FHintShow: Boolean;
    FHotkeyInfo: THotkeyInfo;
    FItemMargin: TSize;
    FIconSize: Integer;
    FIsLightStyle: Boolean;
    FItemOrder: TItemOrder;
    FJumplistShowMode: TJumplistShowMode;
    FJumplistRecentMax: Integer;
    FLookMode: TLookMode;
    FLockLinkbar: Boolean;
    FLockHotIndex: Boolean;
    FCorner1GapWidth, FCorner2GapWidth: Integer;
    FSortAlphabetically: Boolean;
    FStayOnTop: Boolean;
    FBackgroundColor: Cardinal;
    FSysBackgroundColor: Cardinal;
    FTextColor: Cardinal;
    FUseBkgndColor: Boolean;
    FUseTextColor: Boolean;
    FGlowSize: Integer;
    FScreenEdge: TScreenAlign;
    FTextWidth: Integer;
    FTextOffset: Integer;
    FTextLayout: TTextLayout;
    FIconOffset: TPoint;
    FTextRect: TRect;
    IconsInLine, IconLinesCount: integer;
    FPrevForegroundWnd: HWND;
    procedure UpdateWindowSize;
    procedure SetScreenAlign(AValue: TScreenAlign);
    procedure SetAutoHide(AValue: Boolean);
    procedure SetEnableAeroGlass(AValue: Boolean);
    procedure SetItemOrder(AValue: TItemOrder);
    procedure SetPressedIndex(AValue: integer);
    procedure SetHotIndex(AValue: integer);
    procedure SetHotkeyInfo(AValue: THotkeyInfo);
    procedure SetButtonSize(AValue: TSize);
    procedure SetIconSize(AValue: integer);
    procedure SetIsLightStyle(AValue: Boolean);
    procedure SetItemMargin(AValue: TSize);
    procedure SetTextLayout(AValue: TTextLayout);
    procedure SetTextOffset(AValue: Integer);
    procedure SetTextWidth(AValue: Integer);
    procedure SetSortAlphabetically(AValue: Boolean);
    procedure SetStayOnTop(AValue: Boolean);
    procedure SetLookMode(AValue: TLookMode);
    procedure SetUseBkgndColor(AValue: Boolean);
    function GetScreenAlign: TScreenAlign;
    procedure DrawBackground(const ABitmap: THBitmap; const AClipRect: TRect);
    procedure DrawCaption(const ABitmap: THBitmap; const AIndex: Integer;
      const ADrawForDrag: Boolean = False);
    procedure DrawItem(ABitmap: THBitmap; AIndex: integer; ASelected,
      APressed: Boolean; ADrawBg: Boolean = True; ADrawForDrag: Boolean = False);
    procedure DrawItems;
    procedure RecreateMainBitmap(const AWidth, AHeight: integer);
    procedure RecreateButtonBitmap(const AWidth, AHeight: integer);
    procedure UpdateWindow(const AWnd: HWND; const ABounds: TRect;
      const AScreenEdge: TScreenAlign; const ABitmap: THBitmap);
    procedure UpdateBlur;
    procedure UpdateBackgroundColor;
    function GetBackgroundColor: Cardinal;
    function ItemIndexByPoint(const APt: TPoint;
      const ALastIndex: integer = ITEM_NONE): Integer;
    function CheckItem(AIndex: Integer): Boolean;
    procedure DeleteItem(const AIndex: Integer);
    function ScaleDimension(const X: Integer): Integer; inline;
  private
    procedure L10n;
    procedure LoadSettings;
    procedure SaveLinks;
  private
    BitBucketNotify: Cardinal;
    procedure UpdateBitBuckets;
  private
    FRemoved: boolean;
    FDragScreenEdge: TScreenAlign;
    FMonitorNum: Integer;
    FDragMonitorNum: Integer;
    FItemPopup: Integer;
    FDragIndex: Integer;
    MonitorsWorkareaWoTaskbar: TDynRectArray;
    procedure DoExecuteItem(const AIndex: Integer);
    procedure DoClickItem(X, Y: Integer);
    procedure DoRenameItem(AIndex: Integer);
    procedure DoPopupMenuItemExecute(const ACmd: Integer);
    procedure DoDragLinkbar(X, Y: Integer);
    procedure DoPopupMenu(APt: TPoint; AShift: Boolean);
    procedure DoPopupJumplist(APt: TPoint; AShift: Boolean);
    procedure DoDragItem(X, Y: Integer);
    procedure GetOrCreateFilesList(filename: string);
    procedure QuerySizingEvent(Sender: TObject; AVertical: Boolean;
      var AWidth, AHeight: Integer);
    procedure QuerySizedEvent(Sender: TObject; const AX, AY, AWidth, AHeight: Integer);
    procedure QueryHideEvent(Sender: TObject; AEnabled: boolean);
    function IsItemIndex(const AIndex: Integer): Boolean;
    procedure CreateBitmaps;
  protected
    // Drag&Drop functions
    FItemDropPosition: Integer;
    FPidl: PItemIDList;
    procedure SetDropPosition(AValue: TPoint);
    procedure DoDragEnter(const pt: TPoint); override;
    procedure DoDragOver(const pt: TPoint; var ppidl: PItemIDList); override;
    procedure DoDragLeave; override;
    procedure DoDrop(const pt: TPoint); override;
    procedure QueryDragImage(out ABitmap: THBitmap; out AOffset: TPoint); override;
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
    procedure WmHotKey(var Msg: TMessage); message WM_HOTKEY;
    procedure CMDialogKey(var Msg: TCMDialogKey); message CM_DIALOGKEY;
  protected
    FAutoHiden: Boolean;
    FCanAutoHide: Boolean;
    FLockAutoHide: Boolean;
    FBeforeAutoHideBound: TRect;
    FAfterAutoHideBound: TRect;
    FAutoShowDelay: Integer;
    procedure DoAutoHide;
    procedure DoAutoShow;
    procedure DoDelayedAutoShow;
    procedure DoDelayedAutoHide(const ADelay: Cardinal);
    procedure OnFormJumplistDestroy(Sender: TObject);
  public
    procedure SaveSettings;
    procedure UpdateItemSizes;
    property AutoHide: Boolean read FAutoHide write SetAutoHide;
    property AutoHideTransparency: Boolean read FAutoHideTransparency write FAutoHideTransparency;
    property AutoShowDelay: Integer read FAutoShowDelay write FAutoShowDelay;
    property AutoShowMode: TAutoShowMode read FAutoShowMode write FAutoShowMode;
    property BackgroundColor: Cardinal read GetBackgroundColor write FBackgroundColor;
    property ButtonSize: TSize read FButtonSize write SetButtonSize;
    property EnableAeroGlass: Boolean read FEnableAeroGlass write SetEnableAeroGlass;
    property GlowSize: Integer read FGlowSize write FGlowSize;
    property HintShow: Boolean read FHintShow write FHintShow;
    property HotIndex: Integer read FHotIndex write SetHotIndex;
    property HotkeyInfo: THotkeyInfo read FHotkeyInfo write SetHotkeyInfo;
    property IconSize: Integer read FIconSize write SetIconSize;
    property IsLightStyle: Boolean read FIsLightStyle write SetIsLightStyle;
    property ItemMargin: TSize read FItemMargin write SetItemMargin;
    property ItemOrder: TItemOrder read FItemOrder write SetItemOrder;
    property JumplistShowMode: TJumplistShowMode read FJumplistShowMode write FJumplistShowMode;
    property JumplistRecentMax: Integer read FJumplistRecentMax write FJumplistRecentMax;
    property LookMode: TLookMode read FLookMode write SetLookMode;
    property PressedIndex: Integer read FPressedIndex write SetPressedIndex;
    property ScreenAlign: TScreenAlign read GetScreenAlign  write SetScreenAlign;
    property SortAlphabetically: Boolean read FSortAlphabetically write SetSortAlphabetically;
    property StayOnTop: Boolean read FStayOnTop write SetStayOnTop default True;
    property TextLayout: TTextLayout read FTextLayout write SetTextLayout;
    property TextOffset: Integer read FTextOffset write SetTextOffset;
    property TextWidth: Integer read FTextWidth write SetTextWidth;
    property TextColor: Cardinal read FTextColor write FTextColor;
    property UseBkgndColor: Boolean read FUseBkgndColor write SetUseBkgndColor;
    property UseTextColor: Boolean read FUseTextColor write FUseTextColor;
    //
    property Corner1GapWidth: Integer read FCorner1GapWidth write FCorner1GapWidth;
    property Corner2GapWidth: Integer read FCorner2GapWidth write FCorner2GapWidth;
  end;

var
  LinkbarWcl: TLinkbarWcl;
  FSettingsFileName: string;

implementation

{$R *.dfm}

uses
  Types, Math, Dialogs, StrUtils, Themes,
  ExplorerMenu, Linkbar.Shell, Linkbar.Themes,
  Linkbar.OS, Linkbar.L10n, JumpLists.Form, RenameDialog,
  Linkbar.SettingsForm, Linkbar.Settings;

const
  bf: TBlendFunction = (BlendOp: AC_SRC_OVER; BlendFlags: 0;
      SourceConstantAlpha: $FF; AlphaFormat: AC_SRC_ALPHA);

  LM_SHELLNOTIFY = WM_USER + 88;
  TIMER_AUTO_SHOW = 15;
  TIMER_AUTO_HIDE = 16;

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
    if MessageDlg( L10NFind('Message.FileNotFound', 'File does not exists')
        + #13 + fn + #13 +
        L10NFind('Message.DeleteShortcut', 'Delete shortcut?'),
        mtConfirmation, [mbOK, mbCancel], 0, mbCancel) = mrOk
    then begin
      DeleteItem(AIndex);
      UpdateWindowSize;
    end;
  end;
end;

procedure TLinkbarWcl.DeleteItem(const AIndex: Integer);
begin
  Items.Delete(AIndex);
  // Clear FHotIndex/FPressedIndex if Hot/Pressed item deleted
  if (FHotIndex = AIndex)
  then FHotIndex := ITEM_NONE;
  if (FPressedIndex = AIndex)
  then FPressedIndex := ITEM_NONE;
end;

procedure TLinkbarWcl.DrawBackground(const ABitmap: THBitmap;
  const AClipRect: TRect);
var params: TDrawBackgroundParams;
begin
  params.Bitmap := ABitmap;
  params.Align := ScreenAlign;
  params.ClipRect := AClipRect;
  params.IsLight := IsLightStyle;
  params.BgColor := BackgroundColor;
  ThemeDrawBackground(@params);
end;

function CreateHBitmap(const ADc: HDC; const AWidth, AHeight: Integer; const ABbp: Word): HBITMAP;
var bi: TBitmapInfo;
    bits: Pointer;
begin
  FillChar(bi, SizeOf(bi), 0);
  bi.bmiHeader.biSize := sizeof(BITMAPINFOHEADER);
  bi.bmiHeader.biWidth := AWidth;
  bi.bmiHeader.biHeight := AHeight;
  bi.bmiHeader.biPlanes := 1;
  bi.bmiHeader.biBitCount := ABbp;
  Result := CreateDIBSection(ADc, bi, DIB_RGB_COLORS, bits, 0, 0);
end;

procedure TLinkbarWcl.DrawCaption(const ABitmap: THBitmap; const AIndex: Integer;
  const ADrawForDrag: Boolean = False);
var i: Integer;
    LTextRect: TRect;
    LTextFlags: Cardinal;
    LTextColor: TColor;
    item: TLbItem;
    dc, dc2: HDC;
    fnt0: HGDIOBJ;
    bmp: THBitmap;
begin
  if (TextLayout = tlNone) then Exit;

  LTextFlags := TEXTALIGN[TextLayout] or DT_END_ELLIPSIS or DT_SINGLELINE
    or DT_NOPREFIX or DT_NOCLIP;

  if (StyleServices.Enabled)
  then begin
    // Aero theme. Use DrawGlassText
    if (FUseTextColor)
    then begin
      LTextColor := FTextColor;
    end
    else begin
      if (AIndex = ITEM_ALL)
      then begin
        LTextColor := ThemeButtonNormalTextColor;
      end
      else begin
        if (AIndex = PressedIndex)
        then LTextColor := ThemeButtonPressedTextColor
        else if (AIndex = HotIndex)
             then LTextColor := ThemeButtonSelectedTextColor
             else LTextColor := ThemeButtonNormalTextColor;
      end;
    end;

    dc := ABitmap.Dc;

    if (AIndex = ITEM_ALL)
    then begin
      fnt0 := SelectObject(dc, Screen.IconFont.Handle);
      for i := 0 to Items.Count-1 do
      begin
        item := Items[i];
        LTextRect := FTextRect;
        LTextRect.Offset(item.Rect.Left, item.Rect.Top);
        DrawGlassText(dc, item.Caption, LTextRect, LTextFlags, FGlowSize, LTextColor);
      end;
      SelectObject(dc, fnt0);
    end
    else begin
      item := Items[AIndex];

      if ADrawForDrag
      then begin
        LTextRect := FTextRect;
        fnt0 := SelectObject(dc, Screen.IconFont.Handle);
        DrawGlassText(dc, item.Caption, LTextRect, LTextFlags, FGlowSize, LTextColor);
        SelectObject(dc, fnt0);
      end
      else begin
        // The shadow extends beyond the button, creating artifacts
        // Draw on separate bitmap with button size
        bmp := THBitmap.Create(32);
        bmp.SetSize(BmpBtn.Width, BmpBtn.Height);
        dc2 := bmp.Dc;

        LTextRect := FTextRect;
        if (AIndex = PressedIndex)
        then LTextRect.Offset(1,1);

        fnt0 := SelectObject(dc2, Screen.IconFont.Handle);
        DrawGlassText(dc2, item.Caption, LTextRect, LTextFlags, FGlowSize, LTextColor);
        SelectObject(dc2, fnt0);

        Windows.AlphaBlend(dc,
          item.Rect.Left, item.Rect.Top, bmp.Width, bmp.Height,
          dc2, 0, 0, bmp.Width, bmp.Height, bf);

        bmp.Free;
      end;
    end;
  end
  else begin
    // Classic theme
    // NOTE: DrawThemeText/DrawThemeTextEx not work in Classic theme

    Assert(not ADrawForDrag); // Classic Theme don't have Drag Image

    LTextColor := clBtnText;

    dc := ABitmap.Dc;
    fnt0 := SelectObject(dc, Screen.IconFont.Handle);
    SetTextColor(dc, ColorToRGB(LTextColor));
    SetBkColor(dc, ColorToRGB(clBtnFace));

    if (AIndex = ITEM_ALL)
    then begin
      for i := 0 to Items.Count-1 do
      begin
        item := Items[i];
        LTextRect := FTextRect;
        LTextRect.Offset(item.Rect.Left, item.Rect.Top);
        DrawText(dc, item.Caption, -1, LTextRect, LTextFlags);
      end;
      ABitmap.Opaque;
    end
    else begin
      item := Items[AIndex];
      LTextRect := FTextRect;
      LTextRect.Offset(item.Rect.Left, item.Rect.Top);
      if (AIndex = PressedIndex)
      then LTextRect.Offset(1,1);
      DrawText(dc, item.Caption, -1, LTextRect, LTextFlags);
      ABitmap.OpaqueRect(item.Rect);
    end;

    SelectObject(dc, fnt0);
  end;
end;

procedure TLinkbarWcl.DrawItem(ABitmap: THBitmap; AIndex: integer; ASelected,
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
         Windows.AlphaBlend(ABitmap.Dc, r.Left, r.Top, r.Width, r.Height,
           BmpBtn.Dc, 0, 0, r.Width, r.Height, bf);
       end;

  if APressed
  then d := 1
  else d := 0;

  // Draw text
  DrawCaption(ABitmap, AIndex, ADrawForDrag);

  // Draw icon
  Items.Draw(ABitmap.Dc, AIndex, r.Left + FIconOffset.X + d, r.Top + FIconOffset.Y + d);
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
    Items.Draw(BmpMain.Dc, i,
      Items[i].Rect.Left + FIconOffset.X, Items[i].Rect.Top + FIconOffset.Y);
  end;
end;

procedure TLinkbarWcl.RecreateMainBitmap(const AWidth, AHeight: integer);
begin
  BmpMain.SetSize(AWidth, AHeight);
  BmpMain.Clear;
  // Draw background
  DrawBackground(BmpMain, Rect(0, 0, AWidth, AHeight));
  // Draw items
  DrawItems;
end;

procedure TLinkbarWcl.RecreateButtonBitmap(const AWidth, AHeight: integer);
begin
  // Create clear bitmap
  BmpBtn.SetSize(AWidth, AHeight);
  BmpBtn.Clear;
  ThemeDrawButton(BmpBtn, BmpBtn.Bound, False);
  // Buffer for selections
  CBmpSelectedItem.SetSize(AWidth, AHeight);
  // Buffer for drop
  CBmpDropPosition.SetSize(AWidth, AHeight);
end;

procedure TLinkbarWcl.UpdateWindow(const AWnd: HWND; const ABounds: TRect;
  const AScreenEdge: TScreenAlign; const ABitmap: THBitmap);
var w, h, c1gw, c2gw, wh: Integer;
    Pt1, Pt2: TPoint;
    Sz: TSize;
    drawer: IGPGraphics;
    r: TGPRect;
    bmp: THBitmap;
    dc: HDC;
    p: Pointer;
begin
  w := ABounds.Width;
  h := ABounds.Height;

  // Draw
  if (FAutoHiden)
  then begin
    // Hidden

    // Check corner gaps width
    c1gw := FCorner1GapWidth;
    c2gw := FCorner2GapWidth;
    if (c1gw > 0) or (c2gw > 0)
    then begin
      if ScreenAlign in [saLeft, saRight]
      then wh := h
      else wh := w;
      if (c1gw > wh - c2gw)
      then begin
        c1gw := 0;
        c2gw := 0;
      end;
    end;

    if (FAutoHideTransparency)
    then begin
      // and Transparency
      Pt1 := ABounds.TopLeft;
      Sz := TSize.Create(w, h);
      Pt2 := Point(0,0);

      bmp := THBitmap.Create(32);
      bmp.SetSize(w, h);
      dc := bmp.Dc;

      drawer := TGPGraphics.FromHDC(dc);
      if (c1gw > 0) or (c2gw > 0)
      then begin
        if ScreenAlign in [saLeft, saRight]
        then r := TGPRect.Create(0, c1gw, w, h - c1gw - c2gw)
        else r := TGPRect.Create(c1gw, 0, w - c1gw - c2gw, h);
        drawer.SetClip(r);
      end;
      drawer.Clear($01000000);

      UpdateLayeredWindow(AWnd, 0, @Pt1, @Sz, dc, @Pt2, 0, @bf, ULW_ALPHA);
      bmp.Free;
    end
    else begin
      // and Opaque
      if (c1gw > 0) or (c2gw > 0)
      then begin
        // w/ gaps
        Pt1 := ABounds.TopLeft;
        Sz := TSize.Create(w, h);
        case AScreenEdge of
          saLeft:   Pt2 := Point(ABitmap.Width - w, 0);
          saTop:    Pt2 := Point(0, ABitmap.Height - h);
          saRight:  Pt2 := Point(0, 0);
          saBottom: Pt2 := Point(0, 0);
        end;

        bmp := THBitmap.Create(32);
        bmp.SetSize(w, h);
        dc := bmp.Dc;

        if ScreenAlign in [saLeft, saRight]
        then BitBlt(dc, 0, c1gw, w, h - c1gw - c2gw, ABitmap.Dc, Pt2.X, c1gw, SRCCOPY)
        else BitBlt(dc, c1gw, 0, w - c1gw - c2gw, h, ABitmap.Dc, c1gw, Pt2.Y, SRCCOPY);

        Pt2 := Point(0,0);
        UpdateLayeredWindow(AWnd, 0, @Pt1, @Sz, dc, @Pt2, 0, @bf, ULW_ALPHA);
        bmp.Free;
      end
      else begin
        // w/o gaps
        Pt1 := ABounds.TopLeft;
        Sz := TSize.Create(w, h);
        case AScreenEdge of
          saLeft:   Pt2 := Point(ABitmap.Width - w, 0);
          saTop:    Pt2 := Point(0, ABitmap.Height - h);
          saRight:  Pt2 := Point(0, 0);
          saBottom: Pt2 := Point(0, 0);
        end;
        UpdateLayeredWindow(AWnd, 0, @Pt1, @Sz, ABitmap.Dc, @Pt2, 0, @bf, ULW_ALPHA);
      end;
    end;
  end
  else begin
    // Not Hidden
    if (ABounds = BoundsRect)
    then p := nil
    else p := @ABounds.TopLeft;
    Sz := TSize.Create(w, h);
    case AScreenEdge of
      saLeft:   Pt2 := Point(ABitmap.Width - w, 0);
      saTop:    Pt2 := Point(0, ABitmap.Height - h);
      saRight:  Pt2 := Point(0, 0);
      saBottom: Pt2 := Point(0, 0);
    end;

    UpdateLayeredWindow(AWnd, 0, p, @Sz, ABitmap.Dc, @Pt2, 0, @bf, ULW_ALPHA);
  end;
end;

procedure TLinkbarWcl.UpdateBlur;
var blurEnabled: Boolean;
begin
  if IsWindows10
  then begin
    if (FAutoHiden and FAutoHideTransparency)
    then ThemeSetWindowAccentPolicy10(Handle, lmDisabled, 0)
    else ThemeSetWindowAccentPolicy10(Handle, FLookMode, BackgroundColor);
  end
  else begin
    blurEnabled := not (FAutoHiden and FAutoHideTransparency);
    if (IsWindows8And8Dot1 and not FEnableAeroGlass)
    then blurEnabled := False;
    ThemeUpdateBlur(Handle, blurEnabled);
  end;
end;

{ Load settings from file }
procedure TLinkbarWcl.LoadSettings;
var settings: TSettings;
    hki: THotkeyInfo;
begin
  settings.Open(FSettingsFileName);
  // Read
  WorkDir               := settings.Read(INI_DIR_LINKS, DEF_DIR_LINKS);
  FAutoHide             := settings.Read(INI_AUTOHIDE, DEF_AUTOHIDE);
  FAutoHideTransparency := settings.Read(INI_AUTOHIDE_TRANSPARENCY, DEF_AUTOHIDE_TRANSPARENCY);
  FAutoShowDelay        := settings.Read(INI_AUTOSHOW_DELAY, DEF_AUTOSHOW_DELAY, 0, 60000);
  FAutoShowMode         := settings.Read<TAutoShowMode>(INI_AUTOHIDE_SHOWMODE, DEF_AUTOHIDE_SHOWMODE);
  FBackgroundColor      := Cardinal(settings.Read(INI_BKGCOLOR, DEF_BKGCOLOR));
  FCorner1GapWidth      := settings.Read(INI_CORNER1GAP_WIDTH, DEF_CORNERGAP_WIDTH);
  FCorner2GapWidth      := settings.Read(INI_CORNER2GAP_WIDTH, DEF_CORNERGAP_WIDTH);
  FEnableAeroGlass      := settings.Read(INI_ENABLE_AG, DEF_ENABLE_AG);
  FGlowSize             := settings.Read(INI_GLOWSIZE, DEF_GLOWSIZE, GLOW_SIZE_MIN, GLOW_SIZE_MAX);
  FHintShow             := True;
  hki                   := settings.Read(INI_AUTOHIDE_HOTKEY, DEF_AUTOHIDE_HOTKEY);
  FIconSize             := settings.Read(INI_ICON_SIZE, DEF_ICON_SIZE, ICON_SIZE_MIN, ICON_SIZE_MAX);
  FIsLightStyle         := settings.Read(INI_ISLIGHT, DEF_ISLIGHT);
  FItemMargin.cx        := settings.Read(INI_MARGINX, DEF_MARGINX, MARGIN_MIN, MARGIN_MAX);
  FItemMargin.cy        := settings.Read(INI_MARGINY, DEF_MARGINY, MARGIN_MIN, MARGIN_MAX);
  FItemOrder            := settings.Read<TItemOrder>(INI_ITEM_ORDER, DEF_ITEM_ORDER);
  FJumplistRecentMax    := settings.Read(INI_JUMPLIST_RECENTMAX, DEF_JUMPLIST_RECENTMAX, JUMPLIST_RECENTMAX_MIN, JUMPLIST_RECENTMAX_MAX);
  FJumplistShowMode     := settings.Read<TJumplistShowMode>(INI_JUMPLIST_SHOWMODE, DEF_JUMPLIST_SHOWMODE);
  FLockLinkbar          := settings.Read(INI_LOCK_BAR, DEF_LOCK_BAR);
  FLookMode             := settings.Read<TLookMode>(INI_LOOKMODE, DEF_LOOKMODE);
  FMonitorNum           := settings.Read(INI_MONITORNUM, Screen.PrimaryMonitor.MonitorNum, 0, Screen.MonitorCount-1);
  FScreenEdge           := settings.Read<TScreenAlign>(INI_EDGE, DEF_EDGE);
  FSortAlphabetically   := settings.Read(INI_SORT_AB, DEF_SORT_AB);
  FTextColor            := Cardinal(settings.Read(INI_TXTCOLOR, DEF_TXTCOLOR) and $ffffff);
  FTextLayout           := settings.Read<TTextLayout>(INI_TEXT_LAYOUT, DEF_TEXT_LAYOUT);
  FTextOffset           := settings.Read(INI_TEXT_OFFSET, DEF_TEXT_OFFSET, TEXT_OFFSET_MIN, TEXT_OFFSET_MAX);
  FTextWidth            := settings.Read(INI_TEXT_WIDTH, DEF_TEXT_WIDTH, TEXT_WIDTH_MIN, TEXT_WIDTH_MAX);
  FUseBkgndColor          := settings.Read(INI_USEBKGCOLOR, DEF_USEBKGCOLOR);
  FUseTextColor          := settings.Read(INI_USETXTCOLOR, DEF_USETXTCOLOR);
  FStayOnTop := FormStyle = fsStayOnTop;
  StayOnTop             := settings.Read(INI_STAYONTOP, DEF_STAYONTOP);
  //
  settings.Close;

  // Set other values
  FGripSize := GRIP_SIZE;
  FHotIndex := ITEM_NONE;
  FPressedIndex := ITEM_NONE;
  FItemDropPosition := ITEM_NONE;
  FItemPopup := ITEM_NONE;
  FDragIndex := ITEM_NONE;
  FMouseLeftDown := False;
  FMouseDragLinkbar := False;
  FMouseDragItem := False;
  FDragingItem := False;

  ExpAeroGlassEnabled := FEnableAeroGlass;

  // Register Hotkey
  HotkeyInfo := hki;
end;

procedure TLinkbarWcl.SaveLinks;
var sl: TStringList;
    i: integer;
begin
  if DirectoryExists(WorkDir)
     or ForceDirectories(WorkDir)
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
end;

procedure TLinkbarWcl.SaveSettings;
var path: string;
    settings: TSettings;
begin
  path := ExtractFilePath(FSettingsFileName);
  if DirectoryExists(path)
     or ForceDirectories(path)
  then begin
    settings.Open(FSettingsFileName);
    // Write
    settings.Write(INI_MONITORNUM, FMonitorNum);
    settings.Write(INI_EDGE, Integer(ScreenAlign));
    settings.Write(INI_AUTOHIDE, AutoHide);
    settings.Write(INI_AUTOHIDE_TRANSPARENCY, FAutoHideTransparency);
    settings.Write(INI_AUTOHIDE_SHOWMODE, Integer(AutoShowMode));
    settings.Write(INI_AUTOHIDE_HOTKEY, String(HotkeyInfo));
    settings.Write(INI_ICON_SIZE, IconSize);
    settings.Write(INI_MARGINX, ItemMargin.cx);
    settings.Write(INI_MARGINY, ItemMargin.cy);
    settings.Write(INI_TEXT_LAYOUT, Integer(TextLayout));
    settings.Write(INI_TEXT_OFFSET, TextOffset);
    settings.Write(INI_TEXT_WIDTH, TextWidth);
    settings.Write(INI_ITEM_ORDER, Integer(ItemOrder));
    settings.Write(INI_LOCK_BAR, FLockLinkbar);
    settings.Write(INI_ISLIGHT, FIsLightStyle);
    settings.Write(INI_ENABLE_AG, FEnableAeroGlass);
    settings.Write(INI_AUTOSHOW_DELAY, FAutoShowDelay);
    settings.Write(INI_SORT_AB, FSortAlphabetically);
    settings.Write(INI_USEBKGCOLOR, FUseBkgndColor);
    settings.Write(INI_BKGCOLOR, HexDisplayPrefix + IntToHex(BackgroundColor, 8));
    settings.Write(INI_USETXTCOLOR, FUseTextColor);
    settings.Write(INI_TXTCOLOR, HexDisplayPrefix + IntToHex(FTextColor, 6));
    settings.Write(INI_GLOWSIZE, FGlowSize);
    settings.Write(INI_STAYONTOP, FStayOnTop);
    settings.Write(INI_JUMPLIST_SHOWMODE, Integer(JumplistShowMode));
    settings.Write(INI_JUMPLIST_RECENTMAX, JumplistRecentMax);
    settings.Write(INI_LOOKMODE, Integer(FLookMode));
    settings.Write(INI_CORNER1GAP_WIDTH, FCorner1GapWidth);
    settings.Write(INI_CORNER2GAP_WIDTH, FCorner2GapWidth);
    // Save
    settings.Update;
    settings.Close;
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
  FCreated := False;
  CreateBitmaps;

  Self.DesktopFont := True;

  L10n;

  oHint := TTooltip32.Create(Handle);

  pMenu.Items.RethinkHotkeys;

  Color := 0;
  FrmProperties := nil;
  FLockAutoHide := False;
  FCanAutoHide := True;

  LoadSettings;

  UpdateBackgroundColor;

  if IsWindows10
  then ThemeSetWindowAttribute10(Handle, FLookMode, BackgroundColor)
  else ThemeSetWindowAttribute78(Handle);

  ThemeInitData(Handle, FIsLightStyle);

  GetOrCreateFilesList(WorkDir + LINKSLIST_FILE_NAME);

  UpdateItemSizes;

  oAppBar := TAccessBar.Create2(self, FScreenEdge, FALSE);
  oAppBar.StayOnTop := StayOnTop;
  oAppBar.MonitorNum := FMonitorNum;
  oAppBar.QuerySizing := QuerySizingEvent;
  oAppBar.QuerySized := QuerySizedEvent;
  oAppBar.QueryAutoHide := QueryHideEvent;

  if not AutoHide then oAppBar.Loaded
  else AutoHide := TRUE;

  BitBucketNotify := RegisterBitBucketNotify(Handle, LM_SHELLNOTIFY);

  FCreated := True;

  UpdateBlur;

  DoDelayedAutoHide(1000);
end;

procedure TLinkbarWcl.L10n;
begin
  L10nControl(imNewShortcut,  'Menu.Shortcut');
  L10nControl(imOpenWorkdir,  'Menu.Open');
  L10nControl(imAddBar,       'Menu.Create');
  L10nControl(imRemoveBar,    'Menu.Delete');
  L10nControl(imLockBar,      'Menu.Lock');
  L10nControl(imSortAlphabet, 'Menu.Sort');
  L10nControl(imProperties,   'Menu.Properties');
  L10nControl(imClose,        'Menu.Close');
  L10nControl(imCloseAll,     'Menu.CloseAll');
end;

procedure TLinkbarWcl.FormDestroy(Sender: TObject);
begin
  UnregisterBitBucketNotify(BitBucketNotify);
  UnregisterHotkeyNotify(Handle);

  if Assigned(FrmProperties)
  then FrmProperties.Free;

  oAppBar.Free;
  StopDirWatch;

  if (not FRemoved)
  then SaveLinks;

  ThemeCloseData;

  if Assigned(oHint) then oHint.Free;
  if Assigned(BmpMain) then BmpMain.Free;
  if Assigned(BmpBtn) then BmpBtn.Free;
  if Assigned(CBmpSelectedItem) then CBmpSelectedItem.Free;
  if Assigned(CBmpDropPosition) then CBmpDropPosition.Free;
  if Assigned(Items) then Items.Free;
end;

procedure TLinkbarWcl.CreateBitmaps;
begin
  CBmpSelectedItem := THBitmap.Create(32);
  CBmpDropPosition := THBitmap.Create(32);
  BmpBtn := THBitmap.Create(32);
  BmpMain := THBitmap.Create(32);
end;

function TLinkbarWcl.IsItemIndex(const AIndex: Integer): Boolean;
begin
  Result := (AIndex >= 0) and (AIndex < Items.Count);
end;

procedure TLinkbarWcl.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if AutoHide
     and FAutoHiden
  then begin
    Key := 0;
    Exit;
  end;

  if (Items.Count = 0) then Exit;

  case Key of
    VK_SPACE, VK_RETURN: // Run
      begin
        if IsItemIndex(HotIndex)
        then begin
          oHint.Cancel;
          DoExecuteItem(HotIndex);
        end;
        Exit;
      end;
    VK_ESCAPE: // Deselect
      begin
        if (HotIndex = ITEM_NONE)
        then begin
          FCanAutoHide := True;
          DoAutoHide;
        end
        else HotIndex := ITEM_NONE;
        Exit;
      end;
    VK_F2: // Rename
      begin
        if IsItemIndex(HotIndex)
        then begin
          oHint.Cancel;
          DoRenameItem(HotIndex);
        end;
        Exit;
      end;
    VK_DELETE:
      begin
        if IsItemIndex(HotIndex)
        then begin
          oHint.Cancel;
          SHDeleteOp(Handle, Items[HotIndex].FileName, GetKeyState(VK_SHIFT) >= 0);
        end;
        Exit;
      end;
    VK_TAB:
      begin
        HotIndex := HotIndex + 1;
        Exit;
      end;
    // Arrows
    VK_LEFT, VK_RIGHT, VK_DOWN, VK_UP:
      begin
        // No hot item:
        // Left/Up - last
        // Right/Down - first
        if (HotIndex = ITEM_NONE)
        then begin
          if (Key in [VK_LEFT, VK_UP])
          then HotIndex := Items.Count-1
          else HotIndex := 0;
          Exit;
        end;

        // One-line panel:
        // Left/Up - prev
        // Right/Down - next
        if (IconLinesCount = 1)
        then begin
          if (Key in [VK_LEFT, VK_UP])
          then HotIndex := Max(HotIndex - 1, 0)
          else HotIndex := Min(HotIndex + 1, Items.Count-1);
          Exit;
        end;

        // Multi-line panel:
        case Key of
          VK_LEFT:
            begin
              if (ItemOrder = ioLeftToRight)
              then HotIndex := Max(HotIndex - 1, 0)
              else begin
                if (oAppBar.Vertical)
                then HotIndex := Max(HotIndex - IconsInLine,    0)
                else HotIndex := Max(HotIndex - IconLinesCount, 0);
              end;
            end;
          VK_RIGHT:
            begin
              if (ItemOrder = ioLeftToRight)
              then HotIndex := Min(HotIndex + 1, Items.Count-1)
              else begin
                if (oAppBar.Vertical)
                then HotIndex := Min(HotIndex + IconsInLine,    Items.Count-1)
                else HotIndex := Min(HotIndex + IconLinesCount, Items.Count-1)
              end;
            end;
          VK_UP:
            begin
              if (ItemOrder = ioUpToDown)
              then HotIndex := Max(HotIndex - 1, 0)
              else begin
                if (oAppBar.Vertical)
                then HotIndex := Max(HotIndex - IconLinesCount, 0)
                else HotIndex := Max(HotIndex - IconsInLine,    0)
              end;
            end;
          VK_DOWN:
            begin
              if (ItemOrder = ioUpToDown)
              then HotIndex := Min(HotIndex + 1, Items.Count-1)
              else begin
                if (oAppBar.Vertical)
                then HotIndex := Min(HotIndex + IconLinesCount, Items.Count-1)
                else HotIndex := Min(HotIndex + IconsInLine,    Items.Count-1)
              end;
            end;
        end;
      end;
  else
    Exit;
  end;
end;

procedure TLinkbarWcl.CMDialogKey(var Msg: TCMDialogKey);
begin
  // If you do not return 0 then VK_TAB will not pass into FormKeyDown
  if (Msg.CharCode = VK_TAB)
  then Msg.Result := 0
  else inherited;
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
        FLockHotIndex := False;
        PressedIndex := ItemIndexByPoint( Point(X, Y) );
      end
    else Exit;
  end;
end;

var
  prevX: Integer = -MaxInt;
  prevY: Integer = -MaxInt;

procedure TLinkbarWcl.FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  if (X = prevX) and (Y = prevY)
  then Exit;
  prevX := X; prevY := Y;

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
      if (FPressedIndex = ITEM_NONE)
      then begin
        if ( TPoint.Create(X,Y).Distance(FMousePosDown) > PANEL_DRAG_THRESHOLD )
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
        if ( not PtInRect(Items[FPressedIndex].Rect, TPoint.Create(X, Y)) )
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
      then begin
        FCanAutoHide := False;
        DoAutoShow;
      end;
    end;
    Exit;
  end;

  FCanAutoHide := False;
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
          TSettings.Write(FSettingsFileName, INI_EDGE, Integer(FScreenEdge));
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
  if (AIndex <> ITEM_NONE)
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

// Macros from windowsx.h:
// Important  Do not use the LOWORD or HIWORD macros to extract the x- and y-
// coordinates of the cursor position because these macros return incorrect results
// on systems with multiple monitors. Systems with multiple monitors can have
// negative x- and y- coordinates, and LOWORD and HIWORD treat the coordinates
// as unsigned quantities.
function MakePoint(const L: DWORD): TPoint; inline;
Begin
  Result := TPoint.Create(SmallInt(L and $FFFF), SmallInt(L shr 16));
End;

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

    if (pMenu.Items[i] = imSortAlphabet)
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

  // Set icon for "New shortcut" menu item
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
      then PostMessage(Handle, LM_CM_ITEMS, 0, Integer(command));
    end
    else begin
      // Execute Shell context menu + Linkbar context menu as submenu
      // FPopupMenu will be destroyed automatically
      ExplorerMenuPopup(Handle, Items[FItemPopup].Pidl, APt, AShift, FPopupMenu);
    end;
  finally
    FLockHotIndex := False;
    if (WindowFromPoint(MakePoint(GetMessagePos)) <> Handle)
    then begin
      HotIndex := ITEM_NONE;
    end;
    FLockAutoHide := False;
  end;

  DeleteObject(hBmp);
end;

procedure TLinkbarWcl.OnFormJumplistDestroy(Sender: TObject);
begin
  if (not (csDestroying in Self.ComponentState))
  then begin
    FLockHotIndex := False;
    if (WindowFromPoint(MakePoint(GetMessagePos)) <> Handle)
    then begin
      HotIndex := ITEM_NONE;
    end;
    FLockAutoHide := False;
    FCanAutoHide := True;
    DoAutoHide;
  end;
end;

procedure TLinkbarWcl.DoPopupJumplist(APt: TPoint; AShift: Boolean);
var item: TLbItem;
    pt: TPoint;
    r: TRect;
    form: TFormJumpList;
begin
  if (FJumplistShowMode <> jsmDisabled)
  then begin
    item := Items[FItemPopup];
    form := TryCreateJumplist(Self, item.Pidl, FJumplistRecentMax);
    if Assigned(form)
    then begin
      r := item.Rect;
      case ScreenAlign of
        saLeft:   pt := Point(r.Right, r.Bottom);
        saRight:  pt := Point(r.Left, r.Bottom);
        saTop:    pt := Point(r.CenterPoint.X, r.Bottom);
        saBottom: pt := Point(r.CenterPoint.X, r.Top);
      end;
      MapWindowPoints(Handle, 0, pt, 1);

      if form.Popup(Handle, pt, ScreenAlign)
      then begin
        oHint.Cancel;
        form.OnDestroy := OnFormJumplistDestroy;
        FLockHotIndex := True;
        FLockAutoHide := True;
        Exit;
      end;
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
    FItemPopup := HotIndex;
    if IsItemIndex(FItemPopup)
    then pt := Items[HotIndex].Rect.CenterPoint
    else pt := Point(0, 0);
  end
  else
    FItemPopup := ItemIndexByPoint(pt);

  HotIndex := FItemPopup;

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
  textHeight: Integer;
begin
  // Calc text height
  Canvas.Font := Screen.IconFont;
  if TextLayout = tlNone
  then textHeight := 0
  else textHeight := DrawText(Canvas.Handle, 'Wp', 2, r, DT_SINGLELINE or DT_NOCLIP or DT_CALCRECT);

  // Calc margin, icon offset & button size
  case TextLayout of
  tlLeft, tlRight:
    begin
      // button size
      w := FItemMargin.cx + FIconSize + FTextOffset + FTextWidth + FItemMargin.cx;
      h := FItemMargin.cy + Max(FIconSize, textHeight) + FItemMargin.cy;
      // icon offset
      if TextLayout = tlRight
      then FIconOffset.X := FItemMargin.cx
      else FIconOffset.X := FItemMargin.cx + FTextWidth + FTextOffset;
      FIconOffset.Y := (h - FIconSize) div 2;
      // text rect
      if TextLayout = tlRight
      then FTextRect := Bounds( FItemMargin.cx + FIconSize + FTextOffset,
        (h - textHeight) div 2, FTextWidth, textHeight )
      else FTextRect := Bounds( FItemMargin.cx, (h - textHeight) div 2,
        FTextWidth, textHeight );
    end;
  tlTop, tlBottom:
    begin
      // button size
      w := FItemMargin.cx + Max(FIconSize, FTextWidth) + FItemMargin.cx;
      h := FItemMargin.cy + FIconSize + FTextOffset + textHeight + FItemMargin.cy;
      // icon offset
      FIconOffset.X := (w - FIconSize) div 2;
      if textlayout = tlBottom
      then FIconOffset.Y := FItemMargin.cy
      else FIconOffset.Y := FItemMargin.cy + textHeight + FTextOffset;
      // text rect
      if textlayout = tlBottom
      then FTextRect := Bounds( FTextOffset, FItemMargin.cy + FIconSize + FTextOffset,
        w - 2*FTextOffset, textHeight )
      else FTextRect := Bounds( FTextOffset, FItemMargin.cy,
        w - 2*FTextOffset, textHeight );
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
  if AValue = FPressedIndex then Exit;
  oHint.Cancel;
  FPressedIndex := AValue;

  if (FPressedIndex <> FHotIndex)
  then HotIndex := FPressedIndex;

  DrawItem(BmpMain, FHotIndex, True, FPressedIndex <> ITEM_NONE);
  UpdateWindow(Handle, BoundsRect, ScreenAlign, BmpMain);
end;

procedure TLinkbarWcl.SetHotIndex(AValue: integer);
var
  r: TRect;
  Pt: TPoint;
  HA: TAlignment;
  VA: TVerticalAlignment;
begin
  if not IsItemIndex(AValue)
  then AValue := ITEM_NONE;

  if (FLockHotIndex)
     or (AValue = FHotIndex)
  then Exit;

  if FHotIndex >= 0
  then begin // restore pred selected item
    r := Items[FHotIndex].Rect;
    BitBlt(BmpMain.Dc, r.Left, r.Top, r.Width, r.Height,
      CBmpSelectedItem.Dc, 0, 0, SRCCOPY);
  end;
  FHotIndex := AValue;
  if FHotIndex >= 0 then
  begin // store current item
    r := Items[FHotIndex].Rect;
    BitBlt(CBmpSelectedItem.Dc, 0, 0, r.Width, r.Height,
      BmpMain.Dc, r.Left, r.Top, SRCCOPY);
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

procedure TLinkbarWcl.SetHotkeyInfo(AValue: THotkeyInfo);
begin
  FHotkeyInfo := AValue;
  if (AutoHide)
  then RegisterHotkeyNotify(Handle, FHotkeyInfo)
  else UnregisterHotkeyNotify(Handle);
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
  if (FSortAlphabetically = AValue)
  then Exit;

  FSortAlphabetically := AValue;
  // Save setting
  TSettings.Write(FSettingsFileName, INI_SORT_AB, FSortAlphabetically);

  if FSortAlphabetically
  then begin
    Items.Sort;
    RecreateMainBitmap(BmpMain.Width, BmpMain.Height);
    UpdateWindow(Handle, BoundsRect, ScreenAlign, BmpMain);
  end;
end;

procedure TLinkbarWcl.SetStayOnTop(AValue: Boolean);
const FORM_STYLE: array[Boolean] of TFormStyle = (fsNormal, fsStayOnTop);
begin
  if (FStayOnTop = AValue)
  then Exit;

  FStayOnTop := AValue;
  Self.FormStyle := FORM_STYLE[FStayOnTop];

  if Assigned(oAppBar)
  then oAppBar.StayOnTop := FStayOnTop;
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

  if (AutoHide and FAutoHiden)
  then r := FAfterAutoHideBound
  else r := FBeforeAutoHideBound;

  MoveWindow(Handle, r.Left, r.Top, r.Width, r.Height, False);
  UpdateWindow(Handle, r, ScreenAlign, BmpMain);
end;

procedure TLinkbarWcl.QueryHideEvent(Sender: TObject; AEnabled: boolean);
begin
  FAutoHide := AEnabled;
end;

procedure TLinkbarWcl.UpdateBackgroundColor;
begin
  ThemeGetTaskbarColor(FSysBackgroundColor, FLookMode);
end;

function TLinkbarWcl.GetBackgroundColor: Cardinal;
begin
  if (FUseBkgndColor)
  then Result := FBackgroundColor
  else Result := FSysBackgroundColor;
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

procedure TLinkbarWcl.FormResize(Sender: TObject);
begin
  if not FCreated
  then Exit;
  UpdateBlur;
end;

procedure TLinkbarWcl.WndProc(var Msg: TMessage);
begin
  case Msg.Msg of
    WM_THEMECHANGED:
      begin
        inherited;
        Msg.Result := 0;
        if not FCreated then Exit;
        ThemeInitData(Handle, IsLightStyle);
        Exit;
      end;
    WM_SETTINGCHANGE:
      begin
        inherited;
        if (not FCreated)
           //or (Msg.WParam <> SPI_GETICONTITLELOGFONT)
        then Exit;
        UpdateItemSizes;
        RecreateMainBitmap(BmpMain.Width, BmpMain.Height);
        UpdateWindow(Handle, BoundsRect, ScreenAlign, BmpMain);
        Exit;
      end;
    CM_FONTCHANGED:
      begin
        inherited;
        if not FCreated then Exit;
        UpdateItemSizes;
        RecreateMainBitmap(BmpMain.Width, BmpMain.Height);
        UpdateWindow(Handle, BoundsRect, ScreenAlign, BmpMain);
        Exit;
      end;
    WM_SYSCOLORCHANGE:
      begin
        inherited;
        if not FCreated then Exit;
        HotIndex := ITEM_NONE;
        RecreateMainBitmap(BmpMain.Width, BmpMain.Height);
        RecreateButtonBitmap(FButtonSize.Width, FButtonSize.Height);
        UpdateWindow(Handle, BoundsRect, ScreenAlign, BmpMain);
        Exit;
      end;
    WM_DWMCOLORIZATIONCOLORCHANGED:
      begin
        Msg.Result := 0;
        if not FCreated then Exit;

        UpdateBackgroundColor;

        if IsWindows10
        then ThemeSetWindowAccentPolicy10(Handle, FLookMode, BackgroundColor);

        // In Windows 8+ theme color may changed smoothly
        HotIndex := ITEM_NONE;
        RecreateMainBitmap(BmpMain.Width, BmpMain.Height); // <== THIS
        RecreateButtonBitmap(FButtonSize.Width, FButtonSize.Height);
        UpdateWindow(Handle, BoundsRect, ScreenAlign, BmpMain);
      end;
    WM_DWMCOMPOSITIONCHANGED:
      // NOTE: As of Windows 8, DWM composition is always enabled, so this message is
      // not sent regardless of video mode changes.
      begin
        inherited;
        Msg.Result := 0;
        if not FCreated then Exit;
        ThemeInitData(Handle, IsLightStyle);
        UpdateItemSizes;
        UpdateBlur;
      end;
    WM_ACTIVATE:
      begin
        //Msg.Result := 0;
      end;
    WM_KILLFOCUS:
      begin
        inherited;
        //Msg.Result := 0;
        if (csDestroying in ComponentState)
        then Exit;
        FCanAutoHide := not Assigned(FrmProperties);
        DoAutoHide;
        Exit;
      end;
    { Display stste changed (count/size/rotate) }
    WM_DISPLAYCHANGE:
      begin
        inherited;
        Msg.Result := 0;
        if not FCreated then Exit;
        // force update Screen
        FMonitorNum := Self.Monitor.MonitorNum; // or Screen.MonitorFromWindow(0, mdNull);
        oAppBar.MonitorNum := FMonitorNum;
        oAppBar.AppBarPosChanged;
        Exit;
      end;
    { Delayed auto show (timer) }
    WM_TIMER:
      begin
        case Msg.WParam of
          TIMER_AUTO_SHOW:
            begin
              KillTimer(Handle, TIMER_AUTO_SHOW);
              DoAutoShow;
              Exit;
            end;
          TIMER_AUTO_HIDE:
            begin
              KillTimer(Handle, TIMER_AUTO_HIDE);
              DoAutoHide;
              Exit;
            end;
        end;
      end;
    { Messages from ShellContextMenu }
    LM_CM_RENAME:
      begin
        DoRenameItem(FItemPopup);
        Exit;
      end;
    LM_CM_ITEMS:
      begin
        DoPopupMenuItemExecute(Msg.LParam);
        Exit;
      end;
    LM_CM_INVOKE:
      begin
        JumpListClose;
        Exit;
      end;
    { WatchDir stop }
    LM_STOPDIRWATCH:
      begin
        StopDirWatch;
        Exit;
      end;
    { Bit Bucket image changed }
    LM_SHELLNOTIFY:
      begin
        UpdateBitBuckets;
        Exit;
      end;
    { Settings/Rename dialog destroyed }
    LM_DOAUTOHIDE:
      begin
        FCanAutoHide := not Focused;
        DoAutoHide;
        Exit;
      end;
  end;

  inherited WndProc(Msg);
end;

function SetForegroundWindowInternal(AWnd: HWND): HWND;
var ip: TInput; // This structure will be used to create the keyboard input event.
begin
  if not IsWindow(AWnd)
  then Exit(0);

  Result := GetForegroundWindow;

  // First try plain SetForegroundWindow
  SetForegroundWindow(AWnd);
  if (AWnd = GetForegroundWindow)
  then Exit;

  // Set up a generic keyboard event.
  FillChar(ip, SizeOf(ip), 0);
  ip.Itype := INPUT_KEYBOARD;
  // Press the "Alt" key
	ip.ki.wVk := VK_MENU; // virtual-key code for the "Alt" key
	ip.ki.dwFlags := 0;   // 0 for key press
	SendInput(1, ip, SizeOf(ip));

  //Sleep(100); //Sometimes SetForegroundWindow will fail and the window will flash instead of it being show. Sleeping for a bit seems to help.
  Application.ProcessMessages;

	SetForegroundWindow(AWnd);

 	// Release the "Alt" key
	ip.ki.dwFlags := KEYEVENTF_KEYUP; // for key release
	SendInput(1, ip, sizeof(ip));
end;

procedure TLinkbarWcl.WmHotKey(var Msg: TMessage);
begin
  if (Msg.Msg = WM_HOTKEY)
     and (Msg.WParam = LB_HOTKEY_ID)
     and (Msg.LParamHi = FHotkeyInfo.KeyCode)
     and (Msg.LParamLo = FHotkeyInfo.Modifiers)
     and AutoHide
  then begin
    if (FAutoHiden)
    then begin
      FPrevForegroundWnd := SetForegroundWindowInternal(Handle);
      FCanAutoHide := False;
      DoAutoShow;
    end
    else begin
      //SetForegroundWindow(FPrevForegroundWnd);
      // Linkbar will be hidden when it loses Focus
      //DoAutoHide;
    end;
    Exit;
  end;

  inherited;
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
  then PostMessage(wnd, LM_STOPDIRWATCH, 0, 0);
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
  TSettings.Write(FSettingsFileName, INI_LOCK_BAR, FLockLinkbar);
end;

procedure TLinkbarWcl.imAddBarClick(Sender: TObject);
var cmd: string;
begin
  cmd := LBCreateCommandParam(CLK_NEW, '');
  if (Locale <> '')
  then cmd := cmd + LBCreateCommandParam(CLK_LANG, Locale);
  LBCreateProcess(ParamStr(0), cmd);
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
    td.Title := Format( L10NFind('Delete.Title', 'You remove the linkbar "%s"'), [PanelName] );
    td.Text := Format( L10NFind('Delete.Text', 'Working directory: %s'), [WorkDir] );
    td.VerificationText := L10NFind('Delete.Verification', 'Delete working directory') + Format('%*s', [24, ' ']);
    td.CommonButtons := [tcbOk, tcbCancel];
    td.DefaultButton := tcbCancel;

    if (td.Execute)
       and (td.ModalResult = mrOk)
    then begin
      FRemoved := True;
      DeleteFile(FSettingsFileName);
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

procedure TLinkbarWcl.imSortAlphabetClick(Sender: TObject);
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
    HotIndex := ITEM_NONE;
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

procedure TLinkbarWcl.DoAutoShow;
var pt: TPoint;
begin
  pt := MakePoint(GetMessagePos);
  if (AutoHide)
     and (FAutoHiden)
     and ((not FCanAutoHide) or (WindowFromPoint(pt) = Handle))
  then begin
    FAutoHiden := False;
    MoveWindow(Handle, FBeforeAutoHideBound.Left, FBeforeAutoHideBound.Top,
      FBeforeAutoHideBound.Width, FBeforeAutoHideBound.Height, False);
    UpdateWindow(Handle, FBeforeAutoHideBound, ScreenAlign, BmpMain);
    Self.OnContextPopup := FormContextPopup;
  end;
end;

procedure TLinkbarWcl.DoDelayedAutoHide(const ADelay: Cardinal);
begin
  if (not AutoHide)
  then Exit;

  if (ADelay = 0)
  then DoAutoHide
  else SetTimer(Handle, TIMER_AUTO_HIDE, ADelay, nil);
end;

procedure TLinkbarWcl.DoDelayedAutoShow;
begin
  if (not AutoHide)
  then Exit;

  if (FAutoShowDelay = 0)
  then DoAutoShow
  else SetTimer(Handle, TIMER_AUTO_SHOW, FAutoShowDelay, nil);
end;

procedure TLinkbarWcl.FormMouseEnter(Sender: TObject);
begin
  if AutoHide
     and FAutoHiden
     and (FAutoShowMode = smMouseHover)
  then DoDelayedAutoShow;
end;

procedure TLinkbarWcl.FormMouseLeave(Sender: TObject);
begin
  HotIndex := -1;
  if (FAutoShowMode = smMouseHover) or FCanAutoHide
  then DoDelayedAutoHide(TIMER_AUTO_HIDE_DELAY);
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
    if (part = 1)
       and (index <> FDragIndex)
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
    BitBlt(BmpMain.Dc, r.Left, r.Top, r.Width, r.Height,
      CBmpDropPosition.Dc, 0, 0, SRCCOPY);
  end;

  FItemDropPosition := index;

  if (FItemDropPosition <> ITEM_NONE) then
  begin
    r := GetItemDropRect(FItemDropPosition, part);
    _FLastDropRect := r;

    BitBlt(CBmpDropPosition.Dc, 0, 0, r.Width, r.Height,
      BmpMain.Dc, r.Left, r.Top, SRCCOPY);

    if (part = 0)
    then begin
      DrawBackground(BmpMain, r);
      ThemeDrawHover(BmpMain, ScreenAlign, r);
      DrawItem(BmpMain, FItemDropPosition, False, False, False);
    end
    else begin
      gpDrawer := TGpGraphics.Create(BmpMain.Dc);//BmpMain.ToGPGraphics;
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
    DoAutoShow;
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
    SetTimer(Handle, TIMER_AUTO_HIDE, TIMER_AUTO_HIDE_DELAY, nil); // DoAutoHide;
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
    SortAlphabetically := False;
    if FItemDropPosition = ITEM_NONE
    then Items.Move(FDragIndex, Items.Count-1)
    else Items.Move(FDragIndex, FItemDropPosition);
    SetDropPosition( Point(-1, -1) );
    UpdateWindowSize;
  end
  else tmrUpdate.Enabled := True;
end;

procedure TLinkbarWcl.QueryDragImage(out ABitmap: THBitmap; out AOffset: TPoint);
begin
  if not StyleServices.Enabled
  then Exit;

  ABitmap := THBitmap.Create(32);
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
    then DeleteItem(i);
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

  for i := Items.Count-1 downto 0 do
  begin
    item := Items[i];
    if item.NeedLoad
    then begin
      if item.LoadFromFile(item.FileName)
      then Items.LoadIcon(item)
      else DeleteItem(i);
    end
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
      DeleteFile(FSettingsFileName);
      Close;
    end;
  end;
end;

procedure TLinkbarWcl.SetEnableAeroGlass(AValue: Boolean);
begin
  if (not IsWindows8And8Dot1)
     or (AValue = FEnableAeroGlass)
  then Exit;

  FEnableAeroGlass := AValue;
  ExpAeroGlassEnabled := FEnableAeroGlass;
  ThemeSetWindowAttribute78(Handle);
  UpdateBlur;
end;

procedure TLinkbarWcl.SetLookMode(AValue: TLookMode);
begin
  if (not IsWindows10)
  then Exit;
  FLookMode := AValue;
  UpdateBackgroundColor;
  ThemeSetWindowAccentPolicy10(Handle, FLookMode, BackgroundColor);
end;

procedure TLinkbarWcl.SetUseBkgndColor(AValue: Boolean);
begin
  if (AValue = FUseBkgndColor)
  then Exit;
  FUseBkgndColor := AValue;
  UpdateBackgroundColor;
end;

end.
