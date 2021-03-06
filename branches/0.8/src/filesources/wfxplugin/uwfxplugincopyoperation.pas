unit uWfxPluginCopyOperation;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  uFileSourceCopyOperation,
  uFileSource,
  uFileSourceOperation,
  uFileSourceOperationOptions,
  uFileSourceOperationOptionsUI,
  uFile,
  uWfxPluginFileSource,
  uWfxPluginUtil;

type

  { TWfxPluginCopyOperation }

  TWfxPluginCopyOperation = class(TFileSourceCopyOperation)

  private
    FWfxPluginFileSource: IWfxPluginFileSource;
    FOperationHelper: TWfxPluginOperationHelper;
    FCallbackDataClass: TCallbackDataClass;
    FFullFilesTreeToCopy: TFiles;  // source files including all files/dirs in subdirectories
    FStatistics: TFileSourceCopyOperationStatistics; // local copy of statistics
    // Options
    FInfoOperation: LongInt;
  protected
    function UpdateProgress(SourceName, TargetName: String; PercentDone: Integer): Integer;

  public
    constructor Create(aSourceFileSource: IFileSource;
                       aTargetFileSource: IFileSource;
                       var theSourceFiles: TFiles;
                       aTargetPath: String); override;

    destructor Destroy; override;

    procedure Initialize; override;
    procedure MainExecute; override;
    procedure Finalize; override;

    class function GetOptionsUIClass: TFileSourceOperationOptionsUIClass; override;

  end;

implementation

uses
  fWfxPluginCopyMoveOperationOptions, WfxPlugin;

// -- TWfxPluginCopyOperation ---------------------------------------------

function TWfxPluginCopyOperation.UpdateProgress(SourceName, TargetName: String;
                                                   PercentDone: Integer): Integer;
var
  iTemp: Int64;
begin
  Result := 0;

  //DCDebug('SourceName=', SourceName, #32, 'TargetName=', TargetName, #32, 'PercentDone=', IntToStr(PercentDone));

  if State = fsosStopping then  // Cancel operation
    Exit(1);

  with FStatistics do
  begin
    FStatistics.CurrentFileFrom:= SourceName;
    FStatistics.CurrentFileTo:= TargetName;

    iTemp:= CurrentFileTotalBytes * PercentDone div 100;
    DoneBytes := DoneBytes + (iTemp - CurrentFileDoneBytes);
    CurrentFileDoneBytes:= iTemp;

    UpdateStatistics(FStatistics);
  end;

  if not AppProcessMessages(True) then
    Exit(1);
end;

constructor TWfxPluginCopyOperation.Create(aSourceFileSource: IFileSource;
                                              aTargetFileSource: IFileSource;
                                              var theSourceFiles: TFiles;
                                              aTargetPath: String);
begin
  FWfxPluginFileSource:= aSourceFileSource as IWfxPluginFileSource;
  with FWfxPluginFileSource do
  FCallbackDataClass:= TCallbackDataClass(WfxOperationList.Objects[PluginNumber]);

  if theSourceFiles.Count > 1 then
    FInfoOperation:= FS_STATUS_OP_RENMOV_MULTI
  else
    FInfoOperation:= FS_STATUS_OP_RENMOV_SINGLE;

  inherited Create(aSourceFileSource, aTargetFileSource, theSourceFiles, aTargetPath);
end;

destructor TWfxPluginCopyOperation.Destroy;
begin
  inherited Destroy;
end;

procedure TWfxPluginCopyOperation.Initialize;
begin
  with FWfxPluginFileSource do
  begin
    WfxModule.WfxStatusInfo(SourceFiles.Path, FS_STATUS_START, FInfoOperation);
    FCallbackDataClass.UpdateProgressFunction:= @UpdateProgress;
    UpdateProgressFunction:= @UpdateProgress;
    // Get initialized statistics; then we change only what is needed.
    FStatistics := RetrieveStatistics;

    FillAndCount(SourceFiles, False, False,
                 FFullFilesTreeToCopy,
                 FStatistics.TotalFiles,
                 FStatistics.TotalBytes);     // gets full list of files (recursive)
  end;

  if Assigned(FOperationHelper) then
    FreeAndNil(FOperationHelper);

  FOperationHelper := TWfxPluginOperationHelper.Create(
                        FWfxPluginFileSource,
                        @AskQuestion,
                        @RaiseAbortOperation,
                        @CheckOperationState,
                        @UpdateStatistics,
                        Thread,
                        wpohmCopy,
                        TargetPath);

  FOperationHelper.RenameMask := RenameMask;
  FOperationHelper.FileExistsOption := FileExistsOption;
  FOperationHelper.CopyAttributesOptions := CopyAttributesOptions;

  FOperationHelper.Initialize;
end;

procedure TWfxPluginCopyOperation.MainExecute;
begin
  FOperationHelper.ProcessFiles(FFullFilesTreeToCopy, FStatistics);
end;

procedure TWfxPluginCopyOperation.Finalize;
begin
  with FWfxPluginFileSource do
  begin
    WfxModule.WfxStatusInfo(SourceFiles.Path, FS_STATUS_END, FInfoOperation);
    FCallbackDataClass.UpdateProgressFunction:= nil;
    UpdateProgressFunction:= nil;
  end;
  FileExistsOption := FOperationHelper.FileExistsOption;
  FOperationHelper.Free;
end;

class function TWfxPluginCopyOperation.GetOptionsUIClass: TFileSourceOperationOptionsUIClass;
begin
  Result := TWfxPluginCopyOperationOptionsUI;
end;

end.

