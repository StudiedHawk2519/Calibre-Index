import 'dart:convert';
import 'dart:io';

import 'package:calibre_carte/helpers/cache_invalidator.dart';
import 'package:calibre_carte/helpers/metadata_cacher.dart';
import 'package:calibre_carte/helpers/oauth_helper.dart';
import 'package:calibre_carte/providers/color_theme_provider.dart';
import 'package:calibre_carte/providers/update_provider.dart';
import 'package:calibre_carte/widgets/settings_screen_widgets/connect_button.dart';
import 'package:calibre_carte/widgets/settings_screen_widgets/logout_button.dart';
import 'package:calibre_carte/widgets/settings_screen_widgets/refresh_button.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

class DropboxDropdown extends StatefulWidget {
  static const String clientId = String.fromEnvironment('DROPBOX_APP_KEY');
  static const String redirectUri = 'http://localhost:53682/';
  static const int redirectPort = 53682;
  static const String redirectUriCode = 'calibrecarte://dropbox';
  static const String redirectUriToken = 'calibrecarte://dropbox/token';

  const DropboxDropdown({super.key});

  @override
  _DropboxDropdownState createState() => _DropboxDropdownState();
}

class _DropboxDropdownState extends State<DropboxDropdown> {
  final AppLinks _appLinks = AppLinks();
  Future? myFuture;
  String? dropboxEmail;
  String? selected_calibre_lib_dir;
  String? selected_lib_name;
  String? token;
  List<String?> dirNames = [];
  int? noOfCalibreLibs;
  bool? hasChanged;
  String? clientId;
  StreamSubscription<Uri>? _sub;
  static const String NO_CODE_URI = 'no_code_uri';
  HttpServer? _oauthServer;
  bool _authorizationInProgress = false;

  Completer<List<Widget>> _responseCompleter = Completer();

  Future<bool> loadingToken() async {
    String? temp;
    SharedPreferences sp = await SharedPreferences.getInstance();
    if (sp.containsKey('token')) {
      dirNames.clear();
      dropboxEmail = sp.getString('dropboxEmail');
      selected_calibre_lib_dir = sp.getString('selected_calibre_lib_path');
      selected_lib_name = sp.getString('selected_calibre_lib_name');
      noOfCalibreLibs = sp.getInt('noOfCalibreLibs');
      for (int i = 0; i < noOfCalibreLibs!; i++) {
        temp = sp.getString('calibre_lib_name_$i');
        dirNames.add(temp);
      }
      return true;
    }
    clientId = DropboxDropdown.clientId;
    return false;
  }

  Future<void> deleteToken() async {
    final pref = await SharedPreferences.getInstance();
    await pref.remove('token');
  }

