class MyTimeoutException implements Exception {
  final String message;
  MyTimeoutException(this.message);
}

class ServerException implements Exception {
  final String message;
  ServerException(this.message);
}

class RequestCancelledException implements Exception {
  final String message;
  RequestCancelledException(this.message);
}

class DioErrorException implements Exception {
  final String message;
  DioErrorException(this.message);
}

class UnknownException implements Exception {
  final String message;
  UnknownException(this.message);
}
