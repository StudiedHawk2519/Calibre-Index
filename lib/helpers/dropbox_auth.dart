import 'dart:convert';

import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DropboxAuth {
  static const _clientId = String.fromEnvironment('DROPBOX_APP_KEY');
  static const _tokenKey = 'token';
  static const _refreshTokenKey = 'dropbox_refresh_token';
  static const _expiryKey = 'dropbox_token_expiry';
  static Future<String>? _refreshInProgress;

  static Future<String> getValidAccessToken({String? fallbackToken}) async {
    final preferences = await SharedPreferences.getInstance();
    final token = preferences.getString(_tokenKey) ?? fallbackToken;
    if (token == null || token.isEmpty) {
      throw StateError('Connect Dropbox before accessing your library.');
    }

    final expiresAt = preferences.getInt(_expiryKey);
    final refreshToken = preferences.getString(_refreshTokenKey);
    final refreshNeeded = expiresAt != null &&
        expiresAt <=
            DateTime.now()
                .add(const Duration(minutes: 5))
                .millisecondsSinceEpoch;
    if (!refreshNeeded) {
      return token;
    }
    if (refreshToken == null || refreshToken.isEmpty) {
      throw StateError(
        'Dropbox session expired. Reconnect in Settings to enable automatic renewal.',
      );
    }

    return _refreshInProgress ??= _refreshAccessToken(
      preferences,
      refreshToken,
    ).whenComplete(() => _refreshInProgress = null);
  }

  static Future<void> storeTokenResponse(
    Map<String, dynamic> tokenData, {
    String? existingRefreshToken,
  }) async {
    final accessToken = tokenData['access_token'];
    if (accessToken is! String || accessToken.isEmpty) {
      throw const FormatException('Dropbox did not return an access token.');
    }

    final expiresIn = tokenData['expires_in'];
    if (expiresIn is! num || expiresIn <= 0) {
      throw const FormatException('Dropbox returned an invalid token expiry.');
    }

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_tokenKey, accessToken);
    final refreshToken = tokenData['refresh_token'];
    final tokenToStore = refreshToken is String && refreshToken.isNotEmpty
        ? refreshToken
        : existingRefreshToken;
    if (tokenToStore != null && tokenToStore.isNotEmpty) {
      await preferences.setString(_refreshTokenKey, tokenToStore);
    }
    final expiry = DateTime.now()
        .add(Duration(seconds: expiresIn.toInt()))
        .millisecondsSinceEpoch;
    await preferences.setInt(_expiryKey, expiry);
  }

  static Future<String> _refreshAccessToken(
    SharedPreferences preferences,
    String refreshToken,
  ) async {
    final response = await post(
      Uri.https('api.dropboxapi.com', '/oauth2/token'),
      body: {
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
        'client_id': _clientId,
      },
    );
    if (response.statusCode != 200) {
      throw StateError(
        'Dropbox session expired. Reconnect in Settings and try again '
        '(HTTP ${response.statusCode}).',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
          'Dropbox returned an invalid token response.');
    }
    await storeTokenResponse(decoded, existingRefreshToken: refreshToken);
    return decoded['access_token'] as String;
  }
}
