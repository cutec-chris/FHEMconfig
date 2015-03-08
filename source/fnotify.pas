unit fNotify;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, StdCtrls, Buttons, uFhemFrame,
  Dialogs,SynCompletion, SynMemo,LCLType;

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
    mCommand: TSynMemo;
    mEvent: TSynMemo;
    procedure bSaveClick(Sender: TObject);
    procedure bTestConditionClick(Sender: TObject);
    procedure FSynCompletionExecute(Sender: TObject);
    procedure FSynCompletionSearchPosition(var APosition: integer);
    procedure FSynCompletionUTF8KeyPress(Sender: TObject; var UTF8Key: TUTF8Char
      );
    procedure mEventChange(Sender: TObject);
  private
    { private declarations }
    FSynCompletion: TSynCompletion;
  protected
    function GetDeviceType: string; override;
  public
    { public declarations }
    procedure ProcessList(aList: TStrings); override;
    procedure LogReceived(aLog: string); override;
    constructor Create(TheOwner: TComponent); override;
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

procedure TfrNotify.FSynCompletionExecute(Sender: TObject);
function GetCurWord:string;
var
  S:string;
  i,j:integer;
begin
  Result:='';
  with TSynCompletion(Sender).Editor do
    begin
      S:=Trim(Copy(LineText, 1, CaretX));
      I:=Length(S);
      while (i>0) and (S[i]<>':') do Dec(I);
      if (I>0) then
      begin
        J:=i-1;
        //Get table name
        while (j>0) and (S[j] in ['A'..'z','"']) do Dec(j);
        Result:=trim(Copy(S, j+1, i-j-1));
      end;
    end;
end;
var
  sl: TStrings;
  s: String;
begin
  with FSynCompletion.ItemList do
    begin
      Clear;
      s := GetCurWord;
      if s='' then
        sl := GetDeviceList
      else sl := GetDeviceParams(s);
      AddStrings(sl);
      sl.Free;
    end;
end;

procedure TfrNotify.FSynCompletionSearchPosition(var APosition: integer);
var
  i: Integer;
begin
  for i := 0 to FSynCompletion.ItemList.Count-1 do
    if Uppercase(copy(FSynCompletion.ItemList[i],0,length(FSynCompletion.CurrentString))) = Uppercase(FSynCompletion.CurrentString) then
      begin
        aPosition := i;
        FSynCompletion.TheForm.Position:=i-1;
        FSynCompletion.TheForm.Position:=i;
        exit;
      end;
end;

procedure TfrNotify.FSynCompletionUTF8KeyPress(Sender: TObject;
  var UTF8Key: TUTF8Char);
begin
  if (length(UTF8Key)=1) and (System.Pos(UTF8Key[1],FSynCompletion.EndOfTokenChr)>0) then
    begin
      FSynCompletion.TheForm.OnValidate(Sender,UTF8Key,[]);
      UTF8Key:='';
    end
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
    Showmessage(aRes)
  else Change;
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
      mEvent.Text:=GetFirstParam(tmp);
      tmp := copy(tmp,length(mEvent.Text)+1,length(tmp));
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

constructor TfrNotify.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  FSynCompletion := TSynCompletion.Create(Self);
  FSynCompletion.CaseSensitive := False;
  FSynCompletion.AddEditor(mEvent);
  FSynCompletion.AddEditor(mCommand);
  FSynCompletion.OnExecute:=@FSynCompletionExecute;
  FSynCompletion.OnUTF8KeyPress:=@FSynCompletionUTF8KeyPress;
  FSynCompletion.OnSearchPosition:=@FSynCompletionSearchPosition;
end;

initialization
  RegisterFrame(TfrNotify);
end.

