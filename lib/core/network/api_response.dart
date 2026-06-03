class ApiResponse<T> {
  const ApiResponse({
    required this.data,
    required this.statusCode,
    required this.rawBody,
  });

  final T data;
  final int statusCode;
  final String rawBody;
}
