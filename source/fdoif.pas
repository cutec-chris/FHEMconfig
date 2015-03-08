unit fDoIf;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, SynMemo, Forms, Controls, StdCtrls, uFhemFrame,
  Dialogs, Buttons, ExtCtrls,SynCompletion,LCLType;

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
    bSave: TSpeedButton;
    mEvent: TSynMemo;
    mIF: TSynMemo;
    Timer1: TTimer;
    procedure bTestIfClick(Sender: TObject);
    procedure bSaveClick(Sender: TObject);
    procedure FSynCompletionExecute(Sender: TObject);
    procedure FSynCompletionSearchPosition(var APosition: integer);
    procedure FSynCompletionUTF8KeyPress(Sender: TObject; var UTF8Key: TUTF8Char
      );
    procedure Timer1Timer(Sender: TObject);
  private
    { private declarations }
    FSynCompletion: TSynCompletion;
  protected
    function GetDeviceType: string; override;
  public
    { public declarations }
    procedure ProcessList(aList: TStrings); override;
    constructor Create(TheOwner: TComponent); override;
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
  aDef := mEvent.Text;
  if (copy(aDef,0,1)<>'(')
  or (copy(aDef,length(aDef),1)<>')') then
    aDef := '('+aDef+')';
  aDef := aDef+' '+mIF.Text;
  aRes := ChangeValue('detail='+FName+'&val.modify'+FName+'='+HTTPEncode(aDef)+'&cmd.modify'+FName+'=modify+'+FName);
  if aRes <> '' then
    Showmessage(aRes)
  else Change;
end;

procedure TfrDOIF.FSynCompletionExecute(Sender: TObject);
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

procedure TfrDOIF.FSynCompletionSearchPosition(var APosition: integer);
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

procedure TfrDOIF.FSynCompletionUTF8KeyPress(Sender: TObject;
  var UTF8Key: TUTF8Char);
begin
  if (length(UTF8Key)=1) and (System.Pos(UTF8Key[1],FSynCompletion.EndOfTokenChr)>0) then
    begin
      FSynCompletion.TheForm.OnValidate(Sender,UTF8Key,[]);
      UTF8Key:='';
    end
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
  for i := 0 to aList.Count-1 do
    if Uppercase(copy(trim(aList[i]),0,3))='DEF' then
      begin
        tmp := trim(copy(trim(aList[i]),4,length(aList[i])));
        break;
      end;
  inc(i);
  while (i<aList.Count) and (copy(aList[i],0,1)<>' ') do
    begin
      tmp := tmp+LineEnding+aList[i];
      inc(i);
    end;
  if Copy(tmp,0,1)='(' then
    begin
      mEvent.Text:=GetFirstParam(tmp);
      tmp := copy(tmp,length(mEvent.Text)+1,length(tmp));
      mEvent.Text := RemoveBrackets(mEvent.Text);
    end
  else
    begin
      mEvent.Text:=copy(tmp,1,pos(' ',tmp)-1);
      tmp := copy(tmp,pos(' ',tmp)+1,length(tmp));
    end;
  mIF.Text:=trim(tmp);
end;

constructor TfrDOIF.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  FSynCompletion := TSynCompletion.Create(Self);
  FSynCompletion.CaseSensitive := False;
  FSynCompletion.AddEditor(mEvent);
  FSynCompletion.AddEditor(mIF);
  FSynCompletion.OnExecute:=@FSynCompletionExecute;
  FSynCompletion.OnUTF8KeyPress:=@FSynCompletionUTF8KeyPress;
  FSynCompletion.OnSearchPosition:=@FSynCompletionSearchPosition;
end;

initialization
  RegisterFrame(TfrDOIF);
end.

