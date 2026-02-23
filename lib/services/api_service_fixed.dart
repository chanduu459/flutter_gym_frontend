// FIXED VERSION - Save as api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

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
              defaultValue: 'http://10.198.164.90:3001',
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
  }) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    final request = http.MultipartRequest('POST', uri);

    // Add all fields
    request.fields.addAll(fields);

    if (_token != null) {
      request.headers['Authorization'] = 'Bearer $_token';
    }

    // Add file if provided
    if (file != null && fileFieldName != null && file.existsSync()) {
      try {
        request.files.add(await http.MultipartFile.fromPath(
          fileFieldName,
          file.path,
        ));
      } catch (e) {
        throw ApiException('Failed to add file to request: ${e.toString()}');
      }
    }

    http.StreamedResponse streamed;
    try {
      streamed = await request.send();
    } catch (e) {
      throw ApiException('Failed to send request: ${e.toString()}');
    }

    final response = await http.Response.fromStream(streamed);

    if (response.body.isEmpty) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return null;
      }
      throw ApiException('API request failed: empty response');
    }

    // Check if response is HTML (error page) instead of JSON
    if (response.body.trim().startsWith('<')) {
      throw ApiException(
        'Server error: ${response.statusCode}. Please check your backend API. Response: ${response.body}'
      );
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (e) {
      throw ApiException('Invalid response from server: ${e.toString()}. Body: ${response.body}');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = _extractErrorMessage(decoded) ?? 'API request failed';
      throw ApiException('$message (Status: ${response.statusCode})');
    }

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

  /// Create a new member with optional face image
  /// If faceImage is provided, uses multipart/form-data
  /// Otherwise uses application/json
  Future<Map<String, dynamic>> createMember({
    required String fullName,
    required String email,
    required String phone,
    String? password,
    File? faceImage,
  }) async {
    try {
      // If we have a file, use multipart form data
      if (faceImage != null && faceImage.existsSync()) {
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

        if (data is Map<String, dynamic>) {
          return data;
        } else if (data is Map) {
          return data.cast<String, dynamic>();
        }
        return {};
      } else {
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

        if (data is Map<String, dynamic>) {
          return data;
        } else if (data is Map) {
          return data.cast<String, dynamic>();
        }
        return {};
      }
    } catch (e) {
      throw ApiException('Failed to create member: ${e.toString()}');
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

