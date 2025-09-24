# FastALPR Integration Implementation

## Overview

Successfully implemented a local FastALPR option alongside the existing OpenALPR system, creating a configurable ALPR provider system that allows users to choose between different license plate recognition engines.

## Implementation Details

### 1. ONNX Runtime Integration
- **Added dependency**: `onnxruntime: ^1.19.0` in `pubspec.yaml`
- **Local processing**: Both providers now run completely locally without requiring HTTP services
- **Performance**: ONNX Runtime provides optimized inference for mobile devices

### 2. Provider Architecture

#### Core Configuration System
- **File**: `lib/core/alpr_config.dart`
- **Enum**: `ALPRProvider` with options for `openalpr` and `fastalpr`
- **Features**: Provider capabilities comparison, display names, and descriptions

#### Service Interface
- **File**: `lib/services/alpr_service_interface.dart`
- **Abstract interface**: Ensures consistent API across all ALPR providers
- **Methods**: `initialize()`, `recognizePlatesFromFile()`, `recognizePlatesFromBytes()`, `dispose()`

#### Factory Pattern
- **File**: `lib/services/alpr_service_factory.dart`
- **Dynamic switching**: Switch between providers at runtime
- **Singleton management**: Handles service lifecycle and initialization
- **Provider comparison**: Compare capabilities and features

### 3. FastALPR Service Implementation
- **File**: `lib/services/fastalpr_service.dart`
- **ONNX models**: Uses YOLOv9 for detection and CCT-XS-V1 for OCR
- **Two-stage process**:
  1. License plate detection using YOLO model
  2. OCR text recognition on detected regions
- **Model management**: Automatic copying of ONNX models from assets to device storage

### 4. User Interface

#### Settings Screen
- **File**: `lib/screens/alpr_settings_screen.dart`
- **Provider selection**: Radio buttons for choosing ALPR provider
- **Feature comparison**: Side-by-side capability comparison table
- **Real-time switching**: Apply changes with provider initialization

#### Home Screen Integration
- **Updated**: `lib/screens/home_screen.dart`
- **Menu option**: Added "ALPR Settings" to the popup menu
- **Navigation**: Direct access to provider configuration

### 5. Camera Integration
- **File**: `lib/widgets/camera_preview_widget.dart`
- **Refactored**: Removed hardcoded service dependencies
- **Factory usage**: Uses `ALPRServiceFactory.getCurrentService()`
- **Dynamic provider**: Automatically uses the selected provider
- **Error handling**: Unified error handling across all providers

### 6. Model Assets
- **Directory**: `assets/models/`
- **Required models**:
  - `yolo-v9-t-384-license-plate-end2end.onnx` (detection)
  - `cct-xs-v1-global-model.onnx` (OCR)
- **Documentation**: `assets/models/README.md` with download instructions

## Provider Comparison

| Feature | OpenALPR (Native) | FastALPR (ONNX) |
|---------|-------------------|-----------------|
| Local Processing | ✓ | ✓ |
| Real-time | ✓ | ✓ |
| Region Specific | ✓ | - |
| YOLO Detection | - | ✓ |
| Advanced OCR | - | ✓ |
| Confidence Scores | ✓ | ✓ |
| Bounding Boxes | ✓ | ✓ |

## Usage Instructions

### For Users
1. Open the app and tap the menu (⋮) in the top right
2. Select "ALPR Settings"
3. Choose your preferred provider:
   - **OpenALPR (Native)**: Traditional OpenALPR with native processing
   - **FastALPR (ONNX)**: Modern YOLO-based detection with advanced OCR
4. Tap "Apply Settings" to switch providers
5. Return to the main screen and capture photos as usual

### For Developers
1. Run `flutter pub get` to install dependencies
2. Download required ONNX models to `assets/models/` (see README in that directory)
3. Build and run the app
4. The provider system will automatically initialize with the default provider

## Next Steps

### Model Download
The FastALPR provider requires ONNX models that need to be downloaded separately:

```bash
# Option 1: Direct download (when available)
wget https://github.com/ankandrew/fast-alpr/releases/download/v1.0.0/yolo-v9-t-384-license-plate-end2end.onnx
wget https://github.com/ankandrew/fast-alpr/releases/download/v1.0.0/cct-xs-v1-global-model.onnx

# Option 2: Using Python fast-alpr package
pip install fast-alpr[onnx]
python -c "
from fast_alpr import ALPR
alpr = ALPR(
    detector_model='yolo-v9-t-384-license-plate-end2end',
    ocr_model='cct-xs-v1-global-model'
)
# Models downloaded to ~/.cache/fast-alpr/
"
```

### Testing
1. Test OpenALPR provider with existing functionality
2. Add ONNX models and test FastALPR provider
3. Verify provider switching works correctly
4. Compare accuracy and performance between providers

### Future Enhancements
- **Model optimization**: Quantized models for better mobile performance
- **Custom models**: Support for custom-trained ONNX models
- **Batch processing**: Process multiple images efficiently
- **Regional models**: Support for different region-specific models
- **Performance metrics**: Built-in benchmarking and comparison tools

## Files Modified/Created

### New Files
- `lib/core/alpr_config.dart` - Configuration system
- `lib/services/alpr_service_interface.dart` - Abstract interface
- `lib/services/alpr_service_factory.dart` - Factory pattern implementation
- `lib/services/fastalpr_service.dart` - FastALPR with ONNX
- `lib/screens/alpr_settings_screen.dart` - Settings UI
- `assets/models/README.md` - Model documentation
- `FASTALPR_INTEGRATION.md` - This documentation

### Modified Files
- `pubspec.yaml` - Added ONNX Runtime dependency and assets
- `lib/services/openalpr_service.dart` - Implements interface
- `lib/screens/home_screen.dart` - Added settings menu
- `lib/widgets/camera_preview_widget.dart` - Uses factory pattern

## Dependencies Added
- `onnxruntime: ^1.19.0` - ONNX Runtime for model inference

The implementation provides a solid foundation for local ALPR processing with multiple provider options, giving users the flexibility to choose the best engine for their specific needs.