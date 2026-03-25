program FaceDetection;

uses
  Vcl.Forms,
  yolov5faceMain in 'yolov5faceMain.pas' {frmFaceDetection},
  OnnxRuntime in 'OnnxRuntime.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmFaceDetection, frmFaceDetection);
  Application.Run;
end.
