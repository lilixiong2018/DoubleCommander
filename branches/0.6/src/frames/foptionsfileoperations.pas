{
   Double Commander
   -------------------------------------------------------------------------
   File operations options page

   Copyright (C) 2006-2011  Koblov Alexander (Alexx2000@mail.ru)

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
}

unit fOptionsFileOperations;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, StdCtrls, Spin, ExtCtrls, DividerBevel,
  fOptionsFrame;

type

  { TfrmOptionsFileOperations }

  TfrmOptionsFileOperations = class(TOptionsEditor)
    bvlConfirmations: TDividerBevel;
    cbDeleteToTrash: TCheckBox;
    cbDropReadOnlyFlag: TCheckBox;
    cbPartialNameSearch: TCheckBox;
    cbProcessComments: TCheckBox;
    cbRenameSelOnlyName: TCheckBox;
    cbShowCopyTabSelectPanel: TCheckBox;
    cbSkipFileOpError: TCheckBox;
    cbProgressKind: TComboBox;
    cbCopyConfirmation: TCheckBox;
    cbMoveConfirmation: TCheckBox;
    cbDeleteConfirmation: TCheckBox;
    cbDeleteToTrashConfirmation: TCheckBox;
    bvlTypeOfDuplicatedRename: TDividerBevel;
    cmbTypeOfDuplicatedRename: TComboBox;
    edtBufferSize: TEdit;
    gbUserInterface: TGroupBox;
    gbFileSearch: TGroupBox;
    gbExecutingOperations: TGroupBox;
    lblBufferSize: TLabel;
    lblProgressKind: TLabel;
    lblWipePassNumber: TLabel;
    rbUseMmapInSearch: TRadioButton;
    rbUseStreamInSearch: TRadioButton;
    seWipePassNumber: TSpinEdit;
    procedure cbDeleteToTrashChange(Sender: TObject);
    procedure GenericSomethingChanged(Sender: TObject);
  private
    FLoading: Boolean;
    FModificationTookPlace: Boolean;
  protected
    procedure Init; override;
    procedure Load; override;
    function Save: TOptionsEditorSaveFlags; override;
  public
    constructor Create(TheOwner: TComponent); override;
    class function GetIconIndex: Integer; override;
    class function GetTitle: String; override;
    function CanWeClose(var WillNeedUpdateWindowView: boolean): boolean; override;
  end;

implementation

{$R *.lfm}

uses
  fOptions, uShowMsg, DCStrUtils, uGlobs, uLng, fOptionsHotkeys;

{ TfrmOptionsFileOperations }

class function TfrmOptionsFileOperations.GetIconIndex: Integer;
begin
  Result := 8;
end;

class function TfrmOptionsFileOperations.GetTitle: String;
begin
  Result := rsOptionsEditorFileOperations;
end;

procedure TfrmOptionsFileOperations.Init;
begin
  ParseLineToList(rsOptFileOperationsProgressKind, cbProgressKind.Items);
  ParseLineToList(rsOptTypeOfDuplicatedRename, cmbTypeOfDuplicatedRename.Items);
end;

procedure TfrmOptionsFileOperations.cbDeleteToTrashChange(Sender: TObject);
var
  HotkeysEditor: TOptionsEditor;
begin
  if not FLoading then
  begin
    HotkeysEditor := OptionsDialog.GetEditor(TfrmOptionsHotkeys);
    if Assigned(HotkeysEditor) then
      (HotkeysEditor as TfrmOptionsHotkeys).AddDeleteWithShiftHotkey(cbDeleteToTrash.Checked);
    GenericSomethingChanged(Sender);
  end;
end;

