# Quick Termux + Predator ALPR Setup for Samsung Galaxy S25

## 📱 Step 1: Install Termux (5 minutes)

### Download Termux
1. **DON'T use Google Play Store** (outdated version)
2. **Download from F-Droid**: https://f-droid.org/packages/com.termux/
3. **Or direct APK**: https://github.com/termux/termux-app/releases/latest
4. **Install APK** on your Samsung Galaxy S25

## 🔧 Step 2: Basic Termux Setup (10 minutes)

### Open Termux and run these commands:
```bash
# Update package manager
pkg update && pkg upgrade

# Install essential packages
pkg install python git opencv ffmpeg imagemagick

# Install Python packages
pip install opencv-python numpy pillow
```

## 🎯 Step 3: Install Predator Mobile (5 minutes)

### Download and setup Predator:
```bash
# Go to home directory
cd ~

# Create Predator directory
mkdir -p Predator

# Download our mobile script
curl -o Predator/predator_mobile.py https://raw.githubusercontent.com/your-repo/predator_mobile.py
# (Or manually copy the script from your computer)

# Make executable
chmod +x Predator/predator_mobile.py

# Test installation
python Predator/predator_mobile.py
```

## 📋 Step 4: Manual Script Installation

If the download doesn't work, **manually create the script**:

```bash
# Create the script file
nano ~/Predator/predator_mobile.py
```

**Then copy and paste the entire content from `termux_scripts/predator_mobile.py`**

## ✅ Step 5: Test the Integration

### Test in Termux:
```bash
# Test with a sample image
python ~/Predator/predator_mobile.py /path/to/test/image.jpg
```

### Test in Flutter App:
1. **Open the ALPR app**
2. **Take a photo**
3. **Should see**: "🚀 Termux ALPR initialized! Local processing ready..."
4. **Processing message**: "🔍 Processing with Termux ALPR..."
5. **Results**: "✅ Termux ALPR detected X plate(s)!"

## 🚨 Troubleshooting

### If app still shows "Install Termux...":
1. **Restart the app** after installing Termux
2. **Check Termux permissions** in Android settings
3. **Verify script location**: `~/Predator/predator_mobile.py`

### If processing fails:
```bash
# Check Python installation
python --version

# Test OpenCV
python -c "import cv2; print('OpenCV working')"

# Test script directly
python ~/Predator/predator_mobile.py ~/test_image.jpg
```

## 🔧 Advanced Configuration (Optional)

### For better accuracy, install additional packages:
```bash
# Enhanced OCR (if available)
pkg install tesseract

# Additional Python libraries
pip install pytesseract scikit-image
```

## 🎯 Expected Results

Once setup is complete:
- **App detects Termux** automatically
- **Local ALPR processing** in 1-2 seconds
- **No internet required** for plate recognition
- **Complete privacy** - all processing on-device

The app will automatically switch from "camera-only" mode to "Termux ALPR" mode once it detects the properly configured Termux environment!