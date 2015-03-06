unit uAddDevice;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ComCtrls,
  StdCtrls, ButtonPanel;

type

  { TFillThread }

  TFillThread = class(TThread)
  private
    actName: String;
    actSecName: String;
    procedure AddItem;
  public
    constructor Create(CreateSuspended: Boolean; const StackSize: SizeUInt=
  DefaultStackSize);
    procedure Execute; override;
    procedure ParseCommandRef;
  end;

  TModule = class
  public
    Name : string;
    Typ : string;

    Description : string;
    Define : string;
    GetContent : string;
    SetContent : string;
    Attributes : string;
  end;

  { TfAddDevice }

  TfAddDevice = class(TForm)
    ButtonPanel1: TButtonPanel;
    Edit1: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Memo1: TMemo;
    tvMain: TTreeView;
    procedure FormCreate(Sender: TObject);
    procedure FormDeactivate(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
    Modules: TList;
    function Execute : Boolean;
  end;

var
  fAddDevice: TfAddDevice;

implementation

uses uMain,RegExpr;

{$R *.lfm}

{ TFillThread }

procedure TFillThread.AddItem;
var
  aMod: TModule;
begin
  aMod := TModule.Create;
  aMod.Name:=actName;
  aMod.Typ:=actSecName;
  fAddDevice.Modules.Add(aMod);
end;

constructor TFillThread.Create(CreateSuspended: Boolean;
  const StackSize: SizeUInt);
begin
  inherited;
  FreeOnTerminate:=True;
end;

procedure TFillThread.Execute;
var
  FCommandRef: String;
  FCommandRefDE: String;
begin
  ParseCommandRef;
end;

procedure TFillThread.ParseCommandRef;
var
  tmp: String;
  aSec: String;
  tmp1: String;
  i: Integer;
  tmp2: String;
  aSecTp: String;

  procedure FillSection;
  begin
    while (pos('<a href="#',aSec)>0) do
      begin
        aSec := copy(aSec,pos('<a href="#',aSec)+10,length(aSec));
        actName := copy(aSec,0,pos('"',aSec)-1);
        Synchronize(@AddItem);
        aSec := copy(aSec,pos('"></a>',aSec)+6,length(aSec));
      end;

  end;

begin
  tmp := fMain.LoadHTML('/docs/commandref_DE.html');
  tmp := copy(tmp,pos('<b>',tmp)+3,length(tmp));
  tmp := copy(tmp,pos('<b>',tmp)+3,length(tmp));
  aSec := copy(tmp,0,pos('<b>',tmp)-1);
  actSecName := copy(aSec,0,pos('</b>',aSec)-1);
  FillSection;
  tmp := copy(tmp,pos('<b>',tmp)+3,length(tmp));
  aSec := copy(tmp,0,pos('<b>',tmp)-1);
  actSecName := copy(aSec,0,pos('</b>',aSec)-1);
  FillSection;
  tmp := copy(tmp,pos('<b>',tmp)+3,length(tmp));
  aSec := copy(tmp,0,pos('<b>',tmp)-1);
  actSecName := copy(aSec,0,pos('</b>',aSec)-1);
  FillSection;
  tmp := copy(tmp,pos('<b>',tmp)+3,length(tmp));
  aSecTp := 'desc';
  //now we have all Module names
  for i := 0 to fAddDevice.Modules.Count-1 do
    with TModule(fAddDevice.Modules[i]) do
      begin
        tmp1 := '<a name="'+Name+'">';
        aSec := copy(tmp,pos(tmp1,tmp)+9,length(tmp));
        aSec := copy(aSec,pos('</a>',aSec)+4,length(aSec));
        while pos('<a name="',aSec)>0 do
          begin
            tmp1 := copy(aSec,0,pos('<a name="',aSec)-1);
            aSec := copy(aSec,pos('<a name="',aSec)+9,length(aSec));
            tmp2 := copy(aSec,0,pos('"',aSec)-1);
            case aSecTp of
            'desc':Description:=tmp1;
            'define':Define:=tmp1;
            'set':SetContent:=tmp1;
            'get':GetContent:=tmp1;
            'attr':Attributes:=tmp1;
            end;
            if tmp2=Name+'define' then
              begin
                aSecTp := 'define';
              end
            else if tmp2=Name+'set' then
              begin
                aSecTp := 'set';
              end
            else if tmp2=Name+'get' then
              begin
                aSecTp := 'get';
              end
            else if tmp2=Name+'attr' then
              begin
                aSecTp := 'attr';
              end
            else
              begin
                break;
              end;
          end;
      end;
end;

{ TfAddDevice }

procedure TfAddDevice.FormCreate(Sender: TObject);
begin
  Modules := TList.Create;
end;

procedure TfAddDevice.FormDeactivate(Sender: TObject);
begin
  Modules.Free;
end;

function TfAddDevice.Execute: Boolean;
var
  aThread: TFillThread;
begin
  if not Assigned(Self) then
    begin
      Application.CreateForm(TfAddDevice,fAddDevice);
      Self := fAddDevice;
      aThread := TFillThread.Create(True);
      aThread.Execute;
    end;
  Result := Showmodal = mrOK;
end;

end.

