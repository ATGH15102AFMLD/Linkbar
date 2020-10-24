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
    imNewSeparator: TMenuItem;
    imNew: TMenuItem;
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
    procedure imNewSeparatorClick(Sender: TObject);
  private
    BitmapSelected: THBitmap;
    BitmapDropPosition: THBitmap;
    BitmapButton: THBitmap;
    BitmapPanel: THBitmap;
    Items: TLBItemList;
    oAppBar : TAccessBar;
    ToolTip: TTooltip32;
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
    FEnableAeroGlass: Boolean;
    FGripSize: Integer;
    FTooltipShow: Boolean;
    FHotkeyInfo: THotkeyInfo;
    FItemMargin: TSize;
    FIconSize: Integer;
    FIsLightStyle: Boolean;
    FItemOrder: TItemOrder;
    FJumplistShowMode: TJumplistShowMode;
    FJumplistRecentMax: Integer;
    FTransparencyMode: TTransparencyMode;
    FLook: TLook;
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
    FLayout: TPanelLayout;
    FAlign: TPanelAlign;
    FTextWidth: Integer;
    FTextOffset: Integer;
    FTextLayout: TTextLayout;
    FIconOffset: TPoint;
    FTextRect: TRect;
    FPrevForegroundWnd: HWND;
    FSeparatorWidth: Integer;
    FSeparatorStyle: TSeparatorStyle;
    procedure UpdateWindowSize;
    procedure SetLayout(AValue: TPanelLayout);
    procedure SetAlign(AValue: TPanelAlign);
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
    procedure SetTransparencyMode(AValue: TTransparencyMode);
    procedure SetLook(AValue: TLook);
    procedure SetUseBkgndColor(AValue: Boolean);
    function GetAlign: TPanelAlign;
    procedure DrawBackground(const ABitmap: THBitmap; const AClipRect: TRect);
    procedure DrawCaption(const ABitmap: THBitmap; const AIndex: Integer;
      const ADrawForDrag: Boolean = False);
    procedure DrawItem(ABitmap: THBitmap; AIndex: integer; ASelected,
      APressed: Boolean; ADrawBg: Boolean = True; ADrawForDrag: Boolean = False);
    procedure DrawItems(const AWidth, AHeight: integer);
    procedure RecreateMainBitmap(const AWidth, AHeight: integer);
    procedure RecreateButtonBitmap(const AWidth, AHeight: integer);
    procedure UpdateWindow; overload;
    procedure UpdateWindow(const ABounds: TRect); overload;
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
    FDragAlign: TPanelAlign;
    FMonitorNum: Integer;
    FDragMonitorNum: Integer;
    FItemPopup: Integer;
    FDragIndex: Integer;
    MonitorsWorkareaWoTaskbar: TDynRectArray;
    procedure DoClickItem(X, Y: Integer);
    procedure DoExecuteItem(const AIndex: Integer);
    procedure DoRenameItem(const AIndex: Integer);
    procedure DoDelete(const AIndex: Integer);
    procedure DoPopupMenuItemExecute(const ACmd: Integer);
    procedure DoDragLinkbar(const X, Y: Integer);
    procedure DoPopupMenu(APt: TPoint; AShift: Boolean);
    procedure DoPopupJumplist(APt: TPoint; AShift: Boolean);
    procedure DoDragItem(X, Y: Integer);
    procedure GetOrCreateFilesList(const AFileName: string);
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
    property TooltipShow: Boolean read FTooltipShow write FTooltipShow;
    property HotIndex: Integer read FHotIndex write SetHotIndex;
    property HotkeyInfo: THotkeyInfo read FHotkeyInfo write SetHotkeyInfo;
    property IconSize: Integer read FIconSize write SetIconSize;
    property IsLightStyle: Boolean read FIsLightStyle write SetIsLightStyle;
    property ItemMargin: TSize read FItemMargin write SetItemMargin;
    property ItemOrder: TItemOrder read FItemOrder write SetItemOrder;
    property JumplistShowMode: TJumplistShowMode read FJumplistShowMode write FJumplistShowMode;
    property JumplistRecentMax: Integer read FJumplistRecentMax write FJumplistRecentMax;
    property TransparencyMode: TTransparencyMode read FTransparencyMode write SetTransparencyMode;
    property Look: TLook read FLook  write SetLook;
    property PressedIndex: Integer read FPressedIndex write SetPressedIndex;
    property Layout: TPanelLayout read FLayout write SetLayout;
    property Align: TPanelAlign read GetAlign  write SetAlign;
    property SortAlphabetically: Boolean read FSortAlphabetically write SetSortAlphabetically;
    property StayOnTop: Boolean read FStayOnTop write SetStayOnTop default True;
    property TextLayout: TTextLayout read FTextLayout write SetTextLayout;
    property TextOffset: Integer read FTextOffset write SetTextOffset;
    property TextWidth: Integer read FTextWidth write SetTextWidth;
    property TextColor: Cardinal read FTextColor write FTextColor;
    property UseBkgndColor: Boolean read FUseBkgndColor write SetUseBkgndColor;
    property UseTextColor: Boolean read FUseTextColor write FUseTextColor;
    property SeparatorWidth: Integer read FSeparatorWidth write FSeparatorWidth default DEF_SEPARATOR_WIDTH;
    property SeparatorStyle: TSeparatorStyle read FSeparatorStyle write FSeparatorStyle default DEF_SEPARATOR_STYLE;
    //
    property Corner1GapWidth: Integer read FCorner1GapWidth write FCorner1GapWidth;
    property Corner2GapWidth: Integer read FCorner2GapWidth write FCorner2GapWidth;
  public class
    procedure CloseAll;
  end;

var
  LinkbarWcl: TLinkbarWcl;
  FSettingsFileName: string;

implementation

{$R *.dfm}

uses
  Types, Math, Dialogs, StrUtils, Themes,
  Winapi.ShellAPI,
  ExplorerMenu, Linkbar.Shell, Linkbar.Theme,
  Linkbar.OS, Linkbar.L10n, JumpLists.Form, JumpLists.Api_2, RenameDialog,
  Linkbar.SettingsForm, Linkbar.Settings;

const
  bf: TBlendFunction = (BlendOp: AC_SRC_OVER; BlendFlags: 0;
      SourceConstantAlpha: $FF; AlphaFormat: AC_SRC_ALPHA);

  LM_SHELLNOTIFY = WM_USER + 88;
  TIMER_AUTO_SHOW = 15;
  TIMER_AUTO_HIDE = 16;

function EnumWindowProcStopDirWatch(wnd: HWND; lParam: LPARAM): BOOL; stdcall;
var
  className: array[0..MAX_PATH-1] of Char;
begin
  Result := True;
  if (GetClassName(wnd, className, Length(className)) > 0)
     and SameText(string(className), TLinkbarWcl.ClassName)
  then PostMessage(wnd, LM_STOPDIRWATCH, 0, 0);
end;

function EnumWindowProcClose(wnd: HWND; lParam: LPARAM): BOOL; stdcall;
var
  className: array[0..MAX_PATH-1] of Char;
begin
  Result := True;
  if (GetClassName(wnd, className, Length(className)) > 0)
     and SameText(string(className), TLinkbarWcl.ClassName)
  then PostMessage(wnd, WM_CLOSE, 0, 0);
end;

class procedure TLinkbarWcl.CloseAll;
begin
  if MessageDlg('Close all linkbars?',//L10NFind('Message.CloseAll', 'Close all linkbars?'),
        mtConfirmation, [mbOK, mbCancel], 0, mbCancel) = mrOk
  then begin
    EnumWindows(@EnumWindowProcStopDirWatch, 0);
    EnumWindows(@EnumWindowProcClose, 0);
  end;
