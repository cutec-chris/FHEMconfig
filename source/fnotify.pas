unit fNotify;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, StdCtrls, Buttons, uFhemFrame,
  Dialogs;

type

  { TfrNotify }

  TfrNotify = class(TFHEMFrame)
    bSave: TSpeedButton;
    bTestCondition: TButton;
    eName: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    lbLog: TListBox;
    mEvent: TMemo;
    mCommand: TMemo;
    procedure bSaveClick(Sender: TObject);
    procedure bTestConditionClick(Sender: TObject);
    procedure mEventChange(Sender: TObject);
  private
    { private declarations }
  protected
    function GetDeviceType: string; override;
  public
    { public declarations }
    procedure ProcessList(aList: TStrings); override;
    procedure LogReceived(aLog: string); override;
  end;

implementation

uses Utils,RegExpr;

{$R *.lfm}

{ TfrNotify }

procedure TfrNotify.bTestConditionClick(Sender: TObject);
var
  Res: String;
begin
  Res := ExecCommand(mCommand.Text);
  if Res<>'' then Showmessage(Res);
end;

procedure TfrNotify.mEventChange(Sender: TObject);
begin
  lbLog.Clear;
end;

procedure TfrNotify.bSaveClick(Sender: TObject);
var
  aRes: String;
  aDef: String;
begin
  aDef := '('+mEvent.Text+') ('+mCommand.Text+')';
  aRes := ChangeValue('detail='+FName+'&val.modify'+FName+'='+HTTPEncode(aDef)+'&cmd.modify'+FName+'=modify+'+FName);
  if aRes <> '' then
    Showmessage(aRes);
end;

function TfrNotify.GetDeviceType: string;
begin
  Result := 'NOTIFY';
end;

procedure TfrNotify.ProcessList(aList: TStrings);
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
      mEvent.Text:=copy(tmp,1,pos(' ',tmp)-1);
      tmp := copy(tmp,pos(' ',tmp)+1,length(tmp));
    end;
  mCommand.Text:=trim(tmp);
  if copy(mCommand.Text,0,1)='(' then
    mCommand.Text := copy(mCommand.Text,2,length(mCommand.Text)-2);
end;

procedure TfrNotify.LogReceived(aLog: string);
begin
  try
  if ExecRegExpr(StringReplace(mEvent.Text,':','(.*)',[]),aLog) then
    begin
      aLog := copy(aLog,pos(' ',aLog)+1,length(aLog));
      aLog := copy(aLog,pos(' ',aLog)+1,length(aLog));
      lbLog.Items.Add(aLog);
    end;
  except
  end;
end;

initialization
  RegisterFrame(TfrNotify);
end.

