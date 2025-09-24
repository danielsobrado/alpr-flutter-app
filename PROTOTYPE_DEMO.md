# ALPR Prototype Demo

## 🚀 Prototype Ready!

The ALPR Flutter app now includes an **initial provider selection screen** for testing multiple ALPR solutions.

### 📱 APK Location
```
build/app/outputs/flutter-apk/app-debug.apk
```

## 🎯 Demo Flow

### 1. Launch Screen
- App opens with **"ALPR Prototype"** title
- Shows **"Choose License Plate Recognition Engine"**
- Two provider options are displayed as cards

### 2. Provider Selection
**OpenALPR (Native)**
- Traditional OpenALPR library
- Features: Local, Real-time, Regions, Confidence, Bounding Box
- Production-ready implementation

**FastALPR (ONNX) - BETA**
- Modern YOLO-based detection with advanced OCR
- Features: Local, Real-time, YOLO, Advanced OCR, Confidence, Bounding Box
- Currently in **mock mode** (returns "FAST123" test data)
- Blue info box explains mock mode status

### 3. Testing Process
1. **Select Provider**: Tap on desired provider card
2. **Start Testing**: Tap "Start Testing" button
3. **Initialize**: App initializes selected provider
4. **Main Screen**: Navigate to camera interface

### 4. Main App Features
- **Camera Preview**: Real-time camera view
- **Capture & Analyze**: Take photos for plate detection
- **Results Display**: Shows detected plates with confidence scores
- **Settings Access**: Menu → "ALPR Settings" to change providers
- **Notes System**: Add notes to detected plates

## 🧪 Testing Notes

### OpenALPR Provider
- **Status**: ✅ Fully functional
- **Expected Results**: Real license plate detection
- **Performance**: Traditional OpenALPR accuracy

### FastALPR Provider
- **Status**: 🧪 Mock mode for development
- **Expected Results**: Returns "FAST123" test plate
- **Mock Data**: 85% confidence, simulated bounding box
- **Processing**: 500ms simulated delay

## 🔧 Development Status

**✅ Complete Features:**
- Initial provider selection UI
- Provider switching architecture
- Settings screen with comparison table
- Camera integration with both providers
- Mock FastALPR implementation ready for models

**🚧 Next Steps for Full FastALPR:**
1. Download ONNX models (see `assets/models/README.md`)
2. Implement actual ONNX inference
3. Test with real license plates

## 📊 Provider Comparison

| Feature | OpenALPR | FastALPR |
|---------|-----------|-----------|
| Status | ✅ Production | 🧪 Mock Mode |
| Detection | Traditional | YOLO v9 |
| OCR | OpenALPR | Advanced CCT |
| Models | Built-in | ONNX Runtime |
| Real Plates | ✅ Yes | 🚧 Pending Models |

## 🎮 How to Test

### Install & Launch
```bash
# Install APK on Android device
adb install build/app/outputs/flutter-apk/app-debug.apk

# Or transfer APK and install manually
```

### Test Scenario 1: OpenALPR
1. Launch app
2. Select **"OpenALPR (Native)"**
3. Tap **"Start Testing"**
4. Grant camera permissions
5. Take photos of license plates
6. Verify real detection results

### Test Scenario 2: FastALPR Mock
1. Launch app (or use settings to switch)
2. Select **"FastALPR (ONNX) - BETA"**
3. Tap **"Start Testing"**
4. Note blue "mock mode" indicator
5. Take any photo
6. Verify mock result: "FAST123"

### Test Scenario 3: Provider Switching
1. In main app, tap menu (⋮)
2. Select **"ALPR Settings"**
3. Switch between providers
4. Test both implementations
5. Compare results and performance

## 🎯 Prototype Goals

This prototype demonstrates:
- ✅ **Multi-provider Architecture**: Clean switching between ALPR engines
- ✅ **User Choice**: Let users select their preferred engine
- ✅ **Development Ready**: Framework ready for multiple ALPR solutions
- ✅ **Production UI**: Polish selection and settings interfaces
- ✅ **Testing Environment**: Easy comparison between providers

Perfect for evaluating different ALPR solutions and gathering user feedback on preferred engines!