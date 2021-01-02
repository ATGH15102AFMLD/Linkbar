{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{            Copyright (c) 2010-2021 Asaq               }
{*******************************************************}

unit Linkbar.Consts;

{$i linkbar.inc}

interface

uses Windows, Controls, Winapi.Messages;

type
  TItemOrder = (EItemOrderLeftToRight, EItemOrderUpToDown);

  TPanelAlign = (EPanelAlignLeft, EPanelAlignTop, EPanelAlignRight, EPanelAlignBottom);

  TPanelLayout = (EPanelLayoutLeft, EPanelLayoutCenter, EPanelLayoutRight);

  TTextLayout = (ETextLayoutNone, ETextLayoutLeft, ETextLayoutTop, ETextLayoutRight, ETextLayoutBottom);

  TAutoShowMode = (EAutoShowModeMouseHover, EAutoShowModeMouseClickLeft, EAutoShowModeMouseClickRight);

  TJumplistShowMode = (EJumplistShowModeDisabled, EJumplistShowModeMouseClickRight);

  TLook = (ELookLight, ELookDark, ELookAccent, ELookCustom);

  TTransparencyMode = (tmOpaque = 0, tmTransparent = 1, tmGlass = 2, tmDisabled = 3);

  TSeparatorStyle = (ESeparatorStyleBar, ESeparatorStyleSpace);

const

  LM_DOAUTOHIDE = WM_USER + 66;

  APP_ID_LINKBAR  = '991E87F9787C468E8594072D75A476C7';
  APP_NAME_LINKBAR = 'Linkbar';
  URL_WEB = 'https://sourceforge.net/projects/linkbar/';
  URL_EMAIL = 'linkbar@yandex.ru';
  URL_GITHUB = 'https://github.com/ATGH15102AFMLD/Linkbar';
  URL_WINDOWS_HOTKEY = 'https://support.microsoft.com/en-ie/help/12445/windows-keyboard-shortcuts';

  // Supported extentions
  ES_ARRAY: array[0..2] of string = ('.lnk', '.url', '.website');

  CLK_LANG     = 'l';
  CLK_FILE     = 'f';
  CLK_NEW      = 'n';
  CLK_DELAY    = 'd';
  CLK_CLOSEALL = 'ca';

  DN_SHARED_BARS = 'Shared bars\';
  DN_USER_BARS = 'User bars\';
  DN_LOCALES = 'Locales\';
  EXT_LBR = '.lbr';
  MASK_LBR = '*' + EXT_LBR;

  AUTOHIDE_SIZE = 2;

  ICON_SIZE_MIN   = 16;
  ICON_SIZE_MAX   = 256;

  MARGIN_MIN      = 0;
  MARGIN_MAX      = 64;

  TEXT_OFFSET_MIN = 0;
  TEXT_OFFSET_MAX = 64;

  TEXT_WIDTH_MIN  = 16;
  TEXT_WIDTH_MAX  = 512;

  GLOW_SIZE_MIN   = 0;
  GLOW_SIZE_MAX   = 16;

  JUMPLIST_RECENTMAX_MIN = 0;
  JUMPLIST_RECENTMAX_MAX = 60;

  CORNER_GAP_WIDTH_MIN = 0;
  CORNER_GAP_WIDTH_MAX = 512;

  GRIP_SIZE       = 12;
  TOOLTIP_OFFSET  = 8;

  DROP_INDICATOR_SIZE = 4;
  DROP_INDICATOR_PADDING_DIV = 8;
  TEXTALIGN: array[TTextLayout] of Cardinal = (0, DT_RIGHT, DT_CENTER, DT_LEFT, DT_CENTER);

  SEPARATOR_WIDTH_MIN = 2;
  SEPARATOR_WIDTH_MAX = 256;

  PANEL_DRAG_THRESHOLD: Double = 5.0;

  ITEM_NONE = -1;
  ITEM_ALL  = -1;

  TIMER_AUTO_HIDE_DELAY = 300;

  DEF_AUTOHIDE                  = False;
  DEF_AUTOHIDE_TRANSPARENCY     = False;
  DEF_AUTOHIDE_SHOWMODE         = Low(TAutoShowMode);
  DEF_AUTOHIDE_HOTKEY           = '$0007004C'; // Shift+Ctrl+Alt+L //((MOD_SHIFT or MOD_CONTROL or MOD_ALT) shl 16) or Ord('L');
  DEF_DIR_LINKS                 = '.\links';
  DEF_ITEMS_ALIGN               = EPanelLayoutLeft;
  DEF_EDGE                      = EPanelAlignTop;
  DEF_TOOLTIP_SHOW              = True;
  DEF_ICON_SIZE                 = 32;
  DEF_ISLIGHT                   = False;
  DEF_ITEM_ORDER                = EItemOrderLeftToRight;
  DEF_LOCK_BAR                  = False;
  DEF_MARGINX                   = 4;
  DEF_MARGINY                   = 4;
  DEF_TEXT_LAYOUT               = ETextLayoutNone;
  DEF_TEXT_OFFSET               = 4;
  DEF_TEXT_WIDTH                = 64;
  DEF_AUTOSHOW_DELAY            = 0;
  DEF_SORT_AB                   = False;
  DEF_BKGCOLOR                  = $00000000;
  DEF_TXTCOLOR                  = $00000000;
  DEF_USEBKGCOLOR               = False;
  DEF_USETXTCOLOR               = True;
  DEF_GLOWSIZE                  = 12;
  DEF_ENABLE_AG                 = False;
  DEF_JUMPLIST_SHOWMODE         = EJumplistShowModeMouseClickRight;
  DEF_JUMPLIST_RECENTMAX        = 16;
  DEF_STAYONTOP                 = True;
  DEF_COLORMODE                 = ELookAccent;
  DEF_TRANSPARENCYMODE          = tmGlass;
  DEF_CORNERGAP_WIDTH           = 0;
  DEF_SEPARATOR_WIDTH           = 16;
  DEF_SEPARATOR_STYLE           = ESeparatorStyleBar;

  // INI sections
  INI_SECTION_MAIN              = 'Main';                                       { Main }
  INI_SECTION_DEV               = 'Dev';                                        { Developer }
  // INI fields
  INI_AUTOHIDE                  = 'autohide';
  INI_AUTOHIDE_TRANSPARENCY     = 'autohidetransparency';
  INI_AUTOHIDE_SHOWMODE         = 'autohideshowmode';
  INI_AUTOHIDE_HOTKEY           = 'autohidehotkey';
  INI_DIR_LINKS                 = 'dirlinks';
  INI_ITEMS_ALIGN               = 'itemsalign';
  INI_EDGE                      = 'Edge';
  INI_TOOLTIP_SHOW              = 'tooltipshow';
  INI_ICON_SIZE                 = 'iconsize';
  INI_ISLIGHT                   = 'usestylecombined';
  INI_ITEM_ORDER                = 'itemorder';
  INI_LOCK_BAR                  = 'lockbar';
  INI_MARGINX                   = 'marginx';
  INI_MARGINY                   = 'marginy';
  INI_MONITORNUM                = 'monitornum';
  INI_TEXT_LAYOUT               = 'textlayout';
  INI_TEXT_OFFSET               = 'textoffset';
  INI_TEXT_WIDTH                = 'textwidth';
  INI_AUTOSHOW_DELAY            = 'autoshowdelay';
  INI_SORT_AB                   = 'sortab';
  INI_USEBKGCOLOR               = 'usebgcolor';
  INI_BKGCOLOR                  = 'bgcolor';                                    { Background color }
  INI_USETXTCOLOR               = 'usetxtcolor';
  INI_TXTCOLOR                  = 'txtcolor';                                   { Text color }
  INI_GLOWSIZE                  = 'glowsize';
  INI_JUMPLIST_SHOWMODE         = 'jumplistshowmode';
  INI_JUMPLIST_RECENTMAX        = 'jumplistrecentmaxitems';
  INI_STAYONTOP                 = 'stayontop';
  INI_COLORMODE                 = 'colormode';
  INI_TRANSPARENCYMODE          = 'look';
  INI_ENABLE_AG                 = 'enableaeroglass';
  INI_CORNER1GAP_WIDTH          = 'corner1gapwidth';
  INI_CORNER2GAP_WIDTH          = 'corner2gapwidth';
  INI_SEPARATOR_WIDTH           = 'separatorwidth';
  INI_SEPARATOR_STYLE           = 'separatorstyle';

  LINKSLIST_FILE_NAME  = 'list';

var
  GlobalLayout:           TPanelLayout = DEF_ITEMS_ALIGN;
  GlobalLook:             TLook        = DEF_COLORMODE;
  GlobalAeroGlassEnabled: Boolean      = DEF_ENABLE_AG;

implementation

end.
