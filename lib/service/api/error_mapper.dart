import 'package:auto_interviewer/service/api/type_exception.dart';

class ErrorMapper {
  static String mapError(dynamic error) {
    if (error is MyTimeoutException) {
      return 'Request timed out: ${error.message}';
    } else if (error is ServerException) {
      return 'Server error: ${error.message}';
    } else if (error is RequestCancelledException) {
      return 'Request was cancelled: ${error.message}';
    } else if (error is DioErrorException) {
      return 'Dio error: ${error.message}';
    } else {
      return 'Unknown error occurred';
    }
  }
}
