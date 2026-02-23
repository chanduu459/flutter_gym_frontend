# GymSaaS Pro - Feature Diagram

## Current Implementation Structure

```
┌─────────────────────────────────────────────────────────────┐
│                      main.dart                               │
│            (ProviderScope wrapper)                           │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
        ┌──────────────────────────────────┐
        │  AuthContainerScreen             │
        │  (ConsumerWidget)                │
        └──────────────────┬───────────────┘
                           │
        ┌──────────────────┴───────────────┐
        │                                  │
        ▼                                  ▼
   ┌─────────────────┐             ┌──────────────────┐
   │ Login Tab       │             │ Face Recognition │
   │ (Button)        │             │ Tab (Button)     │
   └────────┬────────┘             └────────┬─────────┘
            │                               │
            │ authViewModel.setLoginMode()  │ authViewModel.setFaceRecognitionMode()
            │                               │
        ┌───┴───────────────────────────────┴───┐
        │    authViewModelProvider (Riverpod)   │
        │    AuthState:                         │
        │    - currentMode: AuthMode            │
        └───────────────┬───────────────────────┘
                        │
        ┌───────────────┴───────────────┐
        │                               │
        ▼                               ▼
┌──────────────────────┐        ┌──────────────────────────┐
│ LoginScreenContent   │        │ FaceRecognitionScreen    │
│ (ConsumerWidget)     │        │ Content                  │
│                      │        │ (ConsumerWidget)         │
│ Features:            │        │                          │
│ - Email input        │        │ Features:                │
│ - Password input     │        │ - Open Camera button     │
│ - Toggle visibility  │        │ - Camera state           │
│ - Sign In button     │        │ - Recognition process   │
│ - Error display      │        │ - Success state          │
│ - Loading state      │        │ - Scan Again button      │
└──────────────┬───────┘        └──────────────┬───────────┘
               │                               │
               ▼                               ▼
    loginViewModelProvider         faceRecognitionViewModelProvider
    (Riverpod Provider)            (Riverpod Provider)
    │                              │
    ├─ LoginViewModel              ├─ FaceRecognitionViewModel
    │  Methods:                     │  Methods:
    │  - setEmail()                 │  - openCamera()
    │  - setPassword()              │  - startFaceRecognition()
    │  - togglePasswordVisibility() │  - resetCamera()
    │  - signIn()                   │  - closeCamera()
    │  - clearError()               │  - clearError()
    │                               │
    └─ LoginState                   └─ FaceRecognitionState
       Properties:                     Properties:
       - email: String                 - isLoading: bool
       - password: String              - isCameraOpen: bool
       - obscurePassword: bool         - errorMessage: String?
       - isLoading: bool               - isRecognized: bool
       - errorMessage: String?         - recognizedUser: String?
       - isLoggedIn: bool
```

## Tab Navigation Flow

```
┌─────────────────────────────────────────────────────────┐
│ User sees AuthContainerScreen                           │
│ - Logo and Title                                        │
│ - Two Tab Buttons (Login | Face Recognition)           │
│ - Currently on Login Tab (shown with black background) │
└────────────────────┬────────────────────────────────────┘
                     │
                     ▼
         User clicks Face Recognition Button
                     │
                     ▼
    authViewModel.setFaceRecognitionMode() called
                     │
                     ▼
    authViewModelProvider state updated:
    AuthState(currentMode: AuthMode.faceRecognition)
                     │
                     ▼
    All listeners notified (Riverpod magic ✨)
                     │
                     ▼
    AuthContainerScreen rebuilds
    AuthState.currentMode == AuthMode.faceRecognition
                     │
                     ▼
    Conditional rendering:
    if (authState.currentMode == AuthMode.faceRecognition)
        → Display FaceRecognitionScreenContent
    else
        → Display LoginScreenContent
                     │
                     ▼
    ┌──────────────────────────────────────────────┐
    │ FaceRecognitionScreenContent now visible:   │
    │ - Title: "Face Recognition"                 │
    │ - Description text                          │
    │ - Camera placeholder icon                   │
    │ - "Open Camera" button (active)             │
    │ - Face Recognition Tab highlighted (black)  │
    └──────────────────────────────────────────────┘
```

## Face Recognition Process Flow

```
User clicks "Open Camera" Button
        │
        ▼
FaceRecognitionScreenContent calls:
faceViewModel.openCamera()
        │
        ▼
FaceRecognitionViewModel.openCamera():
1. Set state: isLoading = true
2. Simulate delay (500ms)
3. Set state: isLoading = false, isCameraOpen = true
        │
        ▼
faceRecognitionViewModelProvider notifies listeners
        │
        ▼
UI Rebuilds:
- Camera icon → Black screen with videocam icon
- "Open Camera" button → "Start Recognition" button
- Loading spinner shown during delay
        │
        ▼
User clicks "Start Recognition" Button
        │
        ▼
FaceRecognitionScreenContent calls:
faceViewModel.startFaceRecognition()
        │
        ▼
FaceRecognitionViewModel.startFaceRecognition():
1. Set state: isLoading = true
2. Simulate recognition (3 seconds)
3. Set state: isLoading = false, isRecognized = true
4. Set recognized user name
        │
        ▼
UI Rebuilds:
- Shows success state with:
  ✓ Green checkmark icon
  ✓ "Welcome, Owner!" message
  ✓ "Face recognized successfully" subtitle
  ✓ "Scan Again" button (instead of "Start Recognition")
```

## State Immutability Pattern

```
OLD STATE
┌──────────────────────────────────────────┐
│ LoginState(                              │
│   email: 'john@example.com',             │
│   password: '***',                       │
│   obscurePassword: true,                 │
│   isLoading: false,                      │
│   errorMessage: null,                    │
│   isLoggedIn: false                      │
│ )                                        │
└──────────────────────────────────────────┘

User types new email: 'jane@example.com'
        │
        ▼
loginViewModel.setEmail('jane@example.com')
        │
        ▼
state.copyWith(email: 'jane@example.com')
        │
        ▼
NEW STATE (new instance created)
┌──────────────────────────────────────────┐
│ LoginState(                              │
│   email: 'jane@example.com',  ← CHANGED  │
│   password: '***',                       │
│   obscurePassword: true,                 │
│   isLoading: false,                      │
│   errorMessage: null,                    │
│   isLoggedIn: false                      │
│ )                                        │
└──────────────────────────────────────────┘

Riverpod detects state change → Rebuilds widgets
```

## Demo Credentials

```
Email: owner@demo.com
Password: password123

These credentials unlock the login form and allow:
- Email/Password authentication
- Face recognition simulation (3-second process)
```

