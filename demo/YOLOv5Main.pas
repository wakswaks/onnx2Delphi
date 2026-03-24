unit YOLOv5Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.ComCtrls,
    onnxruntime;

type
  TMainForm = class(TForm)
    Panel1: TPanel;
    Image1: TImage;
    btnSelectImage: TButton;
    btnDetect: TButton;
    OpenDialog1: TOpenDialog;
    StatusBar1: TStatusBar;
    Memo1: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnSelectImageClick(Sender: TObject);
    procedure btnDetectClick(Sender: TObject);
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
    FInputDataType: ONNXTensorElementDataType;  // 输入数据类型
    procedure InitializeONNX;
    procedure LoadModel(const ModelPath: string);
    procedure PreprocessImage(const Image: TImage; var InputData: TArray<Single>);
    procedure PreprocessImageFP16(const Image: TImage; var InputData: TArray<Word>);
    procedure RunInference(const InputData: TArray<Single>; var OutputData: TArray<Single>);
    procedure RunInferenceFP16(const InputData: TArray<Word>; var OutputData: TArray<Single>);
    procedure PostprocessAndDraw(const OutputData: TArray<Single>; Image: TImage);
    function GetInputTypeInfo(out dataType: ONNXTensorElementDataType): Boolean;
  public
    { Public declarations }
  end;

  TDetection = record
    ClassID: Integer;
    Confidence: Single;
    X1, Y1, X2, Y2: Integer;
  end;



var
  MainForm: TMainForm;
  COCO_CLASSES: array[0..79] of string = (
    'person', 'bicycle', 'car', 'motorcycle', 'airplane', 'bus', 'train', 'truck',
    'boat', 'traffic light', 'fire hydrant', 'stop sign', 'parking meter', 'bench',
    'bird', 'cat', 'dog', 'horse', 'sheep', 'cow', 'elephant', 'bear', 'zebra',
    'giraffe', 'backpack', 'umbrella', 'handbag', 'tie', 'suitcase', 'frisbee',
    'skis', 'snowboard', 'sports ball', 'kite', 'baseball bat', 'baseball glove',
    'skateboard', 'surfboard', 'tennis racket', 'bottle', 'wine glass', 'cup',
    'fork', 'knife', 'spoon', 'bowl', 'banana', 'apple', 'sandwich', 'orange',
    'broccoli', 'carrot', 'hot dog', 'pizza', 'donut', 'cake', 'chair', 'couch',
    'potted plant', 'bed', 'dining table', 'toilet', 'tv', 'laptop', 'mouse',
    'remote', 'keyboard', 'cell phone', 'microwave', 'oven', 'toaster', 'sink',
    'refrigerator', 'book', 'clock', 'vase', 'scissors', 'teddy bear', 'hair drier',
    'toothbrush'
  );


  function FloatToFP16(const Value: Single): Word;

implementation
uses System.Math, Jpeg, PNGImage, System.AnsiStrings;
{$R *.dfm}

type
  TCreateTensorWithDataAsOrtValue = function(info: OrtMemoryInfo; p_data: Pointer;
    p_data_len: NativeUInt; shape: PInt64; shape_len: NativeUInt;
    type_: ONNXTensorElementDataType; out value: OrtValue): OrtStatus; stdcall;

const
  INPUT_WIDTH = 640;
  INPUT_HEIGHT = 640;
  CONFIDENCE_THRESHOLD = 0.25;
  IOU_THRESHOLD = 0.45;



// FP16 转换辅助函数
function FloatToFP16(const Value: Single): Word;
var
  FloatBits: Cardinal;
  Sign, Exponent, Mantissa: Cardinal;
  Exp: Integer;
