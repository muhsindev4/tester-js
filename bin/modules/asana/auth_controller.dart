import 'dart:math';
import 'package:dio/dio.dart';

class AuthController {
  static const String authorizationEndpoint =
      'https://app.asana.com/-/oauth_authorize';
  static const String proxyUrl = 'https://cors-anywhere.herokuapp.com/';
  static const String tokenEndpoint = '${proxyUrl}https://app.asana.com/-/oauth_token';

  final String clientId;
  final String clientSecret;
  final String redirectUri;
  String? accessToken;
  String? refreshToken;
  int? expiresIn;
  bool authorized = false;

  Dio _dio = Dio();

  AuthController({required this.clientId, required this.clientSecret, required this.redirectUri});

  String authorizationUrl([String? state]) {
    state ??= Random().nextInt(100000).toString();
    final params = {
      'response_type': 'code',
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'state': state,
    };
    final uri = Uri.parse(authorizationEndpoint).replace(queryParameters: params);
    return uri.toString();
  }

  Future<void> fetchToken(String code) async {
    final params = {
      'grant_type': 'authorization_code',
      'client_id': clientId,
      'client_secret': clientSecret,
      'code': Uri.decodeComponent(code),
      'redirect_uri': redirectUri,
    };

    try {
      final response = await _dio.post(
        tokenEndpoint,
        data: FormData.fromMap(params),
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      final result = response.data;
      accessToken = result['access_token'];
      refreshToken = result['refresh_token'];
      expiresIn = result['expires_in'];
      authorized = accessToken != null;
    } catch (e) {
      throw Exception("Error fetching token: $e");
    }
  }

  Future<void> refreshAccessToken() async {
    if (refreshToken == null) {
      throw Exception("OAuthDispatcher: cannot refresh access token without a refresh token.");
    }

    final params = {
      'grant_type': 'refresh_token',
      'client_id': clientId,
      'client_secret': clientSecret,
      'refresh_token': refreshToken,
      'redirect_uri': redirectUri,
    };

    try {
      final response = await _dio.post(
        tokenEndpoint,
        data: FormData.fromMap(params),
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      final result = response.data;
      accessToken = result['access_token'];
      expiresIn = result['expires_in'];
    } catch (e) {
      throw Exception("Error refreshing access token: $e");
    }
  }

  int? getExpiresInSeconds() {
    if (expiresIn == null) {
      return null;
    } else {
      return expiresIn! - DateTime.now().millisecondsSinceEpoch ~/ 1000;
    }
  }

  Future<void> authenticate(RequestOptions options) async {
    final expiresIn = getExpiresInSeconds();
    if (expiresIn != null && expiresIn < 60) {
      await refreshAccessToken();
    }

    if (accessToken == null) {
      throw Exception("OAuthDispatcher: access token not set");
    }
    options.headers['Authorization'] = 'Bearer $accessToken';
  }
}
