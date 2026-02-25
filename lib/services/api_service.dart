import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class ApiService {
  ApiService({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _baseUrl = baseUrl ??
            const String.fromEnvironment(
              'API_URL',
              defaultValue: 'http://10.169.60.90:3001',
            );

  final http.Client _client;
  final String _baseUrl;
  String? _token;

  void setToken(String? token) {
    _token = token;
  }

  Future<dynamic> _request(
    String endpoint, {
    String method = 'GET',
    Map<String, String>? headers,
    Object? body,
  }) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    final requestHeaders = <String, String>{
      ...?headers,
    };
    if (_token != null) {
      requestHeaders['Authorization'] = 'Bearer $_token';
    }

    http.Response response;
    if (method == 'GET') {
      response = await _client.get(uri, headers: requestHeaders);
    } else if (method == 'POST') {
      response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          ...requestHeaders,
        },
        body: body,
      );
    } else if (method == 'PUT') {
      response = await _client.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          ...requestHeaders,
        },
        body: body,
      );
    } else {
      response = await _client.delete(uri, headers: requestHeaders);
    }

    if (response.body.isEmpty) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return null;
      }
      throw ApiException('API request failed');
    }

    // Check if response is HTML (error page) instead of JSON
    if (response.body.trim().startsWith('<')) {
      throw ApiException(
        'Server error: ${response.statusCode}. Please check your backend API.'
      );
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (e) {
      throw ApiException('Invalid response from server: ${e.toString()}');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = _extractErrorMessage(decoded) ?? 'API request failed';
      throw ApiException(message);
    }

    final result = _unwrapData(decoded);
    return result;
  }

  Future<dynamic> _multipart(
    String endpoint, {
    required Map<String, String> fields,
    File? file,
    String? fileFieldName,
    String method = 'POST',
  }) async {
    print('🌐 Multipart request to: $_baseUrl$endpoint (Method: $method)');
    print('📋 Fields: $fields');

    final uri = Uri.parse('$_baseUrl$endpoint');
    final request = http.MultipartRequest(method, uri);

    // Add all fields
    request.fields.addAll(fields);

    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
      print('🔑 Token added to request');
    }

    // Add file if provided
    if (file != null && fileFieldName != null && file.existsSync()) {
      try {
        print('📎 Adding file: $fileFieldName');
        print('📁 File path: ${file.path}');
        print('📏 File size: ${file.lengthSync()} bytes');

        // Determine MIME type from file extension or path
        String mimeType = 'image/jpeg'; // Default to JPEG
        final filePath = file.path.toLowerCase();

        if (filePath.endsWith('.png')) {
          mimeType = 'image/png';
        } else if (filePath.endsWith('.jpg') || filePath.endsWith('.jpeg')) {
          mimeType = 'image/jpeg';
        } else if (filePath.contains('jpg') || filePath.contains('jpeg')) {
          // Handle cases like "scaled_xxx.jpg" or "camera-capture-xxx.jpg"
          mimeType = 'image/jpeg';
        } else if (filePath.contains('png')) {
          mimeType = 'image/png';
        } else {
          // If extension not clear, check file signature (magic bytes)
          // Read first few bytes to detect file type
          final bytes = file.readAsBytesSync();
          if (bytes.length >= 4) {
            // PNG signature: 89 50 4E 47
            if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) {
              mimeType = 'image/png';
            }
            // JPEG signature: FF D8 FF
            else if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) {
              mimeType = 'image/jpeg';
            }
          }
        }

        print('📝 Detected MIME type: $mimeType');
        print('📝 File name: ${file.path.split('/').last}');

        // Add file with explicit MIME type
        final multipartFile = await http.MultipartFile.fromPath(
          fileFieldName,
          file.path,
          contentType: MediaType.parse(mimeType),
        );

        request.files.add(multipartFile);

        print('✅ File added to request with MIME type: $mimeType');
      } catch (e) {
        print('🔴 Failed to add file: ${e.toString()}');
        throw ApiException('Failed to add file to request: ${e.toString()}');
      }
    }

    http.StreamedResponse streamed;
    try {
      print('📤 Sending multipart request...');
      streamed = await request.send();
      print('📥 Response received - Status: ${streamed.statusCode}');
    } catch (e) {
      print('🔴 Failed to send request: ${e.toString()}');
      throw ApiException('Failed to send request: ${e.toString()}');
    }

    final response = await http.Response.fromStream(streamed);
    print('📄 Response body length: ${response.body.length}');

    if (response.body.isEmpty) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('✅ Empty response with success status');
        return null;
      }
      print('🔴 Empty response with error status: ${response.statusCode}');
      throw ApiException('API request failed: empty response');
    }

    // Check if response is HTML (error page) instead of JSON
    if (response.body.trim().startsWith('<')) {
      print('🔴 Server returned HTML instead of JSON');
      final previewLength = response.body.length > 200 ? 200 : response.body.length;
      print('📄 Response preview: ${response.body.substring(0, previewLength)}...');
      throw ApiException(
        'Server error: ${response.statusCode}. Please check your backend API.'
      );
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
      print('✅ JSON decoded successfully');
    } catch (e) {
      print('🔴 Failed to decode JSON: ${e.toString()}');
      print('📄 Response body: ${response.body}');
      throw ApiException('Invalid response from server: ${e.toString()}');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = _extractErrorMessage(decoded) ?? 'API request failed';
      print('🔴 Error response: $message');
      throw ApiException('$message (Status: ${response.statusCode})');
    }

    print('✅ Multipart request successful');
    return _unwrapData(decoded);
  }

  String? _extractErrorMessage(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      return decoded['error']?.toString() ??
             decoded['message']?.toString() ??
             decoded['errors']?.toString();
    }
    return null;
  }

  dynamic _unwrapData(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      if (decoded.containsKey('data')) return decoded['data'];
      if (decoded.containsKey('result')) return decoded['result'];
    }
    return decoded;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final data = await _request(
      '/api/auth/login',
      method: 'POST',
      body: jsonEncode({'email': email, 'password': password}),
    );
    return (data as Map).cast<String, dynamic>();
  }

  Future<List<dynamic>> getMembers() async {
    final data = await _request('/api/members');
    return (data as List).cast<dynamic>();
  }

  Future<Map<String, dynamic>> createMember({
    required String fullName,
    required String email,
    required String phone,
    String? password,
    File? faceImage,
  }) async {
    try {
      print('🔵 Creating member: $fullName');
      print('📧 Email: $email');
      print('📞 Phone: $phone');
      print('📸 Has image: ${faceImage != null}');

      // If we have a file, use multipart form data
      if (faceImage != null && faceImage.existsSync()) {
        print('📤 Using multipart upload for image');
        print('📁 Image path: ${faceImage.path}');
        print('📏 Image size: ${faceImage.lengthSync()} bytes');

        final fields = <String, String>{
          'fullName': fullName,
          'email': email,
          'phone': phone,
        };

        if (password != null && password.isNotEmpty) {
          fields['password'] = password;
        }

        final data = await _multipart(
          '/api/members',
          fields: fields,
          file: faceImage,
          fileFieldName: 'faceImage',
        );

        print('✅ Multipart response received');
        print('📦 Response type: ${data.runtimeType}');
        print('📦 Response data: $data');

        if (data == null) {
          print('⚠️ Response is null, returning empty map');
          return {};
        }

        if (data is Map<String, dynamic>) {
          print('✅ Response is already Map<String, dynamic>');
          return data;
        } else if (data is Map) {
          print('✅ Response is Map, casting to Map<String, dynamic>');
          return data.cast<String, dynamic>();
        }

        print('⚠️ Unexpected response type, returning empty map');
        return {};
      } else {
        print('📤 Using JSON (no image)');

        // No file - use regular JSON request
        final payload = <String, dynamic>{
          'fullName': fullName,
          'email': email,
          'phone': phone,
        };

        if (password != null && password.isNotEmpty) {
          payload['password'] = password;
        }

        final data = await _request(
          '/api/members',
          method: 'POST',
          body: jsonEncode(payload),
        );

        print('✅ JSON response received');
        print('📦 Response data: $data');

        if (data is Map<String, dynamic>) {
          return data;
        } else if (data is Map) {
          return data.cast<String, dynamic>();
        }
        return {};
      }
    } catch (e) {
      print('🔴 Error creating member: ${e.toString()}');
      throw ApiException('Failed to create member: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> updateMember({
    required String memberId,
    required String fullName,
    required String email,
    required String phone,
    File? faceImage,
  }) async {
    try {
      print('🔵 Updating member: $memberId');
      print('📧 Email: $email');
      print('📞 Phone: $phone');
      print('📸 Has image: ${faceImage != null}');

      // If we have a file, use multipart form data
      if (faceImage != null && faceImage.existsSync()) {
        print('📤 Using multipart upload for image');
        print('📁 Image path: ${faceImage.path}');
        print('📏 Image size: ${faceImage.lengthSync()} bytes');

        final fields = <String, String>{
          'fullName': fullName,
          'email': email,
          'phone': phone,
        };

        final data = await _multipart(
          '/api/members/$memberId',
          fields: fields,
          file: faceImage,
          fileFieldName: 'faceImage',
          method: 'PUT',
        );

        print('✅ Multipart response received');
        print('📦 Response type: ${data.runtimeType}');
        print('📦 Response data: $data');

        if (data == null) {
          return {};
        }

        if (data is Map<String, dynamic>) {
          return data;
        } else if (data is Map) {
          return data.cast<String, dynamic>();
        }
        return {};
      } else {
        // No image, use JSON request
        print('📝 Using JSON update');

        final payload = <String, dynamic>{
          'fullName': fullName,
          'email': email,
          'phone': phone,
        };

        final data = await _request(
          '/api/members/$memberId',
          method: 'PUT',
          body: jsonEncode(payload),
        );

        print('✅ JSON response received');
        print('📦 Response data: $data');

        if (data is Map<String, dynamic>) {
          return data;
        } else if (data is Map) {
          return data.cast<String, dynamic>();
        }
        return {};
      }
    } catch (e) {
      print('🔴 Error updating member: ${e.toString()}');
      throw ApiException('Failed to update member: ${e.toString()}');
    }
  }

  Future<List<dynamic>> getPlans() async {
    final data = await _request('/api/plans');
    return (data as List).cast<dynamic>();
  }

  Future<Map<String, dynamic>> createPlan({
    required String name,
    required double price,
    required int durationDays,
    String? description,
  }) async {
    final data = await _request(
      '/api/plans',
      method: 'POST',
      body: jsonEncode({
        'name': name,
        'price': price,
        'durationDays': durationDays,
        if (description != null && description.isNotEmpty)
          'description': description,
      }),
    );
    return (data as Map).cast<String, dynamic>();
  }

  Future<List<dynamic>> getSubscriptions() async {
    final data = await _request('/api/subscriptions');
    return (data as List).cast<dynamic>();
  }

  Future<Map<String, dynamic>> createSubscription({
    required String userId,
    required String planId,
    required String startDate,
    bool? autoRenew,
  }) async {
    final payload = <String, dynamic>{
      'userId': userId,
      'planId': planId,
      'startDate': startDate,
    };
    if (autoRenew != null) {
      payload['autoRenew'] = autoRenew;
    }

    final data = await _request(
      '/api/subscriptions',
      method: 'POST',
      body: jsonEncode(payload),
    );
    return (data as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    final data = await _request('/api/dashboard/stats');
    return (data as Map).cast<String, dynamic>();
  }

  Future<List<dynamic>> getExpiringSubscriptions({int days = 5}) async {
    final data = await _request('/api/subscriptions/expiring?days=$days');
    return (data as List).cast<dynamic>();
  }

  Future<List<dynamic>> getAllSubscriptions() async {
    final data = await _request('/api/subscriptions');
    return (data as List).cast<dynamic>();
  }

  Future<void> runExpiryCheck() async {
    await _request('/api/cron/check-expiring', method: 'POST');
  }

  Future<Map<String, dynamic>> identifyFace(String imageBase64) async {
    final data = await _request(
      '/api/auth/identify-face',
      method: 'POST',
      body: jsonEncode({
        'imageBase64': imageBase64,
      }),
    );
    return (data as Map).cast<String, dynamic>();
  }
}

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});
