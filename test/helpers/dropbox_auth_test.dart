import 'package:calibre_carte/helpers/dropbox_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('stores offline refresh credentials and token expiry', () async {
    SharedPreferences.setMockInitialValues({});

    await DropboxAuth.storeTokenResponse({
      'access_token': 'access-token',
      'refresh_token': 'refresh-token',
      'expires_in': 14400,
    });

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('token'), 'access-token');
    expect(preferences.getString('dropbox_refresh_token'), 'refresh-token');
    expect(
      preferences.getInt('dropbox_token_expiry'),
      greaterThan(DateTime.now().millisecondsSinceEpoch),
    );
    expect(await DropboxAuth.getValidAccessToken(), 'access-token');
  });

  test('requests reconnection when an old session has expired', () async {
    SharedPreferences.setMockInitialValues({
      'token': 'expired-token',
      'dropbox_token_expiry': DateTime.now()
          .subtract(const Duration(minutes: 1))
          .millisecondsSinceEpoch,
    });

    await expectLater(
      DropboxAuth.getValidAccessToken(),
      throwsA(isA<StateError>()),
    );
  });
}
