## GymSaaS Pro - MVVM Architecture with Riverpod

This project implements a clean MVVM (Model-View-ViewModel) architecture using Riverpod for state management.

### Updated Project Structure

```
lib/
├── main.dart                              # App entry point with ProviderScope
├── screens/
│   ├── auth_container_screen.dart        # Main auth container (manages tabs)
│   ├── login_screen.dart                 # LoginScreenContent widget
│   └── face_recognition_screen.dart      # FaceRecognitionScreenContent widget
└── viewmodels/
    ├── auth_viewmodel.dart               # AuthViewModel (manages auth mode)
    ├── login_viewmodel.dart              # LoginViewModel + LoginState
    └── face_recognition_viewmodel.dart   # FaceRecognitionViewModel + FaceRecognitionState
```

### Architecture Layers

#### 1. **Models** (State Classes)

**LoginState** - Immutable state for login screen
- Properties: email, password, obscurePassword, isLoading, errorMessage, isLoggedIn
- Implements `copyWith()` for immutable updates

**FaceRecognitionState** - Immutable state for face recognition
- Properties: isLoading, isCameraOpen, errorMessage, isRecognized, recognizedUser
- Implements `copyWith()` for immutable updates

**AuthState** - Immutable state for auth mode management
- Properties: currentMode (login or faceRecognition)
- Implements `copyWith()` for immutable updates

#### 2. **ViewModels** (Business Logic)

**LoginViewModel** extends `StateNotifier<LoginState>`
- `setEmail(String email)` - Updates email field
- `setPassword(String password)` - Updates password field
- `togglePasswordVisibility()` - Toggles password visibility
- `signIn()` - Handles authentication with validation
- `clearError()` - Clears error messages

**FaceRecognitionViewModel** extends `StateNotifier<FaceRecognitionState>`
- `openCamera()` - Opens camera
- `startFaceRecognition()` - Initiates face recognition process
- `resetCamera()` - Resets camera state
- `closeCamera()` - Closes camera
- `clearError()` - Clears error messages

**AuthViewModel** extends `StateNotifier<AuthState>`
- `switchMode(AuthMode mode)` - Switches between Login and Face Recognition
- `setLoginMode()` - Sets auth mode to login
- `setFaceRecognitionMode()` - Sets auth mode to face recognition

#### 3. **Views** (UI Widgets)

**AuthContainerScreen** - Main container widget
- Uses `ConsumerWidget` to connect to Riverpod
- Manages tab navigation between Login and Face Recognition
- Displays appropriate content based on `authViewModelProvider`
- Contains header (logo, title) and tab buttons

**LoginScreenContent** - Login form content widget
- Uses `ConsumerWidget` to connect to Riverpod
- Displays email/password form
- Observes `loginViewModelProvider` for state changes
- Shows loading state and error messages

**FaceRecognitionScreenContent** - Face recognition content widget
- Uses `ConsumerWidget` to connect to Riverpod
- Displays camera interface
- Shows different states: idle, camera open, recognizing, recognized
- Observes `faceRecognitionViewModelProvider` for state changes

### State Management Flow

```
User Action (tab click)
    ↓
AuthContainerScreen calls AuthViewModel method (setLoginMode/setFaceRecognitionMode)
    ↓
AuthViewModel updates AuthState
    ↓
AuthContainerScreen rebuilds and displays appropriate content
    
---

User Action (form input, button click)
    ↓
LoginScreenContent/FaceRecognitionScreenContent calls ViewModel method
    ↓
ViewModel updates state (LoginState/FaceRecognitionState)
    ↓
Riverpod notifies all listeners
    ↓
Widget rebuilds with new state
    ↓
UI reflects changes
```

### Key Features

✅ **Tab Navigation** - Seamless switching between Login and Face Recognition
✅ **Reactive State Management** - Riverpod automatically rebuilds widgets
✅ **Separation of Concerns** - UI logic separated from business logic
✅ **Testability** - ViewModels can be tested independently
✅ **Type Safety** - Fully typed with Dart's type system
✅ **Error Handling** - Built-in error message display
✅ **Form Validation** - Email and password validation
✅ **Loading States** - Loading indicators during operations
✅ **Demo Credentials** - owner@demo.com / password123

### Providers Definition

```dart
// Auth mode management
final authViewModelProvider = 
    StateNotifierProvider<AuthViewModel, AuthState>((ref) {
  return AuthViewModel();
});

// Login feature
final loginViewModelProvider = 
    StateNotifierProvider<LoginViewModel, LoginState>((ref) {
  return LoginViewModel();
});

// Face Recognition feature
final faceRecognitionViewModelProvider = 
    StateNotifierProvider<FaceRecognitionViewModel, FaceRecognitionState>((ref) {
  return FaceRecognitionViewModel();
});
```

### Usage Example

```dart
// In AuthContainerScreen
final authState = ref.watch(authViewModelProvider);
final authViewModel = ref.read(authViewModelProvider.notifier);

// Switch to login mode
authViewModel.setLoginMode();

// In LoginScreenContent
final loginState = ref.watch(loginViewModelProvider);
final loginViewModel = ref.read(loginViewModelProvider.notifier);

// Update email
loginViewModel.setEmail('user@example.com');

// In FaceRecognitionScreenContent
final faceState = ref.watch(faceRecognitionViewModelProvider);
final faceViewModel = ref.read(faceRecognitionViewModelProvider.notifier);

// Open camera
await faceViewModel.openCamera();
```

### Auth Mode Enum

```dart
enum AuthMode { 
  login,           // Email/password authentication
  faceRecognition  // Face recognition authentication
}
```

### Dependencies

- `flutter_riverpod: ^2.4.0` - Reactive state management for Flutter
- `riverpod: ^2.4.0` - Core Riverpod library


