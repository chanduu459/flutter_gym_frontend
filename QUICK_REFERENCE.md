# GymSaaS Pro - Quick Reference Guide

## Project Overview
A Flutter gym management system with MVVM architecture and Riverpod state management. Features tab-based authentication with Login and Face Recognition modes.

## File Directory Structure
```
lib/
├── main.dart
├── screens/
│   ├── auth_container_screen.dart    ← Main container with tabs
│   ├── login_screen.dart             ← Login form content
│   └── face_recognition_screen.dart  ← Face recognition content
└── viewmodels/
    ├── auth_viewmodel.dart           ← Tab management
    ├── login_viewmodel.dart          ← Login logic
    └── face_recognition_viewmodel.dart ← Camera/recognition logic
```

## How to Use Each Screen

### AuthContainerScreen (Entry Point)
```dart
// Starting point - displays tabs and switches between modes
AuthContainerScreen()
  ├─ Header (Logo, Title)
  ├─ Navigation Tabs
  │  ├─ Login (black when active)
  │  └─ Face Recognition (black when active)
  └─ Content Area
     ├─ LoginScreenContent (when Login tab active)
     └─ FaceRecognitionScreenContent (when Face Recognition tab active)
```

### LoginScreenContent
```dart
// Login form - visible when "Login" tab is active
Features:
- Email input field
- Password input field
- Show/hide password toggle
- Sign In button
- Error message display
- Loading spinner
- Register link

Demo Credentials:
email: owner@demo.com
password: password123
```

### FaceRecognitionScreenContent
```dart
// Face recognition interface - visible when "Face Recognition" tab active
States:
1. Initial: Camera icon placeholder + "Open Camera" button
2. Camera Open: Black screen + "Start Recognition" button
3. Recognizing: Spinner animation
4. Recognized: Success message + "Scan Again" button

Demo Behavior:
- Opens camera instantly (500ms simulation)
- Recognition takes 3 seconds
- Shows success message with user name
```

## ViewModel Methods Quick Reference

### AuthViewModel
```dart
// Switch authentication mode
authViewModel.setLoginMode();                    // Show login form
authViewModel.setFaceRecognitionMode();         // Show face recognition
authViewModel.switchMode(AuthMode.login);       // Generic switch
```

### LoginViewModel
```dart
// Update form fields
loginViewModel.setEmail('user@example.com');
loginViewModel.setPassword('password123');

// Toggle password visibility
loginViewModel.togglePasswordVisibility();

// Submit form
await loginViewModel.signIn();

// Clear errors
loginViewModel.clearError();
```

### FaceRecognitionViewModel
```dart
// Control camera
await faceViewModel.openCamera();               // Activate camera
faceViewModel.closeCamera();                    // Deactivate camera

// Recognition process
await faceViewModel.startFaceRecognition();    // Start 3-sec process

// Reset state
faceViewModel.resetCamera();                    // Reset to initial state

// Clear errors
faceViewModel.clearError();
```

## State Classes Overview

### AuthState
```dart
AuthState {
  currentMode: AuthMode    // login or faceRecognition
}
```

### LoginState
```dart
LoginState {
  email: String           // User's email input
  password: String        // User's password input
  obscurePassword: bool   // Whether password is hidden
  isLoading: bool         // Loading during sign in
  errorMessage: String?   // Error to display
  isLoggedIn: bool        // Success flag
}
```

### FaceRecognitionState
```dart
FaceRecognitionState {
  isLoading: bool         // Loading during operations
  isCameraOpen: bool      // Camera is open
  errorMessage: String?   // Error to display
  isRecognized: bool      // Recognition successful
  recognizedUser: String? // Name of recognized user
}
```

## Using Riverpod in Widgets

### Watch State (Read-Only Access)
```dart
final state = ref.watch(loginViewModelProvider);
// Use in build method to rebuild when state changes
Text(state.email)
```

### Read ViewModel (Call Methods)
```dart
final viewModel = ref.read(loginViewModelProvider.notifier);
// Call methods to update state
viewModel.setEmail('new@email.com');
```

### Combined Pattern
```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  // Watch state for rebuilds
  final state = ref.watch(loginViewModelProvider);
  
  // Read notifier for method calls
  final viewModel = ref.read(loginViewModelProvider.notifier);
  
  return TextField(
    onChanged: (value) => viewModel.setEmail(value),
    decoration: InputDecoration(
      hintText: 'Email',
      errorText: state.errorMessage,
    ),
  );
}
```

## Navigation Flow

### Switching Tabs
```
User clicks "Face Recognition" button
    ↓
authViewModel.setFaceRecognitionMode()
    ↓
authViewModelProvider state updates
    ↓
All watching widgets rebuild
    ↓
AuthContainerScreen shows FaceRecognitionScreenContent
```

### State Updates
```
User types in email field
    ↓
TextField.onChanged() callback
    ↓
loginViewModel.setEmail(value)
    ↓
loginViewModelProvider state updates
    ↓
LoginScreenContent rebuilds with new email
```

## Key Concepts

### Immutability
All state changes use `.copyWith()` to create new instances:
```dart
// Old way (mutable) ❌
state.email = 'new@email.com';

// New way (immutable) ✅
state = state.copyWith(email: 'new@email.com');
```

### Reactive Updates
Riverpod automatically notifies all listeners when state changes:
```dart
// State changes → listeners notified → widgets rebuild
// No manual setState() needed!
```

### Separation of Concerns
- **View**: Only handles UI presentation
- **ViewModel**: Only handles business logic
- **Model**: Only holds immutable state
- **Provider**: Manages instance lifecycle

## Common Patterns

### Form Submission
```dart
ElevatedButton(
  onPressed: () async {
    // Disable button while loading
    onPressed: state.isLoading ? null : () => viewModel.signIn(),
  },
  child: state.isLoading 
    ? CircularProgressIndicator()
    : Text('Sign In'),
)
```

### Error Display
```dart
if (state.errorMessage != null)
  Container(
    color: Colors.red[100],
    child: Text(state.errorMessage!),
  )
```

### Conditional Rendering
```dart
if (authState.currentMode == AuthMode.login)
  LoginScreenContent()
else
  FaceRecognitionScreenContent()
```

## Testing

### Test Login Flow
1. Click "Login" tab (should be active)
2. Enter: owner@demo.com
3. Enter: password123
4. Click "Sign in"
5. Should show success (loading, then validation passes)

### Test Face Recognition Flow
1. Click "Face Recognition" tab
2. Click "Open Camera" button
3. Camera state shows (black screen)
4. Click "Start Recognition"
5. Wait 3 seconds for simulation
6. Should show success message
7. Click "Scan Again" to reset

### Test Error Handling
1. Try to sign in with empty fields
2. Should show: "Please enter both email and password"
3. Try invalid email format
4. Should show: "Please enter a valid email"
5. Try wrong credentials
6. Should show: "Invalid email or password"

## Useful Resources

- Riverpod Documentation: https://riverpod.dev
- Flutter Widgets: https://flutter.dev/docs/development/ui/widgets
- MVVM Pattern: https://en.wikipedia.org/wiki/Model%E2%80%93view%E2%80%93viewmodel

