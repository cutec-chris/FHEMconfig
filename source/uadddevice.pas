unit uAddDevice;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, IpHtml, Ipfilebroker, SynMemo, Forms, Controls,
  Graphics, Dialogs, ComCtrls, StdCtrls, ButtonPanel, uMain,SynCompletion,
  LCLType;

type

  { TFillThread }

  TFillThread = class(TThread)
  private
    actName: String;
    actSecName: String;
    FAdd: TNotifyEvent;
    procedure AddItem;
  public
    constructor Create(CreateSuspended: Boolean; const StackSize: SizeUInt=
  DefaultStackSize);
    procedure Execute; override;
    procedure ParseCommandRef;
    property OnAddDevice : TNotifyEvent read FAdd write FAdd;
  end;

  TModule = class
  public
    Name : string;
    Typ : string;

    Description : string;
    Define : string;
    GetContent : string;
    SetContent : string;
    Attributes : string;
  end;

  { TfAddDevice }

  TfAddDevice = class(TForm)
    ButtonPanel1: TButtonPanel;
    cbAll: TRadioButton;
    cbName: TRadioButton;
    eDefine: TSynMemo;
    eSearch: TEdit;
    ipHTML: TIpHtmlPanel;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    PageControl1: TPageControl;
    tsDefine: TTabSheet;
    Allgemein: TTabSheet;
    tvMain: TTreeView;
    procedure aThreadAddDevice(Sender: TObject);
    procedure cbAllClick(Sender: TObject);
    procedure eSearchChange(Sender: TObject);
    procedure eSearchEnter(Sender: TObject);
    procedure eSearchExit(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDeactivate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FSynCompletionExecute(Sender: TObject);
    procedure FSynCompletionSearchPosition(var APosition: integer);
    procedure FSynCompletionUTF8KeyPress(Sender: TObject; var UTF8Key: TUTF8Char
      );
    procedure TSimpleIpHtmlGetImageX(Sender: TIpHtmlNode; const URL: string;
      var Picture: TPicture);
    procedure tvMainCustomDrawItem(Sender: TCustomTreeView; Node: TTreeNode;
      State: TCustomDrawState; var DefaultDraw: Boolean);
    procedure tvMainSelectionChanged(Sender: TObject);
  private
    { private declarations }
    FSynCompletion: TSynCompletion;
  public
    { public declarations }
    Modules: TList;
    function Execute : Boolean;
    procedure CreateUs;
  end;

  { TSimpleIpHtml }

  TSimpleIpHtml = class(TIpHtml)
  public
    property OnGetImageX;
    constructor Create;
  end;

var
  fAddDevice: TfAddDevice;

implementation

uses RegExpr,Utils;

{$R *.lfm}

{ TSimpleIpHtml }

constructor TSimpleIpHtml.Create;
begin
  inherited;
end;

{ TFillThread }

procedure TFillThread.AddItem;
var
  aMod: TModule;
begin
  aMod := TModule.Create;
  aMod.Name:=actName;
  aMod.Typ:=actSecName;
  fAddDevice.Modules.Add(aMod);
  if Assigned(FAdd) then
    FAdd(aMod);
end;

constructor TFillThread.Create(CreateSuspended: Boolean;
  const StackSize: SizeUInt);
begin
  inherited;
  FreeOnTerminate:=True;
end;

procedure TFillThread.Execute;
var
  FCommandRef: String;
  FCommandRefDE: String;
begin
  ParseCommandRef;
end;

procedure TFillThread.ParseCommandRef;
var
  tmp: String;
  tmpEN : string;
  aSec: String;
  tmp1: String;
  i: Integer;
  tmp2: String;
  aSecTp: String;

  procedure FillSection;
  begin
    while (pos('<a href',aSec)>0) do
      begin
        aSec := copy(aSec,pos('<a href',aSec)+8,length(aSec));
        aSec := copy(aSec,pos('>',aSec)+1,length(aSec));
        actName := copy(aSec,0,pos('<',aSec)-1);
        Synchronize(@AddItem);
        aSec := copy(aSec,pos('</a>',aSec)+4,length(aSec));
      end;

  end;

begin
  tmp := fMain.LoadHTML('/docs/commandref_DE.html');
  tmp := copy(tmp,pos('<b>',tmp)+3,length(tmp));
  tmp := copy(tmp,pos('<b>',tmp)+3,length(tmp));
  aSec := copy(tmp,0,pos('<b>',tmp)-1);
  actSecName := copy(aSec,0,pos('</b>',aSec)-1);
  //FillSection;
  tmp := copy(tmp,pos('<b>',tmp)+3,length(tmp));
  aSec := copy(tmp,0,pos('<b>',tmp)-1);
  actSecName := HTMLDecode(copy(aSec,0,pos('</b>',aSec)-1));
  FillSection;
  tmp := copy(tmp,pos('<b>',tmp)+3,length(tmp));
  aSec := copy(tmp,0,pos('<b>',tmp)-1);
  actSecName := HTMLDecode(copy(aSec,0,pos('</b>',aSec)-1));
  FillSection;
  tmp := copy(tmp,pos('<b>',tmp)+3,length(tmp));
  //now we have all Module names
  try
  for i := 0 to fAddDevice.Modules.Count-1 do
    with TModule(fAddDevice.Modules[i]) do
      begin
        if Terminated then exit;
        aSecTp := 'desc';
        tmp1 := '<a name="'+Name+'">';
        aSec := copy(tmp,pos(tmp1,tmp)+9,length(tmp));
        aSec := copy(aSec,pos('</a>',aSec)+4,length(aSec));
        while pos('<a name="',aSec)>0 do
          begin
            tmp1 := copy(aSec,0,pos('<a name="',aSec)-1);
            aSec := copy(aSec,pos('<a name="',aSec)+9,length(aSec));
            tmp2 := copy(aSec,0,pos('"',aSec)-1);
            case aSecTp of
            'desc':
              begin
                if pos('Leider keine deutsche',tmp1)>0 then
                  begin
                    tmp1 := '';
                    if tmpEN='' then
                      tmpEN := fMain.LoadHTML('/docs/commandref.html');
                    tmp1 := '<a name="'+Name+'">';
                    aSec := copy(tmpEN,pos(tmp1,tmpEN)+9,length(tmpEN));
                    aSec := copy(aSec,pos('</a>',aSec)+4,length(aSec));
                    tmp1 := copy(aSec,0,pos('<a name="',aSec)-1);
                    aSec := copy(aSec,pos('<a name="',aSec)+9,length(aSec));
                    tmp2 := copy(aSec,0,pos('"',aSec)-1);
                  end;
                Description:=tmp1;
              end;
            'define':Define:=copy(tmp1,pos('>',tmp1)+1,length(tmp1));
            'set':SetContent:=copy(tmp1,pos('>',tmp1)+1,length(tmp1));
            'get':GetContent:=copy(tmp1,pos('>',tmp1)+1,length(tmp1));
            'attr':Attributes:=copy(tmp1,pos('>',tmp1)+1,length(tmp1));
            end;
            if tmp2=Name+'define' then
              begin
                aSecTp := 'define';
              end
            else if tmp2=Name+'set' then
              begin
                aSecTp := 'set';
              end
            else if tmp2=Name+'get' then
              begin
                aSecTp := 'get';
              end
            else if tmp2=Name+'attr' then
              begin
                aSecTp := 'attr';
              end
            else
              begin
                break;
              end;
          end;
      end;
  except
  end;
end;

{ TfAddDevice }

procedure TfAddDevice.FormCreate(Sender: TObject);
begin
  Modules := TList.Create;
end;

procedure TfAddDevice.FormDeactivate(Sender: TObject);
begin

end;

procedure TfAddDevice.FormDestroy(Sender: TObject);
begin
  Modules.Free;
end;

procedure TfAddDevice.FSynCompletionExecute(Sender: TObject);
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
      while (i>0) and (S[i]<>':') and (S[i]<>' ') do Dec(I);
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
        sl := fMain.GetDeviceList
      else sl := fMain.GetDeviceParams(s);
      AddStrings(sl);
      sl.Free;
    end;
end;

procedure TfAddDevice.FSynCompletionSearchPosition(var APosition: integer);
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

procedure TfAddDevice.FSynCompletionUTF8KeyPress(Sender: TObject;
  var UTF8Key: TUTF8Char);
begin
  if (length(UTF8Key)=1) and (System.Pos(UTF8Key[1],FSynCompletion.EndOfTokenChr)>0) then
    begin
      FSynCompletion.TheForm.OnValidate(Sender,UTF8Key,[]);
      UTF8Key:='';
    end
end;

procedure TfAddDevice.aThreadAddDevice(Sender: TObject);
var
  aNode : TTreeNode = nil;
  TypNode: TTreeNode = nil;
begin
  if tvMain.Items.Count>0 then aNode := tvMain.Items[0];
  with TModule(Sender) do
    begin
      while Assigned(aNode) do
        begin
          if aNode.Text=Typ then
            TypNode := aNode;
          aNode := aNode.GetNextSibling;
        end;
      if not Assigned(TypNode) then
        TypNode := tvMain.Items.Add(nil,Typ);
      aNode := tvMain.Items.AddChild(TypNode,Name);
      aNode.Data := Sender;
    end;
end;

procedure TfAddDevice.cbAllClick(Sender: TObject);
begin
  tvMainSelectionChanged(tvMain);
end;

procedure TfAddDevice.eSearchChange(Sender: TObject);
var
  aNode: TTreeNode;
begin
  if tvMain.Items.Count=0 then exit;
  aNode := tvMain.Items[0];
  while assigned(aNode) do
    begin
      if Assigned(aNode.Data) then
        begin
          aNode.Visible := (Assigned(aNode.Data) and (pos(lowercase(eSearch.Text),lowercase(aNode.Text))>0)) or ((trim(eSearch.Text)='') or (eSearch.Text=strSearch) or (aNode.HasChildren));
          if (aNode.Visible and Assigned(aNode.Parent)) and (not ((trim(eSearch.Text)='') or (eSearch.Text=strSearch) or (aNode.HasChildren))) then aNode.Parent.Expanded:=True;
        end;
      aNode := aNode.GetNext;
    end;
end;

procedure TfAddDevice.eSearchEnter(Sender: TObject);
begin
  if (trim(eSearch.Text)='') or (eSearch.Text=strSearch) then
    eSearch.Clear;
  eSearch.Font.Color:=clDefault;
end;

procedure TfAddDevice.eSearchExit(Sender: TObject);
begin
  if (trim(eSearch.Text)='') or (eSearch.Text=strSearch) then
    begin
      eSearch.Text:=strSearch;
      eSearch.Font.Color:=clSilver;
    end;
end;

procedure TfAddDevice.TSimpleIpHtmlGetImageX(Sender: TIpHtmlNode;
  const URL: string; var Picture: TPicture);
begin
  Picture:=nil;
end;

procedure TfAddDevice.tvMainCustomDrawItem(Sender: TCustomTreeView;
  Node: TTreeNode; State: TCustomDrawState; var DefaultDraw: Boolean);
begin
  DefaultDraw:=True;
  Sender.Font.Color:=clWindowText;
  if Assigned(Node.Data) and (TModule(Node.Data).Description='') then
    Sender.Font.Color:=clSilver;
end;

procedure TfAddDevice.tvMainSelectionChanged(Sender: TObject);
function ReplaceChars(s : string) : string;
begin
  Result := StringReplace(s, 'ä', '&auml;', [rfreplaceall]);
  Result := StringReplace(result, 'ö', '&ouml;', [rfreplaceall]);
  Result := StringReplace(result, 'ü', '&uuml;', [rfreplaceall]);
  Result := StringReplace(result, 'Ä', '&Auml;', [rfreplaceall]);
  Result := StringReplace(result, 'Ö', '&Ouml;', [rfreplaceall]);
  Result := StringReplace(result, 'Ü', '&Uuml;', [rfreplaceall]);
  Result := StringReplace(result, 'ß', '&szlig;', [rfreplaceall]);
end;

var
  aHTML: TSimpleIpHtml;
  ss: TStringStream;
  aMod: TModule;
  tmp: String;
begin
  if not Assigned(tvMain.Selected) then exit;
  if not Assigned(tvMain.Selected.Data) then exit;
  Screen.Cursor:=crHourGlass;
  aHTML := TSimpleIpHtml.Create;
  aMod := TModule(tvMain.Selected.Data);
  if cbAll.Checked then
    ss := TStringStream.Create('<html><body>'+ReplaceChars(aMod.Description+aMod.Define+aMod.Attributes+aMod.SetContent+aMod.GetContent)+'</body></html>')
  else
    ss := TStringStream.Create('<html><body>'+ReplaceChars(aMod.Description)+'</body></html>');
  aHTML.OnGetImageX:=@TSimpleIpHtmlGetImageX;
  aHTML.LoadFromStream(ss);
  ss.Free;
  ipHTML.SetHtml(aHTML);
  tmp := StripHTML(aMod.Define);
  tmp := copy(tmp,pos('define ',tmp)-1,length(tmp));
  tmp := copy(tmp,0,pos(#10,tmp)-1);
  eDefine.Text:=trim(tmp);
  Screen.Cursor:=crDefault;
end;

function TfAddDevice.Execute: Boolean;
var
  Res: String;
begin
  CreateUs;
  Show;
  while Visible do
    Application.ProcessMessages;
  Result := ModalResult = mrOK;
  while Result do
    begin
      Res := fMain.ExecCommand(eDefine.Text,fMain.eServer.Text);
      if Res<>'' then
        begin
          Showmessage(Res);
          Show;
          while Visible do
            Application.ProcessMessages;
          Result := ModalResult = mrOK;
        end
      else exit;
    end;
end;

procedure TfAddDevice.CreateUs;
var
  aThread: TFillThread;
begin
  if not Assigned(Self) then
    begin
      Application.CreateForm(TfAddDevice,fAddDevice);
      Self := fAddDevice;
      aThread := TFillThread.Create(False);
      aThread.OnAddDevice:=@aThreadAddDevice;
      FSynCompletion := TSynCompletion.Create(Self);
      FSynCompletion.CaseSensitive := False;
      FSynCompletion.AddEditor(eDefine);
      FSynCompletion.OnExecute:=@FSynCompletionExecute;
      FSynCompletion.OnUTF8KeyPress:=@FSynCompletionUTF8KeyPress;
      FSynCompletion.OnSearchPosition:=@FSynCompletionSearchPosition;
    end;
end;

end.

