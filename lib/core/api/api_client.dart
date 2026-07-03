import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

/// ApiClient works on ALL platforms:
/// - Web browser (Chrome, Firefox, Safari)
/// - Android (phone and tablet)
/// - iOS (iPhone and iPad)
/// Uses shared_preferences for token storage (works everywhere).
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  late final Dio _dio;
  SharedPreferences? _prefs;

  // Add near the top of the ApiClient class, right after `SharedPreferences? _prefs;`
  String get baseUrl => AppConstants.baseUrl;
// Add this getter next to `String get baseUrl => AppConstants.baseUrl;`
  String get mediaBaseUrl {
    final uri = Uri.parse(baseUrl);
    return '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
  }

// Add this method anywhere among your other request methods (get/post/put/...)
  Future<Map<String, dynamic>> uploadFiles(
    String path,
    List<MapEntry<String, List<int>>> files, {
    String fieldName = 'images',
  }) async {
    final formData = FormData();
    for (final f in files) {
      formData.files.add(MapEntry(
        fieldName,
        MultipartFile.fromBytes(f.value, filename: f.key),
      ));
    }
    final res = await _dio.post(path, data: formData);
    return res.data as Map<String, dynamic>;
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (err, handler) {
        final body = err.response?.data;
        String message = err.message ?? 'Something went wrong';
        if (body is Map) {
          final errorMap = body['error'];
          if (errorMap is Map) {
            message = errorMap['message']?.toString() ?? message;
          }
        }
        return handler.next(DioException(
          requestOptions: err.requestOptions,
          response: err.response,
          message: message,
        ));
      },
    ));
  }

  Future<void> saveToken(String token) async =>
      _prefs?.setString(AppConstants.tokenKey, token);
  Future<void> clearToken() async => _prefs?.remove(AppConstants.tokenKey);
  Future<String?> getToken() async => _prefs?.getString(AppConstants.tokenKey);

  Future<Map<String, dynamic>> get(String path,
      {Map<String, dynamic>? params}) async {
    final res = await _dio.get(path, queryParameters: params);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> post(String path, {dynamic data}) async {
    final res = await _dio.post(path, data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> put(String path, {dynamic data}) async {
    final res = await _dio.put(path, data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> patch(String path, {dynamic data}) async {
    final res = await _dio.patch(path, data: data);
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> delete(String path) async {
    final res = await _dio.delete(path);
    return res.data as Map<String, dynamic>;
  }
}
