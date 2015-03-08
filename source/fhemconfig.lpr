program fhemconfig;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, lazcontrols, fpvectorialpkg, uMain, Utils, laz_synapse, uFhemFrame,
  fDoIf, fpGeneric, fpresence, uAddDevice, fat, fnotify, uAttrEditor
  { you can add units after this };

{$R *.res}

begin
  Application.Title:='FHEMconfig';
  RequireDerivedFormResource := True;
  Application.Initialize;
  Application.CreateForm(TfMain, fMain);
  Application.CreateForm(TfAttrEditor, fAttrEditor);
  Application.Run;
end.

