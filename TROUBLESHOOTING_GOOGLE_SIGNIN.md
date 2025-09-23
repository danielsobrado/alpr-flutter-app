# Google Sign-In Troubleshooting Guide

## Current Issue: "Sign in was cancelled or failed"

This error occurs when `GoogleSignIn.signIn()` returns `null`. The enhanced logging will now show you exactly why.

## Step-by-Step Debugging

### 1. **First - Check the Debug Console**

After adding enhanced logging, attempt Google Sign-In again and look for these messages:

```
🔄 Starting Google Sign-In process...
📱 Previously signed in: false/true
🧹 Signing out to ensure clean state...
👥 Checking available accounts...
🤫 Silent sign-in result: null/email
🚀 Triggering Google Sign-In authentication flow...
📋 Google Sign-In Configuration:
   - Client ID configured: null/configured
   - Scopes: [email]
📊 Google Sign-In result analysis:
   - Result: NULL/SUCCESS
```

### 2. **Use the Configuration Checker**

In your app, tap the **"Check Configuration"** button on the login screen. This will output detailed diagnostic information.

### 3. **Common Null Return Scenarios**

#### Scenario A: DEVELOPER_ERROR
**Symptoms**: Console shows "DEVELOPER_ERROR" 
**Cause**: Configuration issue
**Solutions**:
- Replace placeholder `google-services.json` with real Firebase config
- Add your SHA-1 fingerprint to Firebase Console
- Verify package name matches exactly

#### Scenario B: No Error, Just Null
**Symptoms**: No exception, just null return
**Cause**: User cancelled or configuration incomplete
**Solutions**:
- Check if Google Sign-In dialog appears at all
- Verify Google Sign-In is enabled in Firebase Console
- Check internet connectivity

#### Scenario C: Silent Sign-In Fails
**Symptoms**: "Silent sign-in error" in logs
**Cause**: No cached credentials or expired session
**Solutions**: Normal behavior for first-time sign-in

## Required Configuration Steps

### ✅ Step 1: Create Real Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create new project: "alpr-flutter-app"
3. Enable Authentication → Google Sign-In

### ✅ Step 2: Download Real google-services.json
1. In Firebase → Project Settings
2. Add Android app with package: `com.example.alpr_flutter_app`
3. Download `google-services.json`
4. Replace the placeholder file in `/android/app/`

### ✅ Step 3: Get SHA-1 Fingerprint
```bash
# For debug builds (development)
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# Look for SHA1 line like:
# SHA1: AB:CD:EF:12:34:56:78:90:AB:CD:EF:12:34:56:78:90:AB:CD:EF:12
```

### ✅ Step 4: Add SHA-1 to Firebase
1. In Firebase Console → Project Settings → Your Apps
2. Click Android app → Add fingerprint
3. Paste the SHA1 value (without "SHA1:" prefix)

### ✅ Step 5: Configure OAuth 2.0 Client
1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Select same project as Firebase
3. APIs & Services → Credentials
4. Find "Android client" for your package name
5. Verify SHA-1 fingerprint is added there too

## Testing Commands

```bash
# Build debug APK with new configuration
flutter build apk --debug

# Check if google-services.json is valid
cat android/app/google-services.json | grep "project_id"

# Verify gradle configuration includes Google Services
grep -r "google-services" android/
```

## Advanced Debugging

### Check Firebase Options in App
The enhanced logging will show:
```
🔥 Firebase Status:
   ✅ Firebase initialized: [DEFAULT]
   📱 App ID: 1:123456789:android:abcdef123456  
   🏢 Project ID: alpr-flutter-app
```

If these show placeholder values, your `google-services.json` is still the template.

### Expected vs Actual Values

| Component | Expected | Current Status |
|-----------|----------|----------------|
| google-services.json | ✅ Present | ⚠️ Template file |
| Google Services plugin | ✅ Added | ✅ Added |
| SHA-1 fingerprint | ❌ Not registered | Needs setup |
| Firebase project | ❌ Not created | Needs setup |
| OAuth 2.0 client | ❌ Not configured | Needs setup |

## Next Actions

1. **Create real Firebase project** (highest priority)
2. **Download real google-services.json** 
3. **Register SHA-1 fingerprint**
4. **Test with enhanced logging**

## Error Message Meanings

- **"Sign in was cancelled or failed"** → `signIn()` returned null
- **"DEVELOPER_ERROR"** → Configuration problem  
- **"SIGN_IN_FAILED"** → Network or Play Services issue
- **"No cached account"** → Normal for first sign-in attempt

After following these steps, the enhanced logging will guide you to the specific issue.