end;

function FindinSL(sl: TStringList; s: string; var index: integer): boolean;
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

procedure TLinkbarWcl.GetOrCreateFilesList(const AFileName: string);
var list: TStringList;
    templist: TStringList;
    sr: TSearchRec;
    i, j : integer;
    ext: string;
begin
  if not Assigned(Items)
  then Items := TLBItemList.Create;
  Items.Clear;

  // Load last ordered items list
  list := TStringList.Create;
  if FileExists(AFileName)
  then list.LoadFromFile(AFileName, TEncoding.UTF8);

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
    if TItemSeparator.IsSeparator(list[i])
    then begin
      Inc(i);
    end
    else if templist.Find(list[i], j)
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
  for var fileName in list do
  begin
    if TItemSeparator.IsSeparator(fileName)
    then begin
      Items.Add(TItemSeparator.Create);
    end
    else begin
      var item := TItemShortcut.Create;
      if item.LoadFromFile(WorkDir + fileName)
      then Items.Add(item)
      else item.Free;
    end;
  end;
  list.Free;

  if FSortAlphabetically
  then Items.Sort;

  Items.IconSize := IconSize;
end;

function TLinkbarWcl.GetAlign: TPanelAlign;
begin
  if (FMouseDragLinkbar)
  then Result := FDragAlign
  else Result := FAlign;
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
  params.Align := Align;
  params.ClipRect := AClipRect;
  params.IsLight := IsLightStyle;
  params.BgColor := BackgroundColor;
  ThemeDrawBackground(@params);
end;

procedure TLinkbarWcl.DrawCaption(const ABitmap: THBitmap; const AIndex: Integer;
  const ADrawForDrag: Boolean = False);
var
  textRect: TRect;
  textColor: TColor;
  dc, dc2: HDC;
  fnt0: HGDIOBJ;
begin
  if (TextLayout = ETextLayoutNone) then Exit;

  const textFlags: Cardinal = TEXTALIGN[TextLayout] or DT_END_ELLIPSIS or DT_SINGLELINE or DT_NOPREFIX or DT_NOCLIP;

  if (StyleServices.Enabled)
  then begin
    // Aero theme. Use DrawGlassText
    if (FUseTextColor)
    then begin
      textColor := FTextColor;
    end
    else begin
      if (AIndex = ITEM_ALL)
      then begin
        textColor := ThemeButtonNormalTextColor;
      end
      else begin
        if (AIndex = PressedIndex)
        then textColor := ThemeButtonPressedTextColor
        else if (AIndex = HotIndex)
             then textColor := ThemeButtonSelectedTextColor
             else textColor := ThemeButtonNormalTextColor;
      end;
    end;

    dc := ABitmap.Dc;

    if (AIndex = ITEM_ALL)
    then begin
      fnt0 := SelectObject(dc, Screen.IconFont.Handle);
      for var item in Items
      do begin
        if (not Items.IsSeparator(item))
        then begin
          textRect := FTextRect;
          textRect.Offset(item.Rect.TopLeft);
          DrawGlassText(dc, item.Caption, textRect, textFlags, FGlowSize, textColor);
        end;
      end;
      SelectObject(dc, fnt0);
    end
    else begin
      const item = Items[AIndex];

      if (not Items.IsSeparator(item))
      then begin
        if ADrawForDrag
        then begin
          textRect := FTextRect;
          fnt0 := SelectObject(dc, Screen.IconFont.Handle);
          DrawGlassText(dc, item.Caption, textRect, textFlags, FGlowSize, textColor);
          SelectObject(dc, fnt0);
        end
        else begin
          // The shadow extends beyond the button, creating artifacts
          // Draw on separate bitmap with button size
          var bmp := THBitmap.Create(32);
          bmp.SetSize(BitmapButton.Width, BitmapButton.Height);
          dc2 := bmp.Dc;

          textRect := FTextRect;
          if (AIndex = PressedIndex)
          then textRect.Offset(1,1);

          fnt0 := SelectObject(dc2, Screen.IconFont.Handle);
          DrawGlassText(dc2, item.Caption, textRect, textFlags, FGlowSize, textColor);
          SelectObject(dc2, fnt0);

          Windows.AlphaBlend(dc,
            item.Rect.Left, item.Rect.Top, bmp.Width, bmp.Height,
            dc2, 0, 0, bmp.Width, bmp.Height, bf);

          bmp.Free;
        end;
      end;
    end;
  end
  else begin
    // Classic theme
    // NOTE: DrawThemeText/DrawThemeTextEx not work in Classic theme

    Assert(not ADrawForDrag); // Classic Theme don't have Drag Image

    textColor := clBtnText;

    dc := ABitmap.Dc;
    fnt0 := SelectObject(dc, Screen.IconFont.Handle);
    SetTextColor(dc, ColorToRGB(textColor));
    SetBkColor(dc, ColorToRGB(clBtnFace));

    if (AIndex = ITEM_ALL)
    then begin
      for var item in Items
      do begin
        if (not Items.IsSeparator(item))
        then begin
          textRect := FTextRect;
          textRect.Offset(item.Rect.TopLeft);
          DrawText(dc, item.Caption, -1, textRect, textFlags);
        end;
      end;
      ABitmap.Opaque;
    end
    else begin
      const item = Items[AIndex];
      if (not Items.IsSeparator(item))
      then begin
        textRect := FTextRect;
        textRect.Offset(item.Rect.TopLeft);
        if (AIndex = PressedIndex)
        then textRect.Offset(1,1);
        DrawText(dc, item.Caption, -1, textRect, textFlags);
        ABitmap.OpaqueRect(item.Rect);
      end;
    end;

    SelectObject(dc, fnt0);
  end;
end;

procedure TLinkbarWcl.DrawItem(ABitmap: THBitmap; AIndex: integer; ASelected,
  APressed: Boolean; ADrawBg: Boolean; ADrawForDrag: Boolean);
begin
  if AIndex = ITEM_NONE then Exit;

  const item = Items[AIndex];
  if Items.IsSeparator(item) then Exit;

  var r := item.Rect;

  // Classic themes have opaque background and button
  if ADrawBg
     and StyleServices.Enabled
  then DrawBackground(ABitmap, r);

  // For darg not need draw background
  if ADrawForDrag
  then r.Location := TPoint.Zero;

  if APressed
  then ThemeDrawButton(ABitmap, r, True)
  else if ASelected
       then begin
         Windows.AlphaBlend(ABitmap.Dc, r.Left, r.Top, r.Width, r.Height, BitmapButton.Dc, 0, 0, r.Width, r.Height, bf);
       end;

  // Draw text
  DrawCaption(ABitmap, AIndex, ADrawForDrag);

  // Draw icon
  var d: Integer := IfThen(APressed, 1, 0);
  Items.Draw(ABitmap.Dc, item, r.Left + FIconOffset.X + d, r.Top + FIconOffset.Y + d);
end;

procedure TLinkbarWcl.DrawItems(const AWidth, AHeight: integer);
begin
  Items.Sizes.Button := ButtonSize;
  Items.Sizes.Separator := SeparatorWidth;
  Items.Sizes.Margin := FGripSize;
  Items.UpdateLines(IsVertical(Align), AWidth, AHeight);

  // Draw captions
  DrawCaption(BitmapPanel, ITEM_ALL);

  // Draw icons
  for var item in Items do
  begin
    if Items.IsSeparator(item)
       and (FSeparatorStyle <> ESeparatorStyleSpace)
    then begin
      ThemeDrawSeparator(BitmapPanel, Align, item.Rect);
    end
    else begin
      Items.Draw(BitmapPanel.Dc, item, item.Rect.Left + FIconOffset.X, item.Rect.Top + FIconOffset.Y);
    end;
  end;
