import 'dart:convert';
import 'dart:io';

import 'package:calibre_carte/helpers/dropbox_auth.dart';
import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ImageCacher {
  static final Map<String, Future<bool>> _pendingCoverDownloads = {};
  static final Map<String, String> _readyCoverPaths = {};

  static String _memoryKey(String relativePath, int bookId) =>
      '$bookId|$relativePath';

  static String? cachedCoverPath(String relativePath, int bookId) =>
      _readyCoverPaths[_memoryKey(relativePath, bookId)];

  static void clearMemoryCache() => _readyCoverPaths.clear();

  Future<String?> getSelectedLibPathFromSharedPrefs() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString('selected_calibre_lib_path');
  }

  Future<Response> downloadCoverImage(String token, String path) {
    return post(
      Uri.parse('https://content.dropboxapi.com/2/files/download'),
      headers: {
        'Authorization': 'Bearer $token',
        'Dropbox-API-Arg': jsonEncode({'path': path}),
      },
    );
  }

  Future<Response> downloadThumbnailImage(String? token, String path) {
    return post(
      Uri.parse('https://content.dropboxapi.com/2/files/get_thumbnail'),
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
        'Dropbox-API-Arg': jsonEncode({'path': path}),
      },
    );
  }

  Future<Directory> _coverCacheDirectory() async {
    final supportDirectory = await getApplicationSupportDirectory();
    final cacheDirectory =
        Directory(join(supportDirectory.path, 'cover_cache'));
    await cacheDirectory.create(recursive: true);
    return cacheDirectory;
  }

  int _stableHash(String value) {
    var hash = 0x811c9dc5;
    for (final codeUnit in value.codeUnits) {
      hash = ((hash ^ codeUnit) * 0x01000193) & 0xFFFFFFFF;
    }
    return hash;
  }

  Future<File> _coverFile(String relativePath, int bookId) async {
    final libraryPath = await getSelectedLibPathFromSharedPrefs() ?? '';
    final cacheDirectory = await _coverCacheDirectory();
    final cacheKey = _stableHash('$libraryPath/$relativePath/$bookId');
    return File(
        join(cacheDirectory.path, 'cover_${cacheKey.toRadixString(16)}.jpg'));
  }

  Future<bool> downloadAndCacheImage(
    String? relativePath,
    int? bookId,
  ) async {
    if (relativePath == null || bookId == null) return false;

    final token = await DropboxAuth.getValidAccessToken();
    final libraryPath = await getSelectedLibPathFromSharedPrefs();
    if (libraryPath == null) return false;

    final cacheFile = await _coverFile(relativePath, bookId);
    if (await cacheFile.exists()) {
      _readyCoverPaths[_memoryKey(relativePath, bookId)] = cacheFile.path;
      return true;
    }

    final cachePath = cacheFile.path;
    final pendingDownload = _pendingCoverDownloads[cachePath];
    if (pendingDownload != null) return pendingDownload;

    final download = () async {
      final response = await downloadCoverImage(
        token,
        '$libraryPath$relativePath/cover.jpg',
      );
      if (response.statusCode != 200) return false;
      await cacheFile.writeAsBytes(response.bodyBytes, flush: true);
      _readyCoverPaths[_memoryKey(relativePath, bookId)] = cacheFile.path;
      return true;
    }();

    _pendingCoverDownloads[cachePath] = download;
    try {
      return await download;
    } finally {
      if (identical(_pendingCoverDownloads[cachePath], download)) {
        _pendingCoverDownloads.remove(cachePath);
      }
    }
  }

  Future<void> downloadAndCacheImageThumbnail(
    String? relativePath,
    int? bookId,
  ) async {
    if (relativePath == null || bookId == null) return;
    final token = await DropboxAuth.getValidAccessToken();
    final basePath = await getSelectedLibPathFromSharedPrefs();
    if (basePath == null) return;
    final response = await downloadThumbnailImage(
      token,
      '$basePath$relativePath/cover.jpg',
    );
    if (response.statusCode != 200) return;

    final tempDirectory = await getTemporaryDirectory();
    final thumbnailPath = join(tempDirectory.path, 'thumbnail_$bookId.jpg');
    await File(thumbnailPath).writeAsBytes(response.bodyBytes, flush: true);
  }

  Future<bool> checkIfCachedFileExists(
    String? relativePath,
    int? bookId,
  ) async {
    if (relativePath == null || bookId == null) return false;
    final file = await _coverFile(relativePath, bookId);
    final exists = await file.exists();
    if (exists) _readyCoverPaths[_memoryKey(relativePath, bookId)] = file.path;
    return exists;
  }

  Future<bool> checkIfCachedThumbnailExists(int bookId) async {
    final tempDirectory = await getTemporaryDirectory();
    return File(join(tempDirectory.path, 'thumbnail_$bookId.jpg')).exists();
  }

  Future<String> returnCachedImagePath(String relativePath, int bookId) async {
    final file = await _coverFile(relativePath, bookId);
    _readyCoverPaths[_memoryKey(relativePath, bookId)] = file.path;
    return file.path;
  }

  Future<String> returnCachedThumbnailPath(int bookId) async {
    final tempDirectory = await getTemporaryDirectory();
    return join(tempDirectory.path, 'thumbnail_$bookId.jpg');
  }
}
