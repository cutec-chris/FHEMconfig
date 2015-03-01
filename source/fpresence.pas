unit fPresence;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, uFhemFrame;

type

  { TFrame1 }

  TFrame1 = class(TFHEMFrame)
  private
    { private declarations }
  protected
    function GetDeviceType: string; override;
  public
    { public declarations }
  end;

implementation

{$R *.lfm}

{ TFrame1 }

function TFrame1.GetDeviceType: string;
begin
  Result := 'PRESENCE';
end;

end.

