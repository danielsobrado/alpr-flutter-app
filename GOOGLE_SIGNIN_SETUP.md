# Google Sign-In Setup Issues Found

## Critical Configuration Problems

### ❌ 1. Missing google-services.json
**Location**: `/android/app/google-services.json`
**Status**: NOT FOUND
**Solution**: Download from Firebase Console → Project Settings → Your apps → Android app → Download google-services.json

### ❌ 2. Missing Google Services Gradle Plugin
**Location**: `/android/build.gradle.kts`
**Status**: MISSING
**Solution**: Add to build.gradle.kts:
```kotlin
plugins {
    id("com.google.gms.google-services") version "4.4.0" apply false
}
```

### ❌ 3. Missing Google Services Plugin in App Module
**Location**: `/android/app/build.gradle.kts`
**Status**: MISSING
**Solution**: Add to plugins section:
```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")  // ← ADD THIS
}
```

### ⚠️ 4. Package Name Mismatch
**Current Package**: `com.example.alpr_flutter_app`
**Firebase expects**: This must match exactly in Firebase Console
**Action required**: Verify in Firebase Console → Project Settings → Your apps

## Setup Steps to Fix Google Sign-In

### Step 1: Firebase Console Configuration
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project (or create new one)
3. Go to Authentication → Sign-in method
4. Enable Google Sign-In
5. Add your package name: `com.example.alpr_flutter_app`

### Step 2: Add Android App to Firebase
1. In Firebase Console → Project Settings
2. Click "Add app" → Android
3. Package name: `com.example.alpr_flutter_app`
4. Download `google-services.json` → place in `/android/app/`

### Step 3: Get SHA-1 Fingerprint
```bash
# Debug keystore (for development)
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# Look for SHA1 fingerprint and add to Firebase Console
```

### Step 4: Update Gradle Files
Add the missing Google Services plugin configuration (see above)

### Step 5: OAuth 2.0 Configuration
1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Select your project
3. APIs & Services → Credentials
4. Create OAuth 2.0 client ID for Android
5. Add SHA-1 fingerprint and package name

## Debug Commands

Run these to diagnose issues:

```bash
# Check if google-services.json exists
ls -la android/app/google-services.json

# Check gradle configuration
grep -r "google-services" android/

# Run configuration diagnostic in app
# Tap "Check Configuration" button in login screen
```

## Common Error Messages

### "DEVELOPER_ERROR"
- Missing or incorrect google-services.json
- SHA-1 fingerprint not registered
- Package name mismatch

### "SIGN_IN_FAILED"
- Network connectivity issues
- Google Play Services not available
- Invalid OAuth configuration

### "NETWORK_ERROR"  
- No internet connection
- Firewall blocking Google services
- DNS resolution issues

## Testing Checklist

- [ ] google-services.json in place
- [ ] Google Services plugin added to gradle
- [ ] SHA-1 fingerprint registered in Firebase
- [ ] Google Sign-In enabled in Firebase Console
- [ ] OAuth 2.0 client configured in Google Cloud
- [ ] Package name matches everywhere
- [ ] Internet connectivity available
- [ ] Google Play Services installed on device