import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthUser {
  final String userId;
  final String name;
  final String email;
  final String phone;

  const AuthUser({
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
  });
}

class AuthService {
  static const String baseUrl = 'http://localhost:5001';

  static Future<AuthUser> register({
    required String name,
    required String email,
    required String phone,
  }) async {
    final uri = Uri.parse('$baseUrl/api/auth/register');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'phone': phone,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final msg = _extractMessage(response.body) ??
          'Registration failed (${response.statusCode})';
      throw Exception(msg);
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final data = (payload['data'] as Map<String, dynamic>? ?? {});
    return AuthUser(
      userId: data['userId']?.toString() ?? '',
      name: data['name']?.toString() ?? name,
      email: data['email']?.toString() ?? email,
      phone: phone,
    );
  }

  static Future<AuthUser> login({required String email}) async {
    final uri = Uri.parse('$baseUrl/api/auth/login');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final msg = _extractMessage(response.body) ??
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
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'otp': otp}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final msg = _extractMessage(response.body) ??
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
    );
  }

  static String? _extractMessage(String body) {
    try {
      final payload = jsonDecode(body) as Map<String, dynamic>;
      return payload['message']?.toString();
    } catch (_) {
      return null;
    }
  }
}
