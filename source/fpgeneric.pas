unit fpGeneric;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, StdCtrls, ValEdit, ExtCtrls,
  uFhemFrame;

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
    procedure vAttributesGetPickList(Sender: TObject; const KeyName: string;
      Values: TStrings);
  private
    { private declarations }
    FValues : string;
  public
    { public declarations }
    procedure ProcessList(aList: TStrings); override;
  end;

implementation

{$R *.lfm}

{ TfGeneric }

procedure TfGeneric.vAttributesGetPickList(Sender: TObject;
  const KeyName: string; Values: TStrings);
begin
  if FValues='' then
    begin
      FValues := ExecCommand('list '+FName+' ?');
    end;
end;

procedure TfGeneric.ProcessList(aList: TStrings);
var
  i: Integer;
  aCat: String;
  bList: TValueListEditor;
  aStr: String;
  aTime: String;
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

begin
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
                  bList.Values[copy(aStr,0,pos(' ',aStr)-1)]:=trim(copy(aStr,pos(' ',aStr)+1,length(aStr)));//+' ('+aTime+')';
                end
              else
                bList.Values[copy(aStr,0,pos(' ',aStr)-1)]:=trim(copy(aStr,pos(' ',aStr)+1,length(aStr)));
            end;
        end;
    end;
  ProcessActList;
end;

end.

