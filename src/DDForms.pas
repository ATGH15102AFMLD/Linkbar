{*******************************************************}
{          Linkbar - Windows desktop toolbar            }
{            Copyright (c) 2010-2018 Asaq               }
{*******************************************************}

unit DDForms;

{$i linkbar.inc}

interface

uses
  Windows, SysUtils, Classes, Linkbar.Graphics, Forms, ActiveX, ShlObj, CommCtrl,
  Messages, Cromis.DirectoryWatch;

const
  LM_STOPDIRWATCH = WM_USER + 33;

type

  TLinkbarCustomFrom = class abstract (TForm, IDropTarget)
  private
    FPanelName: string;
    FPathExe: string;
    FWorkDir: string;
    FWorkDirPidl: PItemIDList;
    FIsDragDrop: Boolean;
    FIsDragSelf: Boolean;
    FDirWatchDog: TDirectoryWatch;
    procedure SetWorkDir(AValue: string);
  private
    FDragHelper: IDropTargetHelper;
    FDragObject: IDataObject;
    FDragKeyState: Integer;
    FDragTargetPidl: PItemIDList;
    FDragTargetTarget: IDropTarget;
    // IDropTarget
    function DragEnter(const dataObj: IDataObject; grfKeyState: Longint;
      pt: TPoint; var dwEffect: Longint): HResult; stdcall;
    function DragOver(grfKeyState: Longint; pt: TPoint;
      var dwEffect: Longint): HResult; stdcall;
    function DragLeave: HResult; stdcall;
    function Drop(const dataObj: IDataObject; grfKeyState: Longint; pt: TPoint;
      var dwEffect: Longint): HResult; stdcall;
  protected
    // Drop Traget
    procedure DoDragEnter(const pt: TPoint); virtual; abstract;
    procedure DoDragOver(const pt: TPoint; var ppidl: PItemIDList); virtual; abstract;
    procedure DoDragLeave; virtual; abstract;
    procedure DoDrop(const pt: TPoint); virtual; abstract;
    // Drag Source
    procedure QueryDragImage(out ABitmap: THBitmap; out AOffset: TPoint); virtual; abstract;
  protected
    procedure DirWatchChange(const Sender: TObject; const AAction: TWatchAction;
      const AFileName: string); virtual;
  procedure DirWatchError(const Sender: TObject; const ErrorCode: Integer;
      const ErrorMessage: string); virtual;
  protected
    function CreateDragImage(out ASdi: TShDragImage): Boolean;
    function GetDataObjectOfFileWithCuteIcon(AWnd: HWND;
      const AFileName: string; out pdo: IDataObject): HResult;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure StopDirWatch;
    procedure DragFile(const AFileName: string);
    property IsDragDrop: Boolean read FIsDragDrop;
    property PanelName: string read FPanelName;
    property PathExe: string read FPathExe;
    property WorkDir: string read FWorkDir write SetWorkDir;
    property WorkDirPidl: PItemIDList read FWorkDirPidl;
  end;

implementation

uses
  ComObj, Linkbar.Shell;

////////////////////////////////////////////////////////////////////////////////
// TLinkbarCustomFrom
////////////////////////////////////////////////////////////////////////////////

constructor TLinkbarCustomFrom.Create(AOwner: TComponent);
begin
  inherited;
  FPathExe := ExtractFilePath( Application.ExeName );
  FWorkDir := '';
  // IDropTargetHelper
  // minimum support client: Windows 2000 Professional, Windows XP
  // minimum support server: Windows Server 2003
  if Succeeded(CoCreateInstance(CLSID_DragDropHelper, nil, CLSCTX_ALL,
    IID_IDropTargetHelper, FDragHelper))
  then OleCheck(RegisterDragDrop(Handle, Self));
  FIsDragDrop := False;

  FDragTargetPidl := nil;
  FDragObject := nil;
  FDragTargetTarget := nil;
end;

destructor TLinkbarCustomFrom.Destroy;
begin
  OleCheck(RevokeDragDrop(Handle));

  if Assigned(FDragTargetTarget)
  then FDragTargetTarget.DragLeave;
  FDragTargetTarget := nil;
  FDragTargetPidl := nil;
  FDragObject := nil;

  inherited;
