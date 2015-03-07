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
    eName: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    mEvent: TMemo;
    mCommand: TMemo;
  private
    { private declarations }
  protected
    function GetDeviceType: string; override;
  public
    { public declarations }
    procedure ProcessList(aList: TStrings); override;
  end;

implementation

{$R *.lfm}

{ TfrNotify }

function TfrNotify.GetDeviceType: string;
begin
  Result := 'NOTIFY';
end;

procedure TfrNotify.ProcessList(aList: TStrings);
var
  tmp: String;
begin
  eName.Text:=FName;
  tmp := aList.Text;
end;

initialization
  RegisterFrame(TfrNotify);
end.

