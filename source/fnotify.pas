unit fNotify;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, StdCtrls, uFhemFrame;

type

  { TfrNotify }

  TfrNotify = class(TFHEMFrame)
    Button1: TButton;
    Button2: TButton;
    Edit1: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Memo1: TMemo;
    Memo2: TMemo;
  private
    { private declarations }
  protected
    function GetDeviceType: string; override;
  public
    { public declarations }
  end;

implementation

{$R *.lfm}

{ TfrNotify }

function TfrNotify.GetDeviceType: string;
begin
  Result := 'NOTIFY';
end;

initialization
  RegisterFrame(TfrNotify);
end.