end;

procedure TLinkbarWcl.RecreateMainBitmap(const AWidth, AHeight: integer);
begin
  BitmapPanel.SetSize(AWidth, AHeight);
  BitmapPanel.Clear;
  // Draw background
  DrawBackground(BitmapPanel, Rect(0, 0, AWidth, AHeight));
  // Draw items
  DrawItems(AWidth, AHeight);
end;

procedure TLinkbarWcl.RecreateButtonBitmap(const AWidth, AHeight: integer);
begin
  // Create clear bitmap
  BitmapButton.SetSize(AWidth, AHeight);
  BitmapButton.Clear;
  ThemeDrawButton(BitmapButton, BitmapButton.Bound, False);
  // Buffer for selections
  BitmapSelected.SetSize(AWidth, AHeight);
  // Buffer for drop
  BitmapDropPosition.SetSize(AWidth, AHeight);
end;

procedure TLinkbarWcl.UpdateWindow;
begin
  UpdateWindow(BoundsRect);
end;

procedure TLinkbarWcl.UpdateWindow(const ABounds: TRect);
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
      if Align in [EPanelAlignLeft, EPanelAlignRight]
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
        if Align in [EPanelAlignLeft, EPanelAlignRight]
        then r := TGPRect.Create(0, c1gw, w, h - c1gw - c2gw)
        else r := TGPRect.Create(c1gw, 0, w - c1gw - c2gw, h);
        drawer.SetClip(r);
      end;
      drawer.Clear($01000000);

      UpdateLayeredWindow(Handle, 0, @Pt1, @Sz, dc, @Pt2, 0, @bf, ULW_ALPHA);
      bmp.Free;
    end
    else begin
      // and Opaque
      if (c1gw > 0) or (c2gw > 0)
      then begin
        // w/ gaps
        Pt1 := ABounds.TopLeft;
        Sz := TSize.Create(w, h);
        case Align of
          EPanelAlignLeft:   Pt2 := Point(BitmapPanel.Width - w, 0);
          EPanelAlignTop:    Pt2 := Point(0, BitmapPanel.Height - h);
          EPanelAlignRight:  Pt2 := Point(0, 0);
          EPanelAlignBottom: Pt2 := Point(0, 0);
        end;

        bmp := THBitmap.Create(32);
        bmp.SetSize(w, h);
        dc := bmp.Dc;

        if Align in [EPanelAlignLeft, EPanelAlignRight]
        then BitBlt(dc, 0, c1gw, w, h - c1gw - c2gw, BitmapPanel.Dc, Pt2.X, c1gw, SRCCOPY)
        else BitBlt(dc, c1gw, 0, w - c1gw - c2gw, h, BitmapPanel.Dc, c1gw, Pt2.Y, SRCCOPY);

        Pt2 := Point(0,0);
        UpdateLayeredWindow(Handle, 0, @Pt1, @Sz, dc, @Pt2, 0, @bf, ULW_ALPHA);
        bmp.Free;
      end
      else begin
        // w/o gaps
        Pt1 := ABounds.TopLeft;
        Sz := TSize.Create(w, h);
        case Align of
          EPanelAlignLeft:   Pt2 := Point(BitmapPanel.Width - w, 0);
          EPanelAlignTop:    Pt2 := Point(0, BitmapPanel.Height - h);
          EPanelAlignRight:  Pt2 := Point(0, 0);
          EPanelAlignBottom: Pt2 := Point(0, 0);
        end;
        UpdateLayeredWindow(Handle, 0, @Pt1, @Sz, BitmapPanel.Dc, @Pt2, 0, @bf, ULW_ALPHA);
      end;
    end;
  end
  else begin
    // Not Hidden
    if (ABounds = BoundsRect)
    then p := nil
    else p := @ABounds.TopLeft;
    Sz := TSize.Create(w, h);
    case Align of
      EPanelAlignLeft:   Pt2 := Point(BitmapPanel.Width - w, 0);
      EPanelAlignTop:    Pt2 := Point(0, BitmapPanel.Height - h);
      EPanelAlignRight:  Pt2 := Point(0, 0);
      EPanelAlignBottom: Pt2 := Point(0, 0);
    end;

    UpdateLayeredWindow(Handle, 0, p, @Sz, BitmapPanel.Dc, @Pt2, 0, @bf, ULW_ALPHA);
  end;
end;

procedure TLinkbarWcl.UpdateBlur;
var blurEnabled: Boolean;
begin
  if IsWindows10
  then begin
    if (FAutoHiden and FAutoHideTransparency)
    then ThemeSetWindowAccentPolicy10(Handle, tmDisabled, 0)
    else ThemeSetWindowAccentPolicy10(Handle, FTransparencyMode, BackgroundColor);
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
var settings: TSettingsFile;
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
  FTooltipShow          := settings.Read(INI_TOOLTIP_SHOW, DEF_TOOLTIP_SHOW);
  hki                   := settings.Read(INI_AUTOHIDE_HOTKEY, DEF_AUTOHIDE_HOTKEY);
  FIconSize             := settings.Read(INI_ICON_SIZE, DEF_ICON_SIZE, ICON_SIZE_MIN, ICON_SIZE_MAX);
  FIsLightStyle         := settings.Read(INI_ISLIGHT, DEF_ISLIGHT);
  FItemMargin.cx        := settings.Read(INI_MARGINX, DEF_MARGINX, MARGIN_MIN, MARGIN_MAX);
  FItemMargin.cy        := settings.Read(INI_MARGINY, DEF_MARGINY, MARGIN_MIN, MARGIN_MAX);
  FSeparatorWidth       := settings.Read(INI_SEPARATOR_WIDTH, DEF_SEPARATOR_WIDTH, SEPARATOR_WIDTH_MIN, SEPARATOR_WIDTH_MAX);
  FSeparatorStyle       := settings.Read<TSeparatorStyle>(INI_SEPARATOR_STYLE, DEF_SEPARATOR_STYLE);
  FItemOrder            := settings.Read<TItemOrder>(INI_ITEM_ORDER, DEF_ITEM_ORDER);
  FLayout               := settings.Read<TPanelLayout>(INI_ITEMS_ALIGN, DEF_ITEMS_ALIGN);
  FJumplistRecentMax    := settings.Read(INI_JUMPLIST_RECENTMAX, DEF_JUMPLIST_RECENTMAX, JUMPLIST_RECENTMAX_MIN, JUMPLIST_RECENTMAX_MAX);
  FJumplistShowMode     := settings.Read<TJumplistShowMode>(INI_JUMPLIST_SHOWMODE, DEF_JUMPLIST_SHOWMODE);
  FLockLinkbar          := settings.Read(INI_LOCK_BAR, DEF_LOCK_BAR);
  FTransparencyMode     := settings.Read<TTransparencyMode>(INI_TRANSPARENCYMODE, DEF_TRANSPARENCYMODE);
  FLook                 := settings.Read<TLook>(INI_COLORMODE, DEF_COLORMODE);
  FMonitorNum           := settings.Read(INI_MONITORNUM, Screen.PrimaryMonitor.MonitorNum, 0, Screen.MonitorCount-1);
  FAlign                := settings.Read<TPanelAlign>(INI_EDGE, DEF_EDGE);
  FSortAlphabetically   := settings.Read(INI_SORT_AB, DEF_SORT_AB);
  FTextColor            := Cardinal(settings.Read(INI_TXTCOLOR, DEF_TXTCOLOR) and $ffffff);
  FTextLayout           := settings.Read<TTextLayout>(INI_TEXT_LAYOUT, DEF_TEXT_LAYOUT);
  FTextOffset           := settings.Read(INI_TEXT_OFFSET, DEF_TEXT_OFFSET, TEXT_OFFSET_MIN, TEXT_OFFSET_MAX);
  FTextWidth            := settings.Read(INI_TEXT_WIDTH, DEF_TEXT_WIDTH, TEXT_WIDTH_MIN, TEXT_WIDTH_MAX);
  FUseBkgndColor        := settings.Read(INI_USEBKGCOLOR, DEF_USEBKGCOLOR);
  FUseTextColor         := settings.Read(INI_USETXTCOLOR, DEF_USETXTCOLOR);
  FStayOnTop := (FormStyle = fsStayOnTop);
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

  GlobalLayout := FLayout;
  GlobalLook := FLook;
  GlobalAeroGlassEnabled := FEnableAeroGlass;

  // Register Hotkey
  HotkeyInfo := hki;
