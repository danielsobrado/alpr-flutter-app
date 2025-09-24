# FastALPR ONNX Models

This directory should contain the ONNX models for FastALPR license plate recognition.

## Required Models

1. **yolo-v9-t-384-license-plate-end2end.onnx** - License plate detection model
2. **cct-xs-v1-global-model.onnx** - OCR model for text recognition

## How to Obtain Models

### Option 1: Download from fast-alpr GitHub releases
```bash
# Download the models from the fast-alpr repository
wget https://github.com/ankandrew/fast-alpr/releases/download/v1.0.0/yolo-v9-t-384-license-plate-end2end.onnx
wget https://github.com/ankandrew/fast-alpr/releases/download/v1.0.0/cct-xs-v1-global-model.onnx
```

### Option 2: Use fast-alpr Python package to download models
```bash
pip install fast-alpr[onnx]
python -c "
from fast_alpr import ALPR
alpr = ALPR(
    detector_model='yolo-v9-t-384-license-plate-end2end',
    ocr_model='cct-xs-v1-global-model'
)
# Models will be downloaded to ~/.cache/fast-alpr/
# Copy them to this directory
"
```

### Option 3: Build from source
Follow the instructions in the fast-alpr repository to build the models from source.

## Model Specifications

### Detection Model (YOLOv9)
- **Input**: Images resized to 384x384 pixels
- **Format**: RGB, normalized to [0,1]
- **Output**: Bounding boxes with confidence scores

### OCR Model (CCT-XS-V1)
- **Input**: Cropped license plate images, 128x32 pixels
- **Format**: RGB, normalized to [0,1]
- **Output**: Character predictions for plate text

## Notes

- These models are required for the FastALPR provider to function
- Without these models, the app will fall back to OpenALPR only
- Models should be placed directly in this directory
- Total size is approximately 20-50MB depending on the models