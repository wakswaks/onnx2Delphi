unit onnxruntime;

interface

uses
  Winapi.Windows, System.SysUtils;

const
  ORT_API_VERSION = 24;
  ONNXRUNTIME_DLL = 'onnxruntime.dll';

type
  OrtEnv = Pointer;
  OrtSessionOptions = Pointer;
  OrtSession = Pointer;
  OrtMemoryInfo = Pointer;
  OrtValue = Pointer;
  OrtAllocator = Pointer;
  OrtStatus = Pointer;
  OrtTensorTypeAndShapeInfo = Pointer;
  OrtRunOptions = Pointer;
  OrtTypeInfo = Pointer;
  OrtKernelInfo = Pointer;
  OrtKernelContext = Pointer;
  OrtMapTypeInfo = Pointer;
  OrtSequenceTypeInfo = Pointer;
  OrtModelMetadata = Pointer;
  OrtThreadingOptions = Pointer;
  OrtIoBinding = Pointer;
  OrtArenaCfg = Pointer;
  OrtPrepackedWeightsContainer = Pointer;
  OrtCustomOpDomain = Pointer;
  OrtCustomOp = Pointer;

  POrtEnv = ^OrtEnv;
  POrtSessionOptions = ^OrtSessionOptions;
  POrtSession = ^OrtSession;
  POrtMemoryInfo = ^OrtMemoryInfo;
  POrtValue = ^OrtValue;
  POrtAllocator = ^OrtAllocator;
  POrtStatus = ^OrtStatus;
  POrtTensorTypeAndShapeInfo = ^OrtTensorTypeAndShapeInfo;
  POrtRunOptions = ^OrtRunOptions;
  POrtTypeInfo = ^OrtTypeInfo;
  POrtKernelInfo = ^OrtKernelInfo;
  POrtKernelContext = ^OrtKernelContext;
  POrtMapTypeInfo = ^OrtMapTypeInfo;
  POrtSequenceTypeInfo = ^OrtSequenceTypeInfo;
  POrtModelMetadata = ^OrtModelMetadata;
  POrtThreadingOptions = ^OrtThreadingOptions;
  POrtIoBinding = ^OrtIoBinding;
  POrtArenaCfg = ^OrtArenaCfg;
  POrtPrepackedWeightsContainer = ^OrtPrepackedWeightsContainer;
  
  PPAnsiChar = ^PAnsiChar;
  PInt64 = ^Int64;
  PInt32 = ^Int32;
  PSingle = ^Single;

  OrtErrorCode = (
    ORT_OK = 0,
    ORT_FAIL = 1,
    ORT_INVALID_ARGUMENT = 2,
    ORT_NO_SUCHFILE = 3,
    ORT_NO_MODEL = 4,
    ORT_ENGINE_ERROR = 5,
    ORT_RUNTIME_EXCEPTION = 6,
    ORT_INVALID_PROTOBUF = 7,
    ORT_MODEL_LOADED = 8,
    ORT_NOT_IMPLEMENTED = 9,
    ORT_INVALID_GRAPH = 10,
    ORT_EP_FAIL = 11,
    ORT_MODEL_LOAD_CANCELED = 12,
    ORT_MODEL_REQUIRES_COMPILATION = 13,
    ORT_NOT_FOUND = 14
  );

  OrtLoggingLevel = (
    ORT_LOGGING_LEVEL_VERBOSE = 0,
    ORT_LOGGING_LEVEL_INFO = 1,
    ORT_LOGGING_LEVEL_WARNING = 2,
    ORT_LOGGING_LEVEL_ERROR = 3,
    ORT_LOGGING_LEVEL_FATAL = 4
  );

  OrtMemType = (
    OrtMemTypeCPUInput = -2,
    OrtMemTypeCPUOutput = -1,
    OrtMemTypeCPU = -1,
    OrtMemTypeDefault = 0
  );

  OrtAllocatorType = (
    OrtInvalidAllocator = -1,
    OrtDeviceAllocator = 0,
    OrtArenaAllocator = 1,
    OrtReadOnlyAllocator = 2
  );

  ONNXTensorElementDataType = Integer;
