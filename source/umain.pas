unit uMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls, ComCtrls, ActnList, ValEdit, Buttons,blcksock,httpsend;

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

  { TfMain }

  TfMain = class(TForm)
    acConnect: TAction;
    acDisconnect: TAction;
    ActionList1: TActionList;
    eCommand: TEdit;
    eSearch: TEdit;
    eServer: TComboBox;
    ImageList1: TImageList;
    Label2: TLabel;
    Label3: TLabel;
    mCommand: TMemo;
    Memo1: TMemo;
    pcPages: TPageControl;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    bConnect: TSpeedButton;
    Splitter1: TSplitter;
    tsSelected: TTabSheet;
    Kommando: TTabSheet;
    tvMain: TTreeView;
    procedure acConnectExecute(Sender: TObject);
    procedure eCommandKeyPress(Sender: TObject; var Key: char);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure KommandoEnter(Sender: TObject);
    procedure tvMainSelectionChanged(Sender: TObject);
  private
    { private declarations }
    Server:THTTPSend;
    function ExecCommand(aCommand : string) : string;
    procedure Refresh;
  public
    { public declarations }
  end;

var
  fMain: TfMain;

implementation

uses Utils;

{$R *.lfm}

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
end;

procedure TfMain.eCommandKeyPress(Sender: TObject; var Key: char);
begin
  if Key = #13 then
    begin
      mCommand.Text:=ExecCommand(eCommand.Text);
      eCommand.Text:='';
    end;
end;

procedure TfMain.FormCreate(Sender: TObject);
begin
  Server := THTTPSend.Create;
end;

procedure TfMain.FormDestroy(Sender: TObject);
begin
  Server.Free;
end;

procedure TfMain.KommandoEnter(Sender: TObject);
begin
  eCommand.SetFocus;
end;

procedure TfMain.tvMainSelectionChanged(Sender: TObject);
begin
  if Assigned(tvMain.Selected.Data) then
    begin
      Memo1.Text:=ExecCommand('list '+TDevice(tvMain.Selected.Data).Name);
      tsSelected.TabVisible:=True;
      pcPages.ActivePage:=tsSelected;
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
  if copy(lowercase(sl[0]),0,4)='type' then sl.Delete(0);
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