end;

procedure TLinkbarCustomFrom.StopDirWatch;
begin
  if Assigned(FDirWatchDog)
  then begin
    FDirWatchDog.Free;
    FDirWatchDog := nil;
  end;
end;

{ TLinkbarCustomFrom - Drop }

function DragKeyStateToDragEffect(const AKeyState: Integer; const ADefResult: Integer = -1): Integer;
begin
  if ADefResult <> -1
  then Result := ADefResult
  else Result := DROPEFFECT_LINK or DROPEFFECT_COPY or DROPEFFECT_MOVE;
  if (AKeyState and MK_ALT) <> 0
  then Result := DROPEFFECT_LINK;
  if (AKeyState and MK_CONTROL) <> 0
  then Result := DROPEFFECT_COPY;
  if (AKeyState and MK_SHIFT) <> 0
  then Result := DROPEFFECT_MOVE;
end;

function TLinkbarCustomFrom.DragEnter(const dataObj: IDataObject; grfKeyState: Integer;
  pt: TPoint; var dwEffect: Integer): HResult;
// NOTE:
// DROPIMAGE_INVALID - only red circle
// DROPIMAGE_NONE - red circle with description
var
  lpPoints: TPoint;
  lppidl: PItemIDList;
  pFolder: IShellFolder;
  pidlChild: PItemIDList;
begin
  Result := S_FALSE;

  FIsDragDrop := True;
  FDragObject := dataObj;

  lpPoints := pt;
  MapWindowPoints(HWND_DESKTOP, Handle, lpPoints, 1);
  DoDragEnter(lpPoints);

  lppidl := nil;
  DoDragOver(lpPoints, lppidl);
  if lppidl = nil then Exit;

  if FDragTargetPidl = FWorkDirPidl
  then begin
    if FIsDragSelf
    then dwEffect := DROPEFFECT_MOVE
    else dwEffect := DragKeyStateToDragEffect(FDragKeyState, DROPEFFECT_LINK)
  end;

  if (lppidl <> FDragTargetPidl)
  then begin
    FDragTargetPidl := lppidl;
    if Succeeded( SHBindToParent(FDragTargetPidl, IID_IShellFolder, Pointer(pFolder), pidlChild) )
    then try
      if Succeeded( pFolder.GetUIObjectOf(Handle, 1, pidlChild, IDropTarget, nil, FDragTargetTarget) )
      then begin
        dwEffect := DROPEFFECT_COPY or DROPEFFECT_MOVE or DROPEFFECT_LINK;
        FDragTargetTarget.DragEnter(dataObj, grfKeyState, pt, dwEffect);
      end;
    finally
      pFolder := nil;
    end;
  end;

  if Assigned(FDragHelper)
  then FDragHelper.DragEnter(Handle, dataObj, pt, dwEffect);

  Result := S_OK;
end;

function TLinkbarCustomFrom.DragLeave: HResult;
begin
  if Assigned(FDragHelper)
  then FDragHelper.DragLeave;

  if Assigned(FDragTargetTarget)
  then FDragTargetTarget.DragLeave;
  FDragTargetTarget := nil;
  FDragTargetPidl := nil;
  FDragObject := nil;

  DoDragLeave;
  FIsDragDrop := False;

  Result := S_OK;
end;

function TLinkbarCustomFrom.DragOver(grfKeyState: Integer; pt: TPoint;
  var dwEffect: Integer): HResult;
var lpPoints: TPoint;
    lppidl: PItemIDList;
    pidlChild: PItemIDList;
    pFolder: IShellFolder;
