unit fDoIf;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, StdCtrls, uFhemFrame,
  Dialogs, Buttons, ExtCtrls;

type

  { TfrDOIF }

  TfrDOIF = class(TFHEMFrame)
    eName: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    lStatus: TLabel;
    mEvent: TMemo;
    bSave: TSpeedButton;
    mIF: TMemo;
    Timer1: TTimer;
    procedure bTestIfClick(Sender: TObject);
    procedure bSaveClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
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
  aDef := '('+mEvent.Text+') '+mIF.Text;
  aRes := ChangeValue('detail='+FName+'&val.modify'+FName+'='+HTTPEncode(aDef)+'&cmd.modify'+FName+'=modify+'+FName);
  if aRes <> '' then
    Showmessage(aRes)
  else Change;
end;

procedure TfrDOIF.Timer1Timer(Sender: TObject);
begin
  lStatus.Caption:=Device.Status;
end;

function TfrDOIF.GetDeviceType: string;
begin
  Result := 'DOIF';
end;

procedure TfrDOIF.ProcessList(aList: TStrings);
var
  tmp: String='';
  i: Integer;
begin
  eName.Text:=FName;
  tmp := aList.Text;
  for i := 0 to aList.Count-1 do
    if Uppercase(copy(trim(aList[i]),0,3))='DEF' then tmp := trim(copy(trim(aList[i]),4,length(aList[i])));
  if Copy(tmp,0,1)='(' then
    begin
      mEvent.Text:=GetFirstParam(tmp);
      tmp := copy(tmp,length(mEvent.Text)+1,length(tmp));
    end
  else
    begin
      mEvent.Text:=copy(tmp,1,pos(' ',tmp)-1);
      tmp := copy(tmp,pos(' ',tmp)+1,length(tmp));
    end;
  mIF.Text:=trim(tmp);
end;

initialization
  RegisterFrame(TfrDOIF);
end.