begin
  FloatBits := PCardinal(@Value)^;
  Sign := (FloatBits shr 31) and $0001;
  Exponent := (FloatBits shr 23) and $00FF;
  Mantissa := FloatBits and $007FFFFF;
  
  // 处理特殊值
  if Exponent = 0 then
  begin
    // 零或非规格化数
    Result := Word(Sign shl 15);
    Exit;
  end;
  
  if Exponent = 255 then
  begin
    // 无穷大或 NaN
    Result := Word((Sign shl 15) or $7C00);
    Exit;
  end;
  
  // 规格化数 - 使用 Integer 计算避免溢出
  Exp := Integer(Exponent) - 127 + 15;  // 调整指数偏移
  
  // 处理指数溢出
  if Exp >= 31 then
  begin
    Result := Word((Sign shl 15) or $7C00);  // 溢出到无穷大
    Exit;
  end;
  
  if Exp <= 0 then
  begin
    Result := Word(Sign shl 15);  // 下溢到零
    Exit;
  end;
  
  // 舍入到最近
  Mantissa := (Mantissa + $00000FFF) shr 13;
  if Mantissa >= $0400 then
  begin
    // 进位
    Mantissa := 0;
    Inc(Exp);
    if Exp >= 31 then
    begin
      Result := Word((Sign shl 15) or $7C00);
      Exit;
    end;
  end;
  
  Result := Word((Sign shl 15) or (Cardinal(Exp) shl 10) or Mantissa);
end;

function FP16ToFloat(const Value: Word): Single;
var
  Sign, Mantissa: Cardinal;
  Exponent: Integer;
  FloatBits: Cardinal;
begin
  Sign := (Value shr 15) and $0001;
  Exponent := Integer((Value shr 10) and $001F);
  Mantissa := Value and $03FF;
  
  // 处理特殊值
  if Exponent = 0 then
  begin
    if Mantissa = 0 then
    begin
      // 零
      Result := 0.0;
      Exit;
    end;
    // 非规格化数 - 简化处理为零
    Result := 0.0;
    Exit;
  end;
  
  if Exponent = 31 then
  begin
    if Mantissa = 0 then
      Result := Infinity  // 无穷大
    else
      Result := NaN;  // NaN
    Exit;
  end;
  
  // 规格化数 - 使用 Integer 计算避免溢出
  Exponent := Exponent - 15 + 127;  // 调整指数偏移
  Mantissa := Mantissa shl 13;  // 左移到 FP32 位置
  
  FloatBits := (Sign shl 31) or (Cardinal(Exponent) shl 23) or Mantissa;
  Result := PSingle(@FloatBits)^;
end;

procedure TMainForm.FormCreate(Sender: TObject);
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

  Image1.Align := alClient;
  Image1.Stretch := True;
  Image1.Proportional := True;

  OpenDialog1.Filter := '图像文件|*.jpg;*.jpeg;*.png;*.bmp|所有文件|*.*';

  try
    FApi := GetOrtApi;
    if not Assigned(FApi) then
      raise Exception.Create('无法获取ONNX Runtime API');
      
    InitializeONNX;                                             //
    //squeezenet.onnx
    LoadModel(ExtractFilePath(ParamStr(0)) + 'yolov5s6.onnx');
  //  LoadModel(ExtractFilePath(ParamStr(0)) + 'squeezenet.onnx');
   // LoadModel(ExtractFilePath(ParamStr(0)) + 'yolov5s.onnx');
    StatusBar1.SimpleText := '模型加载成功，等待选择图片...';
  except
    on E: Exception do
      StatusBar1.SimpleText := '错误: ' + E.Message;
  end;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
begin
  // 使用 allocator 释放名称字符串
  if Assigned(FOutputName) and Assigned(FAllocator) then
    FApi^.AllocatorFree(FAllocator, FOutputName);
  if Assigned(FInputName) and Assigned(FAllocator) then
    FApi^.AllocatorFree(FAllocator, FInputName);

  // 释放其他资源
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

procedure TMainForm.InitializeONNX;
var
  LogId: PansiChar;
  Status: OrtStatus;
