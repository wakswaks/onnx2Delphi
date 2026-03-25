unit yolov5faceMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  onnxruntime;

type
  TFaceBox = record
    X1, Y1, X2, Y2: Integer;
    Confidence: Single;
  end;

  TfrmFaceDetection = class(TForm)
    btnSelectImage: TButton;
    btnDetectFaces: TButton;
    imgDisplay: TImage;
    pnlBottom: TPanel;
    lblStatus: TLabel;
    OpenDialog: TOpenDialog;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnSelectImageClick(Sender: TObject);
    procedure btnDetectFacesClick(Sender: TObject);
  private
    FApi: POrtApi;
    FEnv: OrtEnv;
    FSession: OrtSession;
    FSessionOptions: OrtSessionOptions;
    FMemoryInfo: OrtMemoryInfo;
    FAllocator: OrtAllocator;
    FInputName: PAnsiChar;
    FOutputName: PAnsiChar;
    FInputShape: array[0..3] of Int64;
    FOutputShape: array[0..3] of Int64;
    FModelLoaded: Boolean;
    FCurrentImage: string;
    FInputDataType: ONNXTensorElementDataType;
    
    procedure InitializeONNX;
    procedure LoadModel(const ModelPath: string);
    procedure PreprocessImage(const Image: TImage; var InputData: TArray<Single>);
    procedure RunInference(const InputData: TArray<Single>; var OutputData: TArray<Single>);
    procedure PostprocessAndDraw(const OutputData: TArray<Single>; Image: TImage);
  public
  end;

var
  frmFaceDetection: TfrmFaceDetection;

implementation

uses
  System.Math, Jpeg, PNGImage, GifImg, System.AnsiStrings;

{$R *.dfm}

const
  INPUT_WIDTH = 640;
  INPUT_HEIGHT = 640;
  CONFIDENCE_THRESHOLD = 0.25;
  IOU_THRESHOLD = 0.45;

procedure TfrmFaceDetection.FormCreate(Sender: TObject);
begin
  FApi := nil;
  FEnv := nil;
  FSession := nil;
  FSessionOptions := nil;
  FMemoryInfo := nil;
  FAllocator := nil;
  FInputName := nil;
  FOutputName := nil;
  FModelLoaded := False;

  imgDisplay.Align := alClient;
  imgDisplay.Stretch := True;
  imgDisplay.Proportional := True;

  OpenDialog.Filter := '图像文件|*.jpg;*.jpeg;*.png;*.bmp;*.gif|所有文件|*.*';

  try
    FApi := GetOrtApi;
    if not Assigned(FApi) then
      raise Exception.Create('无法获取 ONNX Runtime API');

    InitializeONNX;
    LoadModel(ExtractFilePath(ParamStr(0)) + 'yolov5n-face.onnx');
    lblStatus.Caption := '模型加载成功，等待选择图片...';
  except
    on E: Exception do
      lblStatus.Caption := '错误：' + E.Message;
  end;
end;

procedure TfrmFaceDetection.FormDestroy(Sender: TObject);
begin
  if Assigned(FOutputName) and Assigned(FAllocator) then
    FApi^.AllocatorFree(FAllocator, FOutputName);
  if Assigned(FInputName) and Assigned(FAllocator) then
    FApi^.AllocatorFree(FAllocator, FInputName);

  if Assigned(FMemoryInfo) then
    FApi^.ReleaseMemoryInfo(FMemoryInfo);
  if Assigned(FSession) then
    FApi^.ReleaseSession(FSession);
  if Assigned(FSessionOptions) then
    FApi^.ReleaseSessionOptions(FSessionOptions);
  if Assigned(FEnv) then
    FApi^.ReleaseEnv(FEnv);
  if Assigned(FAllocator) then
    FApi^.ReleaseAllocator(FAllocator);
end;

procedure TfrmFaceDetection.InitializeONNX;
var
  LogId: PAnsiChar;
  Status: OrtStatus;