const
  ONNX_TENSOR_ELEMENT_DATA_TYPE_UNDEFINED = 0;
  ONNX_TENSOR_ELEMENT_DATA_TYPE_FLOAT = 1;
  ONNX_TENSOR_ELEMENT_DATA_TYPE_UINT8 = 2;
  ONNX_TENSOR_ELEMENT_DATA_TYPE_INT8 = 3;
  ONNX_TENSOR_ELEMENT_DATA_TYPE_UINT16 = 4;
  ONNX_TENSOR_ELEMENT_DATA_TYPE_INT16 = 5;
  ONNX_TENSOR_ELEMENT_DATA_TYPE_INT32 = 6;
  ONNX_TENSOR_ELEMENT_DATA_TYPE_INT64 = 7;
  ONNX_TENSOR_ELEMENT_DATA_TYPE_STRING = 8;
  ONNX_TENSOR_ELEMENT_DATA_TYPE_BOOL = 9;
  ONNX_TENSOR_ELEMENT_DATA_TYPE_FLOAT16 = 10;
  ONNX_TENSOR_ELEMENT_DATA_TYPE_DOUBLE = 11;
  ONNX_TENSOR_ELEMENT_DATA_TYPE_UINT32 = 12;
  ONNX_TENSOR_ELEMENT_DATA_TYPE_UINT64 = 13;
  ONNX_TENSOR_ELEMENT_DATA_TYPE_COMPLEX64 = 14;
  ONNX_TENSOR_ELEMENT_DATA_TYPE_COMPLEX128 = 15;
  ONNX_TENSOR_ELEMENT_DATA_TYPE_BFLOAT16 = 16;
  ONNX_TENSOR_ELEMENT_DATA_TYPE_FLOAT8E4M3FN = 17;
  ONNX_TENSOR_ELEMENT_DATA_TYPE_FLOAT8E4M3FNUZ = 18;
  ONNX_TENSOR_ELEMENT_DATA_TYPE_FLOAT8E5M2 = 19;
  ONNX_TENSOR_ELEMENT_DATA_TYPE_FLOAT8E5M2FNUZ = 20;
  ONNX_TENSOR_ELEMENT_DATA_TYPE_UINT4 = 21;
  ONNX_TENSOR_ELEMENT_DATA_TYPE_INT4 = 22;
  ONNX_TENSOR_ELEMENT_DATA_TYPE_FLOAT4E2M1 = 23;
  ONNX_TENSOR_ELEMENT_DATA_TYPE_UINT2 = 24;
  ONNX_TENSOR_ELEMENT_DATA_TYPE_INT2 = 25;

