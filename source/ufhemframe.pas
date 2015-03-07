unit uFhemFrame;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, contnrs;

type
  { TDevice }

  TDevice = class
  private
    FClassType: string;
    FFound: Boolean;
    FName: string;
    fStatus: string;
    procedure SetStatus(AValue: string);
  public
    property Status : string read fStatus write SetStatus;
    property Name : string read FName write FName;
    property ClassType : string read FClassType write FClassType;
    property Found : Boolean read FFound write FFound;
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
    procedure Change;
    function GetDeviceType: string;virtual;abstract;
  public
    property Name : string read FName write SetName;
    property Device : TDevice read FDevice write SetDevice;
    property DeviceType : string read GetDeviceType;
    procedure ProcessList(aList : TStrings);virtual;
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
  if Result=nil then
    Result := fpGeneric.TfGeneric;
end;

{ TDevice }

procedure TDevice.SetStatus(AValue: string);
begin
  if fStatus=AValue then Exit;
  fStatus:=AValue;
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

procedure TFHEMFrame.ProcessList(aList: TStrings);
begin

end;

finalization
  Frames.Free;
end.

