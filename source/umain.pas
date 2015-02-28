unit uMain;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls, ComCtrls, ActnList, ValEdit, Buttons,blcksock,httpsend;

type

  { TfMain }

  TfMain = class(TForm)
    acConnect: TAction;
    acDisconnect: TAction;
    ActionList1: TActionList;
    eSearch: TEdit;
    eServer: TComboBox;
    ImageList1: TImageList;
    Label2: TLabel;
    Label3: TLabel;
    Memo1: TMemo;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    bConnect: TSpeedButton;
    Splitter1: TSplitter;
    tvMain: TTreeView;
    procedure acConnectExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
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

{$R *.lfm}

{ TfMain }

procedure TfMain.acConnectExecute(Sender: TObject);
begin
  Refresh;
end;

procedure TfMain.FormCreate(Sender: TObject);
begin
  Server := THTTPSend.Create;
end;

procedure TfMain.FormDestroy(Sender: TObject);
begin
  Server.Free;
end;

function TfMain.ExecCommand(aCommand: string): string;
var
  sl: TStringList;
begin
  result := '';
  sl := TStringList.Create;
  Server.Clear;
  if Server.HTTPMethod('GET','http://'+eServer.Text+':8083/fhem?XHR=1&cmd='+aCommand) then
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
begin
  sl := TStringList.Create;
  sl.Text:=ExecCommand('list');
  i := 0;
  while i < sl.Count do
    if trim(sl[i])='' then sl.Delete(i)
    else inc(i);
  if copy(lowercase(sl[0]),0,4)='type' then sl.Delete(0);
  for i := 0 to sl.Count-1 do
    begin
      if (copy(sl[i],0,1)<>' ') and (copy(sl[i],length(sl[i]),1)=':') then
        tvMain.Items.Add(nil,copy(sl[i],0,length(sl[i])-1));
    end;
  sl.Free;
end;

end.

