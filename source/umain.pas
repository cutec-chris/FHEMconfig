unit uMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, SynMemo, synhighlighterunixshellscript,
  SynHighlighterPerl, SynEdit, SynGutterBase, Forms, Controls, Graphics,
  Dialogs, ExtCtrls, StdCtrls, ComCtrls, ActnList, ValEdit, Buttons, blcksock,
  httpsend, uFhemFrame;

type
  TInfoEvent = procedure(aInfo : string) of object;
  { TLogThread }

  TLogThread = class(TThread)
    procedure FLogSockStatus(Sender: TObject; Reason: THookSocketReason;
      const Value: String);
  private
    FConnType: string;
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
    property ConnType : string read FConnType write FConnType;
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
    mCommand: TSynEdit;
    Memo1: TMemo;
    pcPages: TPageControl;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Splitter1: TSplitter;
    eConfig: TSynEdit;
    SynGutterPartList1: TSynGutterPartList;
    SynUNIXShellScriptSyn1: TSynUNIXShellScriptSyn;
    tsConfig: TTabSheet;
    tsLog: TTabSheet;
    tsSelected: TTabSheet;
    tsCommand: TTabSheet;
    tvMain: TTreeView;
    procedure acConnectExecute(Sender: TObject);
    procedure acSaveExecute(Sender: TObject);
    procedure eCommandKeyPress(Sender: TObject; var Key: char);
    procedure eSearchEnter(Sender: TObject);
    procedure eSearchExit(Sender: TObject);
    procedure eServerSelect(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure tsCommandEnter(Sender: TObject);
    procedure LogThreadInfo(aInfo: string);
    procedure ServerSockStatus(Sender: TObject; Reason: THookSocketReason;
      const Value: String);
    procedure tsConfigShow(Sender: TObject);
    procedure tvMainSelectionChanged(Sender: TObject);
  private
    { private declarations }
    FFrame: TFHEMFrame;
    Server:THTTPSend;
    LogThread : TLogThread;
    LastLogTime : TDateTime;
    ConnType : string;
    function Refresh: Boolean;
    procedure SaveConfig;
    procedure FindConfig;
    function BuildConnStr(aServer : string) : string;
  public
    { public declarations }
    function ExecCommand(aCommand: string; aServer: string): string;
  end;

var
  fMain: TfMain;

  function StripHTML(input : string) : string;

implementation

uses Utils,synautil,dateutils,LCLProc;

resourcestring
  strSearch                       = '<suche>';
  strConnectionError              = 'Verbindungsfehler';

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
  url := FServer+'/fhem?XHR=1&inform=type=raw;filter=.*';
  FLog.Sock.OnStatus:=@FLogSockStatus;
  FLog.Timeout:=15000;
  FLog.KeepAlive:=True;
  while not Terminated do
    begin
      try
        FLog.HTTPMethod('GET',url);
        sleep(1000);
      except
        begin
          FLog.Free;
          exit;
        end;
      end;
    end;
  FLog.Free;
end;

{ TfMain }

procedure TfMain.acConnectExecute(Sender: TObject);
begin
  if Assigned(LogThread) and (LogThread.Server<>eServer.Text) then
    begin
      LogThread.Terminate;
      LogThread.WaitFor;
      FreeAndNil(LogThread);
      lbLog.Clear;
      tsLog.TabVisible:=False;
      tsConfig.TabVisible:=False;
    end;
  if Refresh then
    begin
      if not Assigned(LogThread) then
        begin
          LogThread := TLogThread.Create(BuildConnStr(eServer.Text));
          LogThread.ConnType:=ConnType;
          LogThread.OnInfo:=@LogThreadInfo;
          tsLog.TabVisible:=True;
          tsConfig.TabVisible:=True;
        end;
    end
  else Showmessage(strConnectionError+' '+Server.Sock.LastErrorDesc+' Fehlercode:'+IntToStr(Server.ResultCode));
end;

procedure TfMain.acSaveExecute(Sender: TObject);
var
  Result: String;
begin
  Result := ExecCommand('save',eServer.Text);
  if Result = '' then
    acSave.Enabled:=False;
end;

procedure TfMain.eCommandKeyPress(Sender: TObject; var Key: char);
begin
  if Key = #13 then
    begin
      mCommand.Text:=StripHTML(ExecCommand(eCommand.Text,eServer.Text));
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

procedure TfMain.eServerSelect(Sender: TObject);
begin
  tvMain.Items.Clear;
  ConnType:='http://';
  eConfig.Lines.Text:='';
end;

procedure TfMain.FormCreate(Sender: TObject);
begin
  Server := THTTPSend.Create;
  Server.Timeout:=2000;
  Server.Sock.OnStatus:=@ServerSockStatus;
  ConnType := 'http://';
  FindConfig;
end;

procedure TfMain.FormDestroy(Sender: TObject);
begin
  Hide;
  Application.ProcessMessages;
  if Assigned(LogThread) then
    begin
      LogThread.Terminate;
      LogThread.FLog.Abort;
      //LogThread.WaitFor;
      //LogThread.Free;
    end;
  Server.Free;
end;

procedure TfMain.tsCommandEnter(Sender: TObject);
begin
  eCommand.SetFocus;
end;

procedure TfMain.LogThreadInfo(aInfo: string);
begin
  lbLog.AddItem(StringReplace(aInfo,'<br>','',[]),nil);
  lbLog.ItemIndex:=lbLog.Count-1;
  lbLog.MakeCurrentVisible;
end;

procedure TfMain.ServerSockStatus(Sender: TObject; Reason: THookSocketReason;
  const Value: String);
begin
  case Reason of
  HR_ResolvingBegin:debugln('Resolving "'+Value+'" start');
  HR_ResolvingEnd:debugln('Resolving end "'+Value+'"');
  HR_Error:debugln('Error:'+Value);
  end;
end;

procedure TfMain.tsConfigShow(Sender: TObject);
var
  aConfig: String;
  aConnType: String;
  sl: TStringList;
  url: String;
begin
  if eConfig.Lines.Text='' then
    begin
      url := BuildConnStr(eServer.Text)+'/fhem?cmd='+HTTPEncode('style edit fhem.cfg');
      debugln(url);
      Server.Clear;
      if Server.HTTPMethod('GET',url) then
        begin
          if Server.ResultCode=200 then
            begin
              sl := TStringList.Create;
              sl.LoadFromStream(Server.Document);
              aConfig := sl.Text;
              sl.Free;
            end;
        end;
      aConfig := copy(aConfig,pos('<textarea',aConfig)+5,length(aConfig));
      aConfig := copy(aConfig,pos('cols="80" rows="30">',aConfig)+20,length(aConfig));
      aConfig := copy(aConfig,0,pos('</textarea>',aConfig));
      eConfig.Lines.Text:=aConfig;
    end;
end;

procedure TfMain.tvMainSelectionChanged(Sender: TObject);
var
  aFrameClass: TFHEMFrameClass;
  sl: TStringList;
begin
  if Assigned(tvMain.Selected) and Assigned(tvMain.Selected.Data) then
    begin
      FreeAndNil(FFrame);
      aFrameClass := FindFrame(TDevice(tvMain.Selected.Data).ClassType);
      if aFrameClass<>nil then
        begin
          FFrame := aFrameClass.Create(Self);
          FFrame.Parent := tsSelected;
          FFrame.Align:=alClient;
          FFrame.Device:=TDevice(tvMain.Selected.Data);
          sl := TStringList.Create;
          sl.Text := ExecCommand('list '+TDevice(tvMain.Selected.Data).Name,eServer.Text);
          FFrame.ProcessList(sl);
          sl.Free;
          tsSelected.TabVisible:=True;
          pcPages.ActivePage:=tsSelected;
        end;
    end;
end;

function TfMain.ExecCommand(aCommand: string;aServer : string): string;
var
  sl: TStringList;
  aConnType: String;
begin
  result := '';
  sl := TStringList.Create;
  Server.Clear;
  if Server.HTTPMethod('GET',BuildConnStr(aServer)+'/fhem?XHR=1&cmd='+HTTPEncode(aCommand)) then
    begin
      if Server.ResultCode=200 then
        begin
          sl.LoadFromStream(Server.Document);
          Result := sl.Text;
        end;
    end;
  sl.Free
end;

function TfMain.Refresh : Boolean;
var
  sl: TStringList;
  i: Integer;
  Category : TTreeNode = nil;
  b: Integer;
  Node: TTreeNode;

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
    TDevice(aDevice.Data).ClassType := Category.Text;
    TDevice(aDevice.Data).Found:=True;
  end;

begin
  sl := TStringList.Create;
  sl.Text:=ExecCommand('list',eServer.Text);
  if (sl.Text='') then
    begin
      if ConnType='http://' then
        ConnType:='https://'
      else ConnType:='http://';
    end;
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
                  Node := Category.Items[b];
                  if TDevice(Node.Data).Found then inc(b)
                  else Node.Free;
                end;
              if Category.Count=0 then Category.Free;
            end;
          SelectCategory(copy(sl[i],0,length(sl[i])-1))
        end
      else
        AddDevice(sl[i]);
    end;
  tvMain.EndUpdate;
  if tvMain.Items.Count>0 then
    SaveConfig;
  sl.Free;
  Result := tvMain.Items.Count>0;
end;

procedure TfMain.SaveConfig;
var
  sl: TStringList;
begin
  sl := TStringList.Create;
  sl.Add(eServer.Text);
  sl.SaveToFile(ValidateFileName(eServer.Text)+'.fhem.conf');
  sl.Free;
end;

procedure TfMain.FindConfig;
var
  searchResult: TSearchRec;
  sl: TStringList;
begin
  sl := TStringList.Create;
  eServer.Clear;
  if FindFirst('*.fhem.conf', faAnyFile, searchResult) = 0 then
    begin
      repeat
        if copy(searchResult.Name,0,1)<>'.' then
          begin
            sl.LoadFromFile(searchResult.Name);
            eServer.Items.Add(sl[0]);
          end;
      until FindNext(searchResult) <> 0;
      FindClose(searchResult);
    end;
  sl.Free;
  if eServer.Items.Count=1 then eServer.ItemIndex:=0;
end;

function TfMain.BuildConnStr(aServer: string): string;
var
  aConnType: String;
begin
  if pos(':',aServer)=0 then
    aServer := aServer+':8083';
  aConnType := ConnType;
  if pos('://',eServer.Text)>0 then
    aConntype := '';
  Result := aConnType+aServer;
end;

procedure RemoveTag(var aOut,bOut : string;aTag : string;AllowShortenClose : Boolean = False;IgnoreWhen : string = '');
var
  ShortCloser: Boolean;
  aTagOpen: Integer;
  atmp : string = '';
begin
  while pos('<'+aTag,lowercase(aout))>0 do
    begin
      bOut := bOut+copy(aout,0,pos('<'+aTag,lowercase(aout))-1);
      aOut := copy(aOut,pos('<'+aTag,lowercase(aout))+1+length(aTag),length(aOut));
      aTagOpen := 1;
      ShortCloser:=False;
      while (aTagOpen>0) and (length(aOut)>0) do
        begin
          if copy(aOut,0,1)='<' then inc(aTagOpen);
          if copy(aOut,0,2)='/>' then
            ShortCloser := True;
          if copy(aOut,0,1)='>' then dec(aTagOpen);
          atmp := atmp+copy(aOut,0,1);
          aOut := copy(aOut,2,length(aOut));
        end;
      if (IgnoreWhen<>'') and (pos(IgnoreWhen,atmp)>0) then
        bout := bout+atmp;
      if not ShortCloser then
        begin
          if (pos('</'+aTag+'>',lowercase(aout)) >= pos('<',aout)) or (not AllowShortenClose) then
            begin
              atmp := copy(aOut,0,pos('</'+aTag+'>',lowercase(aout))+3+length(aTag));
              if (IgnoreWhen<>'') and (pos(IgnoreWhen,atmp)>0) then
                bout := bout+atmp;
              aOut := copy(aOut,pos('</'+aTag+'>',lowercase(aout))+3+length(aTag),length(aOut))
            end
          else
            aOut := copy(aOut,pos('<',aout),length(aOut));
        end;
    end;
  aOut := bOut+aOut;
  bOut := '';
end;

function StripHTML(input: string): string;
var
  aOut: String;
  bOut: String;
  TagOpen: Integer;
begin
  aOut := StringReplace(input,'<<','<',[rfReplaceAll]);
  aOut := StringReplace(aOut,'</div>','</div>'+#10,[rfReplaceAll]);
  aOut := StringReplace(aOut,'<br>',#10,[rfReplaceAll]);
  aOut := StringReplace(aOut,'<br/>',#10,[rfReplaceAll]);
  bOut := '';
  RemoveTag(aOut,bOut,'script');
  RemoveTag(aOut,bOut,'style');
  TagOpen := 0;
  while length(aOut)>0 do
    begin
      if copy(aOut,0,1)='<' then
        begin
          aOut := copy(aOut,2,length(aOut));
          TagOpen:=1;
          while (TagOpen>0) and (length(aOut)>0) do
            begin
              if copy(aOut,0,1)='<' then inc(TagOpen);
              if copy(aOut,0,1)='>' then dec(TagOpen);
              aOut := copy(aOut,2,length(aOut));
            end;
        end
      else
        begin
          bOut := bOut+copy(aOut,0,1);
          aOut := copy(aOut,2,length(aOut));
        end;
    end;
  Result := HTMLDecode(bOut);
end;

end.

