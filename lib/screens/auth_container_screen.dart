import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/login_viewmodel.dart';
import 'login_screen.dart';
import 'face_recognition_screen.dart';

class AuthContainerScreen extends ConsumerWidget {
  const AuthContainerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authViewModelProvider);
    final authViewModel = ref.read(authViewModelProvider.notifier);
    final loginState = ref.watch(loginViewModelProvider);
    final loginViewModel = ref.read(loginViewModelProvider.notifier);

    // Navigate to dashboard if login successful
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (loginState.isLoginSuccessful) {
        loginViewModel.resetLoginSuccess();
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
    });

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              // Logo and Title
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.fitness_center, color: Colors.white, size: 30),
              ),
              const SizedBox(height: 12),
              const Text(
                'GymSaaS Pro',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Text(
                'Gym Management System',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              // Tab buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => authViewModel.setLoginMode(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            authState.currentMode == AuthMode.login
                                ? Colors.black
                                : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        side: authState.currentMode != AuthMode.login
                            ? BorderSide(color: Colors.grey[300]!)
                            : BorderSide.none,
                      ),
                      child: Text(
                        'Login',
                        style: TextStyle(
                          color: authState.currentMode == AuthMode.login
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => authViewModel.setFaceRecognitionMode(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            authState.currentMode == AuthMode.faceRecognition
                                ? Colors.black
                                : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        side: authState.currentMode != AuthMode.faceRecognition
                            ? BorderSide(color: Colors.grey[300]!)
                            : BorderSide.none,
                      ),
                      child: Text(
                        'Face Recognition',
                        style: TextStyle(
                          color: authState.currentMode == AuthMode.faceRecognition
                              ? Colors.white
                              : Colors.black,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              // Show appropriate screen based on auth mode
              if (authState.currentMode == AuthMode.login)
                const LoginScreenContent()
              else
                const FaceRecognitionScreenContent(),
              const SizedBox(height: 20),
              // Demo credentials
              const Text(
                'Demo credentials: owner@demo.com / password123',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

