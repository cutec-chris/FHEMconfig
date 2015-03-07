unit fDoIf;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, StdCtrls, uFhemFrame,
  Dialogs, Buttons;

type

  { TfrDOIF }

  TfrDOIF = class(TFHEMFrame)
    bCommandTest: TButton;
    bTestIf: TButton;
    bElseIfTest: TButton;
    eName: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    mElse: TMemo;
    mEvent: TMemo;
    mIF: TMemo;
    bSave: TSpeedButton;
    procedure bElseIfTestClick(Sender: TObject);
    procedure bTestIfClick(Sender: TObject);
    procedure bSaveClick(Sender: TObject);
  private
    { private declarations }
  protected
    function GetDeviceType: string; override;
  public
    { public declarations }
    procedure ProcessList(aList: TStrings); override;
  end;

implementation

uses Utils;

{$R *.lfm}

{ TfrDOIF }

procedure TfrDOIF.bTestIfClick(Sender: TObject);
var
  Res: String;
begin
  Res := ExecCommand(mIf.Text);
  if Res<>'' then Showmessage(Res);
end;

procedure TfrDOIF.bSaveClick(Sender: TObject);
var
  aRes: String;
  aDef: String;
begin
  aDef := '('+mEvent.Text+') ('+mIF.Text+')';
  if mElse.Text<>'' then
    aDef := aDef+' ELSEIF ('+mElse.Text+')';
  aRes := ChangeValue('detail='+FName+'&val.modify'+FName+'='+HTTPEncode(aDef)+'&cmd.modify'+FName+'=modify+'+FName);
  if aRes <> '' then
    Showmessage(aRes);
end;

procedure TfrDOIF.bElseIfTestClick(Sender: TObject);
var
  Res: String;
begin
  Res := ExecCommand(mElse.Text);
  if Res<>'' then Showmessage(Res);
end;

function TfrDOIF.GetDeviceType: string;
begin
  Result := 'DOIF';
end;

procedure TfrDOIF.ProcessList(aList: TStrings);
var
  tmp: String;
  i: Integer;
begin
  eName.Text:=FName;
  for i := 0 to aList.Count-1 do
    if copy(trim(aList[i]),0,3)='DEF' then tmp := trim(copy(trim(aList[i]),4,length(aList[i])));
  if Copy(tmp,0,1)='(' then
    begin
      mEvent.Text:=copy(tmp,2,pos(') ',tmp)-2);
      tmp := copy(tmp,pos(') ',tmp)+2,length(tmp));
    end
  else
    begin
      mEvent.Text:=copy(tmp,2,pos(' ',tmp)-1);
      tmp := copy(tmp,pos(' ',tmp)+1,length(tmp));
    end;
  if pos('DOELSE',tmp)>0 then
    begin
      mIF.Text:=trim(copy(tmp,0,pos('DOELSE',tmp)-1));
      tmp := copy(tmp,pos('DOELSE',tmp)+6,length(tmp));
      mElse.Text:=trim(copy(tmp,0,length(tmp)));
      if copy(mElse.Text,0,1)='(' then
        mElse.Text := copy(mElse.Text,2,length(mElse.Text)-2);
    end
  else mIF.Text:=trim(tmp);
  if copy(mIF.Text,0,1)='(' then
    mIF.Text := copy(mIF.Text,2,length(mIF.Text)-2);
end;

initialization
  RegisterFrame(TfrDOIF);
end.

