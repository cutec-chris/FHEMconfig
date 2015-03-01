unit uMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls, ComCtrls, ActnList, ValEdit, Buttons,blcksock,httpsend,uFhemFrame;

type

  { TDevice }

  TDevice = class
  private
    FFound: Boolean;
    FName: string;
    fStatus: string;
    procedure SetStatus(AValue: string);
  public
    property Status : string read fStatus write SetStatus;
    property Name : string read FName write FName;
    property Found : Boolean read FFound write FFound;
  end;

  TInfoEvent = procedure(aInfo : string) of object;
  { TLogThread }

  TLogThread = class(TThread)
    procedure FLogSockStatus(Sender: TObject; Reason: THookSocketReason;
      const Value: String);
  private
    FOnInfo: TInfoEvent;
    FPos : Integer;
    FBuffer : string;
    FInfo : string;
    FLog: THTTPSend;
    FServer: String;
    procedure Info;
  public
    constructor Create(aServer: string);
    procedure Execute; override;
    property Server : string read FServer;
    property OnInfo : TInfoEvent read FOnInfo write FOnInfo;
  end;

  { TfMain }

  TfMain = class(TForm)
    acConnect: TAction;
    acDisconnect: TAction;
    acSave: TAction;
    acAdd: TAction;
    ActionList1: TActionList;
    bConnect: TSpeedButton;
    bConnect1: TSpeedButton;
    bConnect2: TSpeedButton;
    eCommand: TEdit;
    eSearch: TEdit;
    eServer: TComboBox;
    ImageList1: TImageList;
    Label3: TLabel;
    lbLog: TListBox;
    mCommand: TMemo;
    Memo1: TMemo;
    pcPages: TPageControl;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Splitter1: TSplitter;
    tsLog: TTabSheet;
    tsSelected: TTabSheet;
    Kommando: TTabSheet;
    tvMain: TTreeView;
    procedure acConnectExecute(Sender: TObject);
    procedure eCommandKeyPress(Sender: TObject; var Key: char);
    procedure eSearchEnter(Sender: TObject);
    procedure eSearchExit(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure KommandoEnter(Sender: TObject);
    procedure LogThreadInfo(aInfo: string);
    procedure tvMainSelectionChanged(Sender: TObject);
  private
    { private declarations }
    FFrame: TFHEMFrame;
    Server:THTTPSend;
    LogThread : TLogThread;
    LastLogTime : TDateTime;
    function ExecCommand(aCommand : string) : string;
    procedure Refresh;
  public
    { public declarations }
  end;

var
  fMain: TfMain;

implementation

uses Utils,synautil,dateutils;

resourcestring
  strSearch                       = '<suche>';

{$R *.lfm}

{ TLogThread }

procedure TLogThread.FLogSockStatus(Sender: TObject; Reason: THookSocketReason;
  const Value: String);
var
  aStr: String;
  tmp : string;
  cnt: Integer;
begin
  if Terminated then
    begin
      FLog.Abort;
      exit;
    end;
  if Reason=HR_CanRead then
    while FLog.Document.Size > FPos do
      begin
        FLog.Document.Position:=FPos;
        cnt := FLog.Document.Size-FPos;
        if cnt>255 then
          cnt := 255;
        Setlength(tmp,cnt);
        cnt := FLog.Document.Read(tmp[1],cnt);
        FPos := FPos+cnt;
        FBuffer:=FBuffer+copy(tmp,0,cnt);
      end;
  while pos(#10,FBuffer)>0 do
    begin
      FInfo := copy(FBuffer,0,pos(#10,FBuffer)-1);
      FBuffer := copy(FBuffer,pos(#10,FBuffer)+1,length(FBuffer));
      Synchronize(@Info);
    end;
end;

procedure TLogThread.Info;
begin
  if Assigned(FOnInfo) then
    FOnInfo(FInfo);
end;

constructor TLogThread.Create(aServer : string);
begin
  FServer := aServer;
  FPos := 0;
  FLog := THTTPSend.Create;
  inherited Create(False);
end;

procedure TLogThread.Execute;
var
  aStr: String;
  url: String;
begin
  url := 'http://'+FServer+':8083/fhem?XHR=1&inform=type=raw;filter=.*';
  FLog.Sock.OnStatus:=@FLogSockStatus;
  FLog.KeepAlive:=True;
  FLog.HTTPMethod('GET',url);
  while not Terminated do
    begin
      sleep(10);
    end;
  FLog.Free;
end;

{ TDevice }

procedure TDevice.SetStatus(AValue: string);
begin
  if fStatus=AValue then Exit;
  fStatus:=AValue;
end;

{ TfMain }

procedure TfMain.acConnectExecute(Sender: TObject);
begin
  Refresh;
  if Assigned(LogThread) and (LogThread.Server<>eServer.Text) then
    begin
      LogThread.Terminate;
      LogThread.WaitFor;
      FreeAndNil(LogThread);
      lbLog.Clear;
    end;
  if not Assigned(LogThread) then
    begin
      LogThread := TLogThread.Create(eServer.Text);
      LogThread.OnInfo:=@LogThreadInfo;
      tsLog.TabVisible:=True;
    end;
end;

procedure TfMain.eCommandKeyPress(Sender: TObject; var Key: char);
begin
  if Key = #13 then
    begin
      mCommand.Text:=ExecCommand(eCommand.Text);
      eCommand.Text:='';
    end;
end;

procedure TfMain.eSearchEnter(Sender: TObject);
begin
  eSearch.Clear;
  eSearch.Font.Color:=clDefault;
end;

procedure TfMain.eSearchExit(Sender: TObject);
begin
  eSearch.Text:=strSearch;
  eSearch.Font.Color:=clSilver;
end;

procedure TfMain.FormCreate(Sender: TObject);
begin
  Server := THTTPSend.Create;
  Server.Timeout:=500;
  LastLogTime:=Now();
end;

procedure TfMain.FormDestroy(Sender: TObject);
begin
  Server.Free;
end;

procedure TfMain.KommandoEnter(Sender: TObject);
begin
  eCommand.SetFocus;
end;

procedure TfMain.LogThreadInfo(aInfo: string);
begin
  lbLog.AddItem(StringReplace(aInfo,'<br>','',[]),nil);
  lbLog.ItemIndex:=lbLog.Count-1;
  lbLog.MakeCurrentVisible;
end;

procedure TfMain.tvMainSelectionChanged(Sender: TObject);
var
  aFrameClass: TFHEMFrameClass;
  sl: TStringList;
begin
  if Assigned(tvMain.Selected.Data) then
    begin
      FreeAndNil(FFrame);
      aFrameClass := FindFrame(TDevice(tvMain.Selected.Data).Name);
      if aFrameClass<>nil then
        begin
          FFrame := aFrameClass.Create(Self);
          FFrame.Parent := tsSelected;
          FFrame.Align:=alClient;
          sl := TStringList.Create;
          sl.Text := ExecCommand('list '+TDevice(tvMain.Selected.Data).Name);
          FFrame.ProcessList(sl);
          sl.Free;
          tsSelected.TabVisible:=True;
          pcPages.ActivePage:=tsSelected;
        end;
    end;
end;

function TfMain.ExecCommand(aCommand: string): string;
var
  sl: TStringList;
begin
  result := '';
  sl := TStringList.Create;
  Server.Clear;
  if Server.HTTPMethod('GET','http://'+eServer.Text+':8083/fhem?XHR=1&cmd='+HTTPEncode(aCommand)) then
    begin
      if Server.ResultCode=200 then
        begin
          sl.LoadFromStream(Server.Document);
          Result := sl.Text;
        end;
    end;
  sl.Free
end;

procedure TfMain.Refresh;
var
  sl: TStringList;
  i: Integer;
  Category : TTreeNode;
  b: Integer;

  procedure SelectCategory(aCat : string);
  var
    aItem: TTreeNode;
    a: Integer;
  begin
    aItem := nil;
    if tvMain.Items.Count>0 then aItem := tvMain.Items[0];
    while Assigned(aItem) do
      begin
        if aItem.Text=aCat then
          begin
            Category := aItem;
            for a := 0 to Category.Count-1 do
              TDevice(Category.Items[a].Data).Found := False;
            exit;
          end;
        aItem := aItem.GetNextSibling;
        for a := 0 to Category.Count-1 do
          TDevice(Category.Items[a].Data).Found := False;
      end;
    Category := tvMain.Items.Add(nil,aCat);
  end;
  procedure AddDevice(aDev : string);
  var
    aName: String;
    a: Integer;
    aStatus: String;
    aDevice: TTreeNode;
  begin
    aName := copy(trim(aDev),0,pos(' ',trim(aDev))-1);
    aStatus := copy(trim(aDev),pos(' ',trim(aDev))+1,length(aDev));
    for a := 0 to Category.Count-1 do
      if Category.Items[a].Text=aName then
        begin
          TDevice(Category.Items[a].Data).Status := aStatus;
          TDevice(Category.Items[a].Data).Found:=True;
          exit;
        end;
    aDevice := tvMain.Items.AddChild(Category,aName);
    aDevice.Data := TDevice.Create;
    TDevice(aDevice.Data).Name := aName;
    TDevice(aDevice.Data).Status := aStatus;
    TDevice(aDevice.Data).Found:=True;
  end;

begin
  sl := TStringList.Create;
  sl.Text:=ExecCommand('list');
  tvMain.BeginUpdate;
  i := 0;
  while i < sl.Count do
    if trim(sl[i])='' then sl.Delete(i)
    else inc(i);
  if (sl.Count>0) and (copy(lowercase(sl[0]),0,4)='type') then sl.Delete(0);
  for i := 0 to sl.Count-1 do
    begin
      if (copy(sl[i],0,1)<>' ') and (copy(sl[i],length(sl[i]),1)=':') then
        begin
          if Category<>nil then
            begin
              b := 0;
              while b<Category.Count do
                begin
                  if TDevice(Category.Items[b].Data).Found then inc(b)
                  else Category.Items[b].Free;
                end;
            end;
          SelectCategory(copy(sl[i],0,length(sl[i])-1))
        end
      else
        AddDevice(sl[i]);
    end;
  tvMain.EndUpdate;
  sl.Free;
end;

end.