begin
  LogId := System.AnsiStrings.AnsiStrAlloc(20);
  System.AnsiStrings.StrPCopy(LogId, 'FaceDetection');
  try
    Status := FApi^.CreateEnv(ORT_LOGGING_LEVEL_WARNING, LogId, FEnv);
    OrtCheck(Status);

    Status := FApi^.CreateSessionOptions(FSessionOptions);
    OrtCheck(Status);

    Status := FApi^.SetIntraOpNumThreads(FSessionOptions, 4);
    OrtCheck(Status);

    Status := FApi^.GetAllocatorWithDefaultOptions(FAllocator);
    OrtCheck(Status);

    Status := FApi^.CreateCpuMemoryInfo(OrtArenaAllocator, OrtMemTypeCPU, FMemoryInfo);
    OrtCheck(Status);
  finally
    System.AnsiStrings.StrDispose(LogId);
  end;

  FInputShape[0] := 1;
  FInputShape[1] := 3;
  FInputShape[2] := INPUT_HEIGHT;
  FInputShape[3] := INPUT_WIDTH;

  FOutputShape[0] := 1;
  FOutputShape[1] := 25200;
  FOutputShape[2] := 16;

  FInputDataType := ONNX_TENSOR_ELEMENT_DATA_TYPE_FLOAT;
end;

procedure TfrmFaceDetection.LoadModel(const ModelPath: string);
var
  InputCount, OutputCount: NativeUInt;
  Status: OrtStatus;
begin
  if not FileExists(ModelPath) then
    raise Exception.CreateFmt('模型文件不存在：%s', [ModelPath]);

  Status := FApi^.CreateSession(FEnv, PWideChar(WideString(ModelPath)), FSessionOptions, FSession);
  OrtCheck(Status);

  Status := FApi^.SessionGetInputCount(FSession, InputCount);
  OrtCheck(Status);

  Status := FApi^.SessionGetOutputCount(FSession, OutputCount);
  OrtCheck(Status);

  if (InputCount < 1) or (OutputCount < 1) then
    raise Exception.Create('模型输入或输出数量不正确');

  Status := FApi^.SessionGetInputName(FSession, 0, FAllocator, FInputName);
  OrtCheck(Status);

  Status := FApi^.SessionGetOutputName(FSession, 0, FAllocator, FOutputName);
  OrtCheck(Status);

  FModelLoaded := True;
end;

procedure TfrmFaceDetection.PreprocessImage(const Image: TImage; var InputData: TArray<Single>);
var
  Bmp: TBitmap;
  X, Y: Integer;
  Pixel: PRGBQuad;
  Index: Integer;
begin
  Bmp := TBitmap.Create;
  try
    Bmp.PixelFormat := pf32bit;
    Bmp.Width := INPUT_WIDTH;
    Bmp.Height := INPUT_HEIGHT;

    Bmp.Canvas.StretchDraw(Rect(0, 0, INPUT_WIDTH, INPUT_HEIGHT), Image.Picture.Graphic);

    SetLength(InputData, 3 * INPUT_WIDTH * INPUT_HEIGHT);

    for Y := 0 to INPUT_HEIGHT - 1 do
    begin
      Pixel := Bmp.ScanLine[Y];
      for X := 0 to INPUT_WIDTH - 1 do
      begin
        Index := 0 * INPUT_WIDTH * INPUT_HEIGHT + Y * INPUT_WIDTH + X;
        InputData[Index] := Pixel.rgbRed / 255.0;

        Index := 1 * INPUT_WIDTH * INPUT_HEIGHT + Y * INPUT_WIDTH + X;
        InputData[Index] := Pixel.rgbGreen / 255.0;

        Index := 2 * INPUT_WIDTH * INPUT_HEIGHT + Y * INPUT_WIDTH + X;
        InputData[Index] := Pixel.rgbBlue / 255.0;

        Inc(Pixel);
      end;
    end;
  finally
    Bmp.Free;
  end;
end;

procedure TfrmFaceDetection.RunInference(const InputData: TArray<Single>; var OutputData: TArray<Single>);
var
  InputTensor, OutputTensor: OrtValue;
  RunOptions: OrtRunOptions;
  InputNames, OutputNames: PPAnsiChar;
  OutputDataPtr: Pointer;
  OutputSize: NativeUInt;
  Status: OrtStatus;
  LocalInputData: TArray<Single>;
  ShapeArray: array[0..3] of Int64;
