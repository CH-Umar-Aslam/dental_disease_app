import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://192.168.100.168:8000', // CHANGE TO YOUR DOMAIN
    connectTimeout: const Duration(seconds: 100),
    receiveTimeout: const Duration(seconds: 100),
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