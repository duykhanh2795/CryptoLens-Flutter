import 'package:cryptolens_flutter/core/errors/app_exception.dart';

class NetworkException extends AppException {
  const NetworkException(super.message, {this.statusCode, this.body});

  final int? statusCode;
  final String? body;

  factory NetworkException.http({
    required String label,
    required int statusCode,
    String? body,
  }) {
    return NetworkException(
      '$label failed: HTTP $statusCode',
      statusCode: statusCode,
      body: body,
    );
  }

  factory NetworkException.invalidPayload(String label) {
    return NetworkException('Unexpected $label payload');
  }
}
