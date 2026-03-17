import 'dart:convert';
import 'package:http/http.dart' as http;

import 'session_service.dart';

class AuthUser {
  final String userId;
  final String name;
  final String email;
  final String phone;
  final String token;

  const AuthUser({
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    this.token = '',
  });
}

class AuthService {
  static const String _defaultBaseUrl = 'https://countpluse.onrender.com';
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: _defaultBaseUrl,
  );
  static const Duration _requestTimeout = Duration(seconds: 15);

  static Future<AuthUser> register({
    required String name,
    required String email,
    required String phone,
  }) async {
    final uri = Uri.parse('$baseUrl/api/auth/register');
    final response = await _post(
      uri,
      body: {'name': name, 'email': email, 'phone': phone},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final msg =
          _extractMessage(response.body) ??
          'Registration failed (${response.statusCode})';
      throw Exception(msg);
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final data = (payload['data'] as Map<String, dynamic>? ?? {});
    return AuthUser(
      userId: data['userId']?.toString() ?? '',
      name: data['name']?.toString() ?? name,
      email: data['email']?.toString() ?? email,
      phone: data['phone']?.toString() ?? phone,
    );
  }

  static Future<AuthUser> login({required String email}) async {
    final uri = Uri.parse('$baseUrl/api/auth/login');
    final response = await _post(uri, body: {'email': email});

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final msg =
          _extractMessage(response.body) ??
          'Login failed (${response.statusCode})';
      throw Exception(msg);
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final data = (payload['data'] as Map<String, dynamic>? ?? {});
    return AuthUser(
      userId: data['userId']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      email: data['email']?.toString() ?? email,
      phone: data['phone']?.toString() ?? '',
    );
  }

  static Future<AuthUser> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final uri = Uri.parse('$baseUrl/api/auth/verify-otp');
    final response = await _post(uri, body: {'email': email, 'otp': otp});

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final msg =
          _extractMessage(response.body) ??
          'OTP verification failed (${response.statusCode})';
      throw Exception(msg);
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final data = (payload['data'] as Map<String, dynamic>? ?? {});
    return AuthUser(
      userId: data['userId']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      email: data['email']?.toString() ?? email,
      phone: data['phone']?.toString() ?? '',
      token: data['token']?.toString() ?? '',
    );
  }

  static Future<Map<String, dynamic>> fetchCountHistory({
    DateTime? from,
    DateTime? to,
    int limit = 366,
  }) async {
    final query = <String, String>{'limit': '$limit'};
    if (from != null) query['from'] = _dateString(from);
    if (to != null) query['to'] = _dateString(to);
    final uri = Uri.parse(
      '$baseUrl/api/counts',
    ).replace(queryParameters: query);
    final response = await _get(uri);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final msg =
          _extractMessage(response.body) ??
          'Unable to load counts (${response.statusCode})';
      throw Exception(msg);
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<void> upsertCount({
    required DateTime date,
    required int count,
    String? targetLabel,
  }) async {
    final uri = Uri.parse('$baseUrl/api/counts');
    final response = await _post(
      uri,
      body: {
        'date': _dateString(date),
        'count': count,
        if (targetLabel != null && targetLabel.trim().isNotEmpty)
          'targetLabel': targetLabel.trim(),
      },
      includeAuth: true,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final msg =
          _extractMessage(response.body) ??
          'Unable to save count (${response.statusCode})';
      throw Exception(msg);
    }
  }

  static Future<http.Response> _post(
    Uri uri, {
    required Map<String, dynamic> body,
    bool includeAuth = false,
  }) async {
    try {
      return await http
          .post(
            uri,
            headers: _headers(includeAuth: includeAuth),
            body: jsonEncode(body),
          )
          .timeout(_requestTimeout);
    } catch (error) {
      throw Exception(_networkMessage(error));
    }
  }

  static Future<http.Response> _get(Uri uri, {bool includeAuth = true}) async {
    try {
      return await http
          .get(uri, headers: _headers(includeAuth: includeAuth))
          .timeout(_requestTimeout);
    } catch (error) {
      throw Exception(_networkMessage(error));
    }
  }

  static Map<String, String> _headers({bool includeAuth = false}) {
    return {
      'Content-Type': 'application/json',
      if (includeAuth) ...SessionService.authHeaders(),
    };
  }

  static String _dateString(DateTime value) {
    return DateTime(value.year, value.month, value.day)
        .toIso8601String()
        .split('T')
        .first;
  }

  static String? _extractMessage(String body) {
    try {
      final payload = jsonDecode(body) as Map<String, dynamic>;
      return payload['message']?.toString();
    } catch (_) {
      return null;
    }
  }

  static String _networkMessage(Object error) {
    final message = error.toString();
    if (message.contains('TimeoutException')) {
      return 'Request timed out. Please try again.';
    }
    return 'Unable to reach the server. Please check your connection.';
  }
}