end;

procedure TLinkbarWcl.SaveLinks;
begin
  if DirectoryExists(WorkDir)
     or ForceDirectories(WorkDir)
  then begin
    var sl := TStringList.Create;
    try
      for var item in Items
      do sl.Add(ExtractFileName(item.FileName));

      sl.SaveToFile(WorkDir + LINKSLIST_FILE_NAME, TEncoding.UTF8);
    finally
      sl.Free;
    end;
  end;
end;

procedure TLinkbarWcl.SaveSettings;
var path: string;
    settings: TSettingsFile;
begin
  path := ExtractFilePath(FSettingsFileName);
  if DirectoryExists(path)
     or ForceDirectories(path)
  then begin
    settings.Open(FSettingsFileName);
    // Write
    settings.Write(INI_MONITORNUM, FMonitorNum);
    settings.Write(INI_EDGE, Integer(Align));
    settings.Write(INI_AUTOHIDE, AutoHide);
    settings.Write(INI_AUTOHIDE_TRANSPARENCY, FAutoHideTransparency);
    settings.Write(INI_AUTOHIDE_SHOWMODE, Integer(AutoShowMode));
    settings.Write(INI_AUTOHIDE_HOTKEY, string(HotkeyInfo));
    settings.Write(INI_ICON_SIZE, IconSize);
    settings.Write(INI_MARGINX, ItemMargin.cx);
    settings.Write(INI_MARGINY, ItemMargin.cy);
    settings.Write(INI_TEXT_LAYOUT, Integer(TextLayout));
    settings.Write(INI_TEXT_OFFSET, TextOffset);
    settings.Write(INI_TEXT_WIDTH, TextWidth);
    settings.Write(INI_ITEM_ORDER, Integer(ItemOrder));
    settings.Write(INI_ITEMS_ALIGN, Integer(Layout));
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
    settings.Write(INI_COLORMODE, Integer(FLook));
    settings.Write(INI_TRANSPARENCYMODE, Integer(FTransparencyMode));
    settings.Write(INI_CORNER1GAP_WIDTH, FCorner1GapWidth);
    settings.Write(INI_CORNER2GAP_WIDTH, FCorner2GapWidth);
    settings.Write(INI_SEPARATOR_WIDTH, FSeparatorWidth);
    settings.Write(INI_SEPARATOR_STYLE, Integer(FSeparatorStyle));
    settings.Write(INI_TOOLTIP_SHOW, FTooltipShow);
    // Save
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

  pMenu.Items.RethinkHotkeys;
  imNew.RethinkHotkeys;

  ToolTip := TTooltip32.Create(Handle);

  Color := 0;
  FrmProperties := nil;
  FLockAutoHide := False;
  FCanAutoHide := True;

  LoadSettings;

  UpdateBackgroundColor;

  if IsWindows10
  then ThemeSetWindowAttribute10(Handle, FTransparencyMode, BackgroundColor)
  else ThemeSetWindowAttribute78(Handle);

  ThemeInitData(Handle, FIsLightStyle);

  GetOrCreateFilesList(WorkDir + LINKSLIST_FILE_NAME);

  UpdateItemSizes;

  oAppBar := TAccessBar.Create2(self, FAlign, FALSE);
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

  CreateLinkbarTasksJumplist;

  DoDelayedAutoHide(1000);
end;

procedure TLinkbarWcl.L10n;
begin
  L10nControl(imNew,          'Menu.New');
  L10nControl(imNewShortcut,  'Menu.Shortcut');
  L10nControl(imNewSeparator, 'Menu.Separator');
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

  if Assigned(ToolTip) then ToolTip.Free;
  if Assigned(BitmapPanel) then BitmapPanel.Free;
  if Assigned(BitmapButton) then BitmapButton.Free;
  if Assigned(BitmapSelected) then BitmapSelected.Free;
  if Assigned(BitmapDropPosition) then BitmapDropPosition.Free;
  if Assigned(Items) then Items.Free;
end;

procedure TLinkbarWcl.CreateBitmaps;
begin
  BitmapSelected := THBitmap.Create(32);
  BitmapDropPosition := THBitmap.Create(32);
  BitmapButton := THBitmap.Create(32);
  BitmapPanel := THBitmap.Create(32);
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
          ToolTip.Cancel;
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
          ToolTip.Cancel;
          DoRenameItem(HotIndex);
        end;
        Exit;
      end;
    VK_DELETE:
      begin
        if IsItemIndex(HotIndex)
        then begin
          ToolTip.Cancel;
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
        if (Items.Lines.Count = 1)
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
              if (ItemOrder = EItemOrderLeftToRight)
              then HotIndex := Max(HotIndex - 1, 0)
              else begin
                if (oAppBar.Vertical)
                then begin
                  const prevLineIndex: Integer = Max(0, Items.GetLineIndex(HotIndex) - 1);
                  HotIndex := Max(HotIndex - Items.Lines[prevLineIndex], 0);
                end
                else
                  HotIndex := Max(HotIndex - Items.Lines.Count, 0);
              end;
            end;
          VK_RIGHT:
            begin
              if (ItemOrder = EItemOrderLeftToRight)
              then HotIndex := Min(HotIndex + 1, Items.Count-1)
              else begin
                if (oAppBar.Vertical)
                then begin
                  const nextLineIndex: Integer = Min(Items.Lines.Count-1, Items.GetLineIndex(HotIndex) + 1);
                  HotIndex := Min(HotIndex + Items.Lines[nextLineIndex], Items.Count-1);
                end
                else
                  HotIndex := Min(HotIndex + Items.Lines.Count, Items.Count-1)
              end;
            end;
          VK_UP:
            begin
              if (ItemOrder = EItemOrderUpToDown)
              then HotIndex := Max(HotIndex - 1, 0)
              else begin
                if (oAppBar.Vertical)
                then
                  HotIndex := Max(HotIndex - Items.Lines.Count, 0)
                else begin
                  const prevLineIndex: Integer = Max(0, Items.GetLineIndex(HotIndex) - 1);
                  HotIndex := Max(HotIndex - Items.Lines[prevLineIndex], 0);
                end;
              end;
            end;
          VK_DOWN:
            begin
              if (ItemOrder = EItemOrderUpToDown)
              then HotIndex := Min(HotIndex + 1, Items.Count-1)
              else begin
                if (oAppBar.Vertical)
                then
                  HotIndex := Min(HotIndex + Items.Lines.Count, Items.Count-1)
                else begin
                  const nextLineIndex: Integer = Min(Items.Lines.Count-1, Items.GetLineIndex(HotIndex) + 1);
                  HotIndex := Min(HotIndex + Items.Lines[nextLineIndex], Items.Count-1);
                end;
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

