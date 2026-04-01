import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';

class AuthResult {
  const AuthResult({
    required this.success,
    required this.message,
    this.token,
    this.user,
  });

  final bool success;
  final String message;
  final String? token;
  final Map<String, dynamic>? user;
}

class AuthService {
  static Future<AuthResult> loginUser({
    required String emailOrId,
    required String password,
  }) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/api/users/login');

    try {
      final response = await http.post(
        url,
        headers: const {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': emailOrId.trim(),
          'password': password,
        }),
      );

      Map<String, dynamic> payload = {};
      if (response.body.isNotEmpty) {
        payload = jsonDecode(response.body) as Map<String, dynamic>;
      }

      final success = payload['success'] == true || response.statusCode == 200;
      final message = (payload['message'] ??
              (success ? 'Login successful.' : 'Login failed. Please try again.'))
          .toString();

      if (success) {
        final data = payload['data'] as Map<String, dynamic>?;
        return AuthResult(
          success: true,
          message: message,
          token: data?['token']?.toString(),
          user: data?['user'] as Map<String, dynamic>?,
        );
      }

      return AuthResult(
        success: false,
        message: message,
      );
    } catch (error) {
      return AuthResult(
        success: false,
        message: 'Unable to sign in. ${_friendlyError(error)}',
      );
    }
  }

  static Future<AuthResult> registerUser({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/api/users/register');

    try {
      final response = await http.post(
        url,
        headers: const {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'fullName': fullName.trim(),
          'age': 30,
          'gender': 'Male',
          'phone': phone.trim(),
          'email': email.trim(),
          'password': password,
          'location': {
            'type': 'Point',
            'coordinates': [77.5946, 12.9716],
          },
          'medicalHistory': {
            'conditions': [],
            'medications': [],
            'allergies': [],
          },
          'emergencyContact': {
            'name': fullName.trim(),
            'phone': phone.trim(),
          },
        }),
      );

      Map<String, dynamic> payload = {};
      if (response.body.isNotEmpty) {
        payload = jsonDecode(response.body) as Map<String, dynamic>;
      }

      final success = payload['success'] == true || response.statusCode == 201;
      final message = (payload['message'] ??
              (success ? 'Registration successful.' : 'Registration failed.'))
          .toString();

      return AuthResult(
        success: success,
        message: message,
        token: (payload['data'] as Map<String, dynamic>?)?['token']?.toString(),
        user: (payload['data'] as Map<String, dynamic>?)?['user'] as Map<String, dynamic>?,
      );
    } catch (error) {
      return AuthResult(
        success: false,
        message: 'Unable to register. ${_friendlyError(error)}',
      );
    }
  }

  static Future<AuthResult> requestPasswordOtp({
    required String email,
  }) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/api/users/forgot-password');

    try {
      final response = await http.post(
        url,
        headers: const {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email.trim(),
        }),
      );

      final payload = _decodeJsonSafe(response.body);
      final success = payload['success'] == true || response.statusCode == 200;
      final message = (payload['message'] ??
              (success
                  ? 'OTP sent to your email.'
                  : _messageForStatus(response.statusCode, 'Unable to request OTP.')))
          .toString();

      return AuthResult(
        success: success,
        message: message,
      );
    } catch (error) {
      return AuthResult(
        success: false,
        message: 'Unable to request OTP. ${_friendlyError(error)}',
      );
    }
  }

  static Future<AuthResult> verifyPasswordOtp({
    required String email,
    required String otp,
  }) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/api/users/verify-otp');

    try {
      final response = await http.post(
        url,
        headers: const {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email.trim(),
          'otp': otp.trim(),
        }),
      );

      final payload = _decodeJsonSafe(response.body);
      final success = payload['success'] == true || response.statusCode == 200;
      final message = (payload['message'] ??
              (success
                  ? 'OTP verified successfully.'
                  : _messageForStatus(response.statusCode, 'OTP verification failed.')))
          .toString();

      return AuthResult(
        success: success,
        message: message,
      );
    } catch (error) {
      return AuthResult(
        success: false,
        message: 'Unable to verify OTP. ${_friendlyError(error)}',
      );
    }
  }

  static Future<AuthResult> updatePassword({
    required String email,
    required String newPassword,
  }) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/api/users/reset-password');

    try {
      final response = await http.post(
        url,
        headers: const {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email.trim(),
          'newPassword': newPassword,
        }),
      );

      final payload = _decodeJsonSafe(response.body);
      final success = payload['success'] == true || response.statusCode == 200;
      final message = (payload['message'] ??
              (success
                  ? 'Password updated successfully.'
                  : _messageForStatus(response.statusCode, 'Unable to update password.')))
          .toString();

      return AuthResult(
        success: success,
        message: message,
      );
    } catch (error) {
      return AuthResult(
        success: false,
        message: 'Unable to update password. ${_friendlyError(error)}',
      );
    }
  }

  static Future<AuthResult> updateUserProfile({
    required String token,
    required int age,
    required String gender,
    required String bloodGroup,
    double? heightCm,
    double? weightKg,
    required List<String> conditions,
    bool onboardingCompleted = false,
  }) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/api/users/profile');

    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'age': age,
          'gender': gender,
          'bloodGroup': bloodGroup,
          'physicalDetails': {
            'heightCm': heightCm,
            'weightKg': weightKg,
          },
          'onboardingCompleted': onboardingCompleted,
          'medicalHistory': {
            'conditions': conditions,
          },
        }),
      );

      final payload = _decodeJsonSafe(response.body);
      final success = payload['success'] == true || response.statusCode == 200;
      final message = (payload['message'] ??
              (success
                  ? 'Profile updated successfully.'
                  : _messageForStatus(response.statusCode, 'Unable to update profile.')))
          .toString();

      return AuthResult(
        success: success,
        message: message,
        user: payload['data'] is Map<String, dynamic>
            ? payload['data'] as Map<String, dynamic>
            : null,
      );
    } catch (error) {
      return AuthResult(
        success: false,
        message: 'Unable to update profile. ${_friendlyError(error)}',
      );
    }
  }

  static String _friendlyError(Object error) {
    final message = error.toString();
    if (message.contains('Connection refused') || message.contains('SocketException')) {
      return 'Please make sure the backend is running and the API base URL is correct.';
    }
    return 'Please check your connection and try again.';
  }

  static String _messageForStatus(int statusCode, String fallback) {
    if (statusCode == 404) {
      return 'Route not found. Please check that the backend is running.';
    }
    if (statusCode == 500) {
      return 'Server error. Please try again later.';
    }
    return fallback;
  }

  static Map<String, dynamic> _decodeJsonSafe(String body) {
    if (body.isEmpty) {
      return <String, dynamic>{};
    }
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }
}
