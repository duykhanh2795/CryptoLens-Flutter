import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:cryptolens_flutter/core/errors/network_exception.dart';
import 'package:cryptolens_flutter/core/network/api_response.dart';
import 'package:cryptolens_flutter/core/network/network_config.dart';

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<ApiResponse<Object?>> getJson(
    Uri uri, {
    required String label,
    Map<String, String>? headers,
    Duration timeout = NetworkConfig.defaultTimeout,
    bool throwOnHttpError = true,
  }) async {
    final response = await get(
      uri,
      label: label,
      headers: headers,
      timeout: timeout,
      throwOnHttpError: throwOnHttpError,
    );
    final body = response.rawBody.trim().isEmpty
        ? null
        : jsonDecode(response.rawBody);
    return ApiResponse(
      data: body,
      statusCode: response.statusCode,
      rawBody: response.rawBody,
    );
  }

  Future<ApiResponse<String>> get(
    Uri uri, {
    required String label,
    Map<String, String>? headers,
    Duration timeout = NetworkConfig.defaultTimeout,
    bool throwOnHttpError = true,
  }) async {
    final response = await _client.get(uri, headers: headers).timeout(timeout);
    if (throwOnHttpError && !_isSuccess(response.statusCode)) {
      throw NetworkException.http(
        label: label,
        statusCode: response.statusCode,
        body: response.body,
      );
    }
    return ApiResponse(
      data: response.body,
      statusCode: response.statusCode,
      rawBody: response.body,
    );
  }

  Future<ApiResponse<Object?>> postJson(
    Uri uri, {
    required String label,
    Object? body,
    Map<String, String>? headers,
    Duration timeout = NetworkConfig.defaultTimeout,
    bool throwOnHttpError = true,
  }) async {
    final response = await _client
        .post(uri, headers: headers, body: body)
        .timeout(timeout);
    if (throwOnHttpError && !_isSuccess(response.statusCode)) {
      throw NetworkException.http(
        label: label,
        statusCode: response.statusCode,
        body: response.body,
      );
    }
    final decoded = response.body.trim().isEmpty
        ? null
        : jsonDecode(response.body);
    return ApiResponse(
      data: decoded,
      statusCode: response.statusCode,
      rawBody: response.body,
    );
  }

  void close() => _client.close();

  static bool isSuccessStatus(int statusCode) => _isSuccess(statusCode);

  static bool _isSuccess(int statusCode) =>
      statusCode >= 200 && statusCode < 300;
}
