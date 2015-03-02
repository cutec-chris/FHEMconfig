unit fpGeneric;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, StdCtrls, ValEdit, ExtCtrls,
  uFhemFrame, Grids;

type

  { TfGeneric }

  TfGeneric = class(TFHEMFrame)
    cbRoom: TComboBox;
    eName: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    vAttributes: TValueListEditor;
    vReadings: TValueListEditor;
    vInternals: TValueListEditor;
    procedure vAttributesValidateEntry(sender: TObject; aCol, aRow: Integer;
      const OldValue: string; var NewValue: String);
  private
    { private declarations }
    FAttrValues : string;
    procedure RefreshFValues;
  public
    { public declarations }
    procedure ProcessList(aList: TStrings); override;
  end;

implementation

{$R *.lfm}

{ TfGeneric }

procedure TfGeneric.vAttributesValidateEntry(sender: TObject; aCol,
  aRow: Integer; const OldValue: string; var NewValue: String);
var
  Item: TItemProp;
  Result: String;
  aKey: String;
begin
  if OldValue=NewValue then exit;
  Item := TValueListEditor(Sender).ItemProps[aRow-1];
  if Assigned(Item) then
    begin
      aKey := TValueListEditor(Sender).Keys[aRow];
      Result := ExecCommand('attr '+FName+' '+aKey+' '+NewValue);
      if Result = '' then Change;
    end;
end;

procedure TfGeneric.RefreshFValues;
begin
  if FAttrValues='' then
    begin
      FAttrValues := ExecCommand('attr '+FName+' ?');
      FAttrValues := copy(FAttrValues,pos('one of ',FAttrValues)+7,length(FAttrValues));
    end;
end;

procedure TfGeneric.ProcessList(aList: TStrings);
var
  i: Integer;
  aCat: String;
  bList: TValueListEditor;
  aStr: String;
  aTime: String;
  aVal: String;
  tmp: String;
function GetCategory : string;
begin
  Result := '';
  if (copy(aList[i],length(aList[i]),1)=':') then
    Result := trim(copy(aList[i],0,length(aList[i])-1));
end;
procedure ProcessActList;
begin
  if not Assigned(bList) then exit;
  TPanel(bList.Parent).Visible:=True;
  TPanel(bList.Parent).Height := (bList.RowCount*bList.DefaultRowHeight)+Label1.Height+2;
  if TPanel(bList.Parent).Height>(Self.Height div 3) then
    TPanel(bList.Parent).Height := Self.Height div 3;
  if (bList.RowCount=2) and bList.IsEmptyRow then
    begin
      TPanel(bList.Parent).Height := 0;
      TPanel(bList.Parent).Visible:=False;
    end;
end;
procedure SelectEditor;
begin
  try
    if (pos(aVal+':',FAttrValues)>0) and Assigned(bList.ItemProps[aVal]) then
      begin
        bList.ItemProps[aVal].EditStyle:=esPickList;
        tmp := copy(FAttrValues,pos(aVal+':',FAttrValues),length(FAttrValues));
        tmp := copy(tmp,pos(':',tmp)+1,length(tmp));
        tmp := copy(tmp,0,pos(' ',tmp)-1);
        bList.ItemProps[aVal].PickList.CommaText:=tmp;
      end;
  except
  end;
end;

begin
  RefreshFValues;
  eName.Text:=FName;
  bList:=nil;
  for i := 0 to aList.Count-1 do
    begin
      aCat := GetCategory;
      if aCat = 'Attributes' then
        begin
          ProcessActList;
          bList := vAttributes;
          bList.Clear;
        end
      else if aCat = 'Readings' then
        begin
          ProcessActList;
          bList := vReadings;
          bList.Clear;
        end
      else if aCat = 'Internals' then
        begin
          ProcessActList;
          bList := vInternals;
          bList.Clear;
        end
      else if aCat <> '' then
        begin
          ProcessActList;
          bList := nil;
        end
      else if Assigned(bList) then
        begin
          aStr := trim(aList[i]);
          if trim(copy(aStr,0,pos(' ',aStr)-1))<>'' then
            begin
              if bList = vReadings then
                begin
                  aTime := copy(aStr,0,pos(' ',aStr)-1);
                  aStr := trim(copy(aStr,pos(' ',aStr)+1,length(aStr)));
                  aTime := aTime+' '+copy(aStr,0,pos(' ',aStr)-1);
                  aStr := trim(copy(aStr,pos(' ',aStr)+1,length(aStr)));
                  aVal := copy(aStr,0,pos(' ',aStr)-1);
                  bList.Values[aVal]:=trim(copy(aStr,pos(' ',aStr)+1,length(aStr)));//+' ('+aTime+')';
                  SelectEditor;
                end
              else
                begin
                  aVal := copy(aStr,0,pos(' ',aStr)-1);
                  bList.Values[aVal]:=trim(copy(aStr,pos(' ',aStr)+1,length(aStr)));
                  SelectEditor;
                end;
            end;
        end;
    end;
  ProcessActList;
end;

end.