begin
  LogId := System.AnsiStrings.AnsiStrAlloc(6);
  System.AnsiStrings.StrPCopy(LogId, 'YOLOv5');
  //LogId:=PAnsiChar(ansistring('YOLOv5'));
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
  FOutputShape[2] := 85;
  
  // 设置输入数据类型 - 根据模型类型修改
  // FP16 模型：FInputDataType := ONNX_TENSOR_ELEMENT_DATA_TYPE_FLOAT16;
  // FP32 模型：FInputDataType := ONNX_TENSOR_ELEMENT_DATA_TYPE_FLOAT;
  FInputDataType := ONNX_TENSOR_ELEMENT_DATA_TYPE_FLOAT16;  //ONNX_TENSOR_ELEMENT_DATA_TYPE_FLOAT16     ONNX_TENSOR_ELEMENT_DATA_TYPE_FLOAT
end;

procedure TMainForm.LoadModel(const ModelPath: string);
var
  InputCount, OutputCount: NativeUInt;
  Status: OrtStatus;
begin
  if not FileExists(ModelPath) then
    raise Exception.CreateFmt('模型文件不存在: %s', [ModelPath]);

  Status := FApi^.CreateSession(FEnv, PwideChar(wideString(ModelPath)), FSessionOptions, FSession);
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

  // 使用 FormCreate 中设置的输入数据类型
  if FInputDataType = ONNX_TENSOR_ELEMENT_DATA_TYPE_FLOAT16 then
    Memo1.Lines.Add('模型输入类型：FP16')
  else
    Memo1.Lines.Add('模型输入类型：FP32');

  FModelLoaded := True;
end;

function TMainForm.GetInputTypeInfo(out dataType: ONNXTensorElementDataType): Boolean;
var
  Status: OrtStatus;
  InputTypeInfo: OrtTypeInfo;
  TensorTypeInfo: OrtTensorTypeAndShapeInfo;
begin
  Result := False;
  dataType := ONNX_TENSOR_ELEMENT_DATA_TYPE_UNDEFINED;
  InputTypeInfo := nil;
  TensorTypeInfo := nil;
  
  Status := FApi^.SessionGetInputTypeInfo(FSession, 0, InputTypeInfo);
  if Status <> nil then
  begin
    FApi^.ReleaseStatus(Status);
    Exit;
  end;
  
  try
    Status := FApi^.CastTypeInfoToTensorInfo(InputTypeInfo, TensorTypeInfo);
    if Status <> nil then
    begin
      FApi^.ReleaseStatus(Status);
      Exit;
    end;
    
    Status := FApi^.GetTensorElementType(TensorTypeInfo, dataType);
    if Status <> nil then
    begin
      FApi^.ReleaseStatus(Status);
      Exit;
    end;
    
    Result := True;
  finally
    if Assigned(TensorTypeInfo) then
      FApi^.ReleaseTensorTypeAndShapeInfo(TensorTypeInfo);
    if Assigned(InputTypeInfo) then
      FApi^.ReleaseTypeInfo(InputTypeInfo);
  end;
end;

procedure TMainForm.PreprocessImage(const Image: TImage; var InputData: TArray<Single>);
var
  Bmp: TBitmap;
  X, Y, C: Integer;
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

procedure TMainForm.PreprocessImageFP16(const Image: TImage; var InputData: TArray<Word>);
var
  Bmp: TBitmap;
  X, Y: Integer;
  Pixel: PRGBQuad;
  Index: Integer;
  FloatVal: Single;
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
        // R 通道 - 转换为 FP16
        FloatVal := Pixel.rgbRed / 255.0;
        Index := 0 * INPUT_WIDTH * INPUT_HEIGHT + Y * INPUT_WIDTH + X;
        InputData[Index] := FloatToFP16(FloatVal);

        // G 通道 - 转换为 FP16
        FloatVal := Pixel.rgbGreen / 255.0;
        Index := 1 * INPUT_WIDTH * INPUT_HEIGHT + Y * INPUT_WIDTH + X;
        InputData[Index] := FloatToFP16(FloatVal);

        // B 通道 - 转换为 FP16
        FloatVal := Pixel.rgbBlue / 255.0;
        Index := 2 * INPUT_WIDTH * INPUT_HEIGHT + Y * INPUT_WIDTH + X;
        InputData[Index] := FloatToFP16(FloatVal);

        Inc(Pixel);
      end;
    end;
  finally
    Bmp.Free;
  end;
