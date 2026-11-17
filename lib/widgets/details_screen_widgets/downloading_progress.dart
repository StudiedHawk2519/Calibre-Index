import 'dart:convert';
import 'dart:io';

import 'package:calibre_carte/helpers/book_downloader.dart';
import 'package:dio/dio.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class DownloadingProgress extends StatefulWidget {
  final String? relativePath;
  final String fileName;
  final VoidCallback logout;

  const DownloadingProgress(
    this.relativePath,
    this.fileName,
    this.logout, {
    super.key,
  });

  @override
  State<DownloadingProgress> createState() => _DownloadingProgressState();
}

class _DownloadingProgressState extends State<DownloadingProgress> {
  double? _progress;
  final CancelToken _cancelToken = CancelToken();
  bool _cancelRequested = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _downloadFile();
  }

  Future<void> _downloadFile() async {
    String? partialPath;
    try {
      final downloader = BookDownloader();
      final token = await downloader.getTokenFromPreferences();
      final libraryPath = await downloader.getSelectedLibPathFromSharedPrefs();
      final dropboxPath = BookDownloader.buildDropboxFilePath(
        libraryPath,
        widget.relativePath,
        widget.fileName,
      );
      final temporaryDirectory = await getTemporaryDirectory();
      partialPath = path.join(
        temporaryDirectory.path,
        '${DateTime.now().microsecondsSinceEpoch}_${path.basename(widget.fileName)}',
      );
      await Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(minutes: 5),
        ),
      ).download(
        'https://content.dropboxapi.com/2/files/download',
        partialPath,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Dropbox-API-Arg': jsonEncode({'path': dropboxPath}),
          },
        ),
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (!mounted) return;
          setState(() {
            _progress =
                total > 0 ? (received / total).clamp(0.0, 1.0).toDouble() : null;
          });
        },
      );

      if (mounted) {
        setState(() {
          _saving = true;
          _progress = null;
        });
      }
      await downloader.saveDownloadedFile(
        partialPath,
        widget.fileName,
        mimeType: _mimeType(widget.fileName),
      );
      await _removePartialFile(partialPath);
      _finish('Download Finished!');
    } on DioException catch (error) {
      await _removePartialFile(partialPath);
      final statusCode = error.response?.statusCode;
      if (statusCode == 401) {
        widget.logout();
        _finish('Dropbox session expired. Reconnect in Settings and try again.');
      } else if (CancelToken.isCancel(error)) {
        _finish('Download canceled.');
      } else {
        _finish(_formatDropboxError(error));
      }
    } on Exception catch (error, stackTrace) {
      await _removePartialFile(partialPath);
      debugPrint('Could not download book: $error\n$stackTrace');
      _finish('Download failed: $error');
    }
  }

  String _mimeType(String fileName) {
    switch (path.extension(fileName).toLowerCase()) {
      case '.epub':
        return 'application/epub+zip';
      case '.pdf':
        return 'application/pdf';
      case '.mobi':
        return 'application/x-mobipocket-ebook';
      case '.azw':
      case '.azw3':
        return 'application/vnd.amazon.ebook';
      case '.txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }

  String _formatDropboxError(DioException error) {
    final statusCode = error.response?.statusCode;
    final responseData = error.response?.data;
    if (responseData is Map<String, dynamic>) {
      final message =
          responseData['error_summary'] ?? responseData['error_description'];
      if (message != null) return 'Dropbox download failed: $message';
    } else if (responseData is String && responseData.isNotEmpty) {
      try {
        final decoded = jsonDecode(responseData);
        if (decoded is Map<String, dynamic>) {
          final message =
              decoded['error_summary'] ?? decoded['error_description'];
          if (message != null) return 'Dropbox download failed: $message';
        }
      } on FormatException {
        // Fall through to the HTTP status message.
      }
    }
    if (statusCode != null) {
      return 'Dropbox download failed (HTTP $statusCode).';
    }
    return 'Download failed: ${error.message ?? 'Could not reach Dropbox.'}';
  }

  Future<void> _removePartialFile(String? filePath) async {
    if (filePath == null) return;
    try {
      final file = File(filePath);
      if (await file.exists()) await file.delete();
    } on FileSystemException catch (error) {
      debugPrint('Could not remove incomplete download: $error');
    }
  }

  void _finish(String result) {
    if (mounted) Navigator.of(context).pop(result);
  }

  void _cancelDownload() {
    if (_cancelRequested || _saving) return;
    setState(() => _cancelRequested = true);
    _cancelToken.cancel('Download canceled by user.');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: scheme.surfaceContainerHigh,
        title: const Text('Downloading book'),
        content: SizedBox(
          width: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _cancelRequested
                    ? 'Canceling download…'
                    : _saving
                        ? 'Saving book to the selected folder…'
                    : _progress == null
                        ? 'Preparing download…'
                        : '${(_progress! * 100).round()}% downloaded',
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: _progress,
                minHeight: 8,
                borderRadius: BorderRadius.circular(8),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _cancelRequested || _saving ? null : _cancelDownload,
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
