import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraService {
  static final CameraService _instance = CameraService._internal();

  factory CameraService() {
    return _instance;
  }

  CameraService._internal();

  CameraController? _controller;
  List<CameraDescription>? _cameras;

  Future<void> initializeCameras() async {
    if (_cameras != null) return;
    try {
      _cameras = await availableCameras();
    } catch (e) {
      debugPrint('Error initializing cameras: $e');
      rethrow;
    }
  }

  Future<void> openCamera({CameraLensDirection direction = CameraLensDirection.front}) async {
    try {
      await initializeCameras();

      if (_cameras == null || _cameras!.isEmpty) {
        throw Exception('No cameras available on this device');
      }

      // Find camera by lens direction
      CameraDescription? selectedCamera;
      for (var camera in _cameras!) {
        if (camera.lensDirection == direction) {
          selectedCamera = camera;
          break;
        }
      }

      // Fallback to first camera if not found
      selectedCamera ??= _cameras!.first;

      debugPrint('Opening camera: ${selectedCamera.name}');

      // Close previous controller if exists
      await _controller?.dispose();
      _controller = null;

      _controller = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      debugPrint('Initializing camera controller...');
      await _controller!.initialize();

      debugPrint('Camera initialized successfully');
    } catch (e) {
      debugPrint('Error opening camera: $e');
      _controller = null;
      rethrow;
    }
  }

  Future<void> closeCamera() async {
    try {
      await _controller?.dispose();
      _controller = null;
    } catch (e) {
      debugPrint('Error closing camera: $e');
    }
  }

  CameraController? getController() {
    return _controller;
  }

  bool isCameraInitialized() {
    return _controller != null && _controller!.value.isInitialized;
  }

  Future<String?> takePicture(String path) async {
    try {
      if (!isCameraInitialized()) {
        throw Exception('Camera not initialized');
      }
      final image = await _controller!.takePicture();
      return image.path;
    } catch (e) {
      debugPrint('Error taking picture: $e');
      rethrow;
    }
  }
}