end;

procedure TMainForm.RunInference(const InputData: TArray<Single>; var OutputData: TArray<Single>);
var
  InputTensor, OutputTensor: OrtValue;
  RunOptions: OrtRunOptions;
  InputNames, OutputNames: PPAnsiChar;
  OutputDataPtr: Pointer;
  OutputSize: NativeUInt;
  Status: OrtStatus;
  CreateTensorFunc: TCreateTensorWithDataAsOrtValue;
  LocalInputData: TArray<Single>;
  ShapeArray: array[0..3] of Int64;
  FuncPtr: Pointer;
begin
  if not FModelLoaded then
    raise Exception.Create('模型未加载');

  // 创建本地副本
  LocalInputData := Copy(InputData);
  
  // 复制到本地数组
  ShapeArray[0] := FInputShape[0];
  ShapeArray[1] := FInputShape[1];
  ShapeArray[2] := FInputShape[2];
  ShapeArray[3] := FInputShape[3];

  InputTensor := nil;
  OutputTensor := nil;
  RunOptions := nil;

  try
    // 调试输出
    Memo1.Lines.Add(Format('FApi = %d', [NativeUInt(FApi)]));
    Memo1.Lines.Add(Format('FMemoryInfo = %d', [NativeUInt(FMemoryInfo)]));
    Memo1.Lines.Add(Format('LocalInputData length = %d', [Length(LocalInputData)]));
    Memo1.Lines.Add(Format('InputShape = [%d, %d, %d, %d]', [FInputShape[0], FInputShape[1], FInputShape[2], FInputShape[3]]));
    Memo1.Lines.Add(Format('ONNX_TENSOR_ELEMENT_DATA_TYPE_FLOAT = %d', [Integer(ONNX_TENSOR_ELEMENT_DATA_TYPE_FLOAT)]));
    
    // 直接使用 FApi^.CreateTensorWithDataAsOrtValue
    Status := FApi^.CreateTensorWithDataAsOrtValue(
      FMemoryInfo,
      @LocalInputData[0],
      Length(LocalInputData) * SizeOf(Single),
      @ShapeArray[0],
      4,
      ONNX_TENSOR_ELEMENT_DATA_TYPE_FLOAT,
      InputTensor
    );
    //OrtCheck(Status);

    if Status <> nil then
      begin
        Memo1 .Lines.Add('CreateTensorWithDataAsOrtValue failed: '+ string(FApi^.GetErrorMessage(Status)));
        FApi^.ReleaseStatus(Status);
        Exit;
      end;


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

      // 获取实际输出张量的形状
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
      
      // 计算输出元素总数
      OutputSize := 1;
      for var I := 0 to DimCount - 1 do
        OutputSize := OutputSize * NativeUInt(Dimensions[I]);
      
      FApi^.ReleaseTensorTypeAndShapeInfo(OutputTypeInfo);
      
      // 调试输出
      if DimCount >= 4 then
        Memo1.Lines.Add(Format('输出维度：%d, [%d, %d, %d, %d]', [DimCount, Dimensions[0], Dimensions[1], Dimensions[2], Dimensions[3]]))
      else if DimCount = 3 then
        Memo1.Lines.Add(Format('输出维度：%d, [%d, %d, %d]', [DimCount, Dimensions[0], Dimensions[1], Dimensions[2]]))
      else if DimCount = 2 then
        Memo1.Lines.Add(Format('输出维度：%d, [%d, %d]', [DimCount, Dimensions[0], Dimensions[1]]))
      else if DimCount = 1 then
        Memo1.Lines.Add(Format('输出维度：%d, [%d]', [DimCount, Dimensions[0]]))
      else
        Memo1.Lines.Add(Format('输出维度：%d', [DimCount]));
      Memo1.Lines.Add(Format('输出元素总数：%d', [OutputSize]));
      
      // FP16 输出需要转换为 FP32
      SetLength(OutputData, OutputSize);
      var FP16Data: PWord;
      FP16Data := PWord(OutputDataPtr);
      for var I := 0 to OutputSize - 1 do
        OutputData[I] := FP16ToFloat(PWord(NativeUInt(FP16Data) + I * SizeOf(Word))^);
    finally
      FreeMem(InputNames);
      FreeMem(OutputNames);
    end;
  finally
    if Assigned(OutputTensor) then FApi^.ReleaseValue(OutputTensor);
    if Assigned(InputTensor) then FApi^.ReleaseValue(InputTensor);
    if Assigned(RunOptions) then FApi^.ReleaseRunOptions(RunOptions);
  end;
