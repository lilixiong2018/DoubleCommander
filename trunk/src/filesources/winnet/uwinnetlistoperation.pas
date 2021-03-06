unit uWinNetListOperation;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  uFileSourceListOperation,
  uWinNetFileSource,
  uFileSource;

type

  { TWinNetListOperation }

  TWinNetListOperation = class(TFileSourceListOperation)
  private
    FWinNetFileSource: IWinNetFileSource;
  private
    procedure ShareEnum;
    procedure WorkgroupEnum;
  public
    constructor Create(aFileSource: IFileSource; aPath: String); override;
    procedure MainExecute; override;
  end;

implementation

uses
  LazUTF8, uFile, Windows, JwaWinNetWk, JwaLmCons, JwaLmShare, JwaLmApiBuf,
  DCStrUtils, uShowMsg, DCOSUtils, uOSUtils;

procedure TWinNetListOperation.WorkgroupEnum;
var
  I: DWORD;
  aFile: TFile;
  nFile: TNetResourceW;
  nFileList: PNetResourceW;
  dwResult: DWORD;
  dwCount, dwBufferSize: DWORD;
  hEnum: THandle = INVALID_HANDLE_VALUE;
  lpBuffer: Pointer = nil;
  FilePath: String;
  FileName: UnicodeString;
begin
  with FWinNetFileSource do
  try
    FillChar(nFile, SizeOf(TNetResource), #0);
    nFile.dwScope:= RESOURCE_GLOBALNET;
    nFile.dwType:= RESOURCETYPE_ANY;
    nFile.lpProvider:= PWideChar(ProviderName);

    if not IsPathAtRoot(Path) then
    begin
      FilePath:= ExcludeTrailingPathDelimiter(Path);
      FileName:= UTF8Decode(ExcludeFrontPathDelimiter(FilePath));
      nFile.lpRemoteName:= PWideChar(FileName);
    end;

    dwResult := WNetOpenEnumW(RESOURCE_GLOBALNET, RESOURCETYPE_ANY, 0, @nFile, hEnum);
    if (dwResult <> NO_ERROR) then Exit;
    dwCount := DWORD(-1);
    // 1024 Kb must be enough
    dwBufferSize:= $100000;
    // Allocate output buffer
    GetMem(lpBuffer, dwBufferSize);
    // Enumerate all resources
    dwResult:= WNetEnumResourceW(hEnum, dwCount, lpBuffer, dwBufferSize);
    if dwResult = ERROR_NO_MORE_ITEMS then Exit;
    if (dwResult <> NO_ERROR) then Exit;
    nFileList:= PNetResourceW(lpBuffer);
    for I := 0 to dwCount - 1 do
    begin
      CheckOperationState;
      aFile:= TWinNetFileSource.CreateFile(Path);
      aFile.FullPath:= UTF16ToUTF8(UnicodeString(nFileList^.lpRemoteName));
      aFile.CommentProperty.Value:= UTF16ToUTF8(UnicodeString(nFileList^.lpComment));
      if nFileList^.dwDisplayType = RESOURCEDISPLAYTYPE_SHARE then
        aFile.Attributes:= faFolder;
      FFiles.Add(aFile);
      Inc(nFileList);
    end;

  finally
    if (hEnum <> INVALID_HANDLE_VALUE) then
      dwResult := WNetCloseEnum(hEnum);
    if (dwResult <> NO_ERROR) and (dwResult <> ERROR_NO_MORE_ITEMS) then
      msgError(Thread, mbSysErrorMessage(dwResult));
    if Assigned(lpBuffer) then
      FreeMem(lpBuffer);
  end;
end;

procedure TWinNetListOperation.ShareEnum;
var
  I: DWORD;
  aFile: TFile;
  ServerPath: UnicodeString;
  dwResult: NET_API_STATUS;
  dwEntriesRead: DWORD = 0;
  dwTotalEntries: DWORD = 0;
  BufPtr, nFileList: PShareInfo1;
begin
  ServerPath:= UTF8Decode(ExcludeTrailingPathDelimiter(Path));
  repeat
    // Call the NetShareEnum function
    dwResult:= NetShareEnum (PWideChar(ServerPath), 1, PByte(BufPtr), MAX_PREFERRED_LENGTH, @dwEntriesRead, @dwTotalEntries, nil);
    // If the call succeeds
    if (dwResult = ERROR_SUCCESS) or (dwResult = ERROR_MORE_DATA) then
    begin
      nFileList:= BufPtr;
      // Loop through the entries
      for I:= 1 to dwEntriesRead do
      begin
        CheckOperationState;
        aFile:= TWinNetFileSource.CreateFile(Path);
        aFile.Name:= UTF16ToUTF8(UnicodeString(nFileList^.shi1_netname));
        aFile.CommentProperty.Value:= UTF16ToUTF8(UnicodeString(nFileList^.shi1_remark));
        case (nFileList^.shi1_type and $FF) of
          STYPE_DISKTREE:
            aFile.Attributes:= FILE_ATTRIBUTE_DIRECTORY;
          STYPE_IPC:
            aFile.Attributes:= FILE_ATTRIBUTE_SYSTEM;
        end;
        // Mark special items as hidden
        if (nFileList^.shi1_type and STYPE_SPECIAL = STYPE_SPECIAL) then
          aFile.Attributes:= aFile.Attributes or FILE_ATTRIBUTE_HIDDEN;
        // Mark special items as hidden
        if (lstrcmpiW(nFileList^.shi1_netname, 'FAX$') = 0) then
          aFile.Attributes:= aFile.Attributes or FILE_ATTRIBUTE_HIDDEN;
        // Mark special items as hidden
        if (lstrcmpiW(nFileList^.shi1_netname, 'PRINT$') = 0) then
          aFile.Attributes:= aFile.Attributes or FILE_ATTRIBUTE_HIDDEN;
        FFiles.Add(aFile);
        Inc(nFileList);
      end;
      // Free the allocated buffer
      NetApiBufferFree(BufPtr);
    end;

  // Continue to call NetShareEnum while there are more entries
  until (dwResult <> ERROR_MORE_DATA);

  // Show error if failed
  if (dwResult <> ERROR_SUCCESS) then
    msgError(Thread, mbSysErrorMessage(dwResult));
end;

constructor TWinNetListOperation.Create(aFileSource: IFileSource; aPath: String);
begin
  FFiles := TFiles.Create(aPath);
  FWinNetFileSource := aFileSource as IWinNetFileSource;
  inherited Create(aFileSource, aPath);
end;

procedure TWinNetListOperation.MainExecute;
begin
  FFiles.Clear;
  with FWinNetFileSource do
  // Workstation/Server
  if (IsPathAtRoot(Path) = False) and (Pos('\\', Path) = 1) then
    ShareEnum
  // Root/Domain/Workgroup
  else
    WorkgroupEnum;
end;

end.

