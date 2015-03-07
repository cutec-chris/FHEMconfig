program fhemcontrol;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, lazcontrols, fpvectorialpkg, uMain, Utils, laz_synapse, uFhemFrame,
  fDoIf, fpGeneric, fpresence, uAddDevice, fat, fnotify
  { you can add units after this };

{$R *.res}

begin
  RequireDerivedFormResource := True;
  Application.Initialize;
  Application.CreateForm(TfMain, fMain);
  Application.Run;
end.