  Future<void> storeStringInSharedPrefs(key, val) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(key, val);
  }

  Future<void> storeIntInSharedPrefs(key, val) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(key, val);
  }

  Future<Response> _makePostRequest(dynamic token) {
    return post(
      Uri.https('api.dropboxapi.com', '/2/files/search_v2'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-type': 'application/json',
      },
      body: jsonEncode({
        'query': 'metadata.db',
        'options': {
          'filename_only': true,
          'file_extensions': ['db'],
        },
      }),
    );
  }

  Future<Response> _makePostRequestCode(dynamic code) {
    final codeVerifier = OAuthUtils.codeVerifier;
    if (codeVerifier == null) {
      throw StateError('The Dropbox authorization verifier is missing.');
    }

    return post(
      Uri.https('api.dropboxapi.com', '/oauth2/token'),
      body: {
        'code': code,
        'grant_type': 'authorization_code',
        'code_verifier': codeVerifier,
        'client_id': DropboxDropdown.clientId,
        'redirect_uri': DropboxDropdown.redirectUri,
      },
    );
  }

  selectingCalibreLibrary(key, val, update) {
    //      Navigator.of(context).pop();
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: SimpleDialog(
            key: UniqueKey(),
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
            children: <Widget>[
              Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 10),
                    Text(
                      "Updating library",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );

    MetadataCacher().downloadAndCacheMetadata(path: key).then((value) {
      if (value == 1) {
        storeStringInSharedPrefs('selected_calibre_lib_path', key);
        storeStringInSharedPrefs('selected_calibre_lib_name', val);
        update.updateFlagState(true);
      }
      Navigator.of(context).pop();
    });
  }

  _showLoading(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: SimpleDialog(
            key: UniqueKey(),
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
            children: <Widget>[
              Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 10),
                    Text(
                      "Loading Calibre library",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  selectingCalibreLibraryNew(key, val, update, token) {
    storeStringInSharedPrefs('selected_calibre_lib_path', key);
    storeStringInSharedPrefs('selected_calibre_lib_name', val);
    MetadataCacher().downloadAndCacheMetadata(token: token).then((val) {
      if (val == 1) {
        //        print("storing token");
        storeStringInSharedPrefs('token', token);
        //        print("stored token");
        update.changeTokenState(true);
        update.updateFlagState(true);
      }
      Navigator.of(context).pop();
      Navigator.of(context).pop();
      Navigator.of(context).pop();
    });
  }

  String errorDescription(String? errorCode) {
    String errorMsg;
    switch (errorCode) {
      case 'access_denied':
        errorMsg = "User did not authorize the app";
        break;
      case NO_CODE_URI:
        errorMsg = "Login Failed. Please Try again.";
        break;
      default:
        errorMsg = 'Login Failed';
    }

    return errorMsg;
  }

  Future<bool> _launchURL(Uri url) async {
    try {
      final launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        _showMessage('Could not open Dropbox sign-in.');
      }
      return launched;
    } on PlatformException catch (error) {
      _showMessage(
        'Could not open Dropbox sign-in: ${error.message ?? error.code}',
      );
      return false;
    } on Exception catch (error) {
      _showMessage('Could not open Dropbox sign-in: $error');
      return false;
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _dismissLoadingDialog() {
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Map<String, dynamic> _decodeResponse(Response response) {
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) return decoded;
    throw const FormatException('Dropbox returned an invalid response.');
  }

  String _responseError(Response response) {
    try {
      final decoded = _decodeResponse(response);
      final message = decoded['error_description'] ??
          decoded['error_summary'] ??
          decoded['error'];
      if (message != null) return message.toString();
    } on FormatException {
      // Use the HTTP status when the response is not a Dropbox error object.
    }
    return 'Dropbox returned HTTP ${response.statusCode}.';
  }

  Future<void> _startDropboxAuthorization() async {
    if (_authorizationInProgress) return;

    final codeChallenge = OAuthUtils.generateAndEncodeCodeChallenge();
    final state = OAuthUtils.generateState();
    final callbackCompleter = Completer<Uri>();

    setState(() => _authorizationInProgress = true);
    try {
      _oauthServer = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        DropboxDropdown.redirectPort,
      );
      _oauthServer!.listen((request) async {
        final callback = request.uri;
        if (callback.path != '/' ||
            (!callback.queryParameters.containsKey('code') &&
                !callback.queryParameters.containsKey('error'))) {
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
          return;
        }

        if (callback.queryParameters['state'] != state) {
          request.response.statusCode = HttpStatus.forbidden;
          await request.response.close();
          return;
        }

        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.html
          ..write(
            '<!doctype html><meta name="viewport" content="width=device-width">'
            '<title>Dropbox connected</title>'
            '<p>Dropbox sign-in finished. Return to Calibre Index.</p>',
          );
        await request.response.close();
        if (!callbackCompleter.isCompleted) {
          callbackCompleter.complete(callback);
        }
      });

      final callbackUri = Uri.parse(DropboxDropdown.redirectUri);
      final url = Uri.https(
        'www.dropbox.com',
        '/oauth2/authorize',
        {
          'client_id': DropboxDropdown.clientId,
          'response_type': 'code',
          'redirect_uri': callbackUri.toString(),
          'code_challenge': codeChallenge,
          'code_challenge_method': OAuthUtils.codeChallengeMethod,
          'state': state,
        },
      );

      final launched = await _launchURL(url);
      if (!launched) {
        return;
      }

      final callback = await callbackCompleter.future.timeout(
        const Duration(minutes: 2),
      );
      if (callback.queryParameters['state'] != state) {
        throw const FormatException(
          'Dropbox sign-in could not be verified. Please try again.',
        );
      }
      final error = callback.queryParameters['error_description'] ??
          callback.queryParameters['error'];
      if (error != null) {
        throw StateError('Dropbox sign-in was not completed: $error');
      }
      final code = callback.queryParameters['code'];
      if (code == null || code.isEmpty) {
        throw const FormatException(
          'Dropbox did not return an authorization code.',
        );
      }

      if (mounted) {
        await _completeDropboxAuthorization(
          code,
          Provider.of<Update>(context, listen: false),
        );
      }
    } on SocketException catch (error) {
      _showMessage(
        error.osError?.errorCode == 98 || error.osError?.errorCode == 48
            ? 'Dropbox sign-in is already in progress. Please try again shortly.'
            : 'Could not start Dropbox sign-in: ${error.message}',
      );
    } on TimeoutException {
      _showMessage(
        'Dropbox did not return to the app. Check that '
        '${DropboxDropdown.redirectUri} is registered in the Dropbox app settings.',
      );
    } on FormatException catch (error) {
      _showMessage(error.message);
    } on StateError catch (error) {
      _showMessage(error.message);
    } on HttpException catch (error) {
      _showMessage('Could not start Dropbox sign-in: ${error.message}');
    } finally {
      await _oauthServer?.close(force: true);
      _oauthServer = null;
      if (mounted) setState(() => _authorizationInProgress = false);
    }
  }

  Future<void> _completeDropboxAuthorization(String code, Update update) async {
    _showLoading(context);
    try {
      final tokenResponse = await _makePostRequestCode(code);
      if (tokenResponse.statusCode != 200) {
        _dismissLoadingDialog();
        _showMessage(
          'Dropbox authorization failed: ${_responseError(tokenResponse)}',
        );
        return;
      }

      final tokenData = _decodeResponse(tokenResponse);
      final accessToken = tokenData['access_token'];
      if (accessToken is! String || accessToken.isEmpty) {
        throw const FormatException('Dropbox did not return an access token.');
      }

      final searchResponse = await _makePostRequest(accessToken);
      if (searchResponse.statusCode != 200) {
        _dismissLoadingDialog();
        _showMessage(
          'Could not search Dropbox: ${_responseError(searchResponse)}',
        );
        return;
      }

      final searchData = _decodeResponse(searchResponse);
      final matches = searchData['matches'];
      if (matches is! List) {
        throw const FormatException(
          'Dropbox returned an unexpected library search response.',
        );
      }

      final libraries = <String, String>{};
      for (final match in matches) {
        if (match is! Map<String, dynamic>) continue;
        final wrapper = match['metadata'];
        if (wrapper is! Map<String, dynamic>) continue;
        final metadata = wrapper['metadata'];
        if (metadata is! Map<String, dynamic> ||
            metadata['name'] != 'metadata.db') {
          continue;
        }

        final path = metadata['path_display'];
        if (path is! String || !path.endsWith('metadata.db')) continue;
        final segments = path.split('/');
        if (segments.length < 2) continue;

        libraries.putIfAbsent(
          path.substring(0, path.length - 'metadata.db'.length),
          () => segments[segments.length - 2],
        );
      }

      if (libraries.isEmpty) {
        _dismissLoadingDialog();
        _showMessage(
          'No Calibre library was found in Dropbox. Check the app’s file permissions.',
        );
        return;
      }

      await storeIntInSharedPrefs('noOfCalibreLibs', libraries.length);
      var index = 0;
      for (final entry in libraries.entries) {
        await storeStringInSharedPrefs('calibre_lib_path_$index', entry.key);
        await storeStringInSharedPrefs('calibre_lib_name_$index', entry.value);
        index++;
      }

      if (libraries.length == 1) {
        final library = libraries.entries.single;
        await _connectLibrary(
          path: library.key,
          name: library.value,
          accessToken: accessToken,
          update: update,
          loadingDialogOpen: true,
        );
      } else {
        _dismissLoadingDialog();
        _showLibraryPicker(libraries, accessToken, update);
      }
    } on ClientException catch (error) {
      _dismissLoadingDialog();
      _showMessage('Could not contact Dropbox: ${error.message}');
    } on FormatException catch (error) {
      _dismissLoadingDialog();
      _showMessage(error.message);
    } on StateError catch (error) {
      _dismissLoadingDialog();
      _showMessage(error.message);
    }
  }

  void _showLibraryPicker(
    Map<String, String> libraries,
    String accessToken,
    Update update,
  ) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Select library'),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(dialogContext).size.height * 0.55,
          ),
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final entry in libraries.entries)
                ListTile(
                  leading: const Icon(Icons.folder_rounded),
                  title: Text(entry.value),
                  onTap: () {
                    Navigator.of(dialogContext).pop();
                    unawaited(
                      _connectLibrary(
                        path: entry.key,
                        name: entry.value,
                        accessToken: accessToken,
                        update: update,
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _connectLibrary({
    required String path,
    required String name,
    required String accessToken,
    required Update update,
    bool loadingDialogOpen = false,
  }) async {
    if (!loadingDialogOpen) _showLoading(context);
    try {
      await storeStringInSharedPrefs('selected_calibre_lib_path', path);
      await storeStringInSharedPrefs('selected_calibre_lib_name', name);
      final result = await MetadataCacher().downloadAndCacheMetadata(
        token: accessToken,
        path: path,
      );
      if (result != 1) {
        _dismissLoadingDialog();
        _showMessage(result == 0
            ? 'Could not download the Calibre library. Check your internet connection.'
            : 'Could not download the Calibre library (Dropbox returned HTTP $result).');
        return;
      }

      await storeStringInSharedPrefs('token', accessToken);
      update.changeTokenState(true);
      update.updateFlagState(true);
      if (mounted) {
        setState(() {
          myFuture = loadingToken();
        });
      }
      _dismissLoadingDialog();
    } on ClientException catch (error) {
      _dismissLoadingDialog();
      _showMessage('Could not download the Calibre library: ${error.message}');
    }
  }

  Future<void> initUniLinks() async {
    _sub = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        final String link = uri.toString();
        //Although this is not needed now, but Google actually recommends against using a webview for,
        //So assuming in future we need to do it the url_launcher way then we would have to use this method
        //      print(link);
        if (link.startsWith(DropboxDropdown.redirectUriCode)) {
          Update update = Provider.of<Update>(context, listen: false);

          final uri = Uri.parse(link);
          // Step 1. Parse the token
          String? code;
          const String ERROR = "error";
          const String CODE = 'code';

          if (uri.queryParameters.containsKey(ERROR)) {
            String errorMsg = errorDescription(uri.queryParameters[ERROR]);
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(errorMsg)));
            return;
          }

          if (!uri.queryParameters.containsKey(CODE)) {
            String errorMsg = errorDescription(NO_CODE_URI);
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(errorMsg)));
            return;
          } else {
            code = uri.queryParameters[CODE];
            _showLoading(context);
            _makePostRequestCode(code).then((response) {
              Map<String, dynamic> responseJson = jsonDecode(response.body);
              token = responseJson['access_token'];
              //          print(responseJson);

              Map<String, String> pathNameMap = Map();
              _makePostRequest(token).then((response) {
                Navigator.of(context).pop();
                //Make a map Map<String, String> First value is the base path in lower case
                // Second Value is the name of the Folder(Library)
                // I have to convert string response.body to json
                Map<String, dynamic> responseJson = jsonDecode(response.body);
                if (responseJson['matches'].length != 0) {
                  responseJson['matches'].forEach((element) {
                    if (element["metadata"]["metadata"]["name"] ==
                        "metadata.db") {
                      String libPath =
                          element["metadata"]["metadata"]["path_display"];
                      libPath = libPath.replaceAll('metadata.db', "");
                      List<String> directories =
                          element["metadata"]["metadata"]["path_display"].split(
                        '/',
                      );
                      String libName = directories.elementAt(
                        directories.length - 2,
                      );
                      pathNameMap.putIfAbsent(libPath, () => libName);
                      //                        print(pathNameMap);
                    }
                  });
                  storeIntInSharedPrefs('noOfCalibreLibs', pathNameMap.length);
                  pathNameMap.keys.toList().asMap().forEach((index, path) {
                    String keyName = 'calibre_lib_path_$index';
                    String libName = 'calibre_lib_name_$index';
                    storeStringInSharedPrefs(keyName, path);
                    storeStringInSharedPrefs(libName, pathNameMap[path]);
                  });

                  // TODO: Default selection
                  storeStringInSharedPrefs(
                    'selected_calibre_lib_path',
                    pathNameMap.keys.first,
                  );
                  storeStringInSharedPrefs(
                    'selected_calibre_lib_name',
                    pathNameMap.values.first,
                  );
                  if (pathNameMap.length > 1) {
                    // First set the no of libraries in shared prefs
                    // Show a pop up which displays the list of libraries
                    //                      print('I have come inside the popup dispaly htingy');
                    List<Widget> columnChildren = pathNameMap.keys.toList().map(
                      (element) {
                        return InkWell(
                          onTap: () {
                            _showLoading(context);
                            selectingCalibreLibraryNew(
                              element,
                              pathNameMap[element],
                              update,
                              token,
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.all(8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: <Widget>[
                                Icon(
                                  Icons.folder_rounded,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  pathNameMap[element]!,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ).toList();
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return PopScope(
                          canPop: false,
                          child: AlertDialog(
                            contentPadding: EdgeInsets.all(10),
                            content: Container(
                              width: 300,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Container(
                                    child: Text(
                                      'Select Library',
                                      style: TextStyle(
                                        fontSize: 20,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 20),
                                  Column(children: columnChildren),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  } else {
                    _showLoading(context);
                    storeStringInSharedPrefs(
                      'selected_calibre_lib_path',
                      pathNameMap.keys.first,
                    );
                    storeStringInSharedPrefs(
                      'selected_calibre_lib_name',
                      pathNameMap.values.first,
                    );
                    MetadataCacher()
                        .downloadAndCacheMetadata(token: token)
                        .then((val) {
                      if (val == 1) {
                        //                          print("storing token");
                        storeStringInSharedPrefs('token', token);
                        //                          print("stored token");
                        update.changeTokenState(true);
                        update.updateFlagState(true);
                      }
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    });
                    // Her we have only one library so we make that the default
                  }
                } else {
                  //                print("no libraries found");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("No Calibre libraries found")),
                  );
                  //                Navigator.of(context).pop();
                  // Show the bottom snack bar that no libraries found and Pop out of this context
                }
              });
            });
          }
        }
        //So, just keeping it here.
        // Parse the link and warn the user, if it is not correct
      },
      onError: (err) {
        // Handle exception by warning the user their action did not succeed
      },
    );
  }

  //Let's try and figure out if I can attach a listener and then parse and do something when I finally get a URL back

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    //    print('Hitting it');
    myFuture = loadingToken();
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    unawaited(_oauthServer?.close(force: true));
    super.dispose();
  }

  //  _makePostRequest(token) async {
  ////    print(token);
  //    // set up POST request arguments
  //    String url = 'https://api.dropboxapi.com/2/files/search_v2';
  //    Map<String, String> headers = {
  //      "Authorization": "Bearer $token",
  //      "Content-type": "application/json"
  //    };
  //    String json =
  //        '{"query": "metadata.db", "options":{"filename_only":true, "file_extensions":["db"]}}'; // make POST request
  //    try {
  //      Response response = await post(url, headers: headers, body: json);
  //      return response;
  //    } on SocketException catch (_) {
  //      return null;
  //    }
  //  }

  Future<List<Widget>> refreshLibrary(
    BuildContext context,
    Update update,
    ColorTheme colorTheme,
  ) async {
    //    print("Inside refresh Library for some reason");
    Map<String, String> pathNameMap = Map();
    SharedPreferences sp = await SharedPreferences.getInstance();
    var token = sp.getString('token');

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text("Refreshing Libraries...")));
    //    print("before post request");
    final Response response;
    try {
      response = await _makePostRequest(token);
    } on ClientException catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not contact Dropbox: ${error.message}')),
      );
      return [
        const Text(
          'No Internet',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ];
    }
    //    print("after post request");
    //    print("starting internet check");
    if (response.statusCode == 401) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      deleteToken();
      CacheInvalidator.invalidateImagesCache();
      CacheInvalidator.invalidateDatabaseCache();
      setState(() {
        myFuture = loadingToken();
        update.changeTokenState(false);
        update.updateFlagState(true);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Authentication expired. Please login again.")),
      );
    }
    //    print("Internet check done");
    //Make a map Map<String, String> First value is the base path in lower case
    // Second Value is the name of the Folder(Library)
    // I have to convert string response.body to json
    Map<String, dynamic> responseJson = jsonDecode(response.body);
    if (responseJson['matches'].length != 0) {
      responseJson['matches'].forEach((element) {
        if (element["metadata"]["metadata"]["name"] == "metadata.db") {
          String libPath = element["metadata"]["metadata"]["path_display"];
          libPath = libPath.replaceAll('metadata.db', "");
          List<String> directories =
              element["metadata"]["metadata"]["path_display"].split('/');
          String libName = directories.elementAt(directories.length - 2);
          pathNameMap.putIfAbsent(libPath, () => libName);
        }
      });
      storeIntInSharedPrefs('noOfCalibreLibs', pathNameMap.length);
      pathNameMap.keys.toList().asMap().forEach((index, path) {
        String keyName = 'calibre_lib_path_$index';
        String libName = 'calibre_lib_name_$index';
        storeStringInSharedPrefs(keyName, path);
        storeStringInSharedPrefs(libName, pathNameMap[path]);
      });
      List<Widget> columnChildren = pathNameMap.keys.toList().map((element) {
        return InkWell(
          onTap: selected_lib_name == pathNameMap[element]
              ? () {}
              : () {
                  selectingCalibreLibrary(
                    element,
                    pathNameMap[element],
                    update,
                  );
                  setState(() {
                    myFuture = loadingToken();
                  });
                },
          child: Container(
            alignment: Alignment.bottomLeft,
            padding: EdgeInsets.fromLTRB(70, 5, 20, 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(Icons.cloud_download, color: colorTheme.settingsIcon),
                    SizedBox(width: 10),
                    Text(
                      " ${pathNameMap[element]}",
                      style: TextStyle(
                        fontSize: 15,
                        color: colorTheme.headerText,
                      ),
                    ),
                  ],
                ),
                selected_lib_name == pathNameMap[element]
                    ? Icon(Icons.done, color: colorTheme.settingsIcon)
                    : Container(),
              ],
            ),
          ),
        );
      }).toList();
      //      columnChildren.add(SizedBox(height: 8,));
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      return columnChildren;
    } else {
      //      print("No libs found");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("No libraries found")));
      return [Text("No libraries found")];
    }
  }

  @override
  Widget build(BuildContext context) {
    Update update = Provider.of(context);
    //    BuildContext oldContext = context;
    ColorTheme colorTheme = Provider.of(context);
    //    print(OAuthUtils.codeVerifier);
    return FutureBuilder(
      future: myFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.data == false) {
            return Column(
              children: [
                if (DropboxDropdown.clientId.isEmpty)
                  Text(
                    'Set DROPBOX_APP_KEY when launching the app to connect Dropbox.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  )
                else if (_authorizationInProgress)
                  FilledButton.icon(
                    onPressed: null,
                    icon: const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    label: const Text('Waiting for Dropbox...'),
                  )
                else
                  ConnectButton(() {
                    unawaited(_startDropboxAuthorization());
                  }),
                const SizedBox(height: 8),
                if (DropboxDropdown.clientId.isNotEmpty)
                  Text(
                    'For automatic return, add ${DropboxDropdown.redirectUri} '
                    'to the Dropbox app’s Redirect URIs.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            );
          } else {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // TODO: ADD COMPLETER TO GET LIBRARY LIST
                  RefreshButton(() {
                    deleteToken();
                    CacheInvalidator.invalidateImagesCache();
                    CacheInvalidator.invalidateDatabaseCache();
                    setState(() {
                      myFuture = loadingToken();
                      update.changeTokenState(false);
                      update.updateFlagState(true);
                    });
                  }),
                  ExpansionTile(
                    onExpansionChanged: (bool value) {
                      if (value) {
                        //                              print("tile explanding");
                        setState(() {
                          if (_responseCompleter.isCompleted) {
                            _responseCompleter = Completer();
                          }
                        });
                        _responseCompleter.complete(
                          refreshLibrary(context, update, colorTheme),
                        );
                        //                        print("Getting Expansion Item ");
                      }
                    },
                    title: Card(
                      color: Colors.transparent,
                      elevation: 0.0,
                      child: InkWell(
                        onTap: () {},
                        child: Container(
                          color: Colors.transparent,
                          padding: EdgeInsets.fromLTRB(30, 0, 20, 1),
                          child: Column(
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Icon(
                                    Icons.folder,
                                    color: colorTheme.settingsIcon,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    "Change Library",
                                    style: TextStyle(
                                      color: colorTheme.headerText,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    children: <Widget>[
                      FutureBuilder(
                        future: _responseCompleter.future,
                        builder: (
                          BuildContext context,
                          AsyncSnapshot<List<Widget>> snapshot,
                        ) {
                          if (snapshot.connectionState ==
                              ConnectionState.done) {
                            return Column(
                              children: <Widget>[
                                Column(children: snapshot.data!),
                                SizedBox(height: 7),
                              ],
                            );
                          } else {
                            return Column(
                              children: <Widget>[
                                Center(
                                  child: Text(
                                    'Loading...',
                                    style: TextStyle(
                                      color: colorTheme.headerText,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 7),
                              ],
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  LogoutButton(() {
                    deleteToken();
                    CacheInvalidator.invalidateImagesCache();
                    CacheInvalidator.invalidateDatabaseCache();
                    setState(() {
                      myFuture = loadingToken();
                      update.changeTokenState(false);
                      update.updateFlagState(true);
                    });
                  }),
                  SizedBox(height: 8),
                ],
              ),
            );
          }
        } else {
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}
