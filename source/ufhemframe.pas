unit uFhemFrame;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, contnrs;

type

  { TFHEMFrame }

  TFHEMFrame = class(TFrame)
  private
    function GetDeviceType: string;virtual;abstract;
  protected
  public
    property DeviceType : string read GetDeviceType;
    procedure ProcessList(aList : TStrings);virtual;
  end;
  TFHEMFrameClass = class of TFHEMFrame;

  procedure RegisterFrame(aFrame : TFHEMFrameClass);
  function FindFrame(aClass : string) : TFHEMFrameClass;

var
  Frames : TClassList;

implementation

uses fpGeneric;

procedure RegisterFrame(aFrame: TFHEMFrameClass);
begin
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
      if aClass=(SelFrame as SelClass).GetDeviceType then
        Result := TFHEMFrameClass(Frames[i]);
    end;
  if Result=nil then
    Result := fpGeneric.TfGeneric;
end;

{ TFHEMFrame }

procedure TFHEMFrame.ProcessList(aList: TStrings);
begin

end;

initialization
  Frames := TClassList.Create;
finalization
  Frames.Free;
end.