function TLinkbarWcl.ItemIndexByPoint(const APt: TPoint; const ALastIndex: integer = ITEM_NONE): Integer;
var
  i: Integer;
begin
  if (APt.X < 0) or (APt.Y < 0)
  then Exit(ITEM_NONE);

  if (ALastIndex <> ITEM_NONE)
     and InRange(ALastIndex+1, 0, Items.Count)
     and PtInRect(Items[ALastIndex].Rect, APt)
  then Exit(ALastIndex);

  for i := 0 to Items.Count-1 do
  begin
    if PtInRect(Items[i].Rect, APt)
    then Exit(i);
  end;

  Result := ITEM_NONE;
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
    if ( (AutoShowMode = EAutoShowModeMouseClickLeft) and (Button =  mbLeft) )
       or
       ( (AutoShowMode = EAutoShowModeMouseClickRight) and (Button = mbRight) )
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
          Align := FDragAlign;
          TSettingsFile.Write(FSettingsFileName, INI_MONITORNUM, FMonitorNum);
          TSettingsFile.Write(FSettingsFileName, INI_EDGE, Integer(FAlign));
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
var
  FileName: string;
begin
  FDragIndex := ItemIndexByPoint( Point(X, Y) );
  if (FDragIndex <> ITEM_NONE)
  then begin
    HotIndex := ITEM_NONE;

    const item = Items[FDragIndex];
    if Items.IsSeparator(item)
    then FileName := Application.ExeName
    else FileName := item.FileName;

    DragFile(FileName);
    FormMouseUp(Self, mbLeft, [], -1, -1);
  end;
end;

procedure TLinkbarWcl.DoExecuteItem(const AIndex: Integer);
begin
  if not IsItemIndex(AIndex)
  then Exit;

  Items[AIndex].DoExecute(Handle);
end;

procedure TLinkbarWcl.DoClickItem(X, Y: Integer);
var iIndex: Integer;
begin
  iIndex := ItemIndexByPoint( Point(X, Y) );
  DoExecuteItem(iIndex);
end;

procedure TLinkbarWcl.DoRenameItem(const AIndex: Integer);
var dlg: TRenamingWCl;
begin
  if not IsItemIndex(AIndex)
  then Exit;

  FLockAutoHide := True;
  dlg := TRenamingWCl.Create(Self);
  dlg.Pidl := Items[AIndex].Pidl;
  dlg.ShowModal;
  dlg.Free;
  FLockAutoHide := False;
end;

procedure TLinkbarWcl.DoDelete(const AIndex: Integer);
begin
  if not IsItemIndex(AIndex)
  then Exit;

  Items.Delete(AIndex);
  UpdateWindowSize;
end;

procedure TLinkbarWcl.DoDragLinkbar(const X, Y: Integer);
var Pt: TPoint;
   mon: TMonitor;
   k: Double;
   e: TPanelAlign;
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
    then e := EPanelAlignLeft
    else e := EPanelAlignBottom;
  end else
  begin // top/right
    if (mon.Width-Pt.X) < Pt.Y*k
    then e := EPanelAlignRight
    else e := EPanelAlignTop;
  end;

  if (e = FDragAlign)
     and (mon.MonitorNum = FDragMonitorNum)
  then Exit;

  FDragAlign := e;
  FDragMonitorNum := mon.MonitorNum;

  if (FDragAlign = FAlign)
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

      if IsHorizontal(FDragAlign)
      then begin
        r.Left := MonitorsWorkareaWoTaskbar[FDragMonitorNum].Left;
        r.Right := MonitorsWorkareaWoTaskbar[FDragMonitorNum].Right;
      end;

      // Correct new rect
      if (FDragMonitorNum = FMonitorNum)
         and IsVertical(FDragAlign)
      then begin
        case FAlign of
          EPanelAlignTop: r.Top := r.Top - FBeforeDragBounds.Height;
          EPanelAlignBottom: r.Bottom := r.Bottom + FBeforeDragBounds.Height;
        end;
      end;
    end;

    w := r.Width;
    h := r.Height;

    QuerySizingEvent(nil, IsVertical(e), w, h);
    case FDragAlign of
      EPanelAlignRight: r.Left := r.Right - w;
      EPanelAlignBottom: r.Top := r.Bottom - h;
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
  Flags: Integer;
  mii: TMenuItemInfo;
  mi: TMenuInfo;
  iconsize: Integer;
  icon: HICON;
  bmp: HBITMAP;
  caption: string;
begin
  FPopupMenu := CreatePopupMenu;
  if (FPopupMenu = 0)
  then Exit;

  //for i := 0 to pMenu.Items.Count-1 do
  for var item: TMenuItem in pMenu.Items
  do begin
    if (AShift)
    then begin
      if item.Tag = 20 // Hide in extended menu
      then Continue;
    end
    else begin
      if item.Tag = 10 // Hide in regular menu
      then Continue;
    end;

    Flags := MF_BYCOMMAND;

    if (item.IsLine)
    then Flags := Flags or MF_SEPARATOR
    else Flags := Flags or MF_STRING;

    if (item = imLockBar)
       and (FLockLinkbar)
    then Flags := Flags or MF_CHECKED;

    if (item = imSortAlphabet)
       and (FSortAlphabetically)
    then Flags := Flags or MF_CHECKED;

    if (item.Count = 0)
    then begin
      caption := item.Caption;
      //if (item = imClose)
      //then caption := caption + #9 + 'Alt+F4';
      AppendMenu(FPopupMenu, Flags, item.Command, PChar(caption));
    end
    else begin
      var subMenu := CreatePopupMenu;

      for var subItem: TMenuItem in item
      do begin
        Flags := MF_BYCOMMAND;
        if (subItem.IsLine)
        then Flags := Flags or MF_SEPARATOR
        else Flags := Flags or MF_STRING;
        AppendMenu(subMenu, Flags, subItem.Command, PChar(subItem.Caption));
      end;

      Flags := MF_POPUP or MF_STRING;
      AppendMenu(FPopupMenu, Flags, subMenu, PChar(item.Caption));
    end;
  end;

  // Set icon&default for "Close" or "Close All" menu item
  mii := Default(TMenuItemInfo);
  mii.cbSize := SizeOf(mii);
  mii.fMask := MIIM_BITMAP or MIIM_STATE;
  mii.fState := MFS_DEFAULT;
  mii.hbmpItem := HBMMENU_POPUP_CLOSE;
  if (AShift)
  then SetMenuItemInfo(FPopupMenu, imCloseAll.Command, False, mii)
  else SetMenuItemInfo(FPopupMenu, imClose.Command, False, mii);

  // Set icon for "New shortcut" menu item
  bmp := 0;
  iconsize := GetSystemMetrics(SM_CXSMICON);
  icon := LoadImage(GetModuleHandle('shell32.dll'), MakeIntResource(16769), IMAGE_ICON, iconsize, iconsize, LR_DEFAULTCOLOR);
  if (icon <> 0)
  then begin
    bmp := BitmapFromIcon(icon, iconsize);
    DestroyIcon(icon);
    mii := Default(TMenuItemInfo);
    mii.cbSize := SizeOf(mii);
    mii.fMask := MIIM_BITMAP;
    mii.hbmpItem := bmp;
    SetMenuItemInfo(FPopupMenu, imNewShortcut.Command, False, mii);
  end;

  mi := Default(TMenuInfo);
  mi.cbSize := SizeOf(TMenuInfo);
  mi.fMask := MIM_STYLE;
  mi.dwStyle := MNS_CHECKORBMP;
  SetMenuInfo(FPopupMenu, mi);

  MapWindowPoints(Handle, HWND_DESKTOP, APt, 1);

  FLockHotIndex := True;
  FLockAutoHide := True;
  try
    ToolTip.Cancel;
    if (FItemPopup = ITEM_NONE)
    then begin
      // Execute Linkbar context menu
      const command = TrackPopupMenuEx(FPopupMenu, TPM_RETURNCMD or TPM_RIGHTBUTTON or TPM_NONOTIFY, APt.X, APt.Y, Handle, nil);
      DestroyMenu(FPopupMenu);
      if (command)
      then PostMessage(Handle, LM_CM_ITEMS, 0, Integer(command));
    end
    else begin
      // Execute Shell context menu + Linkbar context menu as submenu
      // FPopupMenu will be destroyed automatically
      Items[FItemPopup].DoPopupMenu(Handle, APt, AShift, FPopupMenu);
    end;
  finally
    FLockHotIndex := False;
    if (WindowFromPoint(MakePoint(GetMessagePos)) <> Handle)
    then begin
      HotIndex := ITEM_NONE;
    end;
    FLockAutoHide := False;
  end;

  DeleteObject(bmp);
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
begin
  if (FJumplistShowMode <> EJumplistShowModeDisabled)
  then begin
    const item = Items[FItemPopup];
    var form := TryCreateJumplist(Self, item.Pidl, FJumplistRecentMax);
    if Assigned(form)
    then begin
      var itemRect := item.Rect;
      MapWindowPoints(Handle, HWND_DESKTOP, itemRect, 2);

      if form.Popup(Handle, itemRect, Align)
      then begin
        ToolTip.Cancel;
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

