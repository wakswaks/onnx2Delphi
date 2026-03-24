# onnx2Delphi
### 中文
Delphi 调用 ONNXRuntime 加载 YOLOv5 ONNX 模型的Demo。
- onnxruntime.pas：由AI根据onnxruntime的头文件翻译而来。
- onnxruntime.dll：来自 https://github.com/microsoft/onnxruntime
- yolov5s6.onnx, yolov5s.onnx：来自 https://github.com/ultralytics/yolov5

Demo仅在Win10 + Delphi XE12.2下测试，注意onnxruntime.dll和项目都为64位。

---

### English
Demo for using ONNXRuntime in Delphi to load YOLOv5 ONNX models.
- onnxruntime.pas: Translated from the official ONNX Runtime header files using AI.
- onnxruntime.dll: Obtained from https://github.com/microsoft/onnxruntime
- yolov5s6.onnx, yolov5s.onnx: Obtained from https://github.com/ultralytics/yolov5

This Demo has only been tested on Windows 10 with Delphi XE12.2.
Note: Both onnxruntime.dll and the project are built for 64-bit systems.
