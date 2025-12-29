import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static final Dio _dio = Dio(BaseOptions(
    // baseUrl: 'https://xeecode-solutions.tech',
    baseUrl: 'http://172.17.242.126:8000',
    connectTimeout: const Duration(seconds: 200),
    receiveTimeout: const Duration(seconds: 200),
  ));

  static const _storage = FlutterSecureStorage();

  static Future<void> init() async {
    // Add auth interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (e, handler) {
        if (e.response?.statusCode == 401) {
          // Optional: refresh token logic
          _storage.deleteAll();
        }
        handler.next(e);
      },
    ));
  }

  static Dio get dio => _dio;
  static FlutterSecureStorage get storage => _storage;
}