procedure TLinkbarWcl.FormContextPopup(Sender: TObject; MousePos: TPoint; var Handled: Boolean);
begin
  Handled := True;

  if FAutoHiden then Exit;

  var pt := MousePos;
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

  var shift := GetKeyState(VK_SHIFT) < 0;

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
  if (AValue = FButtonSize)
  then Exit;

  FButtonSize := AValue;
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
  if (TextLayout = ETextLayoutNone)
  then textHeight := 0
  else textHeight := DrawText(Canvas.Handle, 'Wp', 2, r, DT_SINGLELINE or DT_NOCLIP or DT_CALCRECT);

  // Calc margin, icon offset & button size
  case TextLayout of
  ETextLayoutLeft, ETextLayoutRight:
    begin
      // button size
      w := FItemMargin.cx + FIconSize + FTextOffset + FTextWidth + FItemMargin.cx;
      h := FItemMargin.cy + Max(FIconSize, textHeight) + FItemMargin.cy;
      // icon offset
      if (TextLayout = ETextLayoutRight)
      then FIconOffset.X := FItemMargin.cx
      else FIconOffset.X := FItemMargin.cx + FTextWidth + FTextOffset;
      FIconOffset.Y := (h - FIconSize) div 2;
      // text rect
      if (TextLayout = ETextLayoutRight)
      then FTextRect := Bounds( FItemMargin.cx + FIconSize + FTextOffset, (h - textHeight) div 2, FTextWidth, textHeight )
      else FTextRect := Bounds( FItemMargin.cx, (h - textHeight) div 2, FTextWidth, textHeight );
    end;
  ETextLayoutTop, ETextLayoutBottom:
    begin
      // button size
      w := FItemMargin.cx + Max(FIconSize, FTextWidth) + FItemMargin.cx;
      h := FItemMargin.cy + FIconSize + FTextOffset + textHeight + FItemMargin.cy;
      // icon offset
      FIconOffset.X := (w - FIconSize) div 2;
      if (TextLayout = ETextLayoutBottom)
      then FIconOffset.Y := FItemMargin.cy
      else FIconOffset.Y := FItemMargin.cy + textHeight + FTextOffset;
      // text rect
      if (TextLayout = ETextLayoutBottom)
      then FTextRect := Bounds( FTextOffset, FItemMargin.cy + FIconSize + FTextOffset, w - 2*FTextOffset, textHeight )
      else FTextRect := Bounds( FTextOffset, FItemMargin.cy, w - 2*FTextOffset, textHeight );
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
  ToolTip.Cancel;
  FPressedIndex := AValue;

  if (FPressedIndex <> FHotIndex)
  then HotIndex := FPressedIndex;

  DrawItem(BitmapPanel, FHotIndex, True, FPressedIndex <> ITEM_NONE);
  UpdateWindow;
end;

procedure TLinkbarWcl.SetHotIndex(AValue: integer);
var
  Pt: TPoint;
  HA: TAlignment;
  VA: TVerticalAlignment;
begin
  if not IsItemIndex(AValue)
  then AValue := ITEM_NONE;

  if (FLockHotIndex)
     or (AValue = FHotIndex)
  then Exit;

  if (FHotIndex >= 0)
  then begin // restore pred selected item
    const r = Items[FHotIndex].Rect;
    BitBlt(BitmapPanel.Dc, r.Left, r.Top, r.Width, r.Height, BitmapSelected.Dc, 0, 0, SRCCOPY);
  end;

  FHotIndex := AValue;

  if (FHotIndex >= 0)
  then begin // store current item
    const r = Items[FHotIndex].Rect;
    BitBlt(BitmapSelected.Dc, 0, 0, r.Width, r.Height, BitmapPanel.Dc, r.Left, r.Top, SRCCOPY);
  end;

  DrawItem(BitmapPanel, FHotIndex, True, False); // draw current selected item

  UpdateWindow;

  // show hint
  if (TooltipShow)
     and (FHotIndex >= 0)
     and (not Items.IsSeparator(Items[FHotIndex]))
  then begin
    const r = Items[FHotIndex].Rect;
    case Align of
      EPanelAlignLeft:
        begin
          Pt.X := r.Right + TOOLTIP_OFFSET;
          Pt.Y := r.CenterPoint.Y;
          VA := taVerticalCenter;
          HA := taLeftJustify;
        end;
      EPanelAlignTop:
        begin
          Pt.X := r.CenterPoint.X;
          Pt.Y := r.Bottom + TOOLTIP_OFFSET;
          VA := taAlignBottom;
          HA := taCenter;
        end;
      EPanelAlignRight:
        begin
          Pt.X := r.Left - TOOLTIP_OFFSET;
          Pt.Y := r.CenterPoint.Y;
          VA := taVerticalCenter;
          HA := taRightJustify;
        end;
      EPanelAlignBottom:
        begin
          Pt.X := r.CenterPoint.X;
          Pt.Y := r.Top - TOOLTIP_OFFSET;
          VA := taAlignTop;
          HA := taCenter;
        end
      else begin
        HA := taLeftJustify;
        VA := taAlignBottom;
      end;
    end;
    MapWindowPoints(Handle, HWND_DESKTOP, Pt, 1);
    ToolTip.Activate(Pt, Items[FHotIndex].Caption, HA, VA);
  end
  else begin
    ToolTip.Cancel;
  end;
end;

procedure TLinkbarWcl.SetHotkeyInfo(AValue: THotkeyInfo);
begin
  if (FHotkeyInfo = AValue)
  then Exit;

  FHotkeyInfo := AValue;
  if (AutoHide)
  then RegisterHotkeyNotify(Handle, FHotkeyInfo)
  else UnregisterHotkeyNotify(Handle);
