import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import '../viewmodels/face_recognition_viewmodel.dart';

class FaceRecognitionScreenContent extends ConsumerStatefulWidget {
  const FaceRecognitionScreenContent({super.key});

  @override
  ConsumerState<FaceRecognitionScreenContent> createState() =>
      _FaceRecognitionScreenContentState();
}

class _FaceRecognitionScreenContentState
    extends ConsumerState<FaceRecognitionScreenContent> {
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
  }

  void _startAutoRefreshTimer() {
    // Cancel any existing timer
    _autoRefreshTimer?.cancel();

    // Start a new timer that auto-resets after 10 seconds if face was recognized
    _autoRefreshTimer = Timer(const Duration(seconds: 10), () {
      final faceState = ref.read(faceRecognitionViewModelProvider);

      // Auto-refresh if a face was recognized
      if (faceState.isRecognized && mounted) {
        final viewModel = ref.read(faceRecognitionViewModelProvider.notifier);
        viewModel.resetCamera();
      }
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    final viewModel = ref.read(faceRecognitionViewModelProvider.notifier);
    viewModel.closeCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final faceState = ref.watch(faceRecognitionViewModelProvider);
    final faceViewModel = ref.read(faceRecognitionViewModelProvider.notifier);

    // Start auto-refresh timer when face is recognized
    if (faceState.isRecognized && _autoRefreshTimer == null) {
      _startAutoRefreshTimer();
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Face Recognition',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Identify yourself with face recognition',
              style: TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Error message display
            if (faceState.errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[400]!),
                ),
                child: Text(
                  faceState.errorMessage!,
                  style: TextStyle(color: Colors.red[700], fontSize: 12),
                ),
              ),
            if (faceState.errorMessage != null) const SizedBox(height: 16),
            // Camera preview area
            _buildCameraPreview(faceState, faceViewModel),
            const SizedBox(height: 24),
            // Buttons
            _buildActionButtons(faceState, faceViewModel),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview(
      FaceRecognitionState faceState, FaceRecognitionViewModel faceViewModel) {
    if (!faceState.isCameraOpen && !faceState.isRecognized) {
      // Camera not open - show placeholder
      return Container(
        width: double.infinity,
        height: 350,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[400]!),
        ),
        child: const Center(
          child: Icon(Icons.camera_alt, size: 100, color: Colors.grey),
        ),
      );
    }

    if (faceState.isCameraOpen && !faceState.isRecognized) {
      // Camera open - show live preview with FutureBuilder
      final cameraService = faceViewModel.getCameraService();
      final controller = cameraService.getController();

      return Container(
        width: double.infinity,
        height: 350,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[400]!),
          color: Colors.black,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: controller != null && controller.value.isInitialized
              ? FutureBuilder<void>(
                  future: Future.delayed(const Duration(milliseconds: 100)),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          CameraPreview(controller),
                          // Add focus indicator
                          Center(
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white24,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  },
                )
              : const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
        ),
      );
    }

    // Success state
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[400]!),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Icon(Icons.check_circle, size: 80, color: Colors.green[600]),
            const SizedBox(height: 16),
            Text(
              'Welcome, ${faceState.recognizedUser}!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              faceState.successMessage ?? 'Face recognized successfully',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            if (faceState.confidence != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Confidence: ${(faceState.confidence! * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.green[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            // Subscription Details Section
            if (faceState.subscriptionDetails != null) ...[
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Subscription Details',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSubscriptionRow(
                      'Plan:',
                      faceState.subscriptionDetails!['plan_name']?.toString() ?? 'N/A',
                    ),
                    const SizedBox(height: 8),
                    _buildSubscriptionRow(
                      'Status:',
                      faceState.subscriptionDetails!['status']?.toString() ?? 'Active',
                      statusColor: faceState.subscriptionDetails!['status']?.toString() == 'Active'
                          ? Colors.green
                          : Colors.red,
                    ),
                    const SizedBox(height: 8),
                    if (faceState.subscriptionDetails!['expiry_date'] != null)
                      _buildSubscriptionRow(
                        'Valid Until:',
                        faceState.subscriptionDetails!['expiry_date']?.toString() ?? 'N/A',
                      ),
                    const SizedBox(height: 8),
                    if (faceState.subscriptionDetails!['days_remaining'] != null)
                      _buildSubscriptionRow(
                        'Days Remaining:',
                        '${faceState.subscriptionDetails!['days_remaining']} days',
                        valueColor: Colors.orange[700],
                      ),
                  ],
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionRow(String label, String value, {Color? statusColor, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: statusColor ?? valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(
      FaceRecognitionState faceState, FaceRecognitionViewModel faceViewModel) {
    // Open Camera button
    if (!faceState.isCameraOpen && !faceState.isRecognized) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: faceState.isLoading
              ? null
              : () => faceViewModel.openCamera(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
            disabledBackgroundColor: Colors.grey[400],
          ),
          child: const Text(
            '📷 Open Camera',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      );
    }

    // Start Recognition button and Stop Camera button (side by side)
    if (faceState.isCameraOpen && !faceState.isRecognized) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: faceState.isLoading
                  ? null
                  : () => faceViewModel.startFaceRecognition(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                disabledBackgroundColor: Colors.grey[400],
              ),
              child: faceState.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Start Recognition',
                      style: TextStyle(
                          color: Colors.white, fontSize: 16),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () => faceViewModel.stopCamera(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              padding: const EdgeInsets.symmetric(
                vertical: 14,
                horizontal: 20,
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              'Stop',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      );
    }

    // Reset button (shown after successful recognition)
    if (faceState.isRecognized) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => faceViewModel.resetCamera(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text(
            'Scan Again',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}


