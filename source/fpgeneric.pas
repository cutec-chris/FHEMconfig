unit fpGeneric;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, StdCtrls, ValEdit, uFhemFrame;

type

  { TfGeneric }

  TfGeneric = class(TFHEMFrame)
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    vAttributes: TValueListEditor;
    vReadings: TValueListEditor;
    vInternals: TValueListEditor;
  private
    { private declarations }
  public
    { public declarations }
    procedure ProcessList(aList: TStrings); override;
  end;

implementation

{$R *.lfm}

{ TfGeneric }

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
begin
  bList:=nil;
  for i := 0 to aList.Count-1 do
    begin
      aCat := GetCategory;
      if aCat = 'Attributes' then
        begin
          bList := vAttributes;
          bList.Clear;
        end
      else if aCat = 'Readings' then
        begin
          bList := vReadings;
          bList.Clear;
        end
      else if aCat = 'Internals' then
        begin
          bList := vInternals;
          bList.Clear;
        end
      else if aCat <> '' then bList := nil
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
end;

end.

