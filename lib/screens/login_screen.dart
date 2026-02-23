import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/login_viewmodel.dart';

class LoginScreenContent extends ConsumerWidget {
  const LoginScreenContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loginState = ref.watch(loginViewModelProvider);
    final loginViewModel = ref.read(loginViewModelProvider.notifier);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome back',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter your credentials to access your account',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Error message display
            if (loginState.errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[400]!),
                ),
                child: Text(
                  loginState.errorMessage!,
                  style: TextStyle(color: Colors.red[700], fontSize: 12),
                ),
              ),
            if (loginState.errorMessage != null) const SizedBox(height: 16),
            // Email field
            const Text('Email', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              enabled: !loginState.isLoading,
              onChanged: (value) => loginViewModel.setEmail(value),
              decoration: InputDecoration(
                hintText: 'name@example.com',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 20),
            // Password field
            const Text('Password', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              enabled: !loginState.isLoading,
              onChanged: (value) => loginViewModel.setPassword(value),
              obscureText: loginState.obscurePassword,
              decoration: InputDecoration(
                hintText: '••••••••',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                suffixIcon: IconButton(
                  icon: Icon(loginState.obscurePassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => loginViewModel.togglePasswordVisibility(),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Sign In button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loginState.isLoading ? null : () => loginViewModel.signIn(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  disabledBackgroundColor: Colors.grey[400],
                ),
                child: loginState.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Sign in', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 16),
            // Register link
            Center(
              child: RichText(
                text: TextSpan(
                  text: "Don't have an account? ",
                  style: const TextStyle(color: Colors.grey),
                  children: [
                    TextSpan(
                      text: 'Register your gym',
                      style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

