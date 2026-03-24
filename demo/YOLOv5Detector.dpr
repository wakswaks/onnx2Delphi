program YOLOv5Detector;

uses
  Vcl.Forms,
  OnnxRuntime in 'OnnxRuntime.pas',
  YOLOv5Main in 'YOLOv5Main.pas' {MainForm};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
