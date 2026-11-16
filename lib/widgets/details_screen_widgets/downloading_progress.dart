import 'dart:convert';

import 'package:calibre_carte/helpers/book_downloader.dart';
import 'package:calibre_carte/homepage.dart';
import 'package:material_ui/material_ui.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DownloadingProgress extends StatefulWidget {
  final String? relativePath;
  final String fileName;
  final BuildContext oldContext;
  final VoidCallback logout;

  DownloadingProgress(
    this.relativePath,
    this.fileName,
    this.oldContext,
    this.logout, {
    super.key,
  });

  @override
  _DownloadingProgressState createState() => _DownloadingProgressState();
}

class _DownloadingProgressState extends State<DownloadingProgress> {
  double? _progress = 0;
  final String url = 'https://content.dropboxapi.com/2/files/download';
  final CancelToken cancelToken = CancelToken();

  Future<int> downloadFile() async {
    final downloader = BookDownloader();
    final token = await downloader.getTokenFromPreferences();
    final basePath = await downloader.getSelectedLibPathFromSharedPrefs();
    final absPath = '$basePath${widget.relativePath!}/${widget.fileName}';
    final savePath =
        await downloader.returnFileDirectoryExternal(widget.fileName);

    final headers = {
      'Authorization': 'Bearer $token',
      'Dropbox-API-Arg': jsonEncode({'path': absPath}),
    };

    try {
      await Dio().download(
        url,
        savePath,
        options: Options(headers: headers),
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (!mounted) return;
          setState(() {
            _progress = total > 0
                ? (received / total).clamp(0.0, 1.0).toDouble()
                : null;
          });
        },
      );
      return 0;
    } on DioException catch (e) {
      return e.response?.statusCode ?? -1;
    }
  }

  void _cancelDownload() {
    cancelToken.cancel("cancelled");
  }

  Future<void> deleteToken() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    pref.remove('token');
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    downloadFile().then((value) {
      if (!mounted) return;
      if (value == 401) {
        widget.logout();
        Navigator.of(context).push(MaterialPageRoute(builder: (context) {
          return MyHomePage();
        }));
      } else if (value == 0) {
        Navigator.of(context).pop("Download Finished!");
      } else {
        Navigator.pop(context, "Download Failed.");
      }
    });
  }

  textScaleFactor(BuildContext context) {
    if (MediaQuery.of(context).size.height > 610) {
      return MediaQuery.of(context).textScaler.scale(1).clamp(0.6, 1.0);
    } else {
      return MediaQuery.of(context).textScaler.scale(1).clamp(0.6, 0.85);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScaleFactor(context))),
      child: PopScope(
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
                  _progress == null
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
              onPressed: _cancelDownload,
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