type
  OrtApi = record
    // Status functions (3 functions)
    CreateStatus: function(code: OrtErrorCode; msg: PAnsiChar): OrtStatus; stdcall;
    GetErrorCode: function(status: OrtStatus): OrtErrorCode; stdcall;
    GetErrorMessage: function(status: OrtStatus): PAnsiChar; stdcall;
    
    // Environment functions (4 functions: CreateEnv, CreateEnvWithCustomLogger, EnableTelemetryEvents, DisableTelemetryEvents)
    CreateEnv: function(log_severity_level: OrtLoggingLevel; logid: PAnsiChar; 
      out env: OrtEnv): OrtStatus; stdcall;
    CreateEnvWithCustomLogger: function(logging_function: Pointer; logger_param: Pointer; 
      log_severity_level: OrtLoggingLevel; logid: PAnsiChar; out env: OrtEnv): OrtStatus; stdcall;
    EnableTelemetryEvents: function(env: OrtEnv): OrtStatus; stdcall;
    DisableTelemetryEvents: function(env: OrtEnv): OrtStatus; stdcall;
    
    // Session functions (2 functions: CreateSession, CreateSessionFromArray)
    CreateSession: function(env: OrtEnv; model_path: PWideChar;
      options: OrtSessionOptions; out session: OrtSession): OrtStatus; stdcall;
    CreateSessionFromArray: function(env: OrtEnv; model_data: Pointer; 
      model_data_length: NativeUInt; options: OrtSessionOptions; 
      out session: OrtSession): OrtStatus; stdcall;
    
    // Run function (1 function)
    Run: function(session: OrtSession; run_options: OrtRunOptions;
      input_names: PPAnsiChar; inputs: POrtValue; input_count: NativeUInt;
      output_names: PPAnsiChar; output_count: NativeUInt;
      outputs: POrtValue): OrtStatus; stdcall;
    
    // SessionOptions functions
    CreateSessionOptions: function(out options: OrtSessionOptions): OrtStatus; stdcall;
    SetOptimizedModelFilePath: function(options: OrtSessionOptions; optimized_model_filepath: PWideChar): OrtStatus; stdcall;
    CloneSessionOptions: function(in_options: OrtSessionOptions; out out_options: OrtSessionOptions): OrtStatus; stdcall;
    SetSessionExecutionMode: function(options: OrtSessionOptions; execution_mode: Integer): OrtStatus; stdcall;
    EnableProfiling: function(options: OrtSessionOptions; profile_file_prefix: PWideChar): OrtStatus; stdcall;
    DisableProfiling: function(options: OrtSessionOptions): OrtStatus; stdcall;
    EnableMemPattern: function(options: OrtSessionOptions): OrtStatus; stdcall;
    DisableMemPattern: function(options: OrtSessionOptions): OrtStatus; stdcall;
    EnableCpuMemArena: function(options: OrtSessionOptions): OrtStatus; stdcall;
    DisableCpuMemArena: function(options: OrtSessionOptions): OrtStatus; stdcall;
    SetSessionLogId: function(options: OrtSessionOptions; logid: PAnsiChar): OrtStatus; stdcall;
    SetSessionLogVerbosityLevel: function(options: OrtSessionOptions; session_log_verbosity_level: Integer): OrtStatus; stdcall;
    SetSessionLogSeverityLevel: function(options: OrtSessionOptions; session_log_severity_level: Integer): OrtStatus; stdcall;
    SetSessionGraphOptimizationLevel: function(options: OrtSessionOptions; graph_optimization_level: Integer): OrtStatus; stdcall;
    SetIntraOpNumThreads: function(options: OrtSessionOptions; num_threads: Integer): OrtStatus; stdcall;
    SetInterOpNumThreads: function(options: OrtSessionOptions; num_threads: Integer): OrtStatus; stdcall;
    
    // CustomOpDomain functions
    CreateCustomOpDomain: function(domain: PAnsiChar; out out_: Pointer): OrtStatus; stdcall;
    CustomOpDomain_Add: function(custom_op_domain: Pointer; op: Pointer): OrtStatus; stdcall;
    AddCustomOpDomain: function(options: OrtSessionOptions; custom_op_domain: Pointer): OrtStatus; stdcall;
    RegisterCustomOpsLibrary: function(options: OrtSessionOptions; library_path: PAnsiChar; library_handle: Pointer): OrtStatus; stdcall;
    
    // Session metadata functions
    SessionGetInputCount: function(session: OrtSession; out count: NativeUInt): OrtStatus; stdcall;
    SessionGetOutputCount: function(session: OrtSession; out count: NativeUInt): OrtStatus; stdcall;
    SessionGetOverridableInitializerCount: function(session: OrtSession; out count: NativeUInt): OrtStatus; stdcall;
    SessionGetInputTypeInfo: function(session: OrtSession; index: NativeUInt; out type_info: OrtTypeInfo): OrtStatus; stdcall;
    SessionGetOutputTypeInfo: function(session: OrtSession; index: NativeUInt; out type_info: OrtTypeInfo): OrtStatus; stdcall;
    SessionGetOverridableInitializerTypeInfo: function(session: OrtSession; index: NativeUInt; out type_info: OrtTypeInfo): OrtStatus; stdcall;
    SessionGetInputName: function(session: OrtSession; index: NativeUInt;
      allocator: OrtAllocator; out name: PAnsiChar): OrtStatus; stdcall;
    SessionGetOutputName: function(session: OrtSession; index: NativeUInt;
      allocator: OrtAllocator; out name: PAnsiChar): OrtStatus; stdcall;
    SessionGetOverridableInitializerName: function(session: OrtSession; index: NativeUInt;
      allocator: OrtAllocator; out name: PAnsiChar): OrtStatus; stdcall;
    
    // RunOptions functions
    CreateRunOptions: function(out out_: OrtRunOptions): OrtStatus; stdcall;
    RunOptionsSetRunLogVerbosityLevel: function(options: OrtRunOptions; log_verbosity_level: Integer): OrtStatus; stdcall;
    RunOptionsSetRunLogSeverityLevel: function(options: OrtRunOptions; log_severity_level: Integer): OrtStatus; stdcall;
    RunOptionsSetRunTag: function(options: OrtRunOptions; run_tag: PAnsiChar): OrtStatus; stdcall;
    RunOptionsGetRunLogVerbosityLevel: function(options: OrtRunOptions; out log_verbosity_level: Integer): OrtStatus; stdcall;
    RunOptionsGetRunLogSeverityLevel: function(options: OrtRunOptions; out log_severity_level: Integer): OrtStatus; stdcall;
    RunOptionsGetRunTag: function(options: OrtRunOptions; out run_tag: PAnsiChar): OrtStatus; stdcall;
    RunOptionsSetTerminate: function(options: OrtRunOptions): OrtStatus; stdcall;
    RunOptionsUnsetTerminate: function(options: OrtRunOptions): OrtStatus; stdcall;
    
    // Tensor functions
    CreateTensorAsOrtValue: function(allocator: OrtAllocator; shape: PInt64; shape_len: NativeUInt; 
      type_: ONNXTensorElementDataType; out value: OrtValue): OrtStatus; stdcall;
    CreateTensorWithDataAsOrtValue: function(info: OrtMemoryInfo; p_data: Pointer; 
      p_data_len: NativeUInt; shape: PInt64; shape_len: NativeUInt; 
      type_: ONNXTensorElementDataType; out value: OrtValue): OrtStatus; stdcall;
    IsTensor: function(value: OrtValue; out out_: Integer): OrtStatus; stdcall;
    GetTensorMutableData: function(value: OrtValue; out data: Pointer): OrtStatus; stdcall;
    FillStringTensor: function(value: OrtValue; s: PPAnsiChar; s_len: NativeUInt): OrtStatus; stdcall;
    GetStringTensorDataLength: function(value: OrtValue; out len: NativeUInt): OrtStatus; stdcall;
    GetStringTensorContent: function(value: OrtValue; s: Pointer; s_len: NativeUInt; 
      offsets: PNativeUInt; offsets_len: NativeUInt): OrtStatus; stdcall;
    
    // TypeInfo functions
    CastTypeInfoToTensorInfo: function(type_info: OrtTypeInfo; out out_: OrtTensorTypeAndShapeInfo): OrtStatus; stdcall;
    GetOnnxTypeFromTypeInfo: function(type_info: OrtTypeInfo; out out_: Integer): OrtStatus; stdcall;
    
    // TensorTypeAndShapeInfo functions
    CreateTensorTypeAndShapeInfo: function(out out_: OrtTensorTypeAndShapeInfo): OrtStatus; stdcall;
    SetTensorElementType: function(info: OrtTensorTypeAndShapeInfo; type_: ONNXTensorElementDataType): OrtStatus; stdcall;
    SetDimensions: function(info: OrtTensorTypeAndShapeInfo; dim_values: PInt64; dim_count: NativeUInt): OrtStatus; stdcall;
    GetTensorElementType: function(info: OrtTensorTypeAndShapeInfo; out out_: ONNXTensorElementDataType): OrtStatus; stdcall;
    GetDimensionsCount: function(info: OrtTensorTypeAndShapeInfo; out out_: NativeUInt): OrtStatus; stdcall;
    GetDimensions: function(info: OrtTensorTypeAndShapeInfo; dim_values: PInt64; dim_values_len: NativeUInt): OrtStatus; stdcall;
    GetSymbolicDimensions: function(info: OrtTensorTypeAndShapeInfo; dim_params: PPAnsiChar; dim_params_len: NativeUInt): OrtStatus; stdcall;
    GetTensorShapeElementCount: function(info: OrtTensorTypeAndShapeInfo; out out_: NativeUInt): OrtStatus; stdcall;
    GetTensorTypeAndShape: function(value: OrtValue; out out_: OrtTensorTypeAndShapeInfo): OrtStatus; stdcall;
    GetTypeInfo: function(value: OrtValue; out out_: OrtTypeInfo): OrtStatus; stdcall;
    GetValueType: function(value: OrtValue; out out_: Integer): OrtStatus; stdcall;
    
    // MemoryInfo functions
    CreateMemoryInfo: function(name: PAnsiChar; type_: OrtAllocatorType; id: Integer; 
      mem_type: OrtMemType; out out_: OrtMemoryInfo): OrtStatus; stdcall;
    CreateCpuMemoryInfo: function(type_: OrtAllocatorType; mem_type: OrtMemType; 
      out memory_info: OrtMemoryInfo): OrtStatus; stdcall;
    CompareMemoryInfo: function(info1: OrtMemoryInfo; info2: OrtMemoryInfo; out out_: Integer): OrtStatus; stdcall;
    MemoryInfoGetName: function(ptr: OrtMemoryInfo; out out_: PAnsiChar): OrtStatus; stdcall;
    MemoryInfoGetId: function(ptr: OrtMemoryInfo; out out_: Integer): OrtStatus; stdcall;
    MemoryInfoGetMemType: function(ptr: OrtMemoryInfo; out out_: OrtMemType): OrtStatus; stdcall;
    MemoryInfoGetType: function(ptr: OrtMemoryInfo; out out_: OrtAllocatorType): OrtStatus; stdcall;
    
    // Allocator functions
    AllocatorAlloc: function(ort_allocator: OrtAllocator; size: NativeUInt; out out_: Pointer): OrtStatus; stdcall;
    AllocatorFree: function(ort_allocator: OrtAllocator; p: Pointer): OrtStatus; stdcall;
    AllocatorGetInfo: function(ort_allocator: OrtAllocator; out out_: OrtMemoryInfo): OrtStatus; stdcall;
    GetAllocatorWithDefaultOptions: function(out allocator: OrtAllocator): OrtStatus; stdcall;
    
    // SessionOptions functions (continued)
    AddFreeDimensionOverride: function(options: OrtSessionOptions; dim_denotation: PAnsiChar; dim_value: Int64): OrtStatus; stdcall;
    
    // OrtValue functions
    GetValue: function(value: OrtValue; index: Integer; allocator: OrtAllocator; out out_: OrtValue): OrtStatus; stdcall;
    GetValueCount: function(value: OrtValue; out out_: NativeUInt): OrtStatus; stdcall;
    CreateValue: function(in_: POrtValue; num_values: NativeUInt; value_type: Integer; out out_: OrtValue): OrtStatus; stdcall;
    CreateOpaqueValue: function(domain_name: PAnsiChar; type_name: PAnsiChar; data_container: Pointer; data_container_size: NativeUInt; out out_: OrtValue): OrtStatus; stdcall;
    GetOpaqueValue: function(domain_name: PAnsiChar; type_name: PAnsiChar; in_: OrtValue; data_container: Pointer; data_container_size: NativeUInt): OrtStatus; stdcall;
    
    // KernelInfo functions
    KernelInfoGetAttribute_float: function(info: OrtKernelInfo; name: PAnsiChar; out out_: Single): OrtStatus; stdcall;
    KernelInfoGetAttribute_int64: function(info: OrtKernelInfo; name: PAnsiChar; out out_: Int64): OrtStatus; stdcall;
    KernelInfoGetAttribute_string: function(info: OrtKernelInfo; name: PAnsiChar; out out_: PAnsiChar; out size: NativeUInt): OrtStatus; stdcall;
    
    // KernelContext functions
    KernelContext_GetInputCount: function(context: OrtKernelContext; out out_: NativeUInt): OrtStatus; stdcall;
    KernelContext_GetOutputCount: function(context: OrtKernelContext; out out_: NativeUInt): OrtStatus; stdcall;
    KernelContext_GetInput: function(context: OrtKernelContext; index: NativeUInt; out out_: OrtValue): OrtStatus; stdcall;
    KernelContext_GetOutput: function(context: OrtKernelContext; index: NativeUInt; dim_values: PInt64; dim_count: NativeUInt; out out_: OrtValue): OrtStatus; stdcall;
    
    // Env Release function
    ReleaseEnv: procedure(env: OrtEnv); stdcall;
    
    // Status Release function
    ReleaseStatus: procedure(status: OrtStatus); stdcall;
    
    // MemoryInfo Release function
    ReleaseMemoryInfo: procedure(memory_info: OrtMemoryInfo); stdcall;
    
    // Session Release function
    ReleaseSession: procedure(session: OrtSession); stdcall;
    
    // Value Release function
    ReleaseValue: procedure(value_: OrtValue); stdcall;
    
    // RunOptions Release function
    ReleaseRunOptions: procedure(options: OrtRunOptions); stdcall;
    
    // TypeInfo Release function
    ReleaseTypeInfo: procedure(info: OrtTypeInfo); stdcall;
    
    // TensorTypeAndShapeInfo Release function
    ReleaseTensorTypeAndShapeInfo: procedure(info: OrtTensorTypeAndShapeInfo); stdcall;
    
    // SessionOptions Release function
    ReleaseSessionOptions: procedure(options: OrtSessionOptions); stdcall;
    
    // CustomOpDomain Release function
    ReleaseCustomOpDomain: procedure(domain: OrtCustomOpDomain); stdcall;
    
    // TypeInfo functions (continued)
    GetDenotationFromTypeInfo: function(type_info: OrtTypeInfo; out denotation: PAnsiChar): OrtStatus; stdcall;
    CastTypeInfoToMapTypeInfo: function(type_info: OrtTypeInfo; out out_: OrtMapTypeInfo): OrtStatus; stdcall;
    CastTypeInfoToSequenceTypeInfo: function(type_info: OrtTypeInfo; out out_: OrtSequenceTypeInfo): OrtStatus; stdcall;
    GetMapKeyType: function(map_type_info: OrtMapTypeInfo; out out_: ONNXTensorElementDataType): OrtStatus; stdcall;
    GetMapValueType: function(map_type_info: OrtMapTypeInfo; out type_info: OrtTypeInfo): OrtStatus; stdcall;
    GetSequenceElementType: function(sequence_type_info: OrtSequenceTypeInfo; out type_info: OrtTypeInfo): OrtStatus; stdcall;
    
    // Session functions (continued)
    SessionEndProfiling: function(session: OrtSession; allocator: OrtAllocator; out out_: PAnsiChar): OrtStatus; stdcall;
    SessionGetModelMetadata: function(session: OrtSession; out out_: OrtModelMetadata): OrtStatus; stdcall;
    
    // ModelMetadata functions
    ModelMetadataGetProducerName: function(model_metadata: OrtModelMetadata; allocator: OrtAllocator; out out_: PAnsiChar): OrtStatus; stdcall;
    ModelMetadataGetGraphName: function(model_metadata: OrtModelMetadata; allocator: OrtAllocator; out out_: PAnsiChar): OrtStatus; stdcall;
    ModelMetadataGetDomain: function(model_metadata: OrtModelMetadata; allocator: OrtAllocator; out out_: PAnsiChar): OrtStatus; stdcall;
    ModelMetadataGetDescription: function(model_metadata: OrtModelMetadata; allocator: OrtAllocator; out out_: PAnsiChar): OrtStatus; stdcall;
    ModelMetadataLookupCustomMetadataMap: function(model_metadata: OrtModelMetadata; allocator: OrtAllocator; key: PAnsiChar; out out_: PAnsiChar): OrtStatus; stdcall;
    ModelMetadataGetVersion: function(model_metadata: OrtModelMetadata; out out_: Int64): OrtStatus; stdcall;
    
    // Env functions (continued)
    CreateEnvWithGlobalThreadPools: function(log_severity_level: OrtLoggingLevel; logid: PAnsiChar; out env: OrtEnv): OrtStatus; stdcall;
    DisablePerSessionThreads: function(options: OrtSessionOptions): OrtStatus; stdcall;
    CreateThreadingOptions: function(out out_: OrtThreadingOptions): OrtStatus; stdcall;
    ModelMetadataGetCustomMetadataMapKeys: function(model_metadata: OrtModelMetadata; allocator: OrtAllocator; out out_: PPAnsiChar; out num_keys: NativeUInt): OrtStatus; stdcall;
    AddFreeDimensionOverrideByName: function(options: OrtSessionOptions; dim_name: PAnsiChar; dim_value: Int64): OrtStatus; stdcall;
    GetAvailableProviders: function(out out_ptr: PPAnsiChar; out provider_length: Integer): OrtStatus; stdcall;
    ReleaseAvailableProviders: function(ptr: PPAnsiChar; provider_length: Integer): OrtStatus; stdcall;
    
    // Tensor functions (continued)
    GetStringTensorElementLength: function(value: OrtValue; index: NativeUInt; out out_: NativeUInt): OrtStatus; stdcall;
    GetStringTensorElement: function(value: OrtValue; s_len: NativeUInt; index: NativeUInt; s: Pointer): OrtStatus; stdcall;
    FillStringTensorElement: function(value: OrtValue; s: PAnsiChar; index: NativeUInt): OrtStatus; stdcall;
    
    // SessionOptions functions (continued)
    AddSessionConfigEntry: function(options: OrtSessionOptions; config_key: PAnsiChar; config_value: PAnsiChar): OrtStatus; stdcall;
    
    // Allocator functions (continued)
    CreateAllocator: function(session: OrtSession; mem_info: OrtMemoryInfo; out out_: OrtAllocator): OrtStatus; stdcall;
    
    // Session functions (continued)
    RunWithBinding: function(session: OrtSession; run_options: OrtRunOptions; binding_ptr: OrtIoBinding): OrtStatus; stdcall;
    CreateIoBinding: function(session: OrtSession; out out_: OrtIoBinding): OrtStatus; stdcall;
    BindInput: function(binding_ptr: OrtIoBinding; name: PAnsiChar; val_ptr: OrtValue): OrtStatus; stdcall;
    BindOutput: function(binding_ptr: OrtIoBinding; name: PAnsiChar; val_ptr: OrtValue): OrtStatus; stdcall;
    BindOutputToDevice: function(binding_ptr: OrtIoBinding; name: PAnsiChar; mem_info_ptr: OrtMemoryInfo): OrtStatus; stdcall;
    GetBoundOutputNames: function(binding_ptr: OrtIoBinding; allocator: OrtAllocator; out out_: PPAnsiChar; out num_names: NativeUInt): OrtStatus; stdcall;
    GetBoundOutputValues: function(binding_ptr: OrtIoBinding; allocator: OrtAllocator; out out_: POrtValue; out num_values: NativeUInt): OrtStatus; stdcall;
    
    // Tensor functions (continued)
    TensorAt: function(value: OrtValue; location_values: PInt64; location_values_count: NativeUInt; out out_: Pointer): OrtStatus; stdcall;
    
    // Env functions (continued)
    CreateAndRegisterAllocator: function(env: OrtEnv; mem_info: OrtMemoryInfo): OrtStatus; stdcall;
    SetLanguageProjection: function(ort_env: OrtEnv; projection: Integer): OrtStatus; stdcall;
    
    // Session functions (continued)
    SessionGetProfilingStartTimeNs: function(session: OrtSession; out out_: UInt64): OrtStatus; stdcall;
    
    // ThreadingOptions functions
    SetGlobalIntraOpNumThreads: function(tp_options: OrtThreadingOptions; intra_op_num_threads: Integer): OrtStatus; stdcall;
    SetGlobalInterOpNumThreads: function(tp_options: OrtThreadingOptions; inter_op_num_threads: Integer): OrtStatus; stdcall;
    SetGlobalSpinControl: function(tp_options: OrtThreadingOptions; allow_spinning: Integer): OrtStatus; stdcall;
    
    // SessionOptions functions (continued)
    AddInitializer: function(options: OrtSessionOptions; name: PAnsiChar; initializer: OrtValue): OrtStatus; stdcall;
    
    // Env functions (continued)
    CreateEnvWithCustomLoggerAndGlobalThreadPools: function(logging_function: Pointer; logger_param: Pointer; log_severity_level: OrtLoggingLevel; logid: PAnsiChar; out env: OrtEnv): OrtStatus; stdcall;
    
    // SessionOptions functions (continued)
    SessionOptionsAppendExecutionProvider_CUDA: function(options: OrtSessionOptions; cuda_options: Pointer): OrtStatus; stdcall;
    SessionOptionsAppendExecutionProvider_ROCM: function(options: OrtSessionOptions; rocm_options: Pointer): OrtStatus; stdcall;
    SessionOptionsAppendExecutionProvider_OpenVINO: function(options: OrtSessionOptions; openvino_options: Pointer): OrtStatus; stdcall;
    
    // ThreadingOptions functions (continued)
    SetGlobalDenormalAsZero: function(tp_options: OrtThreadingOptions): OrtStatus; stdcall;
    
    // ArenaCfg functions
    CreateArenaCfg: function(max_mem: NativeUInt; arena_extend_strategy: Integer; initial_chunk_size_bytes: Integer; out out_: OrtArenaCfg): OrtStatus; stdcall;
    
    // ModelMetadata functions (continued)
    ModelMetadataGetGraphDescription: function(model_metadata: OrtModelMetadata; allocator: OrtAllocator; out out_: PAnsiChar): OrtStatus; stdcall;
    
    // SessionOptions functions (continued)
    SessionOptionsAppendExecutionProvider_TensorRT: function(options: OrtSessionOptions; tensorrt_options: Pointer): OrtStatus; stdcall;
    SetCurrentGpuDeviceId: function(device_id: Integer): OrtStatus; stdcall;
    GetCurrentGpuDeviceId: function(out device_id: Integer): OrtStatus; stdcall;
    
    // KernelInfo functions (continued)
    KernelInfoGetAttributeArray_float: function(info: OrtKernelInfo; name: PAnsiChar; out out_: PSingle; out size: NativeUInt): OrtStatus; stdcall;
    KernelInfoGetAttributeArray_int64: function(info: OrtKernelInfo; name: PAnsiChar; out out_: PInt64; out size: NativeUInt): OrtStatus; stdcall;
    
    // ArenaCfg functions (continued)
    CreateArenaCfgV2: function(arena_config_keys: PPAnsiChar; num_keys: NativeUInt; out out_: OrtArenaCfg): OrtStatus; stdcall;
    
    // RunOptions functions (continued)
    AddRunConfigEntry: function(options: OrtRunOptions; config_key: PAnsiChar; config_value: PAnsiChar): OrtStatus; stdcall;
    
    // PrepackedWeightsContainer functions
    CreatePrepackedWeightsContainer: function(out out_: OrtPrepackedWeightsContainer): OrtStatus; stdcall;
    
    // Session functions (continued)
    CreateSessionWithPrepackedWeightsContainer: function(env: OrtEnv; model_path: PWideChar; options: OrtSessionOptions; out session: OrtSession): OrtStatus; stdcall;
    CreateSessionFromArrayWithPrepackedWeightsContainer: function(env: OrtEnv; model_data: Pointer; model_data_length: NativeUInt; options: OrtSessionOptions; out session: OrtSession): OrtStatus; stdcall;
    
    // SessionOptions functions (continued)
    SessionOptionsAppendExecutionProvider_TensorRT_V2: function(options: OrtSessionOptions; tensorrt_options: Pointer): OrtStatus; stdcall;
    CreateTensorRTProviderOptions: function(out out_: Pointer): OrtStatus; stdcall;
    UpdateTensorRTProviderOptions: function(tensorrt_options: Pointer; provider_options_keys: PPAnsiChar; provider_options_values: PPAnsiChar; num_keys: NativeUInt): OrtStatus; stdcall;
    GetTensorRTProviderOptionsAsString: function(tensorrt_options: Pointer; allocator: OrtAllocator; out ptr: PAnsiChar): OrtStatus; stdcall;
    
    // SessionOptions functions (continued)
    EnableOrtCustomOps: function(options: OrtSessionOptions): OrtStatus; stdcall;
    
    // Env functions (continued)
    RegisterAllocator: function(env: OrtEnv; allocator: OrtAllocator): OrtStatus; stdcall;
    UnregisterAllocator: function(env: OrtEnv; mem_info: OrtMemoryInfo): OrtStatus; stdcall;
    
    // Tensor functions (continued)
    IsSparseTensor: function(value: OrtValue; out out_: Integer): OrtStatus; stdcall;
    CreateSparseTensorAsOrtValue: function(allocator: OrtAllocator; dense_shape: PInt64; dense_shape_len: NativeUInt; type_: ONNXTensorElementDataType; out out_: OrtValue): OrtStatus; stdcall;
    FillSparseTensorCoo: function(ort_value: OrtValue; data_mem_info: OrtMemoryInfo; data_shape: PInt64; data_shape_len: NativeUInt; indices_data: PInt64; indices_num: NativeUInt): OrtStatus; stdcall;
    FillSparseTensorCsr: function(ort_value: OrtValue; data_mem_info: OrtMemoryInfo; data_shape: PInt64; data_shape_len: NativeUInt; inner_indices_data: PInt64; inner_indices_num: NativeUInt; outer_indices_data: PInt64; outer_indices_num: NativeUInt): OrtStatus; stdcall;
    FillSparseTensorBlockSparse: function(ort_value: OrtValue; data_mem_info: OrtMemoryInfo; data_shape: PInt64; data_shape_len: NativeUInt; indices_shape: PInt64; indices_shape_len: NativeUInt; indices_data: PInt32): OrtStatus; stdcall;
    CreateSparseTensorWithValuesAsOrtValue: function(info: OrtMemoryInfo; p_data: Pointer; p_data_len: NativeUInt; dense_shape: PInt64; dense_shape_len: NativeUInt; type_: ONNXTensorElementDataType; out out_: OrtValue): OrtStatus; stdcall;
    UseCooIndices: function(ort_value: OrtValue; indices_data: PInt64; indices_num: NativeUInt): OrtStatus; stdcall;
    UseCsrIndices: function(ort_value: OrtValue; inner_data: PInt64; inner_num: NativeUInt; outer_data: PInt64; outer_num: NativeUInt): OrtStatus; stdcall;
    UseBlockSparseIndices: function(ort_value: OrtValue; indices_shape: PInt64; indices_shape_len: NativeUInt; indices_data: PInt32): OrtStatus; stdcall;
    GetSparseTensorFormat: function(ort_value: OrtValue; out out_: Integer): OrtStatus; stdcall;
    GetSparseTensorValuesTypeAndShape: function(ort_value: OrtValue; out out_: OrtTensorTypeAndShapeInfo): OrtStatus; stdcall;
    GetSparseTensorValues: function(ort_value: OrtValue; out out_: Pointer): OrtStatus; stdcall;
    GetSparseTensorIndicesTypeShape: function(ort_value: OrtValue; indices_format: Integer; out out_: OrtTensorTypeAndShapeInfo): OrtStatus; stdcall;
    GetSparseTensorIndices: function(ort_value: OrtValue; indices_format: Integer; out num_indices: NativeUInt; out indices: Pointer): OrtStatus; stdcall;
    HasValue: function(value: OrtValue; out out_: Integer): OrtStatus; stdcall;
    
    // KernelContext functions (continued)
    KernelContext_GetGPUComputeStream: function(context: OrtKernelContext; out out_: Pointer): OrtStatus; stdcall;
    
    // Tensor functions (continued)
    GetTensorMemoryInfo: function(value: OrtValue; out mem_info: OrtMemoryInfo): OrtStatus; stdcall;
    
    // Provider functions
    GetExecutionProviderApi: function(provider_name: PAnsiChar; version: UInt32; out provider_api: Pointer): OrtStatus; stdcall;
    
    // SessionOptions functions (continued)
    SessionOptionsSetCustomCreateThreadFn: function(options: OrtSessionOptions; ort_custom_create_thread_fn: Pointer): OrtStatus; stdcall;
    SessionOptionsSetCustomThreadCreationOptions: function(options: OrtSessionOptions; ort_custom_thread_creation_options: Pointer): OrtStatus; stdcall;
    SessionOptionsSetCustomJoinThreadFn: function(options: OrtSessionOptions; ort_custom_join_thread_fn: Pointer): OrtStatus; stdcall;
    
    // ThreadingOptions functions (continued)
    SetGlobalCustomCreateThreadFn: function(tp_options: OrtThreadingOptions; ort_custom_create_thread_fn: Pointer): OrtStatus; stdcall;
    SetGlobalCustomThreadCreationOptions: function(tp_options: OrtThreadingOptions; ort_custom_thread_creation_options: Pointer): OrtStatus; stdcall;
    SetGlobalCustomJoinThreadFn: function(tp_options: OrtThreadingOptions; ort_custom_join_thread_fn: Pointer): OrtStatus; stdcall;
    
    // IoBinding functions
    SynchronizeBoundInputs: function(binding_ptr: OrtIoBinding): OrtStatus; stdcall;
    SynchronizeBoundOutputs: function(binding_ptr: OrtIoBinding): OrtStatus; stdcall;
    
    // SessionOptions functions (continued)
    SessionOptionsAppendExecutionProvider_CUDA_V2: function(options: OrtSessionOptions; cuda_options: Pointer): OrtStatus; stdcall;
    CreateCUDAProviderOptions: function(out out_: Pointer): OrtStatus; stdcall;
    UpdateCUDAProviderOptions: function(cuda_options: Pointer; provider_options_keys: PPAnsiChar; provider_options_values: PPAnsiChar; num_keys: NativeUInt): OrtStatus; stdcall;
    
    // MapTypeInfo Release function
    ReleaseMapTypeInfo: procedure(map_type_info: OrtMapTypeInfo); stdcall;
    
    // SequenceTypeInfo Release function
    ReleaseSequenceTypeInfo: procedure(sequence_type_info: OrtSequenceTypeInfo); stdcall;
    
    // ModelMetadata Release function
    ReleaseModelMetadata: procedure(model_metadata: OrtModelMetadata); stdcall;
    
    // ThreadingOptions Release function
    ReleaseThreadingOptions: procedure(tp_options: OrtThreadingOptions); stdcall;
    
    // Allocator Release function
    ReleaseAllocator: procedure(allocator: OrtAllocator); stdcall;
    
    // IoBinding Release function
    ReleaseIoBinding: procedure(binding_ptr: OrtIoBinding); stdcall;
    
    // ArenaCfg Release function
    ReleaseArenaCfg: procedure(arena_cfg: OrtArenaCfg); stdcall;
    
    // PrepackedWeightsContainer Release function
    ReleasePrepackedWeightsContainer: procedure(container: OrtPrepackedWeightsContainer); stdcall;
  end;
  POrtApi = ^OrtApi;

  OrtApiBase = record
    GetApi: function(version: NativeUInt): POrtApi; stdcall;
    GetVersionString: function: PAnsiChar; stdcall;
  end;
  POrtApiBase = ^OrtApiBase;

