import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AuthMode { login, faceRecognition }

class AuthState {
  final AuthMode currentMode;

  AuthState({this.currentMode = AuthMode.login});

  AuthState copyWith({AuthMode? currentMode}) {
    return AuthState(currentMode: currentMode ?? this.currentMode);
  }
}

class AuthViewModel extends StateNotifier<AuthState> {
  AuthViewModel() : super(AuthState());

  void switchMode(AuthMode mode) {
    state = state.copyWith(currentMode: mode);
  }

  void setLoginMode() {
    state = state.copyWith(currentMode: AuthMode.login);
  }

  void setFaceRecognitionMode() {
    state = state.copyWith(currentMode: AuthMode.faceRecognition);
  }
}

final authViewModelProvider = StateNotifierProvider<AuthViewModel, AuthState>((ref) {
  return AuthViewModel();
});