begin
  Result := S_FALSE;
  FDragKeyState := grfKeyState;

  lpPoints := pt;
  MapWindowPoints(HWND_DESKTOP, Handle, lpPoints, 1);
  lppidl := nil;
  DoDragOver(lpPoints, lppidl);
  if lppidl = nil then Exit;

  if FDragTargetPidl = FWorkDirPidl
  then begin
    if FIsDragSelf
    then dwEffect := DROPEFFECT_MOVE
    else dwEffect := DragKeyStateToDragEffect(FDragKeyState, DROPEFFECT_LINK)
  end;

  if (lppidl <> FDragTargetPidl)
  then begin
    FDragTargetPidl := lppidl;

    if Assigned(FDragTargetTarget)
    then FDragTargetTarget.DragLeave;
    FDragTargetTarget := nil;

    if Succeeded( SHBindToParent(FDragTargetPidl, IID_IShellFolder, Pointer(pFolder), pidlChild) )
    then try
      if Succeeded( pFolder.GetUIObjectOf(Handle, 1, pidlChild, IDropTarget, nil, FDragTargetTarget) )
      then begin
        dwEffect := DROPEFFECT_COPY or DROPEFFECT_MOVE or DROPEFFECT_LINK;
        FDragTargetTarget.DragEnter(FDragObject, grfKeyState, pt, dwEffect);
      end;
    finally
      pFolder := nil;
    end;
  end;

  if Assigned(FDragTargetTarget)
  then FDragTargetTarget.DragOver(grfKeyState, pt, dwEffect);

  if Assigned(FDragHelper)
  then FDragHelper.DragOver(pt, dwEffect);

  FDragKeyState := grfKeyState;

  Result := S_OK;
end;

function TLinkbarCustomFrom.Drop(const dataObj: IDataObject; grfKeyState: Integer;
  pt: TPoint; var dwEffect: Integer): HResult;
var lpPoints: TPoint;
    pAsync: IAsyncOperation;
begin
  if Assigned(FDragHelper)
  then FDragHelper.Drop(dataObj, pt, dwEffect);

  if FIsDragSelf
  then begin
    dwEffect := DROPEFFECT_NONE;
    if Assigned(FDragTargetTarget)
    then FDragTargetTarget.DragLeave;
  end
  else begin
    if FDragTargetPidl = FWorkDirPidl
    then dwEffect := DragKeyStateToDragEffect(FDragKeyState, DROPEFFECT_LINK);

    if Assigned(FDragTargetTarget)
    then begin
      if Succeeded(dataObj.QueryInterface(IAsyncOperation, pAsync))
      then pAsync.SetAsyncMode(False);
      FDragTargetTarget.Drop(dataObj, FDragKeyState, pt, dwEffect);
    end;
  end;

  FDragTargetTarget := nil;
  FDragTargetPidl := nil;
  FDragObject := nil;

  lpPoints := pt;
  MapWindowPoints(HWND_DESKTOP, Handle, lpPoints, 1);
  DoDrop(lpPoints);

  Result := S_OK;
  FIsDragDrop := False;
end;

{ TLinkbarCustomFrom - Drag }

function TLinkbarCustomFrom.CreateDragImage(out ASdi: TShDragImage): Boolean;
var
  bmp: THBitmap;
  pt: TPoint;
  DC: HDC;
  hbmPrev: HBITMAP;
begin
  QueryDragImage(bmp, pt);

  if not Assigned(bmp) then Exit(False);

  FillChar(ASdi, SizeOf(ASdi), 0);
  ASdi.sizeDragImage.cx := bmp.Width;
  ASdi.sizeDragImage.cy := bmp.Height;
  ASdi.ptOffset := pt;
  ASdi.crColorKey := CLR_NONE;

  ASdi.hbmpDragImage := CreateBitmap(ASdi.sizeDragImage.cx,
    ASdi.sizeDragImage.cy, 1, 32, nil);
  if (ASdi.hbmpDragImage <> 0)
  then begin
    DC := CreateCompatibleDC(HWND_DESKTOP);
    hbmPrev := SelectObject(DC, ASdi.hbmpDragImage);
    BitBlt(DC, 0, 0, ASdi.sizeDragImage.cx, ASdi.sizeDragImage.cy,
      bmp.Dc, 0, 0, SRCCOPY);
    SelectObject(DC, hbmPrev);
    DeleteDC(DC);
  end;
  bmp.Free;
  Result := (ASdi.hbmpDragImage <> 0);
end;

function TLinkbarCustomFrom.GetDataObjectOfFileWithCuteIcon(AWnd: HWND;
  const AFileName: string; out pdo: IDataObject): HResult;
