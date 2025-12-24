import 'dart:convert';
import 'package:http/http.dart' as http;
import '../configs/flavors.dart';
import 'storage.dart';
import 'logger.dart';

class HttpClient {
  final http.Client _client = http.Client();

  String get baseUrl => FlavorConfig.apiBaseUrl;

  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final token = StorageService.getAccessToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint').replace(
        queryParameters: queryParams,
      );

      LoggerService.network('GET', uri.toString());

      final response = await _client.get(uri, headers: _headers);

      LoggerService.network('GET', uri.toString(), statusCode: response.statusCode);

      return _handleResponse(response);
    } catch (e, stackTrace) {
      LoggerService.error('GET request failed', e, stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');

      LoggerService.network('POST', uri.toString(), data: body);

      final response = await _client.post(
        uri,
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      );

      LoggerService.network('POST', uri.toString(), statusCode: response.statusCode);

      return _handleResponse(response);
    } catch (e, stackTrace) {
      LoggerService.error('POST request failed', e, stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');

      LoggerService.network('PUT', uri.toString(), data: body);

      final response = await _client.put(
        uri,
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      );

      LoggerService.network('PUT', uri.toString(), statusCode: response.statusCode);

      return _handleResponse(response);
    } catch (e, stackTrace) {
      LoggerService.error('PUT request failed', e, stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> patch(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');

      LoggerService.network('PATCH', uri.toString(), data: body);

      final response = await _client.patch(
        uri,
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      );

      LoggerService.network('PATCH', uri.toString(), statusCode: response.statusCode);

      return _handleResponse(response);
    } catch (e, stackTrace) {
      LoggerService.error('PATCH request failed', e, stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');

      LoggerService.network('DELETE', uri.toString());

      final response = await _client.delete(uri, headers: _headers);

      LoggerService.network('DELETE', uri.toString(), statusCode: response.statusCode);

      return _handleResponse(response);
    } catch (e, stackTrace) {
      LoggerService.error('DELETE request failed', e, stackTrace);
      rethrow;
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {'success': true};
      }
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    final errorBody = response.body.isNotEmpty
        ? jsonDecode(response.body)
        : {'message': 'Unknown error'};

    throw HttpException(
      statusCode: response.statusCode,
      message: errorBody['message'] ?? 'Request failed',
      data: errorBody,
    );
  }

  void dispose() {
    _client.close();
  }
}

class HttpException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? data;

  HttpException({
    required this.statusCode,
    required this.message,
    this.data,
  });

  @override
  String toString() => 'HttpException($statusCode): $message';
}

final httpClientProvider = Provider<HttpClient>((ref) => HttpClient());