end;

procedure TLinkbarWcl.SetLayout(AValue: TPanelLayout);
begin
  if (FLayout = AValue)
  then Exit;

  FLayout := AValue;
  GlobalLayout := FLayout;

  //RecreateMainBitmap(Width, Height);
  //UpdateWindow;
end;

procedure TLinkbarWcl.SetAlign(AValue: TPanelAlign);
begin
  //if (FScreenEdge = AValue)
  //then Exit;

  FAlign := AValue;
  FDragAlign := FAlign;
  oAppBar.MonitorNum := FMonitorNum;
  oAppBar.Align := AValue;
end;

procedure TLinkbarWcl.SetSortAlphabetically(AValue: Boolean);
begin
  if (FSortAlphabetically = AValue)
  then Exit;

  FSortAlphabetically := AValue;
  TSettingsFile.Write(FSettingsFileName, INI_SORT_AB, FSortAlphabetically);

  if FSortAlphabetically
  then begin
    Items.Sort;
    RecreateMainBitmap(BitmapPanel.Width, BitmapPanel.Height);
    UpdateWindow;
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

procedure TLinkbarWcl.QuerySizingEvent(Sender: TObject; AVertical: Boolean; var AWidth, AHeight: Integer);
begin
  Items.Sizes.Button := ButtonSize;
  Items.Sizes.Separator := SeparatorWidth;
  Items.Sizes.Margin := FGripSize;
  Items.UpdateLines(AVertical, AWidth, AHeight);

  if (AVertical)
  then AWidth := ButtonSize.Width * Items.Lines.Count
  else AHeight := ButtonSize.Height * Items.Lines.Count;
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
  UpdateWindow(r);
end;

procedure TLinkbarWcl.QueryHideEvent(Sender: TObject; AEnabled: boolean);
begin
  FAutoHide := AEnabled;
end;

procedure TLinkbarWcl.UpdateBackgroundColor;
var lookmode: TLookMode;
begin
  lookmode.Color := FLook;
  lookmode.Transparency := FTransparencyMode;
  ThemeGetTaskbarColor(FSysBackgroundColor, lookmode);
end;

function TLinkbarWcl.GetBackgroundColor: Cardinal;
begin
  if (FUseBkgndColor)
  then Result := FBackgroundColor
  else Result := FSysBackgroundColor;
end;

procedure TLinkbarWcl.UpdateWindowSize;
var
  t, l, w, h: Integer;