var
  pdsh: IDragSourceHelper;
  pdsh2: IDragSourceHelper2;
  sdi: TShDragImage;
begin
  Result := GetUIObjectOfFile(AWnd, AFileName, IDataObject, pdo);
  if Succeeded(Result) then
  begin
    // IDragSourceHelper2
    // minimum support client: Windows Vista
    // minimum support server: Windows Server 2008
    Result := CoCreateInstance(CLSID_DragDropHelper, nil, CLSCTX_ALL,
      IID_IDragSourceHelper2, pdsh2);
    if Succeeded(Result)
    then begin
      if CreateDragImage(sdi)
      then begin
        pdsh2.SetFlags(DSH_ALLOWDROPDESCRIPTIONTEXT);
        Result := pdsh2.InitializeFromBitmap(@sdi, pdo);
        DeleteObject(sdi.hbmpDragImage);
      end else
        Result := S_FALSE;
      Exit;
    end;
    // IDragSourceHelper
    // minimum support client: Windows 2000 Professional, Windows XP
    // minimum support server: Windows Server 2003
    Result := CoCreateInstance(CLSID_DragDropHelper, nil, CLSCTX_ALL,
      IID_IDragSourceHelper, pdsh);
    if Succeeded(Result)
    then begin
      if CreateDragImage(sdi)
      then begin
        Result := pdsh.InitializeFromBitmap(@sdi, pdo);
        DeleteObject(sdi.hbmpDragImage);
      end else
        Result := S_FALSE;
      Exit;
    end;
  end;
end;

procedure TLinkbarCustomFrom.DragFile(const AFileName: string);
var
  dataObj: IDataObject;
  dragEffect, supportEffects: DWORD;
begin
  if Succeeded( GetDataObjectOfFileWithCuteIcon(Handle, AFileName, dataObj) )
  then begin
    dragEffect := DROPEFFECT_NONE;
    supportEffects := DROPEFFECT_LINK or DROPEFFECT_COPY or DROPIMAGE_MOVE;
    FIsDragSelf := True;
    SHDoDragDrop(0, dataObj, nil, supportEffects, dragEffect);
    FIsDragSelf := False;
    // If DropTarget can't move the file it copies it and return DROPEFFECT_MOVE
    if (dragEffect and DROPEFFECT_MOVE) <> 0
    then begin
      DeleteFile(AFileName);
    end;
  end;
end;

function DoGetFileName(FileName: String): string;
var SeparatorIdx: Integer;
begin
  Result := '';
  if (FileName <> '')
  then begin
    SeparatorIdx := LastDelimiter('\/:', FileName);
    // cut the file name on the right of the separator
    if SeparatorIdx > 0 then
      Result := Copy(FileName, SeparatorIdx + 1, Length(FileName) - SeparatorIdx)
    else
      Result := FileName;
  end;
end;

procedure TLinkbarCustomFrom.SetWorkDir(AValue: string);
var
  lstr: String;
  lsfgao: DWORD;
begin
  lstr := ExpandFileName(IncludeTrailingPathDelimiter(AValue));
  if lstr = FWorkDir then Exit;

  FWorkDir := lstr;

  SHParseDisplayName(PChar(FWorkDir), nil, FWorkDirPidl, 0, lsfgao);

  FPanelName := DoGetFileName( ExcludeTrailingPathDelimiter(FWorkDir) );

  if Assigned(FDirWatchDog)
  then FDirWatchDog.Free;

  FDirWatchDog := TDirectoryWatch.Create;
  FDirWatchDog.Directory := FWorkDir;
  FDirWatchDog.WatchSubTree := False;
  FDirWatchDog.WatchOptions := [woFileName, woLastWrite];
  FDirWatchDog.OnNotify := DirWatchChange;
  FDirWatchDog.OnError := DirWatchError;
  FDirWatchDog.Start;
end;

procedure TLinkbarCustomFrom.DirWatchChange(const Sender: TObject;
  const AAction: TWatchAction; const AFileName: string);
begin
end;

procedure TLinkbarCustomFrom.DirWatchError(const Sender: TObject;
  const ErrorCode: Integer; const ErrorMessage: string);
begin
end;

end.