procedure TfrmOptionsFileOperations.Load;
begin
  FLoading := True;

  edtBufferSize.Text               := IntToStr(gCopyBlockSize div 1024);
  cbSkipFileOpError.Checked        := gSkipFileOpError;
  cbDropReadOnlyFlag.Checked       := gDropReadOnlyFlag;
  rbUseMmapInSearch.Checked        := gUseMmapInSearch;
  cbPartialNameSearch.Checked      := gPartialNameSearch;
  seWipePassNumber.Value           := gWipePassNumber;
  cbProcessComments.Checked        := gProcessComments;
  cbShowCopyTabSelectPanel.Checked := gShowCopyTabSelectPanel;
  cbDeleteToTrash.Checked          := gUseTrash;
  cbRenameSelOnlyName.Checked      := gRenameSelOnlyName;

  case gFileOperationsProgressKind of
    fopkSeparateWindow:           cbProgressKind.ItemIndex := 0;
    fopkSeparateWindowMinimized:  cbProgressKind.ItemIndex := 1;
    fopkOperationsPanel:          cbProgressKind.ItemIndex := 2;
  end;

  cbCopyConfirmation.Checked          := focCopy in gFileOperationsConfirmations;
  cbMoveConfirmation.Checked          := focMove in gFileOperationsConfirmations;
  cbDeleteConfirmation.Checked        := focDelete in gFileOperationsConfirmations;
  cbDeleteToTrashConfirmation.Checked := focDeleteToTrash in gFileOperationsConfirmations;
  cmbTypeOfDuplicatedRename.ItemIndex := Integer(gTypeOfDuplicatedRename);

  FLoading := False;
  FModificationTookPlace := False;
end;

function TfrmOptionsFileOperations.Save: TOptionsEditorSaveFlags;
begin
  Result := [];

  gCopyBlockSize          := StrToIntDef(edtBufferSize.Text, gCopyBlockSize) * 1024;
  gSkipFileOpError        := cbSkipFileOpError.Checked;
  gDropReadOnlyFlag       := cbDropReadOnlyFlag.Checked;
  gUseMmapInSearch        := rbUseMmapInSearch.Checked;
  gPartialNameSearch      := cbPartialNameSearch.Checked;
  gWipePassNumber         := seWipePassNumber.Value;
  gProcessComments        := cbProcessComments.Checked;
  gShowCopyTabSelectPanel := cbShowCopyTabSelectPanel.Checked;
  gUseTrash               := cbDeleteToTrash.Checked;
  gRenameSelOnlyName      := cbRenameSelOnlyName.Checked;

  case cbProgressKind.ItemIndex of
    0: gFileOperationsProgressKind := fopkSeparateWindow;
    1: gFileOperationsProgressKind := fopkSeparateWindowMinimized;
    2: gFileOperationsProgressKind := fopkOperationsPanel;
  end;

  gFileOperationsConfirmations := [];
  if cbCopyConfirmation.Checked then
    Include(gFileOperationsConfirmations, focCopy);
  if cbMoveConfirmation.Checked then
    Include(gFileOperationsConfirmations, focMove);
  if cbDeleteConfirmation.Checked then
    Include(gFileOperationsConfirmations, focDelete);
  if cbDeleteToTrashConfirmation.Checked then
    Include(gFileOperationsConfirmations, focDeleteToTrash);
  gTypeOfDuplicatedRename := tDuplicatedRename(cmbTypeOfDuplicatedRename.ItemIndex);
  FModificationTookPlace := False;
end;

constructor TfrmOptionsFileOperations.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  FLoading := False;
end;

procedure TfrmOptionsFileOperations.GenericSomethingChanged(Sender: TObject);
begin
  FModificationTookPlace := True;
end;

function TfrmOptionsFileOperations.CanWeClose(var WillNeedUpdateWindowView: boolean): boolean;
var
  Answer: TMyMsgResult;
begin
  Result := not FModificationTookPlace;

  if not Result then
  begin
    ShowOptions(TfrmOptionsFileOperations);
    Answer := MsgBox(rsMsgFileOperationsModifiedWantToSave, [msmbYes, msmbNo, msmbCancel], msmbCancel, msmbCancel);
    case Answer of
      mmrYes:
      begin
        Save;
        Result := True;
      end;

      mmrNo: Result := True;
      else
        Result := False;
    end;
  end;
end;

end.

