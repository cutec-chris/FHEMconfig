unit fpGeneric;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, StdCtrls, ValEdit, uFhemFrame;

type

  { TfGeneric }

  TfGeneric = class(TFHEMFrame)
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    vAttributes: TValueListEditor;
    vReadings: TValueListEditor;
    vInternals: TValueListEditor;
  private
    { private declarations }
  public
    { public declarations }
  end;

implementation

{$R *.lfm}

end.