end;

procedure TMainForm.RunInferenceFP16(const InputData: TArray<Word>; var OutputData: TArray<Single>);
var
  InputTensor, OutputTensor: OrtValue;
  RunOptions: OrtRunOptions;
  InputNames, OutputNames: PPAnsiChar;
  OutputDataPtr: Pointer;
  OutputSize: NativeUInt;
  Status: OrtStatus;
  LocalInputData: TArray<Word>;
  ShapeArray: array[0..3] of Int64;
begin
  if not FModelLoaded then
    raise Exception.Create('模型未加载');

  // 创建本地副本
  LocalInputData := Copy(InputData);
  
  // 复制到本地数组
  ShapeArray[0] := FInputShape[0];
  ShapeArray[1] := FInputShape[1];
  ShapeArray[2] := FInputShape[2];
  ShapeArray[3] := FInputShape[3];

  InputTensor := nil;
  OutputTensor := nil;
  RunOptions := nil;
  OutputDataPtr := nil;

  try
    // 调试输出
    Memo1.Lines.Add(Format('FApi = %d', [NativeUInt(FApi)]));
    Memo1.Lines.Add(Format('FMemoryInfo = %d', [NativeUInt(FMemoryInfo)]));
    Memo1.Lines.Add(Format('LocalInputData length = %d', [Length(LocalInputData)]));
    Memo1.Lines.Add(Format('InputShape = [%d, %d, %d, %d]', [FInputShape[0], FInputShape[1], FInputShape[2], FInputShape[3]]));
    Memo1.Lines.Add(Format('ONNX_TENSOR_ELEMENT_DATA_TYPE_FLOAT16 = %d', [Integer(ONNX_TENSOR_ELEMENT_DATA_TYPE_FLOAT16)]));
    
    // 使用 FP16 数据类型创建张量
    Status := FApi^.CreateTensorWithDataAsOrtValue(
      FMemoryInfo,
      @LocalInputData[0],
      Length(LocalInputData) * SizeOf(Word),
      @ShapeArray[0],
      4,
      ONNX_TENSOR_ELEMENT_DATA_TYPE_FLOAT16,
      InputTensor
    );

    if Status <> nil then
      begin
        Memo1.Lines.Add('CreateTensorWithDataAsOrtValue failed: '+ string(FApi^.GetErrorMessage(Status)));
        FApi^.ReleaseStatus(Status);
        Exit;
      end;

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
      
      // 调试输出 - Run 成功
      Memo1.Lines.Add('Run succeeded');

      Status := FApi^.GetTensorMutableData(OutputTensor, OutputDataPtr);
      OrtCheck(Status);
      
      // 调试输出
      Memo1.Lines.Add(Format('OutputDataPtr = %d', [NativeUInt(OutputDataPtr)]));
      
      if OutputDataPtr = nil then
        raise Exception.Create('OutputDataPtr is nil');

      // 获取实际输出张量的形状
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
      
      // 计算输出元素总数
      OutputSize := 1;
      for var I := 0 to DimCount - 1 do
        OutputSize := OutputSize * NativeUInt(Dimensions[I]);
      
      FApi^.ReleaseTensorTypeAndShapeInfo(OutputTypeInfo);
      
      // 调试输出
      if DimCount >= 4 then
        Memo1.Lines.Add(Format('输出维度：%d, [%d, %d, %d, %d]', [DimCount, Dimensions[0], Dimensions[1], Dimensions[2], Dimensions[3]]))
      else if DimCount = 3 then
        Memo1.Lines.Add(Format('输出维度：%d, [%d, %d, %d]', [DimCount, Dimensions[0], Dimensions[1], Dimensions[2]]))
      else if DimCount = 2 then
        Memo1.Lines.Add(Format('输出维度：%d, [%d, %d]', [DimCount, Dimensions[0], Dimensions[1]]))
      else if DimCount = 1 then
        Memo1.Lines.Add(Format('输出维度：%d, [%d]', [DimCount, Dimensions[0]]))
      else
        Memo1.Lines.Add(Format('输出维度：%d', [DimCount]));
      Memo1.Lines.Add(Format('输出元素总数：%d', [OutputSize]));
      
      // FP16 输出需要转换为 FP32
      SetLength(OutputData, OutputSize);
      var FP16Data: PWord;
      FP16Data := PWord(OutputDataPtr);
      for var I := 0 to OutputSize - 1 do
      begin
        OutputData[I] := FP16ToFloat(FP16Data^);
        Inc(FP16Data);
      end;
    finally
      FreeMem(InputNames);
      FreeMem(OutputNames);
    end;
  finally
    if Assigned(OutputTensor) then FApi^.ReleaseValue(OutputTensor);
    if Assigned(InputTensor) then FApi^.ReleaseValue(InputTensor);
    if Assigned(RunOptions) then FApi^.ReleaseRunOptions(RunOptions);
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

