import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'dart:convert';
import 'dart:io';
import '../services/camera_service.dart';
import '../services/api_service.dart';

class FaceRecognitionState {
  final bool isLoading;
  final bool isCameraOpen;
  final String? errorMessage;
  final bool isRecognized;
  final String? recognizedUser;
  final double? confidence;
  final String? successMessage;
  final Map<String, dynamic>? subscriptionDetails;

  FaceRecognitionState({
    this.isLoading = false,
    this.isCameraOpen = false,
    this.errorMessage,
    this.isRecognized = false,
    this.recognizedUser,
    this.confidence,
    this.successMessage,
    this.subscriptionDetails,
  });

  FaceRecognitionState copyWith({
    bool? isLoading,
    bool? isCameraOpen,
    String? errorMessage,
    bool? isRecognized,
    String? recognizedUser,
    double? confidence,
    String? successMessage,
    Map<String, dynamic>? subscriptionDetails,
  }) {
    return FaceRecognitionState(
      isLoading: isLoading ?? this.isLoading,
      isCameraOpen: isCameraOpen ?? this.isCameraOpen,
      errorMessage: errorMessage ?? this.errorMessage,
      isRecognized: isRecognized ?? this.isRecognized,
      recognizedUser: recognizedUser ?? this.recognizedUser,
      confidence: confidence ?? this.confidence,
      successMessage: successMessage ?? this.successMessage,
      subscriptionDetails: subscriptionDetails ?? this.subscriptionDetails,
    );
  }
}

class FaceRecognitionViewModel extends StateNotifier<FaceRecognitionState> {
  final CameraService _cameraService = CameraService();
  final ApiService _apiService;

  FaceRecognitionViewModel(this._apiService) : super(FaceRecognitionState());

  /// Compress image to reduce payload size
  Future<List<int>> _compressImage(File imageFile) async {
    final imageBytes = await imageFile.readAsBytes();
    final image = img.decodeImage(imageBytes);

    if (image == null) {
      throw Exception('Failed to decode image');
    }

    // Resize image to 640x480 for face recognition (good balance)
    final resized = img.copyResize(image,
        width: 640,
        height: 480,
        interpolation: img.Interpolation.linear);

    // Encode as JPEG with 85% quality
    final compressed = img.encodeJpg(resized, quality: 85);
    return compressed;
  }

  Future<void> openCamera() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _cameraService.openCamera();
      await Future.delayed(const Duration(milliseconds: 300));

      state = state.copyWith(
        isLoading: false,
        isCameraOpen: true,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isCameraOpen: false,
        errorMessage: 'Failed to open camera: ${e.toString()}',
      );
    }
  }

  Future<void> startFaceRecognition() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final cameraService = getCameraService();
      final controller = cameraService.getController();

      if (controller == null || !controller.value.isInitialized) {
        throw Exception('Camera not initialized');
      }

      // Capture image from camera
      final imageFile = await controller.takePicture();

      // Compress image to reduce payload size (typically reduces by 80-90%)
      final compressedBytes = await _compressImage(File(imageFile.path));
      final imageBase64 = base64Encode(compressedBytes);

      // Send to backend for AWS Rekognition verification
      final response = await _apiService.identifyFace(imageBase64);

      // Check if face was recognized
      final recognized = response['recognized'] as bool? ?? false;

      if (recognized) {
        final member = response['member'] as Map<String, dynamic>?;
        final memberName = member?['full_name']?.toString() ?? 'Member';
        final confidence = response['confidence'] as double? ?? 0.0;
        final subscription = response['subscription'] as Map<String, dynamic>?;

        state = state.copyWith(
          isLoading: false,
          isRecognized: true,
          recognizedUser: memberName,
          confidence: confidence,
          subscriptionDetails: subscription,
          successMessage: 'Face matched successfully!\nWelcome, $memberName!',
          errorMessage: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Face not found in database. Please register first.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Recognition failed: ${e.toString()}',
      );
    }
  }

  void stopCamera() {
    _cameraService.closeCamera();
    state = state.copyWith(isCameraOpen: false);
  }

  void resetCamera() {
    _cameraService.closeCamera();
    state = FaceRecognitionState();
  }

  void closeCamera() {
    _cameraService.closeCamera();
    state = state.copyWith(isCameraOpen: false);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  CameraService getCameraService() => _cameraService;
}

final faceRecognitionViewModelProvider =
    StateNotifierProvider<FaceRecognitionViewModel, FaceRecognitionState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return FaceRecognitionViewModel(apiService);
});

