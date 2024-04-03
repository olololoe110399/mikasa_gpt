import 'dart:async';
import 'dart:typed_data';
import 'package:mikasa_gpt/model/message.dart';
import 'package:mikasa_gpt/service/api/custom_log_interceptor.dart';
import 'package:mikasa_gpt/service/api/type_exception.dart';
import 'package:dio/dio.dart';

class AnthropicClient {
  final Dio _dio;

  AnthropicClient({
    required String apiKey,
  }) : _dio = Dio(
          BaseOptions(
            baseUrl: 'https://api.anthropic.com/v1/',
            headers: {
              'anthropic-version': '2023-06-01',
              'anthropic-beta': 'messages-2023-12-15',
              'Content-Type': 'application/json',
              'x-api-key': apiKey,
            },
          ),
        )..interceptors.add(CustomLogInterceptor());

  Future<Stream<Uint8List>> createMessage({
    required List<Message> messageHistory,
    String? system,
  }) async {
    try {
      Response<ResponseBody> response = await _dio.post(
        'messages',
        data: {
          'model': "claude-3-opus-20240229",
          'max_tokens': 1024,
          'stream': true,
          if (system != null) 'system': system,
          'messages': messageHistory.map((e) => e.toJson()).toList(),
        },
        options: Options(
          responseType: ResponseType.stream,
        ),
      );
      return response.data!.stream;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw MyTimeoutException('Request timed out: $e');
      } else if (e.type == DioExceptionType.badResponse) {
        // The request was made and the server responded with a status code
        throw ServerException(
            'Failed to create message. Status code: ${e.response!.statusCode}.');
      } else if (e.type == DioExceptionType.cancel) {
        throw RequestCancelledException('Request was cancelled: $e');
      } else {
        // Something went wrong in setting up or sending the request
        throw DioErrorException('Failed to create message: $e');
      }
    } catch (e) {
      throw UnknownException('Failed to create message: $e');
    }
  }
}
