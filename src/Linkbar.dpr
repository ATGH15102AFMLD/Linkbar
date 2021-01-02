{$IFDEF DEBUG}
// JCL_DEBUG_EXPERT_GENERATEJDBG OFF
// JCL_DEBUG_EXPERT_INSERTJDBG OFF
// JCL_DEBUG_EXPERT_DELETEMAPFILE OFF
{$ENDIF}

program Linkbar;

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
{$IFDEF DEBUG}
  Linkbar.ExceptionDialog,
{$ENDIF}
  Linkbar.Newbar,
  Linkbar.Shell,
  Linkbar.L10n,
  Linkbar.SettingsForm in 'Linkbar.SettingsForm.pas' {FrmProperties},
  Linkbar.Graphics in 'Linkbar.Graphics.pas',
  Linkbar.Theme in 'Linkbar.Theme.pas',
  Linkbar.DarkTheme in 'Linkbar.DarkTheme.pas',
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
      + #13 + 'Linkbar doesn''t support your operating system.'
      + #13
      + #13 + 'Minimum supported client: Windows Vista'
      + #13 + 'Minimum supported server: Windows Server 2008 R2',
      mtWarning, [mbClose], 0);
    Exit;
  end;

  { Check CMD Delay start }
  delay := 0;
  if FindCmdLineSwitch(CLK_DELAY, cmd, True)
     and TryStrToInt(cmd, delay)
     and (delay > 0) {and (delay < INFINITE)}
  then Sleep(delay);

  InitDarkMode;
  AllowDarkModeForApp(true);

  { Check CMD Language }
  FindCmdLineSwitch(CLK_LANG, cmd, True);
  L10nLoad(ExtractFilePath(ParamStr(0)) + DN_LOCALES, cmd);

  { Check CMD New Linkbar }
  if FindCmdLineSwitch(CLK_NEW, True)
  then begin
    RunAsNewLinkbar;
    Exit;
  end;

  { Check CMD New Linkbar }
  if FindCmdLineSwitch(CLK_CLOSEALL, True)
  then begin
    Application.Initialize;
    Application.MainFormOnTaskBar := False;
    TLinkbarWcl.CloseAll;
    Application.Run;
    Exit;
  end;

  if FindCmdLineSwitch(CLK_FILE, FSettingsFileName, True)
     and SameText(ExtractFileExt(FSettingsFileName), EXT_LBR)
     and TFile.Exists(FSettingsFileName)
  then begin
    // delete profile if working directory invalid
    if not TSettingsFile.IsValid(FSettingsFileName)
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
        if not TSettingsFile.IsValid(sl[i])
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
