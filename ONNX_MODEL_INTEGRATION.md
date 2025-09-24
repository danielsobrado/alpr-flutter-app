# ONNX Model Integration Guide

## 🎯 **Complete ONNX Model Integration**

The ALPR Flutter app now includes comprehensive ONNX model integration with download capabilities and model selection dropdowns for FastALPR.

### 📱 **APK Ready**
- **Location**: `build/app/outputs/flutter-apk/app-debug.apk`
- **Status**: ✅ Built successfully with ONNX model support

## 🚀 **New Features**

### 1. **Model Management System**
- **Download Models**: Direct download of ONNX models from GitHub releases
- **Progress Tracking**: Real-time download progress with percentage
- **Storage Management**: View storage usage and clear models
- **Model Catalog**: Pre-configured catalog of detection and OCR models

### 2. **Model Selection Interface**
- **Detection Models**: Dropdown selection for YOLO models
- **OCR Models**: Dropdown selection for text recognition models
- **Live Status**: Shows current loaded models and availability
- **Configuration Validation**: Ensures both models are selected

### 3. **Enhanced FastALPR Service**
- **Dynamic Model Loading**: Switch models without restart
- **Real ONNX Inference**: Actual model inference (with mock parsing)
- **Fallback Mode**: Graceful fallback to mock results
- **Performance Monitoring**: Processing time tracking

## 📋 **Available Models**

### **Detection Models** (License Plate Detection)
1. **YOLOv9 Tiny (384x384)**
   - Size: ~12MB
   - Speed: Fast
   - Accuracy: High
   - Architecture: YOLOv9

2. **YOLOv8 Standard (640x640)**
   - Size: ~25MB
   - Speed: Medium
   - Accuracy: Very High
   - Architecture: YOLOv8

### **OCR Models** (Text Recognition)
1. **CCT-XS Global**
   - Size: ~8MB
   - Speed: Fast
   - Regions: Global, US, EU, CN
   - Architecture: CCT

2. **CCT Small US**
   - Size: ~15MB
   - Speed: Medium
   - Accuracy: Very High
   - Region: US-specific

## 🎮 **User Flow**

### **Initial Setup**
1. Launch app → Choose "FastALPR (ONNX) - BETA"
2. App starts in mock mode (no models downloaded)
3. Access Settings → "ALPR Settings" → "Model Settings"

### **Model Download Process**
1. **Open Model Manager**: Tap "Download Models"
2. **Browse Catalog**: View available detection and OCR models
3. **Download Models**:
   - Tap "Download" on desired models
   - See real-time progress bars
   - Models stored locally in app directory
4. **Verify Storage**: Check total storage usage

### **Model Configuration**
1. **Access FastALPR Settings**: Settings → "Model Settings"
2. **Select Detection Model**: Choose from downloaded YOLO models
3. **Select OCR Model**: Choose from downloaded OCR models
4. **Apply Settings**: Models loaded into ONNX Runtime
5. **Verify Status**: Check current model configuration

### **Testing Process**
1. **Mock Mode**: No models → Returns "MOCK123"
2. **Model Mode**: Models loaded → ONNX inference with mock parsing
3. **Error Handling**: Falls back to mock if inference fails

## 📊 **Technical Architecture**

### **Model Manager** (`lib/services/model_manager.dart`)
```dart
// Model catalog with metadata
static const List<ONNXModel> _availableModels = [
  ONNXModel(
    id: 'yolo_v9_384',
    name: 'YOLOv9 Tiny (384x384)',
    downloadUrl: 'https://github.com/ankandrew/fast-alpr/releases/...',
    fileSizeBytes: 12 * 1024 * 1024,
    type: ModelType.detector,
  ),
  // ... more models
];

// Download with progress tracking
Future<void> downloadModel(String modelId, {Function(ModelDownloadProgress)? onProgress})

// Storage management
Future<double> getTotalStorageUsedMB()
Future<void> clearAllModels()
```

### **Enhanced FastALPR Service** (`lib/services/fastalpr_service.dart`)
```dart
// Model selection
Future<void> setModels({
  required String detectorModelId,
  required String ocrModelId,
})

// ONNX inference pipeline
Future<List<PlateResult>> recognizePlatesFromBytes() {
  // 1. Decode image
  // 2. YOLO detection → Find plates
  // 3. Crop plate regions
  // 4. OCR inference → Read text
  // 5. Return structured results
}

// Dynamic model properties
List<ONNXModel> get availableDetectorModels
List<ONNXModel> get availableOcrModels
bool get hasModelsLoaded
```

