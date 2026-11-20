import 'dart:convert';
import 'dart:io';

import 'package:calibre_carte/helpers/dropbox_auth.dart';
import 'package:http/http.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ImageCacher {
  static final Map<String, Future<bool>> _pendingCoverDownloads = {};
  static final Map<String, Future<String?>> _pendingThumbnailDownloads = {};
  static final Map<String, String> _readyCoverPaths = {};
  static final Map<String, String> _readyThumbnailPaths = {};

  static String _memoryKey(String relativePath, int bookId) =>
      '$bookId|$relativePath';

  static String? cachedCoverPath(String relativePath, int bookId) =>
      _readyCoverPaths[_memoryKey(relativePath, bookId)];

  static String? cachedThumbnailPath(String relativePath, int bookId) =>
      _readyThumbnailPaths[_memoryKey(relativePath, bookId)];

  static void clearMemoryCache() {
    _readyCoverPaths.clear();
    _readyThumbnailPaths.clear();
  }

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

  Future<Response> downloadThumbnailImage(String token, String path) {
    return post(
      Uri.parse('https://content.dropboxapi.com/2/files/get_thumbnail'),
      headers: {
        'Authorization': 'Bearer $token',
        'Dropbox-API-Arg': jsonEncode({
          'path': path,
          'format': 'jpeg',
          'size': 'w256h256',
          'mode': 'bestfit',
        }),
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

  Future<File> _thumbnailFile(String relativePath, int bookId) async {
    final coverFile = await _coverFile(relativePath, bookId);
    return File(
      join(dirname(coverFile.path), 'thumbnail_${basename(coverFile.path)}'),
    );
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

  Future<String?> downloadAndCacheImageThumbnail(
    String? relativePath,
    int? bookId,
  ) async {
    if (relativePath == null || bookId == null) return null;
    final cacheFile = await _thumbnailFile(relativePath, bookId);
    final cachePath = cacheFile.path;
    if (await cacheFile.exists()) {
      _readyThumbnailPaths[_memoryKey(relativePath, bookId)] = cachePath;
      return cachePath;
    }

    final pending = _pendingThumbnailDownloads[cachePath];
    if (pending != null) return pending;

    final download = () async {
      final token = await DropboxAuth.getValidAccessToken();
      final libraryPath = await getSelectedLibPathFromSharedPrefs();
      if (libraryPath == null) return null;
      final response = await downloadThumbnailImage(
        token,
        '$libraryPath$relativePath/cover.jpg',
      );
      if (response.statusCode != 200) return null;
      await cacheFile.writeAsBytes(response.bodyBytes, flush: true);
      _readyThumbnailPaths[_memoryKey(relativePath, bookId)] = cachePath;
      return cachePath;
    }();

    _pendingThumbnailDownloads[cachePath] = download;
    try {
      return await download;
    } finally {
      if (identical(_pendingThumbnailDownloads[cachePath], download)) {
        _pendingThumbnailDownloads.remove(cachePath);
      }
    }
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

  Future<String?> findCachedThumbnailPath(
    String relativePath,
    int bookId,
  ) async {
    final file = await _thumbnailFile(relativePath, bookId);
    if (!await file.exists()) return null;
    _readyThumbnailPaths[_memoryKey(relativePath, bookId)] = file.path;
    return file.path;
  }

  Future<String> returnCachedImagePath(String relativePath, int bookId) async {
    final file = await _coverFile(relativePath, bookId);
    _readyCoverPaths[_memoryKey(relativePath, bookId)] = file.path;
    return file.path;
  }
}
