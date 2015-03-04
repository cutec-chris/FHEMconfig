unit fPresence;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, uFhemFrame;

type

  { TFrPresence }

  TFrPresence = class(TFHEMFrame)
  private
    { private declarations }
  protected
    function GetDeviceType: string; override;
  public
    { public declarations }
  end;

implementation

{$R *.lfm}

{ TFrPresence }

function TFrPresence.GetDeviceType: string;
begin
  Result := 'PRESENCE';
end;

initialization
//  RegisterFrame(TFrPresence); not ready
end.

