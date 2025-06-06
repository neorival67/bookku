/// Base exception class for all app-specific exceptions
class AppException implements Exception {
  final String message;
  final String? prefix;
  
  AppException(this.message, [this.prefix]);
  
  @override
  String toString() {
    return "$prefix$message";
  }
}

/// Exception thrown when there is an error fetching data from the API
class FetchDataException extends AppException {
  FetchDataException([String? message]) 
      : super(message ?? "Error During Communication", "Communication Error: ");
}

/// Exception thrown when the request is invalid
class BadRequestException extends AppException {
  BadRequestException([String? message]) 
      : super(message ?? "Invalid Request", "Invalid Request: ");
}

/// Exception thrown when the user is not authorized
class UnauthorizedException extends AppException {
  UnauthorizedException([String? message]) 
      : super(message ?? "Unauthorized", "Unauthorized: ");
}

/// Exception thrown when the requested resource is not found
class NotFoundException extends AppException {
  NotFoundException([String? message]) 
      : super(message ?? "Resource Not Found", "Not Found: ");
}

/// Exception thrown when the input is invalid
class InvalidInputException extends AppException {
  InvalidInputException([String? message]) 
      : super(message ?? "Invalid Input", "Invalid Input: ");
}

/// Exception thrown when there is an authentication error
class AuthException extends AppException {
  AuthException([String? message]) 
      : super(message ?? "Authentication Failed", "Auth Error: ");
}

/// Exception thrown when there is a validation error
class ValidationException extends AppException {
  ValidationException([String? message]) 
      : super(message ?? "Validation Failed", "Validation Error: ");
}

/// Exception thrown when there is a database error
class DatabaseException extends AppException {
  DatabaseException([String? message]) 
      : super(message ?? "Database Error", "Database Error: ");
}

/// Exception thrown when there is a network error
class NetworkException extends AppException {
  NetworkException([String? message]) 
      : super(message ?? "Network Error", "Network Error: ");
}

/// Exception thrown when there is a timeout
class TimeoutException extends AppException {
  TimeoutException([String? message]) 
      : super(message ?? "Connection Timeout", "Timeout: ");
}
