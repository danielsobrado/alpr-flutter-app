# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ALPR Flutter App is a modern Android application for automatic license plate recognition (ALPR) with secure cloud-based note management. The app combines real-time camera-based plate detection using OpenALPR with Firebase authentication and Firestore for seamless note synchronization across devices.

## Development Commands

```bash
# Get Flutter dependencies
flutter pub get

# Generate JSON serialization code
flutter packages pub run build_runner build --delete-conflicting-outputs

# Run on Android device/emulator
flutter run

# Build debug APK
flutter build apk --debug

# Build release APK
flutter build apk --release

# Clean build artifacts
flutter clean

# Analyze code
flutter analyze

# Run tests
flutter test
```

## Project Architecture

### Core Application Structure
The app follows a clean architecture pattern with clear separation of concerns:

**Authentication Flow:**
1. `lib/main.dart` - Entry point with Firebase initialization and Provider setup
2. `lib/screens/auth_wrapper.dart` - Authentication state router
3. `lib/screens/login_screen.dart` - Google Sign-In interface 
4. `lib/screens/home_screen.dart` - Main camera and detection interface

**Key Services Architecture**
- **Authentication**: Firebase Auth with Google Sign-In following Omi pattern
- **Data Storage**: Cloud Firestore for user profiles and plate notes
- **Camera & ALPR**: Native Android integration with OpenALPR library
- **State Management**: Provider pattern for auth and UI state
- **Image Processing**: Camera plugin with OpenALPR native method channels

**Widget Component System**
- `camera_preview_widget.dart` - Real-time camera with plate detection overlay
- `add_note_dialog.dart` - Modal for adding contextual notes to detected plates
- `plate_notes_widget.dart` - Display and management of existing notes
- `all_notes_screen.dart` - Full notes history and management interface

### Key Dependencies & Integration Points
- **Firebase Stack**: `firebase_core`, `firebase_auth`, `cloud_firestore`
- **Authentication**: `google_sign_in` for seamless OAuth flow
- **Camera & Vision**: `camera` plugin with native OpenALPR integration
- **State Management**: `provider` for reactive UI updates
- **Permissions**: `permission_handler` for camera and storage access
- **Serialization**: `json_annotation` + `json_serializable` for data models

### Android Configuration & Native Integration
- **Package ID**: `com.example.alpr_flutter_app`
- **Min SDK**: 23 (Android 6.0) - Required for Camera2 API
- **Permissions**: CAMERA, INTERNET, ACCESS_NETWORK_STATE, READ/WRITE_EXTERNAL_STORAGE
- **Native Libraries**: OpenALPR Android library via Jitpack
- **Method Channels**: Custom implementation for OpenALPR communication
- **Google Services**: Google Sign-In configuration and API keys

## Firebase Integration Pattern

### Authentication (Omi-inspired Implementation)
The app follows the same authentication pattern as Omi:
- **Auto Account Creation**: Firebase creates accounts automatically on first sign-in
- **Upsert Pattern**: User profiles created/updated in Firestore with retry logic
- **Session Management**: Token-based auth with automatic refresh
- **Cross-device Sync**: Notes accessible from any authenticated device

### Data Storage Structure
```
Firestore Collections:
├── users/{userId}           # User profile data
│   ├── uid: string
│   ├── email: string
│   ├── displayName: string
│   ├── photoUrl: string?
│   ├── createdAt: timestamp
│   └── updatedAt: timestamp
└── plate_notes/{noteId}     # User's plate observations
    ├── id: string
    ├── plateNumber: string
    ├── userId: string        # Owner reference
    ├── note: string
    ├── location: string?
    ├── latitude: double?
    ├── longitude: double?
    ├── createdAt: timestamp
    ├── updatedAt: timestamp
    ├── imageUrls: string[]?
    └── metadata: map        # Detection confidence, region, etc.
```

## OpenALPR Integration

### Native Android Implementation
- **Method Channel**: `openalpr_flutter` for Dart ↔ Native communication
- **Configuration**: `assets/runtime_data/openalpr.conf` with mobile-optimized settings
- **Recognition Flow**: Image capture → Native processing → JSON results → Dart models
- **Performance**: Optimized for mobile with 1280x720 max resolution, 65% confidence threshold

### Detection Data Models
- `PlateResult`: Main detection result with confidence and coordinates
- `Coordinate`: Bounding box points for visual overlay
- `PlateCandidate`: Alternative plate readings with confidence scores
- `OpenALPRResponse`: Complete API response wrapper

## Model Integration & Notes System

### Current Implementation Status
**✅ Firebase Authentication**: Google Sign-In with automatic account creation
**✅ Cloud Storage**: Firestore integration for notes and user data
**✅ Camera Integration**: Real-time camera preview with capture functionality
**✅ OpenALPR Processing**: Native Android library integration via method channels
**✅ Note Management**: Full CRUD operations with cloud sync
**✅ Material Design 3**: Modern Android UI with dark/light themes

### Note Management Features
- **Contextual Notes**: Add observations directly from detected plates
- **Rich Metadata**: Stores detection confidence, region, timestamp, location
- **Cloud Sync**: Automatic backup and synchronization via Firestore
- **Search & Filter**: Browse notes chronologically with plate number grouping
- **Offline Support**: Notes cached locally and synced when connected

## Testing & Development

### Firebase Setup Requirements
1. Create Firebase project with Authentication and Firestore enabled
2. Download `google-services.json` to `android/app/`
3. Configure Google Sign-In in Firebase Console
4. Update `lib/firebase_options.dart` with project configuration

### Development Workflow
1. **Initial Setup**: Configure Firebase project and download config files
2. **Dependencies**: Run `flutter pub get` and code generation
3. **Permissions**: Grant camera and storage permissions on test device
4. **Authentication**: Sign in with Google account for full functionality
5. **Testing**: Use real Android device for camera and OpenALPR testing

### Known Limitations & Considerations
- **Android Only**: No iOS support due to OpenALPR Android library dependency
- **Camera Required**: App requires rear-facing camera with autofocus for optimal results
- **Network Dependency**: Authentication and note sync require internet connectivity
- **OpenALPR License**: Commercial use requires OpenALPR licensing (current implementation for development/testing)

## Security & Privacy

### Data Protection
- **User Isolation**: Firestore security rules ensure users only access their own data
- **Encrypted Transit**: All Firebase communication uses HTTPS/TLS
- **Authentication Required**: All data operations require valid authentication
- **No Image Storage**: Captured images processed locally, not stored in cloud

### Production Deployment Considerations
- **Firestore Rules**: Implement production security rules for user data isolation
- **API Keys**: Secure Firebase configuration and Google Sign-In credentials  
- **OpenALPR Licensing**: Obtain commercial license for production use
- **Privacy Policy**: Implement privacy policy for data collection and processing