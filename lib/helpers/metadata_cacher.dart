import 'dart:convert';

import 'package:calibre_carte/helpers/cache_invalidator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:io';

import '../helpers/db_helper.dart';
import 'dropbox_auth.dart';

class MetadataCacher {
  //Should make a shared preferences helper
  Future<String> getTokenFromPreferences() async {
    return DropboxAuth.getValidAccessToken();
  }

  Future<String?> getSelectedLibPathFromSharedPrefs() async {
    SharedPreferences sp = await SharedPreferences.getInstance();
    return sp.getString('selected_calibre_lib_path');
  }

  Future<Response?> downloadMetadata(String? token, String path) async {
    String url = "https://content.dropboxapi.com/2/files/download";
    Map<String, String> headers = {
      "Authorization": "Bearer $token",
      "Dropbox-API-Arg": jsonEncode({"path": path}),
    };
    try {
      Response response = await post(Uri.parse(url), headers: headers);
      return response;
    } on SocketException catch (_) {
      return null;
    }
  }

  Future<int> downloadAndCacheMetadata({String? token, String? path}) async {
    final selectedPath = path ?? await getSelectedLibPathFromSharedPrefs();
    if (selectedPath == null) {
      throw StateError('No Calibre library is selected.');
    }

    final accessToken = token ?? await getTokenFromPreferences();

    final response =
        await downloadMetadata(accessToken, '${selectedPath}metadata.db');
    if (response == null) return 0;
    //Get the bytes, get the temp directory and write a file in temp
    if (response.statusCode == 200) {
      await DatabaseHelper.deleteDb();
      await CacheInvalidator.invalidateImagesCache();
      List<int> bytes = response.bodyBytes;
      String tempDir = await getDatabasesPath();
      String pathMetadata = join(tempDir + "/metadata.db");
      await File(pathMetadata).writeAsBytes(bytes, flush: true);
      return 1;
    } else {
      return response.statusCode;
    }
  }

  Future<bool> checkIfCachedFileExists() async {
    Directory tempDir = await getTemporaryDirectory();
    String pathMetadata = join(tempDir.path + "metadata.db");
    return await File(pathMetadata).exists();
  }

  Future<String> returnCachedMetadataPath(bookID) async {
    Directory tempDir = await getTemporaryDirectory();
    String pathMetadata = join(tempDir.path + "/cover_$bookID.jpg");
    return pathMetadata;
  }
}