begin
  Items.Sizes.Button := ButtonSize;
  Items.Sizes.Separator := SeparatorWidth;
  Items.Sizes.Margin := FGripSize;
  Items.UpdateLines(IsVertical(Align), Width, Height);

  t := Top;
  l := Left;
  w := Width;
  h := Height;

  if IsVertical(Align) then
  begin
    w := ButtonSize.Width * Items.Lines.Count;
    if (Align = EPanelAlignRight)
    then l := Left + Width - w;
  end else
  begin
    h := ButtonSize.Height * Items.Lines.Count;
    if (Align = EPanelAlignBottom)
    then t := Top + Height - h;
  end;

  RecreateMainBitmap(w, h);
  MoveWindow(Self.Handle, l, t, w, h, FALSE);
  UpdateWindow(Bounds(l, t, w, h));
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
    //CUSTOM_ABN_FULLSCREENAPP:
    //  begin
    //    oAppBar.AppBarFullScreenApp(Msg.LParam <> 0);
    //  end;
    // DWM Messages
    { TODO: Provide this message for Windows Vista
    WM_DWMWINDOWMAXIMIZE: {}
    (*
    WM_SIZE:
      begin
        Msg.Result := 0;
        if not FCreated then Exit;
        UpdateBlur;
      end; *)
    (*
    WM_SETFOCUS:
      begin
        {$IFDEF DEBUGUS}DebugusMessage('WM_SETFOCUS');{$ENDIF}
        Msg.Result := 0;
        FCanAutoHide := False;
        DoAutoShow;
      end;
    *)
    //WM_WINDOWPOSCHANGED:
    //  begin
        //Beep;
        //p := PWindowPos(Msg.LParam);
        //{$IFDEF DEBUGUS}DebugusMessage( Format('WPC: %d %d %d %d %d %d flags %s', [p.hwnd, p.hwndInsertAfter, p.x, p.y, p.cx, p.cy, GetSwpFlags(p.flags)]) );{$ENDIF}
    //  end;
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
        RecreateMainBitmap(BitmapPanel.Width, BitmapPanel.Height);
        UpdateWindow;

        if SameText(PChar(Msg.LParam), 'ImmersiveColorSet')
        then begin
          OutputDebugString('1');
          if Assigned(ToolTip)
          then ToolTip.ThemeChanged;
        end;

        Exit;
      end;
    CM_FONTCHANGED:
      begin
        inherited;
        if not FCreated then Exit;
        UpdateItemSizes;
        RecreateMainBitmap(BitmapPanel.Width, BitmapPanel.Height);
        UpdateWindow;
        Exit;
      end;
    WM_SYSCOLORCHANGE:
      begin
        inherited;
        if not FCreated then Exit;
        HotIndex := ITEM_NONE;
        RecreateMainBitmap(BitmapPanel.Width, BitmapPanel.Height);
        RecreateButtonBitmap(FButtonSize.Width, FButtonSize.Height);
        UpdateWindow;
        Exit;
      end;
    WM_DWMCOLORIZATIONCOLORCHANGED:
      begin
        Msg.Result := 0;
        if not FCreated then Exit;

        UpdateBackgroundColor;

        if IsWindows10
        then ThemeSetWindowAccentPolicy10(Handle, FTransparencyMode, BackgroundColor);

        // In Windows 8+ theme color may changed smoothly
        HotIndex := ITEM_NONE;
        RecreateMainBitmap(BitmapPanel.Width, BitmapPanel.Height); // <== THIS
        RecreateButtonBitmap(FButtonSize.Width, FButtonSize.Height);
        UpdateWindow;
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
    LM_CM_DELETE:
      begin
        DoDelete(FItemPopup);
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
     //and (FAutoShowMode = smHotkey)
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
    UpdateWindow;
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

procedure TLinkbarWcl.imCloseAllClick(Sender: TObject);
begin
  TLinkbarWcl.CloseAll;
end;

procedure TLinkbarWcl.imCloseClick(Sender: TObject);
begin
  StopDirWatch;
  Close;
end;

procedure TLinkbarWcl.imLockBarClick(Sender: TObject);
begin
  FLockLinkbar := not FLockLinkbar;
  TSettingsFile.Write(FSettingsFileName, INI_LOCK_BAR, FLockLinkbar);
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

procedure TLinkbarWcl.imNewSeparatorClick(Sender: TObject);
begin
  var item := TItemSeparator.Create;
  if (FItemPopup <> ITEM_NONE)
  then Items.Insert(FItemPopup, item)
  else Items.Add(item);
  UpdateWindowSize;
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
    case Align of
      EPanelAlignTop: r.Bottom := r.Top + ScaleDimension(AUTOHIDE_SIZE);
      EPanelAlignLeft: r.Right := r.Left + ScaleDimension(AUTOHIDE_SIZE);
      EPanelAlignRight: r.Left := r.Right - ScaleDimension(AUTOHIDE_SIZE);
      EPanelAlignBottom: r.Top := r.Bottom - ScaleDimension(AUTOHIDE_SIZE);
    end;
    FAfterAutoHideBound := r;
    MoveWindow(Handle, r.Left, r.Top, r.Width, r.Height, False);
    UpdateWindow(FAfterAutoHideBound);
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
     //(FAutoShowMode <> smHotKey)
  then begin
    FAutoHiden := False;
    MoveWindow(Handle, FBeforeAutoHideBound.Left, FBeforeAutoHideBound.Top,
      FBeforeAutoHideBound.Width, FBeforeAutoHideBound.Height, False);
    UpdateWindow(FBeforeAutoHideBound);
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
     and (FAutoShowMode = EAutoShowModeMouseHover)
  then DoDelayedAutoShow;
end;

procedure TLinkbarWcl.FormMouseLeave(Sender: TObject);
begin
  HotIndex := -1;
  if (FAutoShowMode = EAutoShowModeMouseHover) or FCanAutoHide
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
        if IsVertical(Align)
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
        if IsVertical(Align)
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
  part: Integer;
begin
  index := ItemIndexByPoint(AValue);

  if (index = ITEM_NONE)
  then part := -1
  else begin
    part := Items[index].GetDropPart(AValue, IsVertical(Align), FDragingItem);

    if (part = 1) and (index <> FDragIndex)
    then begin
      index := index + 1;
      part := -1;
    end;

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
    BitBlt(BitmapPanel.Dc, r.Left, r.Top, r.Width, r.Height, BitmapDropPosition.Dc, 0, 0, SRCCOPY);
  end;

  FItemDropPosition := index;

  if (FItemDropPosition <> ITEM_NONE) then
  begin
    r := GetItemDropRect(FItemDropPosition, part);
    _FLastDropRect := r;

    BitBlt(BitmapDropPosition.Dc, 0, 0, r.Width, r.Height, BitmapPanel.Dc, r.Left, r.Top, SRCCOPY);

    if (part = 0)
    then begin
      DrawBackground(BitmapPanel, r);
      ThemeDrawHover(BitmapPanel, Align, r);
      DrawItem(BitmapPanel, FItemDropPosition, False, False, False);
    end
    else begin
      var gpDrawer: IGPGraphics := TGpGraphics.Create(BitmapPanel.Dc);
      var gpBrush: IGPSolidBrush := TGPSolidBrush.Create(TGPColor.Create($ff000000));
      gpDrawer.FillRectangle(gpBrush, TGPRect.Create(r));
      gpBrush.Color := TGPColor.Create($ffffffff);
      r.Inflate(-1,-1,-1,-1);
      gpDrawer.FillRectangle(gpBrush, TGPRect.Create(r));
    end;
  end;

  UpdateWindow;
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
    if (FItemDropPosition = ITEM_NONE)
    then begin
      if (Items.Count > 0)
         and ((Items.First.Rect.TopLeft.X < pt.X) or (Items.First.Rect.TopLeft.Y < pt.Y))
      then Items.Move(FDragIndex, 0)
      else Items.Move(FDragIndex, Items.Count-1);
    end
    else begin
      if (FItemDropPosition <= FDragIndex)
      then Items.Move(FDragIndex, FItemDropPosition)
      else Items.Move(FDragIndex, FItemDropPosition-1);
    end;
    SetDropPosition( Point(-1, -1) );
    UpdateWindowSize;
  end
  else tmrUpdate.Enabled := True;
end;

procedure TLinkbarWcl.QueryDragImage(out ABitmap: THBitmap; out AOffset: TPoint);
var ItemRect: TRect;
begin
  if (not StyleServices.Enabled)
  then begin
    ABitmap := nil;
    Exit;
  end;

  ItemRect := Items[FDragIndex].Rect;

  ABitmap := THBitmap.Create(32);
  ABitmap.SetSize(ItemRect.Width, ItemRect.Height);
  // Drag Image will faded when size > 300 px (DPI independent)
  DrawItem(ABitmap, FDragIndex, False, True, False, True);

  AOffset := Point(FMousePosDown.X - ItemRect.Left, FMousePosDown.Y - ItemRect.Top);
end;

var
  _LastModifiedItemHash: Cardinal = 0;
  _RenamedOldItemHash: Cardinal = 0;

procedure TLinkbarWcl.DirWatchChange(const Sender: TObject; const AAction: TWatchAction; const AFileName: string);

  function FindItemByHash(AHash: Cardinal): Integer;
  begin
    for var i := 0 to Items.Count-1
    do if Items[i].Hash = AHash
       then Exit(i);
    Result := ITEM_NONE;
  end;

var ext: string;
    hash: Cardinal;
    index: integer;
begin
  inherited;
  // Skip unsupported files
  ext := ExtractFileExt(AFileName);
  if not MatchText(ext, ES_ARRAY) then Exit;

  tmrUpdate.Enabled := False;

  case AAction of
  waAdded:
  begin
    var item := TItemShortcut.Create;
    item.Hash := StrToHash(AFileName);
    item.FileName := WorkDir + AFileName;
    item.NeedLoad := True;
    if (FItemDropPosition = ITEM_NONE)
    then Items.Add(item)
    else Items.Insert(FItemDropPosition, item);
  end;
  waRemoved:
  begin
    index := FindItemByHash(StrToHash(AFileName));
    if (index <> ITEM_NONE)
    then DeleteItem(index);
  end;
  waModified:
  begin
    hash := StrToHash(AFileName);
    if (_LastModifiedItemHash <> hash)
    then begin
      _LastModifiedItemHash := hash;
      index := FindItemByHash(hash);
      if (index <> ITEM_NONE)
      then Items[index].NeedLoad := True;
    end;
  end;
  waRenamedOld:
  begin
    _RenamedOldItemHash := StrToHash(AFileName);
  end;
  waRenamedNew:
  begin
    index := FindItemByHash(_RenamedOldItemHash);
    if (index <> ITEM_NONE)
    then begin
      var item := Items[index];
      item.FileName := WorkDir + AFileName;
      item.NeedLoad := True;
      _RenamedOldItemHash := 0;
    end;
  end;
  end;

  tmrUpdate.Enabled := True;
end;

procedure TLinkbarWcl.tmrUpdateTimer(Sender: TObject);
begin
  tmrUpdate.Enabled := False;

  for var i := Items.Count-1 downto 0 do
  begin
    const item = Items[i];
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
  GlobalAeroGlassEnabled := FEnableAeroGlass;
  ThemeSetWindowAttribute78(Handle);
  UpdateBlur;
end;

procedure TLinkbarWcl.SetTransparencyMode(AValue: TTransparencyMode);
begin
  if (not IsWindows10)
     //or (AValue = FTransparencyMode)
  then Exit;
  FTransparencyMode := AValue;
  UpdateBackgroundColor;
  ThemeSetWindowAccentPolicy10(Handle, FTransparencyMode, BackgroundColor);
end;

procedure TLinkbarWcl.SetLook(AValue: TLook);
begin
  if (not IsWindows10)
     //or (AValue = FTransparencyMode)
  then Exit;

  GlobalLook := AValue;

  BitmapButton.Clear;
  ThemeDrawButton(BitmapButton, BitmapButton.Bound, False);

  FLook := AValue;
  UpdateBackgroundColor;
  ThemeSetWindowAccentPolicy10(Handle, FTransparencyMode, BackgroundColor);
end;

procedure TLinkbarWcl.SetUseBkgndColor(AValue: Boolean);
begin
  if (AValue = FUseBkgndColor)
  then Exit;
  FUseBkgndColor := AValue;
  UpdateBackgroundColor;
end;

end.