begin
  if not FModelLoaded then
    raise Exception.Create('模型未加载');

  LocalInputData := Copy(InputData);

  ShapeArray[0] := FInputShape[0];
  ShapeArray[1] := FInputShape[1];
  ShapeArray[2] := FInputShape[2];
  ShapeArray[3] := FInputShape[3];

  InputTensor := nil;
  OutputTensor := nil;
  RunOptions := nil;

  try
    Status := FApi^.CreateTensorWithDataAsOrtValue(
      FMemoryInfo,
      @LocalInputData[0],
      Length(LocalInputData) * SizeOf(Single),
      @ShapeArray[0],
      4,
      ONNX_TENSOR_ELEMENT_DATA_TYPE_FLOAT,
      InputTensor
    );
    OrtCheck(Status);

    Status := FApi^.CreateRunOptions(RunOptions);
    OrtCheck(Status);

    GetMem(InputNames, SizeOf(PAnsiChar));
    GetMem(OutputNames, SizeOf(PAnsiChar));

    try
      InputNames^ := FInputName;
      OutputNames^ := FOutputName;

      Status := FApi^.Run(
        FSession,
        RunOptions,
        InputNames,
        @InputTensor,
        1,
        OutputNames,
        1,
        @OutputTensor
      );
      OrtCheck(Status);

      Status := FApi^.GetTensorMutableData(OutputTensor, OutputDataPtr);
      OrtCheck(Status);

      var OutputTypeInfo: OrtTypeInfo;
      Status := FApi^.GetTensorTypeAndShape(OutputTensor, OutputTypeInfo);
      OrtCheck(Status);

      var DimCount: NativeUInt;
      Status := FApi^.GetDimensionsCount(OutputTypeInfo, DimCount);
      OrtCheck(Status);

      var Dimensions: array of Int64;
      SetLength(Dimensions, DimCount);
      Status := FApi^.GetDimensions(OutputTypeInfo, @Dimensions[0], DimCount);
      OrtCheck(Status);

      OutputSize := 1;
      for var I := 0 to DimCount - 1 do
        OutputSize := OutputSize * NativeUInt(Dimensions[I]);

      FApi^.ReleaseTensorTypeAndShapeInfo(OutputTypeInfo);

      SetLength(OutputData, OutputSize);
      Move(OutputDataPtr^, OutputData[0], OutputSize * SizeOf(Single));
    finally
      FreeMem(InputNames);
      FreeMem(OutputNames);
    end;
  finally
    if Assigned(OutputTensor) then
      FApi^.ReleaseValue(OutputTensor);
    if Assigned(InputTensor) then
      FApi^.ReleaseValue(InputTensor);
    if Assigned(RunOptions) then
      FApi^.ReleaseRunOptions(RunOptions);
  end;
end;

function CalculateIOU(const Box1, Box2: TRect): Single;
var
  InterRect: TRect;
  InterArea, UnionArea: Integer;
begin
  InterRect.Left := Max(Box1.Left, Box2.Left);
  InterRect.Top := Max(Box1.Top, Box2.Top);
  InterRect.Right := Min(Box1.Right, Box2.Right);
  InterRect.Bottom := Min(Box1.Bottom, Box2.Bottom);

  if (InterRect.Right <= InterRect.Left) or (InterRect.Bottom <= InterRect.Top) then
    Result := 0
  else
  begin
    InterArea := (InterRect.Right - InterRect.Left) * (InterRect.Bottom - InterRect.Top);
    UnionArea := (Box1.Right - Box1.Left) * (Box1.Bottom - Box1.Top) +
                 (Box2.Right - Box2.Left) * (Box2.Bottom - Box2.Top) - InterArea;
    Result := InterArea / UnionArea;
  end;
end;

procedure TfrmFaceDetection.PostprocessAndDraw(const OutputData: TArray<Single>; Image: TImage);
var
  FaceBoxes: array of TFaceBox;
  DetectionCount: Integer;
  I, J: Integer;
  X, Y, W, H: Single;
  ScaleX, ScaleY: Single;
  Bmp: TBitmap;
  Keep: array of Boolean;
  IOU,Conf: Single;
  GridCount: Integer;

