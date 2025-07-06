# 📱 Arabic Lip Reading App

A Flutter-based mobile application that uses artificial intelligence to convert lip movements into Arabic text. This app leverages machine learning models to analyze video recordings and transcribe spoken words from lip movements.

![Flutter](https://img.shields.io/badge/Flutter-3.6.2+-blue.svg)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey.svg)
![Firebase](https://img.shields.io/badge/Backend-Firebase-orange.svg)
![AI](https://img.shields.io/badge/AI-Lip%20Reading-green.svg)

## 📋 Table of Contents

- [📋 Table of Contents](#-table-of-contents)
- [🎯 App Overview](#-app-overview)
  - [Key Functionalities](#key-functionalities)
- [🎬 Demo](#-demo)
- [🚀 Flutter-Specific Features](#-flutter-specific-features)
  - [Core Features](#core-features)
  - [State Management](#state-management)
  - [AI Models Available](#ai-models-available)
- [🛠 Tech Stack & Dependencies](#-tech-stack--dependencies)
  - [Flutter SDK](#flutter-sdk)
  - [Core Dependencies](#core-dependencies)
  - [Backend Integration](#backend-integration)
- [🏗 App Architecture](#-app-architecture)
  - [Folder Structure](#folder-structure)
  - [State Management Architecture](#state-management-architecture)
  - [Data Flow](#data-flow)
- [📱 Prerequisites & Installation](#-prerequisites--installation)
  - [System Requirements](#system-requirements)
  - [Platform-Specific Setup](#platform-specific-setup)
  - [Firebase Configuration](#firebase-configuration)
- [🚀 Getting Started](#-getting-started)
  - [1. Clone the Repository](#1-clone-the-repository)
  - [2. Install Dependencies](#2-install-dependencies)
  - [3. Firebase Setup](#3-firebase-setup)
  - [4. Run the Application](#4-run-the-application)
- [🎯 Usage Guide](#-usage-guide)
  - [Recording a Video](#recording-a-video)
  - [Using Gallery Videos](#using-gallery-videos)
  - [Managing History](#managing-history)
  - [AI Model Selection](#ai-model-selection)
  - [Text Format Options](#text-format-options)
- [🤖 AI Models](#-ai-models)
  - [Available Models](#available-models)
  - [Model Comparison](#model-comparison)
- [🔧 Configuration](#-configuration)
  - [Backend Configuration](#backend-configuration)
  - [Firebase Configuration](#firebase-configuration-1)
  - [App Theme Customization](#app-theme-customization)
- [📊 Progress Tracking](#-progress-tracking)
  - [Real-time Updates](#real-time-updates)
  - [Progress Steps](#progress-steps)
- [🔐 Authentication & Security](#-authentication--security)
  - [Firebase Authentication](#firebase-authentication)
  - [Data Security](#data-security)
- [💾 Data Management](#-data-management)
  - [Firestore Database](#firestore-database)
  - [Firebase Storage](#firebase-storage)
  - [Video Repository](#video-repository)
- [🎨 UI/UX Design](#-uiux-design)
  - [Material 3 Design](#material-3-design)
  - [Theme System](#theme-system)
  - [Custom Components](#custom-components)
- [📝 API Documentation](#-api-documentation)
  - [Backend API](#backend-api)
  - [Progress Streaming](#progress-streaming)
- [🧪 Testing & Debugging](#-testing--debugging)
  - [BLoC Observer](#bloc-observer)
  - [Error Handling](#error-handling)
- [📝 Contributing](#-contributing)
- [🐛 Troubleshooting](#-troubleshooting)
  - [Common Issues](#common-issues)
- [🤝 Support](#-support)
- [🔮 Future Enhancements](#-future-enhancements)

## 🎯 App Overview

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

## 🎬 Demo

Watch the application in action with our demo video showcasing the Arabic lip reading functionality:

<video width="600" controls>
  <source src="assets/video/demo.mp4" type="video/mp4">
  Your browser does not support the video tag.
</video>

*The demo video demonstrates the complete workflow from video recording to Arabic text transcription.*

## 🚀 Flutter-Specific Features

### Core Features
- **Video Recording & Selection**: Native camera integration and gallery picker using `image_picker`
- **Custom Video Player**: Built with `video_player` package with custom controls
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
- **State Persistence**: Proper state management across app lifecycle

### AI Models Available
- **MSTCN**: Multi-Scale Temporal Convolutional Network (Fast & efficient)
- **DCTCN**: Densely-Connected Temporal Convolutional Network (Balanced accuracy)
- **Conformer**: Convolution-augmented Transformer (Highest accuracy)

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
  connectivity_plus: ^6.1.4     # Network connectivity
  path_provider: ^2.1.5         # File system paths
  uuid: ^4.5.1                  # Unique identifiers
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
│   ├── custom_video_player.dart    # Video player with controls
│   ├── model_selector.dart         # AI model selection widget
│   ├── modern_progress_bar.dart    # Animated progress indicator
│   ├── diacritized_toggle.dart     # Text format toggle
│   └── custom_text_from_field.dart # Custom input field
├── cubit/                      # State management (BLoC pattern)
│   ├── auth/                   # Authentication logic
│   │   ├── auth_cubit.dart
│   │   └── auth_state.dart
│   ├── video_cubit/            # Video handling and processing
│   │   ├── video_cubit.dart
│   │   └── video_state.dart
│   ├── progress/               # Progress tracking
│   │   ├── progress_cubit.dart
│   │   └── progress_state.dart
│   └── navigation_cubit/       # Bottom navigation
│       └── navigation_cubit.dart
├── model/                      # Data models
│   ├── video_model.dart        # Video data structure
│   └── progress_model.dart     # Progress tracking model
├── repository/                 # Data layer
│   └── video_repository.dart   # Video data operations
├── screens/                    # UI screens
│   ├── auth/                   # Login/signup screens
│   │   ├── login_screen.dart
│   │   └── signup_screen.dart
│   ├── lip_reading/            # Main recording screen
│   │   └── lip_reading_screen.dart
│   ├── layout/                 # App shell with navigation
│   │   └── app_shell.dart
│   └── splash_screen/          # Splash and history
│       ├── splash_screen.dart
│       └── history_screen.dart
├── service/                    # Business logic
│   ├── api_service.dart        # Backend communication
│   ├── firestore_service.dart  # Database operations
│   ├── storage_service.dart    # File management
│   └── connectivity_service.dart # Network monitoring
└── utils/                      # Utilities and themes
    ├── app_theme.dart          # Material 3 theming
    ├── app_route.dart          # Navigation routes
    └── app_colors.dart         # Color constants
```

### State Management Architecture
- **BLoC Pattern**: Separation of business logic from UI components
- **Event-Driven**: User actions trigger events processed by cubits
- **Stream-Based**: Real-time progress updates through streams
- **Firebase Integration**: Reactive data binding with Firestore

### Data Flow
1. **Video Input** → Camera recording or gallery selection via `image_picker`
2. **Video Processing** → Compression using `video_compress`
3. **API Communication** → Upload to lip reading backend via `http`
4. **Progress Tracking** → Real-time updates via Server-Sent Events
5. **Results Storage** → Save to Firebase with transcription
6. **History Management** → Retrieve and manage past results from Firestore

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

## 🎯 Usage Guide

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
2. **Search videos** by title using search field
3. **Tap any video** to reload and reprocess
4. **Delete videos** using the delete button
5. **Pull to refresh** to update the list

### AI Model Selection
- **MSTCN**: Best for quick processing
- **DCTCN**: Balanced performance
- **Conformer**: Highest accuracy

### Text Format Options
- **Plain Text**: Arabic without diacritical marks
- **Diacritized**: Arabic with harakat (diacritical marks)

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

### Model Comparison
| Model | Speed | Accuracy | Best For |
|-------|-------|----------|----------|
| MSTCN | ⭐⭐⭐ | ⭐⭐ | Quick results |
| DCTCN | ⭐⭐ | ⭐⭐⭐ | Balanced use |
| Conformer | ⭐ | ⭐⭐⭐ | High accuracy |

## 🔧 Configuration

### Backend Configuration
The app connects to a remote lip reading service. Update the base URL in `lib/service/api_service.dart`:

```dart
static const String baseUrl = "https://arabic-lip-reading.loca.lt";
```

### Firebase Configuration
Firebase configuration is handled automatically through `flutterfire configure`. Manual setup is in `lib/firebase_options.dart`.

### App Theme Customization
Customize the app theme in `lib/utils/app_theme.dart`:
- Material 3 design system
- Google Fonts (Inter) integration
- Light and dark theme support
- Custom color schemes

## 📊 Progress Tracking

### Real-time Updates
- Server-Sent Events for live progress
- Animated progress bars with steps
- Estimated time remaining
- Cancellation support

### Progress Steps
1. **Initializing** - Setting up processing
2. **Loading Video** - Preparing video file
3. **Compressing Video** - Optimizing file size
4. **Uploading** - Sending to server
5. **Backend Processing** - AI analysis
6. **Completed** - Results ready

## 🔐 Authentication & Security

### Firebase Authentication
- Email/password authentication
- Secure user session management
- User-specific data isolation

### Data Security
- Firebase Security Rules
- Encrypted data transmission
- User data privacy protection

## 💾 Data Management

### Firestore Database
- User video history storage
- Scalable document structure
- Real-time synchronization

### Firebase Storage
- Secure video file storage
- Automatic file management
- CDN-powered delivery

### Video Repository
- Abstracted data layer
- CRUD operations for videos
- Error handling and validation

## 🎨 UI/UX Design

### Material 3 Design
- Modern design system
- Adaptive color schemes
- Smooth animations and transitions

### Theme System
- System-based theme switching
- Custom color palettes
- Typography using Inter font

### Custom Components
- `CustomVideoPlayer` - Video playback with controls
- `ModelSelector` - AI model selection interface
- `ModernProgressBar` - Animated progress tracking
- `DiacritizedToggle` - Text format switching

## 📝 API Documentation

### Backend API
- **GET** `/config` - Retrieve available models
- **POST** `/transcribe/` - Start transcription process
- **GET** `/progress/{taskId}` - Stream progress updates
- **DELETE** `/progress/{taskId}/cancel` - Cancel processing

### Progress Streaming
Real-time updates via Server-Sent Events with structured progress data including status, steps, and error handling.

## 🧪 Testing & Debugging

### BLoC Observer
Custom BLoC observer for state tracking:
- State creation and changes
- Error monitoring
- Performance debugging

### Error Handling
- User-friendly error messages
- Network error recovery
- Graceful failure handling

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

**Model loading issues:**
- Check network connectivity
- Verify server status
- Try refreshing the model list

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
- Advanced user analytics
- Video quality optimization
- Cloud-based model updates

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Note**: This application requires clear video quality with visible lip movements for optimal results. Performance may vary based on lighting conditions, video quality, and pronunciation clarity.