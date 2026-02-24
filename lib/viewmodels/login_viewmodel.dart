import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

class LoginState {
  final String email;
  final String password;
  final bool obscurePassword;
  final bool isLoading;
  final String? errorMessage;
  final bool isLoggedIn;
  final bool isLoginSuccessful;
  final String? token;
  final String? userId;
  final String? userName;
  final String? userRole;

  LoginState({
    this.email = '',
    this.password = '',
    this.obscurePassword = true,
    this.isLoading = false,
    this.errorMessage,
    this.isLoggedIn = false,
    this.isLoginSuccessful = false,
    this.token,
    this.userId,
    this.userName,
    this.userRole,
  });

  LoginState copyWith({
    String? email,
    String? password,
    bool? obscurePassword,
    bool? isLoading,
    String? errorMessage,
    bool? isLoggedIn,
    bool? isLoginSuccessful,
    String? token,
    String? userId,
    String? userName,
    String? userRole,
  }) {
    return LoginState(
      email: email ?? this.email,
      password: password ?? this.password,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isLoginSuccessful: isLoginSuccessful ?? this.isLoginSuccessful,
      token: token ?? this.token,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userRole: userRole ?? this.userRole,
    );
  }
}

class LoginViewModel extends StateNotifier<LoginState> {
  LoginViewModel(this._api) : super(LoginState());

  final ApiService _api;

  void setEmail(String email) {
    state = state.copyWith(email: email, errorMessage: null);
  }

  void setPassword(String password) {
    state = state.copyWith(password: password, errorMessage: null);
  }

  void togglePasswordVisibility() {
    state = state.copyWith(obscurePassword: !state.obscurePassword);
  }

  Future<void> signIn() async {
    // Validate inputs
    if (state.email.isEmpty || state.password.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Please enter both email and password',
      );
      return;
    }

    // Simple email validation
    if (!state.email.contains('@')) {
      state = state.copyWith(
        errorMessage: 'Please enter a valid email',
      );
      return;
    }

    state = state.copyWith(isLoading: true);

    try {
      final response = await _api.login(
        email: state.email,
        password: state.password,
      );

      final token = response['token']?.toString();
      final user = response['user'] as Map<String, dynamic>?;

      if (token != null && user != null) {
        _api.setToken(token);

        // Extract user data from response
        final userId = user['id']?.toString();
        final userName = user['fullName']?.toString() ?? user['full_name']?.toString();
        final userRole = user['role']?.toString();

        state = state.copyWith(
          isLoading: false,
          isLoggedIn: true,
          isLoginSuccessful: true,
          token: token,
          userId: userId,
          userName: userName,
          userRole: userRole,
          errorMessage: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Invalid response from server',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  void resetLoginSuccess() {
    state = state.copyWith(isLoginSuccessful: false);
  }

  void logout() {
    _api.setToken(null);
    state = LoginState();
  }
}

final loginViewModelProvider =
    StateNotifierProvider<LoginViewModel, LoginState>((ref) {
  return LoginViewModel(ref.read(apiServiceProvider));
});
