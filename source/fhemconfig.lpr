program fhemconfig;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, lazcontrols, fpvectorialpkg, uMain, Utils, laz_synapse,
  zvdatetimectrls, uFhemFrame, fDoIf, fpGeneric, fpresence,
  uAddDevice, fat, fnotify, uIcons
  { you can add units after this };

{$R *.res}

begin
  Application.Title:='FHEMconfig';
  RequireDerivedFormResource := True;
  Application.Initialize;
  Application.CreateForm(TfMain, fMain);
  Application.Run;
end.

