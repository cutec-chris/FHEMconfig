unit uFhemFrame;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, ComCtrls, contnrs;

type
  { TDevice }

  TDevice = class
  private
    FClassType: string;
    FFound: Boolean;
    FII: Integer;
    FName: string;
    FRoom: string;
    fStatus: string;
    procedure SetRoom(AValue: string);
    procedure SetStatus(AValue: string);
  public
    property Status : string read fStatus write SetStatus;
    property Name : string read FName write FName;
    property ClassType : string read FClassType write FClassType;
    property Found : Boolean read FFound write FFound;
    property Room : string read FRoom write SetRoom;
    property ImageIndex : Integer read FII write FII;
    constructor Create;
  end;

  { TFHEMFrame }

  TFHEMFrame = class(TFrame)
  private
    FDevice: TDevice;
    procedure SetDevice(AValue: TDevice);
    procedure SetName(AValue: string);
  protected
    FName: string;
    function ExecCommand(aCmd : string) : string;
    function ChangeValue(aValue : string) : string;
    function GetDeviceType: string;virtual;abstract;
  public
    property Name : string read FName write SetName;
    property Device : TDevice read FDevice write SetDevice;
    property DeviceType : string read GetDeviceType;
    procedure ProcessList(aList : TStrings);virtual;
    procedure LogReceived(aLog : string);virtual;
    function GetFirstParam(aParam : string) : string;
    function RemoveBrackets(aParam : string;aType : char = '(') : string;
    procedure Change;
    function GetDeviceList : TStrings;
    function GetDeviceParams(aDevice : string) : TStrings;
  end;
  TFHEMFrameClass = class of TFHEMFrame;

  procedure RegisterFrame(aFrame : TFHEMFrameClass);
  function FindFrame(aClass : string) : TFHEMFrameClass;

var
  Frames : TClassList;

implementation

uses fpGeneric,uMain;

procedure RegisterFrame(aFrame: TFHEMFrameClass);
begin
  if not Assigned(Frames) then
    Frames := TClassList.Create;
  Frames.Add(aFrame);
end;

function FindFrame(aClass: string): TFHEMFrameClass;
var
  i: Integer;
  SelFrame : TFHEMFrame;
  SelClass : TFHEMFrameClass;
begin
  Result := nil;
  for i := 0 to Frames.Count-1 do
    begin
      SelClass:=TFHEMFrameClass(Frames[i]);
      SelFrame := SelClass.Create(nil);
      if Uppercase(aClass)=UpperCase(SelFrame.GetDeviceType) then
        Result := TFHEMFrameClass(Frames[i]);
      SelFrame.Free;
    end;
end;

{ TDevice }

procedure TDevice.SetStatus(AValue: string);
begin
  if fStatus=AValue then Exit;
  fStatus:=AValue;
end;

constructor TDevice.Create;
begin
  FII := -1;
end;

procedure TDevice.SetRoom(AValue: string);
var
  aNode: TTreeNode;

  procedure CheckRoom(Node : TTreeNode);
  var
    bNode: TTreeNode;
  begin
    bNode := aNode.GetFirstChild;
    while Assigned(bNode) do
      begin
        if bNode.Text=AValue then exit;
        bNode := bNode.GetNextSibling;
      end;
    bNode := fMain.tvMain.Items.AddChild(Node,Self.Name);
    bNode.Data := Self;
    bNode.ImageIndex:=Self.ImageIndex;
    bNode.SelectedIndex:=Self.ImageIndex;
  end;

begin
  if FRoom=AValue then Exit;
  FRoom:=AValue;
  aNode := fMain.RoomNode.GetFirstChild;
  while Assigned(aNode) do
    begin
      if aNode.Text=aValue then
        begin
          CheckRoom(aNode);
          exit;
        end;
      aNode := aNode.GetNextSibling;
    end;
  if AValue='hidden' then exit;
  aNode := fMain.tvMain.Items.AddChild(fMain.RoomNode,AValue);
  CheckRoom(aNode);
end;

{ TFHEMFrame }

procedure TFHEMFrame.SetDevice(AValue: TDevice);
begin
  if FDevice=AValue then Exit;
  FDevice:=AValue;
  FName := FDevice.Name;
end;

procedure TFHEMFrame.SetName(AValue: string);
begin
  if FName=AValue then Exit;
  FName:=AValue;
end;

function TFHEMFrame.ExecCommand(aCmd: string): string;
begin
  Result := fMain.ExecCommand(aCmd,fMain.eServer.Text);
end;

function TFHEMFrame.ChangeValue(aValue: string): string;
begin
  Result := fMain.ChangeVal(FName,aValue);
end;

procedure TFHEMFrame.Change;
begin
  fMain.acSave.Enabled:=True;
end;

function TFHEMFrame.GetDeviceList: TStrings;
begin
  Result := fMain.GetDeviceList;
end;

function TFHEMFrame.GetDeviceParams(aDevice: string): TStrings;
begin
  Result := fMain.GetDeviceParams(aDevice);
end;

procedure TFHEMFrame.ProcessList(aList: TStrings);
begin

end;

procedure TFHEMFrame.LogReceived(aLog: string);
begin

end;

function TFHEMFrame.GetFirstParam(aParam: string): string;
var
  aChar: Char;
  bChar: Char;
  InParam : Integer = 0;
begin
  Result := '';
  aParam:=trim(aParam);
  aChar := copy(aParam,0,1)[1];
  if (aChar <> '(')
  and (aChar <> '{') then
    begin
      exit;
    end;
  if aChar='(' then bChar := ')';
  if aChar='{' then bChar := '}';
  while ((copy(aParam,0,1)<>' ') or (InParam>0)) and (aParam<>'') do
    begin
      Result := Result+copy(aParam,0,1);
      if copy(aParam,0,1)=aChar then inc(InParam);
      if copy(aParam,0,1)=bChar then dec(InParam);
      aParam:=copy(aParam,2,length(aParam));
    end;
end;

function TFHEMFrame.RemoveBrackets(aParam: string; aType: char): string;
begin
  Result := aParam;
  if copy(aParam,length(aParam),1)=#10 then
    aParam:=copy(aParam,1,length(aParam)-1);
  if (copy(aParam,0,1)<>'(')
  or (copy(aParam,length(aParam)-1,1)<>')') then
    Result:=copy(aParam,2,length(aParam)-2);
end;

finalization
  Frames.Free;
end.