function OrtGetApiBase: POrtApiBase; stdcall; external ONNXRUNTIME_DLL;

function GetOrtApi: POrtApi;
function GetOrtApiFunction(Api: POrtApi; Index: Integer): Pointer;
function OrtSucceeded(status: OrtStatus): Boolean;
procedure OrtCheck(status: OrtStatus);

implementation

function GetOrtApi: POrtApi;
var
  ApiBase: POrtApiBase;
begin
  ApiBase := OrtGetApiBase;
  if Assigned(ApiBase) then
    Result := POrtApi(ApiBase^.GetApi(ORT_API_VERSION))
  else
    Result := nil;
end;

function GetOrtApiFunction(Api: POrtApi; Index: Integer): Pointer;
type
  PPointerArray = ^TPointerArray;
  TPointerArray = array[0..MaxInt div SizeOf(Pointer) - 1] of Pointer;
var
  PtrArray: PPointerArray;
begin
  // 将 OrtApi 指针视为函数指针数组，返回指定索引的函数指针
  PtrArray := PPointerArray(Api);
  Result := PtrArray^[Index];
end;

function OrtSucceeded(status: OrtStatus): Boolean;
var
  Api: POrtApi;
begin
  if status = nil then
    Result := True
  else
  begin
    Api := GetOrtApi;
    if Assigned(Api) then
      Result := Api^.GetErrorCode(status) = ORT_OK
    else
      Result := False;
  end;
end;

procedure OrtCheck(status: OrtStatus);
var
  Api: POrtApi;
  ErrorCode: OrtErrorCode;
  ErrorMsg: PAnsiChar;
begin
  if status <> nil then
  begin
    Api := GetOrtApi;
    if Assigned(Api) then
    begin
      ErrorCode := Api^.GetErrorCode(status);
      ErrorMsg := Api^.GetErrorMessage(status);
      raise Exception.CreateFmt('ONNX Runtime Error %d: %s', [Ord(ErrorCode), ErrorMsg]);
    end
    else
      raise Exception.Create('ONNX Runtime Error: Failed to get API');
  end;
end;

end.

