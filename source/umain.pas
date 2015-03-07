unit uMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, SynMemo, synhighlighterunixshellscript,
  SynHighlighterPerl, SynEdit, SynGutterBase, Forms, Controls, Graphics,
  Dialogs, ExtCtrls, StdCtrls, ComCtrls, ActnList, ValEdit, Buttons, Menus,
  blcksock, httpsend, uFhemFrame, ssl_openssl, types;

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
    acSaveConfig: TAction;
    acDelete: TAction;
    ActionList1: TActionList;
    bConnect: TSpeedButton;
    bConnect1: TSpeedButton;
    bConnect2: TSpeedButton;
    bConnect3: TSpeedButton;
    cbFile: TComboBox;
    eCommand: TEdit;
    eSearchC: TEdit;
    eSearch: TEdit;
    eServer: TComboBox;
    ImageList1: TImageList;
    ImageList2: TImageList;
    Label3: TLabel;
    lbLog: TListBox;
    mCommand: TMemo;
    Memo1: TMemo;
    MenuItem1: TMenuItem;
    Panel4: TPanel;
    pcPages: TPageControl;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    PopupMenu1: TPopupMenu;
    SpeedButton1: TSpeedButton;
    SpeedButton2: TSpeedButton;
    Splitter1: TSplitter;
    eConfig: TSynEdit;
    SynGutterPartList1: TSynGutterPartList;
    SynUNIXShellScriptSyn1: TSynUNIXShellScriptSyn;
    tsConfig: TTabSheet;
    tsLog: TTabSheet;
    tsSelected: TTabSheet;
    tsCommand: TTabSheet;
    tvMain: TTreeView;
    procedure acAddExecute(Sender: TObject);
    procedure acConnectExecute(Sender: TObject);
    procedure acDeleteExecute(Sender: TObject);
    procedure acSaveConfigExecute(Sender: TObject);
    procedure acSaveExecute(Sender: TObject);
    procedure cbFileSelect(Sender: TObject);
    procedure eCommandKeyPress(Sender: TObject; var Key: char);
    procedure eConfigChange(Sender: TObject);
    procedure eConfigMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure eSearchCChange(Sender: TObject);
    procedure eSearchCEnter(Sender: TObject);
    procedure eSearchCExit(Sender: TObject);
    procedure eSearchChange(Sender: TObject);
    procedure eSearchEnter(Sender: TObject);
    procedure eSearchExit(Sender: TObject);
    procedure eServerSelect(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
    procedure SpeedButton2Click(Sender: TObject);
    procedure tsCommandEnter(Sender: TObject);
    procedure LogThreadInfo(aInfo: string);
    procedure ServerSockStatus(Sender: TObject; Reason: THookSocketReason;
      const Value: String);
    procedure tsConfigHide(Sender: TObject);
    procedure tsConfigShow(Sender: TObject);
    procedure tvMainAdvancedCustomDrawItem(Sender: TCustomTreeView;
      Node: TTreeNode; State: TCustomDrawState; Stage: TCustomDrawStage;
      var PaintImages, DefaultDraw: Boolean);
    procedure tvMainSelectionChanged(Sender: TObject);
  private
    { private declarations }
    FFrame: TFHEMFrame;
    Server:THTTPSend;
    LogThread : TLogThread;
    LastLogTime : TDateTime;
    ConnType : string;
    function Refresh: Boolean;
    procedure RefreshTree(sl: TStrings;SelectLast : Boolean = false);
    procedure SaveConfig;
    procedure FindConfig;
    procedure RefreshFileList;
    procedure LoadFile(aFile : string);
    procedure SaveFile(aFile : string);
  public
    { public declarations }
    function BuildConnStr(aServer : string) : string;
    function LoadHTML(aFile: string): string;
    function ChangeVal(aDevice:string;aDetail : string) : string;
    function ExecCommand(aCommand: string; aServer: string): string;
  end;

var
  fMain: TfMain;

  function StripHTML(input : string) : string;

resourcestring
    strSearch                       = '<suche>';
    strConnectionError              = 'Verbindungsfehler';

implementation

uses Utils,synautil,dateutils,LCLProc,SynEditTypes,RegExpr,uAddDevice;

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
          eConfig.Lines.Clear;
        end;
      pcPages.ActivePage:=tsCommand;
      RefreshFileList;
      acAdd.Enabled:=True;
    end
  else Showmessage(strConnectionError+' '+Server.Sock.LastErrorDesc+' Fehlercode:'+IntToStr(Server.ResultCode));
end;

procedure TfMain.acDeleteExecute(Sender: TObject);
var
  Res: String;
begin
  if Assigned(tvMain.Selected) and Assigned(tvMain.Selected.Data) then
    begin
      Res := ExecCommand('delete '+TDevice(tvMain.Selected.Data).Name,eServer.Text);
      if Res = '' then
        begin
          tvMain.Items.Delete(tvMain.Selected);
          acSave.Enabled:=True;
        end
      else Showmessage(Res);
    end;
end;

procedure TfMain.acAddExecute(Sender: TObject);
var
  sl: TStringList;
begin
  acSave.Enabled := fAddDevice.Execute or acSave.Enabled;
  if acSave.Enabled then
    begin
      sl := TStringList.Create;
      sl.Text:=ExecCommand('list',eServer.Text);
      if (sl.Text='') then
        begin
          if ConnType='http://' then
            ConnType:='https://'
          else ConnType:='http://';
        end;
      RefreshTree(sl,True);
      sl.Free;
    end;
end;

procedure TfMain.acSaveConfigExecute(Sender: TObject);
begin
  SaveFile(cbFile.Text);
end;

procedure TfMain.acSaveExecute(Sender: TObject);
var
  Result: String;
begin
  Result := ExecCommand('save',eServer.Text);
  if Result = '' then
    acSave.Enabled:=False;
end;

procedure TfMain.cbFileSelect(Sender: TObject);
begin
  LoadFile(cbFile.Text);
end;

procedure TfMain.eCommandKeyPress(Sender: TObject; var Key: char);
begin
  if Key = #13 then
    begin
      mCommand.Text:=StripHTML(ExecCommand(eCommand.Text,eServer.Text));
      eCommand.Text:='';
    end;
end;

procedure TfMain.eConfigChange(Sender: TObject);
begin
  acSaveConfig.Enabled:=eConfig.Modified;
end;

procedure TfMain.eConfigMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin
  if ssCtrl in Shift then
    eConfig.Font.Size:=round(eConfig.Font.Size+((-WheelDelta)/120));
end;

procedure TfMain.eSearchCChange(Sender: TObject);
begin
  eConfig.SearchReplace(eSearchC.Text,'',[ssoEntireScope]);
end;

procedure TfMain.eSearchCEnter(Sender: TObject);
begin
  eSearchC.Clear;
  eSearchC.Font.Color:=clDefault;
end;

procedure TfMain.eSearchCExit(Sender: TObject);
begin
  eSearchC.Text:=strSearch;
  eSearchC.Font.Color:=clSilver;
end;

procedure TfMain.eSearchChange(Sender: TObject);
var
  aNode: TTreeNode;
begin
  if tvMain.Items.Count=0 then exit;
  aNode := tvMain.Items[0];
  while assigned(aNode) do
    begin
      aNode.Visible := (Assigned(aNode.Data) and (pos(lowercase(eSearch.Text),lowercase(aNode.Text))>0)) or ((trim(eSearch.Text)='') or (eSearch.Text=strSearch) or (aNode.HasChildren));
      if (aNode.Visible and Assigned(aNode.Parent)) and (not ((trim(eSearch.Text)='') or (eSearch.Text=strSearch) or (aNode.HasChildren))) then aNode.Parent.Expanded:=True;
      aNode := aNode.GetNext;
    end;
end;

procedure TfMain.eSearchEnter(Sender: TObject);
begin
  if (trim(eSearch.Text)='') or (eSearch.Text=strSearch) then
    eSearch.Clear;
  eSearch.Font.Color:=clDefault;
end;

procedure TfMain.eSearchExit(Sender: TObject);
begin
  if (trim(eSearch.Text)='') or (eSearch.Text=strSearch) then
    begin
      eSearch.Text:=strSearch;
      eSearch.Font.Color:=clSilver;
    end;
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

procedure TfMain.SpeedButton1Click(Sender: TObject);
begin
  eConfig.SearchReplace(eSearchC.Text,'',[ssoFindContinue]);
end;

procedure TfMain.SpeedButton2Click(Sender: TObject);
begin
  eConfig.SearchReplace(eSearchC.Text,'',[ssoFindContinue,ssoBackwards]);
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

procedure TfMain.tsConfigHide(Sender: TObject);
begin
  if not eConfig.Modified then
    eConfig.Clear;
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
      LoadFile(cbFile.Text)
    end;
end;

procedure TfMain.tvMainAdvancedCustomDrawItem(Sender: TCustomTreeView;
  Node: TTreeNode; State: TCustomDrawState; Stage: TCustomDrawStage;
  var PaintImages, DefaultDraw: Boolean);
var
  aRect: Classes.TRect;
  aCol: TColor;
  al: Integer;
begin
  if Stage = cdPostPaint then
    begin
      if Assigned(Node.Data) then
        begin
          aRect := Node.DisplayRect(True);
          aCol := Sender.Canvas.Font.Color;
          Sender.Canvas.Font.Color:=clSilver;
          al := 150;
          if aRect.Right+10>al then
            al := aRect.Right+10;
          Sender.Canvas.TextOut(al,aRect.Top,TDevice(Node.Data).Status);
          Sender.Canvas.Font.Color:=aCol;
        end
    end
  else DefaultDraw:=True;
end;

procedure TfMain.tvMainSelectionChanged(Sender: TObject);
var
  aFrameClass: TFHEMFrameClass;
  sl: TStringList;
begin
  acDelete.Enabled:=False;
  if Assigned(tvMain.Selected) and Assigned(tvMain.Selected.Data) then
    begin
      if pcPages.ActivePage=tsConfig then
        begin
          eSearchC.Text:='define '+TDevice(tvMain.Selected.Data).Name;
        end
      else
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
      acDelete.Enabled:=True;
    end;
end;

function TfMain.ExecCommand(aCommand: string; aServer: string): string;
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
begin
  sl := TStringList.Create;
  sl.Text:=ExecCommand('list',eServer.Text);
  if (sl.Text='') then
    begin
      if ConnType='http://' then
        ConnType:='https://'
      else ConnType:='http://';
    end;
  RefreshTree(sl);
  if tvMain.Items.Count>0 then
    SaveConfig;
  sl.Free;
  Result := tvMain.Items.Count>0;
end;

procedure TfMain.RefreshTree(sl: TStrings; SelectLast: Boolean);
var
  i: Integer;
  Category : TTreeNode = nil;
  b: Integer;
  Node: TTreeNode;
  aDevice: TTreeNode = nil;

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
  begin
    aName := copy(trim(aDev),0,pos(' ',trim(aDev))-1);
    aStatus := trim(copy(trim(aDev),pos(' ',trim(aDev))+1,length(aDev)));
    for a := 0 to Category.Count-1 do
      if TDevice(Category.Items[a].Data).Name=aName then
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
  if SelectLast and Assigned(aDevice) then tvMain.Selected:=aDevice;
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

procedure TfMain.RefreshFileList;
var
  url: String;
  sl: TStringList;
  aConfig: String;
begin
  sl := TStringList.Create;
  url := BuildConnStr(eServer.Text)+'/fhem?cmd='+HTTPEncode('style list');
  debugln(url);
  Server.Clear;
  if Server.HTTPMethod('GET',url) then
    begin
      if Server.ResultCode=200 then
        begin
          sl.LoadFromStream(Server.Document);
          aConfig := sl.Text;
        end;
    end;
  cbFile.Clear;
  while pos('<a href="/fhem?cmd=style edit ',aConfig)>0 do
    begin
      aConfig:=copy(aConfig,pos('<a href="/fhem?cmd=style edit ',aConfig)+30,length(aConfig));
      cbFile.Items.Add(trim(copy(aConfig,0,pos('">',aConfig)-1)));
      aConfig:=copy(aConfig,pos('">',aConfig)+2,length(aConfig));
    end;
  sl.Free;
  cbFile.Text:='fhem.cfg';
end;

function TfMain.LoadHTML(aFile: string) : string;
var
  url: String;
  sl: TStringList;
begin
  Result := '';
  url := BuildConnStr(eServer.Text)+'/fhem'+aFile;
  debugln(url);
  Server.Clear;
  if Server.HTTPMethod('GET',url) then
    begin
      if Server.ResultCode=200 then
        begin
          sl := TStringList.Create;
          sl.LoadFromStream(Server.Document);
          Result := sl.Text;
          sl.Free;
        end;
    end;
end;

function TfMain.ChangeVal(aDevice: string; aDetail: string): string;
var
  url: String;
  sl: TStringList;
begin
  result := 'Error';
  url := BuildConnStr(eServer.Text)+'/fhem?detail='+aDevice;
  debugln(url);
  Server.Clear;
  sl := TStringList.Create;
  sl.Assign(eConfig.Lines);
  sl.TextLineBreakStyle:=tlbsCRLF;
  WriteStrToStream(Server.Document, aDetail);
  sl.Free;
  Server.MimeType := 'application/x-www-form-urlencoded';
  if Server.HTTPMethod('POST',url) then
    begin
      if Server.ResultCode=200 then
        begin
          result := '';
        end
      else Result := IntToStr(Server.ResultCode)+' '+Server.ResultString;
    end;
end;

procedure TfMain.LoadFile(aFile: string);
var
  url: String;
  sl: TStringList;
  aConfig: String;
begin
  url := BuildConnStr(eServer.Text)+'/fhem?cmd='+HTTPEncode('style edit '+aFile);
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
  aConfig := copy(aConfig,0,pos('</textarea>',aConfig)-1);
  eConfig.Lines.Text:=HTMLDecode(aConfig);
  eConfig.SetFocus;
end;

procedure TfMain.SaveFile(aFile: string);
var
  url: String;
  sl: TStringList;
begin
  if eConfig.Modified then
    begin
      url := BuildConnStr(eServer.Text)+'/fhem?cmd='+HTTPEncode('style edit '+aFile);
      debugln(url);
      Server.Clear;
      sl := TStringList.Create;
      sl.Assign(eConfig.Lines);
      sl.TextLineBreakStyle:=tlbsCRLF;
      WriteStrToStream(Server.Document, 'save=Save+'+aFile+'&saveName='+aFile+'&cmd=style+save+'+aFile+'+&data='+HTTPEncode(sl.Text));
      sl.Free;
      Server.MimeType := 'application/x-www-form-urlencoded';
      if Server.HTTPMethod('POST',url) then
        begin
          if Server.ResultCode=200 then
            begin
              acSaveConfig.Enabled:=False;
              eConfig.Clear;
              tsConfigShow(tsConfig);
            end;
        end;
    end;
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

