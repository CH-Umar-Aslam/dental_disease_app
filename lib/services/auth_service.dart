import 'dart:convert';
import 'package:dio/dio.dart';
import 'api_client.dart';

class AuthService {
  static Future<Map<String, dynamic>?> login(
      String email, String password) async {
    try {
      final res = await ApiClient.dio.post('/login', data: {
        'email': email,
        'password': password,
      });

      print('res is $res');

      final token = res.data['access_token'];
      final user = res.data['user'];

      print(token);

      await ApiClient.storage.write(key: 'access_token', value: token);
      await ApiClient.storage.write(key: 'user', value: jsonEncode(user));
      await ApiClient.storage
          .write(key: 'user_id', value: user['user_id'].toString());
      await ApiClient.storage.write(key: 'role', value: user['role']);

      return user;
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Login failed';
    }
  }

  static Future<Map<String, dynamic>> getMe() async {
    try {
      final res = await ApiClient.dio.get('/me');
      final user = res.data['user'];
      if (user is Map<String, dynamic>) {
        return user;
      }
      throw 'Invalid user data';
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Failed to fetch user';
    }
  }

  static Future<void> logout() async {
    await ApiClient.storage.deleteAll();
  }

  static Future<void> signup(Map<String, dynamic> data) async {
    try {
      final response = await ApiClient.dio.post('/signup', data: data);
      return response.data;
    } on DioException catch (e) {
      print('dio exception is $e');
      throw e.response?.data['message'] ?? 'Failed to fetch user';
    }
  }
}
