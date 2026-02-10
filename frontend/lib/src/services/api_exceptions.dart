class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'ApiException: $message ${statusCode != null ? "($statusCode)" : ""}';
}

class UnauthorizedException extends ApiException {
  UnauthorizedException([String message = 'Unauthorized']) : super(message, 401);
}

class ForbiddenException extends ApiException {
  ForbiddenException([String message = 'Forbidden']) : super(message, 403);
}

class NotFoundException extends ApiException {
  NotFoundException([String message = 'Not Found']) : super(message, 404);
}

class ServerException extends ApiException {
  ServerException([String message = 'Server Error']) : super(message, 500);
}

class NetworkException extends ApiException {
  NetworkException([String message = 'Network Error']) : super(message);
}

class BadRequestException extends ApiException {
  BadRequestException([String message = 'Bad Request']) : super(message, 400);
}
