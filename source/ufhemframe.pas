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
  end;
  TFHEMFrameClass = class of TFHEMFrame;

  procedure RegisterFrame(aFrame : TFHEMFrameClass);

var
  Frames : TClassList;

implementation

procedure RegisterFrame(aFrame: TFHEMFrameClass);
begin
  Frames.Add(aFrame);
end;

initialization
  Frames := TClassList.Create;
finalization
  Frames.Free;
end.