begin
  if Length(OutputData) > 0 then
  begin
    GridCount := Length(OutputData) div 16;
  end
  else
    Exit;

  DetectionCount := 0;
  SetLength(FaceBoxes, GridCount);

  ScaleX := Image.Picture.Width / INPUT_WIDTH;
  ScaleY := Image.Picture.Height / INPUT_HEIGHT;

  for I := 0 to GridCount - 1 do
  begin
    Conf := OutputData[I * 16 + 4];

    if Conf > CONFIDENCE_THRESHOLD then
    begin
      X := OutputData[I * 16 + 0];
      Y := OutputData[I * 16 + 1];
      W := OutputData[I * 16 + 2];
      H := OutputData[I * 16 + 3];

      FaceBoxes[DetectionCount].X1 := Trunc((X - W / 2) * ScaleX);
      FaceBoxes[DetectionCount].Y1 := Trunc((Y - H / 2) * ScaleY);
      FaceBoxes[DetectionCount].X2 := Trunc((X + W / 2) * ScaleX);
      FaceBoxes[DetectionCount].Y2 := Trunc((Y + H / 2) * ScaleY);
      FaceBoxes[DetectionCount].Confidence := Conf;
      Inc(DetectionCount);
    end;
  end;

  SetLength(FaceBoxes, DetectionCount);

  SetLength(Keep, DetectionCount);
  for I := 0 to DetectionCount - 1 do
    Keep[I] := True;

  for I := 0 to DetectionCount - 1 do
  begin
    if not Keep[I] then
      Continue;
    for J := I + 1 to DetectionCount - 1 do
    begin
      if not Keep[J] then
        Continue;

      IOU := CalculateIOU(
        Rect(FaceBoxes[I].X1, FaceBoxes[I].Y1, FaceBoxes[I].X2, FaceBoxes[I].Y2),
        Rect(FaceBoxes[J].X1, FaceBoxes[J].Y1, FaceBoxes[J].X2, FaceBoxes[J].Y2)
      );

      if IOU > IOU_THRESHOLD then
      begin
        if FaceBoxes[I].Confidence > FaceBoxes[J].Confidence then
          Keep[J] := False
        else
          Keep[I] := False;
      end;
    end;
  end;

  Bmp := TBitmap.Create;
  try
    Bmp.Assign(Image.Picture.Graphic);
    Bmp.Canvas.Pen.Width := 2;
    Bmp.Canvas.Font.Size := 12;
    Bmp.Canvas.Font.Style := [fsBold];

    for I := 0 to DetectionCount - 1 do
    begin
      if Keep[I] then
      begin
        Bmp.Canvas.Pen.Color := clRed;
        Bmp.Canvas.Brush.Style := bsClear;
        Bmp.Canvas.Rectangle(FaceBoxes[I].X1, FaceBoxes[I].Y1, FaceBoxes[I].X2, FaceBoxes[I].Y2);

        Bmp.Canvas.Brush.Style := bsSolid;
        Bmp.Canvas.Brush.Color := clRed;
        Bmp.Canvas.TextOut(FaceBoxes[I].X1, FaceBoxes[I].Y1 - 18,
          Format('Face: %.2f', [FaceBoxes[I].Confidence]));
      end;
    end;

    Image.Picture.Assign(Bmp);
  finally
    Bmp.Free;
  end;
end;

procedure TfrmFaceDetection.btnSelectImageClick(Sender: TObject);
begin
  OpenDialog.Filter := '图片文件|*.jpg;*.jpeg;*.png;*.bmp;*.gif|所有文件|*.*';
  OpenDialog.FilterIndex := 1;

  if OpenDialog.Execute then
  begin
    try
      FCurrentImage := OpenDialog.FileName;
      imgDisplay.Picture.LoadFromFile(FCurrentImage);
      lblStatus.Caption := '已加载图片：' + ExtractFileName(FCurrentImage);
    except
      on E: Exception do
      begin
        ShowMessageFmt('加载图片失败：%s'#13'文件路径：%s', [E.Message, FCurrentImage]);
        lblStatus.Caption := '加载图片失败：' + E.Message;
      end;
    end;
  end;
end;

procedure TfrmFaceDetection.btnDetectFacesClick(Sender: TObject);
var
  InputData: TArray<Single>;
  OutputData: TArray<Single>;
  StartTime, EndTime: DWORD;
begin
  if imgDisplay.Picture.Graphic = nil then
  begin
    ShowMessage('请先选择一张图片');
    Exit;
  end;

  if not FModelLoaded then
  begin
    ShowMessage('模型未加载');
    Exit;
  end;

  Screen.Cursor := crHourGlass;
  try
    StartTime := GetTickCount;
    lblStatus.Caption := '正在预处理图像...';

    PreprocessImage(imgDisplay, InputData);

    lblStatus.Caption := '正在推理...';
    RunInference(InputData, OutputData);

    lblStatus.Caption := '正在后处理并绘制结果...';
    PostprocessAndDraw(OutputData, imgDisplay);

    EndTime := GetTickCount;
    lblStatus.Caption := Format('识别完成，耗时：%d ms', [EndTime - StartTime]);
  finally
    Screen.Cursor := crDefault;
  end;
end;

end.
