import 'dart:async';
import 'dart:convert';

import 'package:calibre_carte/helpers/metadata_cacher.dart';
import 'package:calibre_carte/providers/update_provider.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart';

class DropboxAuthentication extends StatefulWidget {
  final String selectedUrl;
  final BuildContext? oldContext;

  DropboxAuthentication({required this.selectedUrl, this.oldContext});

  @override
  _DropboxAuthenticationState createState() =>
      _DropboxAuthenticationState(selectedUrl);
}

class _DropboxAuthenticationState extends State<DropboxAuthentication> {
  final url;
  late final WebViewController _controller;
  final key = UniqueKey();
  int _stackToView = 1;

  _makePostRequest(token) async {
//    print(token);
    // set up POST request arguments
    String url = 'https://api.dropboxapi.com/2/files/search_v2';
    Map<String, String> headers = {
      "Authorization": "Bearer $token",
      "Content-type": "application/json"
    };
    String json =
        '{"query": "metadata.db", "options":{"filename_only":true, "file_extensions":["db"]}}'; // make POST request
    Response response =
        await post(Uri.parse(url), headers: headers, body: json);
    return response;
  }

  //Let's try and figure out if I can attach a listener and then parse and do something when I finally get a URL back

  void _handleLoad(String value) {
    setState(() {
      _stackToView = 0;
    });
  }

  NavigationDecision _handleNavigationRequest(NavigationRequest request) {
    if (!request.url.startsWith('calibrecarte://dropbox')) {
      return NavigationDecision.navigate;
    }

    final update = Provider.of<Update>(context, listen: false);
    final uri = Uri.parse(request.url);
    final tempUri = Uri.parse('http://test.com?${uri.fragment}');
    final String? token = tempUri.queryParameters['access_token'];
    if (token == null || token.isEmpty) {
      return NavigationDecision.prevent;
    }

    final Map<String, String> pathNameMap = {};
    _makePostRequest(token).then((response) {
      final Map<String, dynamic> responseJson = jsonDecode(response.body);
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
          final String keyName = 'calibre_lib_path_$index';
          final String libName = 'calibre_lib_name_$index';
          storeStringInSharedPrefs(keyName, path);
          storeStringInSharedPrefs(libName, pathNameMap[path]!);
        });

        storeStringInSharedPrefs(
          'selected_calibre_lib_path',
          pathNameMap.keys.first,
        );
        storeStringInSharedPrefs(
          'selected_calibre_lib_name',
          pathNameMap.values.first,
        );
        if (pathNameMap.length > 1) {
          final List<Widget> columnChildren =
              pathNameMap.keys.toList().map((element) {
            return InkWell(
              onTap: () {
                _showLoading(context);
                selectingCalibreLibrary(
                    element, pathNameMap[element], update, token);
              },
              child: Container(
                padding: EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Icon(Icons.folder, color: Color(0xffFED962)),
                    SizedBox(width: 10),
                    Text(
                      pathNameMap[element]!,
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xff002242),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList();
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
                              color: Color(0xff002242),
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
              'selected_calibre_lib_path', pathNameMap.keys.first);
          storeStringInSharedPrefs(
              'selected_calibre_lib_name', pathNameMap.values.first);
          MetadataCacher().downloadAndCacheMetadata(token: token).then((val) {
            if (val == 1) {
              storeStringInSharedPrefs('token', token);
              update.changeTokenState(true);
              update.updateFlagState(true);
            }
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No Calibre libraries found")),
        );
        Navigator.of(context).pop();
      }
    });

    return NavigationDecision.prevent;
  }

  _DropboxAuthenticationState(this.url);

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: _handleNavigationRequest,
          onPageFinished: _handleLoad,
        ),
      );
    _controller.loadRequest(Uri.parse(widget.selectedUrl));
  }

  Future<void> storeStringInSharedPrefs(key, val) async {
//    print("Storing token");
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setString(key, val);
  }

  Future<void> storeIntInSharedPrefs(key, val) async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    sp.setInt(key, val);
  }

  selectingCalibreLibrary(key, val, update, token) {
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

  _showLoading(BuildContext context) {
    showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return PopScope(
              canPop: false,
              child: SimpleDialog(
                  key: UniqueKey(),
                  backgroundColor: Colors.black54,
                  children: <Widget>[
                    Center(
                      child: Column(children: [
                        CircularProgressIndicator(),
                        SizedBox(
                          height: 10,
                        ),
                        Text(
                          "Loading Calibre library",
                          style: TextStyle(color: Colors.blueAccent),
                        )
                      ]),
                    )
                  ]));
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xff002242),
        iconTheme: IconThemeData(
          color: Colors.white, //change your color here
        ),
        title: Text('Dropbox Login', style: TextStyle(color: Colors.white)),
      ),
      body: IndexedStack(
        index: _stackToView,
        children: <Widget>[
          Text('Redirecting to dropbox'),
          WebViewWidget(controller: _controller),
          Container(
            color: Colors.white,
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ],
      ),
    );
  }
}
