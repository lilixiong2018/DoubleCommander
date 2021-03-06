{ $threading on}
program doublecmd;
// uGlobs must be first in uses, uLng must be before any form;
{%File 'doc/changelog.txt'}

{$APPTYPE GUI}
uses
  {$IFDEF UNIX}
  cthreads,
  //cwstring,
  {$ENDIF}
  Interfaces,
  InterfaceBase,
  LCLProc,
  LResources,
  SysUtils,
  Forms,
  uGlobsPaths,
  uGlobs,
  fHackForm,
  fMain,
  fAbout,
  fMkDir,
  dmHigh, dmHelpManager, dmCommonData,
  uPixMapManager,
  uKeyboard;

const
  dcBuildDate = {$I %DATE%};
  dcVersion = '0.4.5.2 beta';
  lazVersion = {$I version.inc};
  fpcVersion = {$I %FPCVERSION%};
  TargetCPU = {$I %FPCTARGETCPU%};
  TargetOS = {$I %FPCTARGETOS%};

{$I revision.inc} // Lazarus revision number
{$I dcrevision.inc} // Double Commander revision number

{$IFDEF WINDOWS}{$R doublecmd.rc}{$ENDIF}

begin
  {$I doublecmd.lrs}
  Application.Title:= 'Double Commander';
  Application.Initialize;

  ThousandSeparator:= ' ';
  DebugLn('Double Commander ' + dcVersion);
  DebugLn('Revision: ' + dcRevision);
  DebugLn('Build: ' + dcBuildDate);
  DebugLn('Lazarus: ' + lazVersion + '-' + RevisionStr);
  DebugLn('Free Pascal: ' + fpcVersion);
  DebugLn('Platform: ' + TargetCPU + '-' + TargetOS + '-' + LCLPlatform[WidgetSet.LCLPlatform]);
  DebugLn('This program is free software released under terms of GNU GPL 2');
  DebugLn('(C)opyright 2006-2010 Koblov Alexander (Alexx2000@mail.ru)');
  DebugLn('   and contributors (see about dialog)');

  fAbout.dcBuildDate := dcBuildDate;
  fAbout.dcVersion:= dcVersion;
  fAbout.dcRevision:= dcRevision;
  fAbout.lazRevision:= RevisionStr;
  fAbout.fpcVersion:= fpcVersion;
  fAbout.TargetCPU:= TargetCPU;
  fAbout.TargetOS:= TargetOS;

  LoadPaths; // must be first
  Application.ShowMainForm:= False;
  Application.CreateForm(TfrmHackForm, frmHackForm);
  if LoadGlobs then
     begin
       LoadPixMapManager;
       Application.CreateForm(TfrmMain, frmMain); // main form
       Application.CreateForm(TdmHighl, dmHighl); // highlighters
       Application.CreateForm(TdmComData, dmComData); // common data
       Application.CreateForm(TdmHelpManager, dmHelpMgr); // help manager
       Application.CreateForm(TfrmMkDir, frmMkDir);  // 21.05.2009 - makedir form

       // Initializing keyboard module on GTK needs GTKProc.InitKeyboardTables
       // which is called by Application.Initialize. On QT needs the handle
       // of the main form created in Application.CreateForm above.
       uKeyboard.InitializeKeyboard;

       Application.Run;

       uKeyboard.CleanupKeyboard;
     end;
end.