procedure TMainForm.PostprocessAndDraw(const OutputData: TArray<Single>; Image: TImage);
var
  Detections: array of TDetection;
  DetectionCount: Integer;
  I, J, ClassIdx: Integer;
  X, Y, W, H: Single;
  MaxConf, Conf: Single;
  ScaleX, ScaleY: Single;
  Bmp: TBitmap;
  R: TRect;
  Keep: array of Boolean;
  IOU: Single;
  GridCount, ClassCount: Integer;
begin
  // 计算网格数量和类别数量
  if Length(OutputData) > 0 then
  begin
    GridCount := Length(OutputData) div 85;  // 假设每个检测有 85 个值（4 个框 + 1 个置信度 + 80 个类别）
    ClassCount := 80;  // COCO 数据集有 80 个类别
  end
  else
    Exit;
  
  DetectionCount := 0;
  SetLength(Detections, GridCount);

  ScaleX := Image.Picture.Width / INPUT_WIDTH;
  ScaleY := Image.Picture.Height / INPUT_HEIGHT;

  for I := 0 to GridCount - 1 do
  begin
    MaxConf := 0;
    ClassIdx := 0;

    for J := 5 to 4 + ClassCount do
    begin
      // 检查索引是否越界
      if (I * 85 + J) < Length(OutputData) then
        Conf := OutputData[I * 85 + J]
      else
        Conf := 0;
        
      if Conf > MaxConf then
      begin
        MaxConf := Conf;
        ClassIdx := J - 5;
      end;
    end;

    // 检查索引是否越界
    if (I * 85 + 4) < Length(OutputData) then
    begin
      if (OutputData[I * 85 + 4] * MaxConf) > CONFIDENCE_THRESHOLD then
      begin
        X := OutputData[I * 85 + 0];
        Y := OutputData[I * 85 + 1];
        W := OutputData[I * 85 + 2];
        H := OutputData[I * 85 + 3];

        Detections[DetectionCount].ClassID := ClassIdx;
        Detections[DetectionCount].Confidence := OutputData[I * 85 + 4] * MaxConf;
        Detections[DetectionCount].X1 := Trunc((X - W / 2) * ScaleX);
        Detections[DetectionCount].Y1 := Trunc((Y - H / 2) * ScaleY);
        Detections[DetectionCount].X2 := Trunc((X + W / 2) * ScaleX);
        Detections[DetectionCount].Y2 := Trunc((Y + H / 2) * ScaleY);
        Inc(DetectionCount);
      end;
    end;
  end;

  SetLength(Detections, DetectionCount);

  SetLength(Keep, DetectionCount);
  for I := 0 to DetectionCount - 1 do
    Keep[I] := True;

  for I := 0 to DetectionCount - 1 do
  begin
    if not Keep[I] then Continue;
    for J := I + 1 to DetectionCount - 1 do
    begin
      if not Keep[J] then Continue;
      if Detections[I].ClassID = Detections[J].ClassID then
      begin
        R.Left := Detections[I].X1;
        R.Top := Detections[I].Y1;
        R.Right := Detections[I].X2;
        R.Bottom := Detections[I].Y2;

        IOU := CalculateIOU(R, Rect(Detections[J].X1, Detections[J].Y1, Detections[J].X2, Detections[J].Y2));
        if IOU > IOU_THRESHOLD then
        begin
          if Detections[I].Confidence > Detections[J].Confidence then
            Keep[J] := False
          else
            Keep[I] := False;
        end;
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
        case Detections[I].ClassID mod 8 of
          0: Bmp.Canvas.Pen.Color := clRed;
          1: Bmp.Canvas.Pen.Color := clLime;
          2: Bmp.Canvas.Pen.Color := clBlue;
          3: Bmp.Canvas.Pen.Color := clYellow;
          4: Bmp.Canvas.Pen.Color := clFuchsia;
          5: Bmp.Canvas.Pen.Color := clAqua;
          6: Bmp.Canvas.Pen.Color := clWhite;
          7: Bmp.Canvas.Pen.Color := clGray;
        end;

        Bmp.Canvas.Brush.Style := bsClear;
        Bmp.Canvas.Rectangle(Detections[I].X1, Detections[I].Y1, Detections[I].X2, Detections[I].Y2);

        Bmp.Canvas.Brush.Style := bsSolid;
        Bmp.Canvas.Brush.Color := Bmp.Canvas.Pen.Color;
        Bmp.Canvas.TextOut(Detections[I].X1, Detections[I].Y1 - 18,
          Format('%s %.2f', [COCO_CLASSES[Detections[I].ClassID], Detections[I].Confidence]));
      end;
    end;

    Image.Picture.Assign(Bmp);
  finally
    Bmp.Free;
  end;
