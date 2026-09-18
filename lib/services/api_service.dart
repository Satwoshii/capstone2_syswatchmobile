import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/app_models.dart';
import 'secure_session.dart';

class ApiException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;
  final int? retryAfterSeconds;

  const ApiException(
    this.message, {
    this.code,
    this.statusCode,
    this.retryAfterSeconds,
  });

  @override
  String toString() => message;
}

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();

  String _token = '';

  Uri _uri(String path) => Uri.parse('${AppConfig.apiBaseUrl}$path');

  Map<String, String> get _jsonHeaders => <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (_token.isNotEmpty) 'Authorization': 'Bearer $_token',
      };

  Future<void> init() async {
    _token = await SecureSession.instance.readToken() ?? '';
  }

  Future<Map<String, dynamic>> _decode(http.Response response) async {
    Map<String, dynamic> body;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map) throw const FormatException();
      body = Map<String, dynamic>.from(decoded);
    } catch (_) {
      throw ApiException(
        'The Syswatch server returned an invalid response.',
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        body['ok'] != true) {
      throw ApiException(
        '${body['message'] ?? 'Request failed.'}',
        code: body['code']?.toString(),
        statusCode: response.statusCode,
        retryAfterSeconds: int.tryParse('${body['retry_after_seconds'] ?? ''}'),
      );
    }
    return body;
  }

  Never _networkError(Object error) {
    if (error is TimeoutException) {
      throw const ApiException(
        'Syswatch server timed out. Check XAMPP and the API address.',
        code: 'timeout',
      );
    }
    if (error is SocketException) {
      throw const ApiException(
        'Cannot reach the Syswatch server. Check that Apache is running and that this device is on the same network.',
        code: 'network_unreachable',
      );
    }
    if (error is ApiException) throw error;
    throw ApiException('Network error: $error');
  }

  Future<void> healthCheck() async {
    try {
      final response = await http
          .get(
            _uri('health.php'),
            headers: const <String, String>{'Accept': 'application/json'},
          )
          .timeout(AppConfig.healthTimeout);
      await _decode(response);
    } catch (e) {
      _networkError(e);
    }
  }

  Future<OtpRequestResult> requestOtp(String email) async {
    try {
      final response = await http
          .post(
            _uri('auth/request_otp.php'),
            headers: _jsonHeaders,
            body: jsonEncode(<String, dynamic>{'email': email.trim()}),
          )
          .timeout(AppConfig.requestTimeout);
      final data = await _decode(response);
      return OtpRequestResult(
        email: '${data['email'] ?? email.trim()}',
        expiresInSeconds:
            int.tryParse('${data['expires_in_seconds']}') ?? 600,
        resendAfterSeconds:
            int.tryParse('${data['resend_after_seconds']}') ?? 45,
        debugCode: data['debug_otp']?.toString(),
      );
    } catch (e) {
      _networkError(e);
    }
  }

  Future<StudentUser> verifyOtp({
    required String email,
    required String code,
  }) async {
    try {
      final response = await http
          .post(
            _uri('auth/verify_otp.php'),
            headers: _jsonHeaders,
            body: jsonEncode(<String, dynamic>{
              'email': email.trim(),
              'code': code.trim(),
            }),
          )
          .timeout(AppConfig.requestTimeout);
      final data = await _decode(response);

      _token = '${data['api_token'] ?? ''}';
      if (_token.isEmpty) {
        throw const ApiException('The server did not return a login token.');
      }
      await SecureSession.instance.saveToken(_token);

      return StudentUser.fromJson(
        Map<String, dynamic>.from(data['user'] as Map),
      );
    } catch (e) {
      _networkError(e);
    }
  }

  Future<StudentUser?> restoreSession() async {
    if (_token.isEmpty) return null;
    try {
      final response = await http
          .get(_uri('auth/me.php'), headers: _jsonHeaders)
          .timeout(AppConfig.requestTimeout);
      final data = await _decode(response);
      return StudentUser.fromJson(
        Map<String, dynamic>.from(data['user'] as Map),
      );
    } catch (_) {
      await logout(localOnly: true);
      return null;
    }
  }

  Future<List<LabRoom>> fetchLabs() async {
    try {
      final response = await http
          .get(_uri('labs/list.php'), headers: _jsonHeaders)
          .timeout(AppConfig.requestTimeout);
      final data = await _decode(response);
      return (data['rooms'] as List? ?? const <dynamic>[])
          .map((e) => LabRoom.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      _networkError(e);
    }
  }

  Future<List<StudentReport>> fetchMyReports() async {
    try {
      final response = await http
          .get(_uri('reports/my.php'), headers: _jsonHeaders)
          .timeout(AppConfig.requestTimeout);
      final data = await _decode(response);
      return (data['reports'] as List? ?? const <dynamic>[])
          .map((e) => StudentReport.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      _networkError(e);
    }
  }

  Future<CreatedReport> createReport({
    required int roomId,
    int? workstationId,
    required String category,
    required String description,
    String? evidencePath,
  }) async {
    try {
      final request = http.MultipartRequest('POST', _uri('reports/create.php'));
      request.headers['Accept'] = 'application/json';
      request.headers['Authorization'] = 'Bearer $_token';
      request.fields['room_id'] = '$roomId';
      if (workstationId != null) {
        request.fields['workstation_id'] = '$workstationId';
      }
      request.fields['category'] = category;
      request.fields['description'] = description.trim();

      if (evidencePath != null && evidencePath.isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath('evidence', evidencePath),
        );
      }

      final streamed = await request.send().timeout(AppConfig.uploadTimeout);
      final response = http.Response(
        await streamed.stream.bytesToString(),
        streamed.statusCode,
        headers: streamed.headers,
      );
      final data = await _decode(response);

      return CreatedReport(
        id: int.tryParse('${data['report_id']}') ?? 0,
        code: '${data['report_code'] ?? ''}',
        duplicate: data['duplicate'] == true,
      );
    } catch (e) {
      _networkError(e);
    }
  }

  Future<void> logout({bool localOnly = false}) async {
    if (!localOnly && _token.isNotEmpty) {
      try {
        await http
            .post(_uri('auth/logout.php'), headers: _jsonHeaders)
            .timeout(const Duration(seconds: 5));
      } catch (_) {
        // Always clear the local token even when the LAN API is unavailable.
      }
    }
    _token = '';
    await SecureSession.instance.clear();
  }
}
