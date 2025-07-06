# 📱 Arabic Lip Reading App

A Flutter-based mobile application that uses artificial intelligence to convert lip movements into Arabic text. This app leverages machine learning models to analyze video recordings and transcribe spoken Arabic words from lip movements.

![Flutter](https://img.shields.io/badge/Flutter-3.6.2+-blue.svg)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey.svg)
![Firebase](https://img.shields.io/badge/Backend-Firebase-orange.svg)
![AI](https://img.shields.io/badge/AI-Lip%20Reading-green.svg)

## 📋 App Overview

The Arabic Lip Reading App is designed to bridge communication gaps by converting Arabic lip movements into text using advanced AI models. This application is particularly useful for:

- **Arabic language learners** seeking pronunciation assistance
- **Hearing-impaired individuals** in Arabic-speaking communities  
- **Silent communication** in noise-sensitive environments
- **Research and development** in Arabic speech recognition technology

### Key Functionalities
- Real-time video recording for lip movement capture
- Multiple AI model selection (MSTCN, DCTCN, Conformer)
- Arabic text output with optional diacritization (Harakat)
- Video history management with Firebase integration
- Cross-platform support (Android & iOS)
- Modern Material 3 UI with dark/light theme support

## 🚀 Flutter-Specific Features

### Core Features
- **Video Recording & Selection**: Native camera integration and gallery picker
- **Multiple AI Models**: Support for MSTCN, DCTCN, and Conformer models
- **Real-time Progress Tracking**: Server-sent events for processing updates
- **Firebase Integration**: Authentication, Firestore database, and Cloud Storage
- **Diacritization Toggle**: Arabic text with or without diacritical marks
- **History Management**: Save, search, and replay previous transcriptions
- **Responsive UI**: Material 3 design with smooth animations

### State Management
- **BLoC Pattern**: Using `flutter_bloc` for predictable state management
- **Cubit Implementation**: Separate cubits for video, auth, progress, and navigation
- **Stream Handling**: Real-time progress updates via Server-Sent Events

## 🛠 Tech Stack & Dependencies

### Flutter SDK
- **Version**: 3.6.2+
- **Dart**: Compatible with latest stable versions

### Core Dependencies
```yaml
dependencies:
  flutter_bloc: ^9.1.1          # State management
  video_player: ^2.10.0         # Video playback
  image_picker: ^1.1.2          # Camera & gallery access
  firebase_core: ^3.15.0        # Firebase initialization
  firebase_auth: ^5.6.1         # User authentication
  cloud_firestore: ^5.6.10      # Database
  firebase_storage: ^12.4.8     # File storage
  http: ^1.4.0                  # API communication
  google_fonts: ^6.2.1          # Inter font family
  video_compress: ^3.1.4        # Video optimization
  responsive_framework: ^1.5.1   # Responsive design
  awesome_dialog: ^3.2.1        # Modern dialogs
  fluttertoast: ^8.2.12        # User notifications
```

### Backend Integration
- **API Service**: Custom service connecting to Arabic lip reading backend
- **Base URL**: `https://arabic-lip-reading.loca.lt`
- **Progress Streaming**: Server-Sent Events for real-time updates
- **File Upload**: Multipart form data with hash-based caching

## 🏗 App Architecture

### Folder Structure
```
lib/
├── main.dart                    # App entry point with BLoC providers
├── components/                  # Reusable UI components
│   ├── custom_video_player.dart
│   ├── model_selector.dart
│   ├── modern_progress_bar.dart
│   └── diacritized_toggle.dart
├── cubit/                      # State management
│   ├── auth/                   # Authentication logic
│   ├── video_cubit/            # Video handling and processing
│   ├── progress/               # Progress tracking
│   └── navigation_cubit/       # Bottom navigation
├── model/                      # Data models
│   ├── video_model.dart
│   └── progress_model.dart
├── repository/                 # Data layer
│   └── video_repository.dart
├── screens/                    # UI screens
│   ├── auth/                   # Login/signup
│   ├── lip_reading/            # Main recording screen
│   ├── layout/                 # App shell with navigation
│   └── splash_screen/          # Splash and history
├── service/                    # Business logic
│   ├── api_service.dart        # Backend communication
│   ├── firestore_service.dart  # Database operations
│   └── storage_service.dart    # File management
└── utils/                      # Utilities and themes
    ├── app_theme.dart          # Material 3 theming
    ├── app_route.dart          # Navigation routes
    └── app_colors.dart         # Color constants
```

### State Management Architecture
- **BLoC Pattern**: Separation of business logic from UI
- **Event-Driven**: User actions trigger events processed by cubits
- **Stream-Based**: Real-time progress updates through streams
- **Firebase Integration**: Reactive data binding with Firestore

### Data Flow
1. **Video Input** → Camera recording or gallery selection
2. **Video Processing** → Compression and optimization
3. **API Communication** → Upload to lip reading backend
4. **Progress Tracking** → Real-time updates via SSE
5. **Results Storage** → Save to Firebase with transcription
6. **History Management** → Retrieve and manage past results

## 📱 Prerequisites & Installation

### System Requirements
- **Flutter SDK**: 3.6.2 or higher
- **Android Studio**: Latest stable version
- **Xcode**: 14+ (for iOS development)
- **Firebase Project**: Required for backend services

### Platform-Specific Setup

#### Android Requirements
- **Min SDK**: 21 (Android 5.0)
- **Target SDK**: Latest stable
- **Permissions**: Camera, microphone, internet, storage

#### iOS Requirements  
- **Min iOS**: 11.0+
- **Xcode**: 14+
- **Permissions**: Camera, microphone, photo library

### Firebase Configuration
1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com)
2. Enable Authentication, Firestore, and Storage
3. Download configuration files:
   - `google-services.json` for Android
   - `GoogleService-Info.plist` for iOS
4. Place files in respective platform directories

## 🚀 Getting Started

### 1. Clone the Repository
```bash
git clone <repository-url>
cd lip_reading
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Firebase Setup
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Configure FlutterFire
dart pub global activate flutterfire_cli
flutterfire configure
```

### 4. Run the Application

#### For Android:
```bash
flutter run
```

#### For iOS:
```bash
cd ios && pod install && cd ..
flutter run
```

## 🎯 Usage

### Recording a Video
1. **Launch the app** and complete authentication
2. **Tap "Record"** button to start video capture
3. **Speak clearly** in Arabic while facing the camera
4. **Stop recording** when finished
5. **Select AI model** (MSTCN for speed, Conformer for accuracy)
6. **Choose text format** (with or without diacritics)
7. **Wait for processing** - progress shown in real-time
8. **View results** in the transcription area

### Using Gallery Videos
1. **Tap "Pick Video"** to select from gallery
2. **Choose your video** file
3. **Follow steps 5-8** from recording process

### Managing History
1. **Navigate to History tab**
2. **Search videos** by title
3. **Tap any video** to reload and reprocess
4. **Delete videos** using the delete button
5. **Pull to refresh** to update the list

## 🤖 AI Models

### Available Models
- **MSTCN**: Multi-Scale Temporal Convolutional Network
  - Fast processing
  - Good for real-time applications
  - Lower accuracy but efficient

- **DCTCN**: Densely-Connected Temporal Convolutional Network  
  - Balanced performance
  - Moderate processing time
  - Good accuracy-speed tradeoff

- **Conformer**: Convolution-augmented Transformer
  - Highest accuracy
  - Slower processing
  - Best for quality transcription

## 🔧 Configuration

### Backend Configuration
The app connects to a remote lip reading service. Update the base URL in `lib/service/api_service.dart`:

```dart
static const String baseUrl = "https://arabic-lip-reading.loca.lt";
```

### Firebase Configuration
Firebase configuration is handled automatically through `flutterfire configure`. Manual setup is in `lib/firebase_options.dart`.

## 📝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 🐛 Troubleshooting

### Common Issues

**Video not loading:**
- Check internet connection
- Verify camera permissions
- Ensure video format is supported (MP4, MOV, AVI)

**Processing fails:**
- Check server availability
- Verify video has clear face visibility
- Try with shorter video clips
- Switch to different AI model

**Firebase errors:**
- Verify Firebase configuration
- Check authentication status
- Ensure Firestore rules allow read/write


## 🤝 Support

For support and questions:
- Create an issue in the repository
- Check the troubleshooting section
- Review Firebase and Flutter documentation

## 🔮 Future Enhancements

- Offline processing capabilities
- Multiple Arabic dialect support
- Enhanced video preprocessing
- Batch processing for multiple videos
- Export options (PDF, text files)
- Real-time lip reading during recording
- Integration with Arabic TTS services

---

**Note**: This application requires clear video quality with visible lip movements for optimal results. Performance may vary based on lighting conditions, video quality, and