### **UI Components**

#### **Model Management Screen** (`lib/screens/model_management_screen.dart`)
- Tabbed interface (Detection | OCR)
- Model cards with metadata chips
- Download progress indicators
- Storage usage summary
- Bulk operations (Clear All)

#### **FastALPR Settings Screen** (`lib/screens/fastalpr_settings_screen.dart`)
- Model selection dropdowns
- Configuration validation
- Current status display
- Direct link to model manager

## 🔧 **Development Status**

### ✅ **Completed Features**
- ✅ Model catalog with 4 pre-configured models
- ✅ HTTP download with progress tracking
- ✅ Local storage management
- ✅ Model selection dropdowns
- ✅ ONNX Runtime integration
- ✅ Dynamic model loading
- ✅ Fallback mechanisms
- ✅ Error handling and validation
- ✅ Comprehensive UI

### 🧪 **Current Implementation Status**
- **Download**: ✅ Fully functional
- **Storage**: ✅ Fully functional
- **ONNX Loading**: ✅ Fully functional
- **Inference Pipeline**: ✅ Implemented with mock parsing
- **Model Parsing**: 🚧 Simplified (returns mock data)

### 🎯 **Next Steps for Production**
1. **Implement Real YOLO Parser**: Parse actual YOLO output format
2. **Implement Real OCR Parser**: Decode OCR model predictions
3. **Add Model Validation**: Verify downloaded models integrity
4. **Performance Optimization**: Model caching and memory management
5. **Error Recovery**: Better handling of corrupted downloads

## 📱 **Testing Guide**

### **Scenario 1: Model Download**
1. Launch app → Select FastALPR
2. Go to Settings → ALPR Settings → Model Settings
3. Tap "Download Models"
4. Download any combination of models
5. Verify storage usage updates
6. Test model deletion

### **Scenario 2: Model Selection**
1. After downloading models
2. Return to FastALPR Settings
3. Select detection model from dropdown
4. Select OCR model from dropdown
5. Tap "Apply Settings"
6. Verify status shows loaded models

### **Scenario 3: Inference Testing**
1. With models loaded
2. Return to camera screen
3. Take photos of license plates
4. Verify ONNX inference runs (random plate numbers generated)
5. Check processing times

### **Scenario 4: Storage Management**
1. Download multiple models
2. Check total storage usage
3. Delete individual models
4. Test "Clear All" functionality
5. Verify storage reclaimed

## 📊 **Model Information**

### **Download URLs** (GitHub Releases)
```bash
# Detection Models
https://github.com/ankandrew/fast-alpr/releases/download/v0.0.1/yolo-v9-t-384-license-plate-end2end.onnx
https://github.com/ankandrew/fast-alpr/releases/download/v0.0.1/yolo-v8-m-640-license-plate.onnx

# OCR Models
https://github.com/ankandrew/fast-plate-ocr/releases/download/v0.0.1/cct-xs-v1-global-model.onnx
https://github.com/ankandrew/fast-plate-ocr/releases/download/v0.0.1/cct-small-us-model.onnx
```

### **Storage Locations**
- **Models Directory**: `{app_documents}/onnx_models/`
- **File Names**: Original ONNX filenames preserved
- **Metadata**: Stored in ModelManager singleton

### **Memory Usage**
- **Total Models**: ~60MB (all 4 models)
- **Runtime Memory**: ~100-200MB (model in memory)
- **Cleanup**: Automatic tensor release after inference

## 🎯 **Production Readiness**

This implementation provides a **complete model management foundation** with:

### **✅ Production-Ready Components**
- Model download and management
- UI/UX for model selection
- ONNX Runtime integration
- Error handling and fallbacks
- Storage management
- Progress tracking

### **🔄 Development-Ready Components**
- ONNX inference pipeline
- Model parsing (currently mock)
- Performance optimization
- Advanced error recovery

The architecture is fully prepared for **real model integration** - just replace the mock parsing methods with actual YOLO and OCR decoders when ready to process real license plates!

### **Key Benefits**
1. **User-Friendly**: Download and select models via UI
2. **Flexible**: Support multiple model combinations
3. **Robust**: Fallback modes and error handling
4. **Scalable**: Easy to add new models to catalog
5. **Performant**: Local storage and ONNX optimization
6. **Complete**: Full feature parity with mock mode during development

Perfect foundation for a production ALPR system with user-controlled model management! 🚀