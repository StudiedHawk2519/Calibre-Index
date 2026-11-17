import 'dart:io';

import 'package:flutter/services.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;

class BookDownloader {
  static const MethodChannel _downloadStorageChannel =
      MethodChannel('calibre_index/download_storage');
  static final Map<String, Future<Set<String>>> _directoryFileNames = {};

  static void invalidateDownloadDirectoryCache() {
    _directoryFileNames.clear();
  }

  Future<String?> requestDownloadDirectory() {
    return _downloadStorageChannel.invokeMethod<String>('pickDirectory');
  }

  Future<String> getTokenFromPreferences() async {
    final preferences = await SharedPreferences.getInstance();
    final token = preferences.getString('token');
    if (token == null || token.isEmpty) {
      throw StateError('Connect Dropbox before downloading a book.');
    }
    return token;
  }

  Future<String> getSelectedLibPathFromSharedPrefs() async {
    final preferences = await SharedPreferences.getInstance();
    final libraryPath = preferences.getString('selected_calibre_lib_path');
    if (libraryPath == null || libraryPath.isEmpty) {
      throw StateError('Select a Calibre library before downloading a book.');
    }
    return libraryPath;
  }

  static String buildDropboxFilePath(
    String libraryPath,
    String? relativePath,
    String fileName,
  ) {
    final segments = [
      ...libraryPath.split('/'),
      ...(relativePath ?? '').split('/'),
      ...fileName.split('/'),
    ].where((segment) => segment.isNotEmpty);
    return '/${segments.join('/')}';
  }

  Future<bool> checkIfDownloadedFileExists(String fileName) async {
    final directoryUri = await _getSelectedDirectoryUri();
    if (directoryUri != null) {
      if ((await _getDirectoryFileNames(directoryUri)).contains(fileName)) {
        return true;
      }
    }

    final filePath = await _tryReturnLegacyFilePath(fileName);
    return filePath != null && await File(filePath).exists();
  }

  Future<bool> checkAndDeleteIfDownloadedFilesExists(String fileName) async {
    var deleted = false;
    final directoryUri = await _getSelectedDirectoryUri();
    if (directoryUri != null) {
      deleted = await _downloadStorageChannel.invokeMethod<bool>(
            'deleteFile',
            {'directoryUri': directoryUri, 'fileName': fileName},
          ) ??
          false;
      if (deleted) invalidateDownloadDirectoryCache();
    }

    final filePath = await _tryReturnLegacyFilePath(fileName);
    if (filePath != null) {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        deleted = true;
      }
    }
    return deleted;
  }

  Future<bool> openDownloadedFile(String fileName) async {
    final directoryUri = await _getSelectedDirectoryUri();
    if (directoryUri != null &&
        (await _getDirectoryFileNames(directoryUri)).contains(fileName)) {
      return await _downloadStorageChannel.invokeMethod<bool>(
            'openFile',
            {'directoryUri': directoryUri, 'fileName': fileName},
          ) ??
          false;
    }

    final filePath = await _tryReturnLegacyFilePath(fileName);
    if (filePath == null || !await File(filePath).exists()) return false;
    final result = await OpenFile.open(filePath);
    return result.type != ResultType.noAppToOpen;
  }

  Future<void> saveDownloadedFile(
    String sourcePath,
    String fileName, {
    String mimeType = 'application/octet-stream',
  }) async {
    final directoryUri = await _getSelectedDirectoryUri();
    if (directoryUri != null) {
      final saved = await _downloadStorageChannel.invokeMethod<bool>(
        'writeFile',
        {
          'directoryUri': directoryUri,
          'sourcePath': sourcePath,
          'fileName': fileName,
          'mimeType': mimeType,
        },
      );
      if (saved != true) {
        throw StateError('The selected folder did not save the downloaded book.');
      }
      invalidateDownloadDirectoryCache();
      return;
    }

    final filePath = await returnFileDirectoryExternal(fileName);
    await Directory(path.dirname(filePath)).create(recursive: true);
    await File(sourcePath).copy(filePath);
  }

  Future<Set<String>> _getDirectoryFileNames(String directoryUri) {
    return _directoryFileNames.putIfAbsent(
      directoryUri,
      () async {
        final names = await _downloadStorageChannel.invokeListMethod<String>(
          'listFiles',
          {'directoryUri': directoryUri},
        );
        return names?.toSet() ?? <String>{};
      },
    );
  }

  Future<String> returnFileDirectory(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    return path.join(directory.path, fileName);
  }

  Future<String> returnFileDirectoryExternal(String fileName) async {
    final filePath = await _tryReturnLegacyFilePath(fileName);
    if (filePath == null) {
      throw StateError('Choose a download folder in Settings first.');
    }
    return filePath;
  }

  Future<String?> _getSelectedDirectoryUri() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString('downloaded_directory_uri');
  }

  Future<String?> _tryReturnLegacyFilePath(String fileName) async {
    final preferences = await SharedPreferences.getInstance();
    final directory = preferences.getString('downloaded_directory');
    if (directory == null || directory.isEmpty) return null;
    return path.join(directory, fileName);
  }
}