end;

procedure TMainForm.btnSelectImageClick(Sender: TObject);
begin
  OpenDialog1.Filter := '图片文件|*.jpg;*.jpeg;*.png;*.bmp|所有文件|*.*';
  OpenDialog1.FilterIndex := 1;

  if OpenDialog1.Execute then
  begin
    try
      FCurrentImage := OpenDialog1.FileName;
      Image1.Picture.LoadFromFile(FCurrentImage);
      StatusBar1.SimpleText := '已加载图片: ' + ExtractFileName(FCurrentImage);
    except
      on E: Exception do
      begin
        ShowMessageFmt('加载图片失败：%s'#13'文件路径：%s', [E.Message, FCurrentImage]);
        StatusBar1.SimpleText := '加载图片失败: ' + E.Message;
      end;
    end;
  end;
end;

procedure TMainForm.btnDetectClick(Sender: TObject);
var
  InputData: TArray<Single>;
  InputDataFP16: TArray<Word>;
  OutputData: TArray<Single>;
  StartTime, EndTime: DWORD;
begin
  if Image1.Picture.Graphic = nil then
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
    StatusBar1.SimpleText := '正在预处理图像...';
    
    // 根据输入数据类型选择预处理方式
    if FInputDataType = ONNX_TENSOR_ELEMENT_DATA_TYPE_FLOAT16 then
    begin
      PreprocessImageFP16(Image1, InputDataFP16);
      StatusBar1.SimpleText := '正在推理...';
      RunInferenceFP16(InputDataFP16, OutputData);
    end
    else
    begin
      PreprocessImage(Image1, InputData);
      StatusBar1.SimpleText := '正在推理...';
      RunInference(InputData, OutputData);
    end;

    StatusBar1.SimpleText := '正在后处理并绘制结果...';
    PostprocessAndDraw(OutputData, Image1);

    EndTime := GetTickCount;
    StatusBar1.SimpleText := Format('识别完成，耗时: %d ms', [EndTime - StartTime]);
  finally
    Screen.Cursor := crDefault;
  end;
end;

end.
