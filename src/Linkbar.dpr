program Linkbar;

{$IFNDEF DEBUG}
  {$IFOPT D-}{$WEAKLINKRTTI ON}{$ENDIF}
  {$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}
{$ENDIF}

{$i linkbar.inc}

uses
  Windows,
  SysUtils,
  Forms,
  Classes,
  Dialogs,
  System.IOUtils,
  Types,
  System.UITypes,
  ActiveX,
  Linkbar.Consts,
  Linkbar.OS,
  mUnit in 'mUnit.pas',
  Linkbar.Newbar,
  Linkbar.Shell,
  Linkbar.L10n,
  Linkbar.SettingsForm in 'Linkbar.SettingsForm.pas' {FrmProperties},
  Linkbar.Graphics in 'Linkbar.Graphics.pas',
  Linkbar.Themes in 'Linkbar.Themes.pas',
  Linkbar.Settings in 'Linkbar.Settings.pas';

{$R *.res}

procedure RunAsNewLinkbar;
begin
  Application.Initialize;
  Application.MainFormOnTaskBar := True;
  Application.CreateForm(TBarCreatorWCl, BarCreatorWCl);
  Application.Run;
end;

var dn, cmd: string;
    files: TStringDynArray;
    sl: TStringList;
    i, delay: Integer;
    CreatedPanels: Integer;
begin
{$IFDEF DEBUG}
  ReportMemoryLeaksOnShutdown := True;
{$ENDIF}

  { Check supported OS }
  if not IsMinimumSupportedOS
  then begin
    MessageDlg('Sorry :('
      + #13 + 'Linkbar not support your operating system.'
      + #13
      + #13 + 'Minimum supported client: Windows 7'
      + #13 + 'Minimum supported server: Windows Server 2008 R2',
      mtWarning, [mbClose], 0);
    Exit;
  end;

  { Check CMD Delay start }
  delay := 0;
  if FindCmdLineSwitch(CLK_DELAY, cmd, True)
     and TryStrToInt(cmd, delay)
     and (delay > 0)
  then Sleep(delay);

  { Check CMD Language }
  FindCmdLineSwitch(CLK_LANG, cmd, True);
  L10nLoad(ExtractFilePath(ParamStr(0)) + DN_LOCALES, cmd);

  { Check CMD New Linkbar }
  if FindCmdLineSwitch(CLK_NEW, True)
  then begin
    RunAsNewLinkbar;
    Exit;
  end;

  if FindCmdLineSwitch(CLK_FILE, FSettingsFileName, True)
     and SameText(ExtractFileExt(FSettingsFileName), EXT_LBR)
     and TFile.Exists(FSettingsFileName)
  then begin
    // delete profile if working directory invalid
    if not TSettings.IsValid(FSettingsFileName)
    then begin
      TFile.Delete(FSettingsFileName);
      Exit;
    end;
    OleInitialize(nil);
    Application.Initialize;
    Application.MainFormOnTaskBar := True;
    Application.CreateForm(TLinkbarWcl, LinkbarWcl);
    Application.Run;
    OleUninitialize;
  end
  else begin
    sl := TStringList.Create;
    try
      // Find *.lbr in Application folder
      dn := ExtractFilePath(ParamStr(0)) + DN_SHARED_BARS;
      if DirectoryExists(dn)
      then begin
        files := TDirectory.GetFiles(dn, MASK_LBR, TSearchOption.soTopDirectoryOnly);
        for i := Low(files) to High(files)
        do sl.Add(files[i]);
      end;

      // Find *.lbr in Roaming folder
      dn := GetLinkbarRoamingFolderPath + DN_USER_BARS;
      if DirectoryExists(dn)
      then begin
        files := TDirectory.GetFiles(dn, MASK_LBR, TSearchOption.soTopDirectoryOnly);
        for i := Low(files) to High(files)
        do sl.Add(files[i]);
      end;

      CreatedPanels := 0;
      for i := 0 to sl.Count-1 do
      begin
        // delete profile if working directory invalid
        if not TSettings.IsValid(sl[i])
        then begin
          TFile.Delete(sl[i]);
          Continue;
        end;

        cmd := LBCreateCommandParam(CLK_FILE, sl[i]);
        if (Locale <> '')
        then cmd := LBCreateCommandParam(CLK_LANG, Locale) + cmd;

        LBCreateProcess(ParamStr(0), cmd);
        Inc(CreatedPanels);
      end;

      if (CreatedPanels = 0)
      then RunAsNewLinkbar;

    finally
      sl.Free;
    end;
  end;
end.
