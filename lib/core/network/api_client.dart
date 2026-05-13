import 'dart:convert';
import 'package:http/http.dart' as http;
import 'result.dart';

class ApiClient {
  final String baseUrl;
  final http.Client _client;
  String? _token;

  ApiClient({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  void setToken(String token) => _token = token;

  Future<Result<T>> get<T>(String path, T Function(dynamic) fromJson) async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl$path'),
        headers: _headers,
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return Success(fromJson(jsonDecode(response.body)));
      }
      return Failure('HTTP ${response.statusCode}', statusCode: response.statusCode);
    } catch (e) {
      return Failure('Network error: $e');
    }
  }

  Future<Result<T>> post<T>(String path, Map<String, dynamic> body, T Function(dynamic) fromJson) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl$path'),
        headers: _headers,
        body: jsonEncode(body),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return Success(fromJson(jsonDecode(response.body)));
      }
      final errBody = jsonDecode(response.body);
      return Failure(errBody['error'] ?? 'HTTP ${response.statusCode}', statusCode: response.statusCode);
    } catch (e) {
      return Failure('Network error: $e');
    }
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };
}
