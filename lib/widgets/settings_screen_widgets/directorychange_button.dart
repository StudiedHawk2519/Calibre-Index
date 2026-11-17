import 'dart:io';

import 'package:calibre_carte/helpers/book_downloader.dart';
import 'package:calibre_carte/helpers/data_provider.dart';
import 'package:calibre_carte/models/data.dart';
import 'package:calibre_carte/providers/color_theme_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DirectoryChange extends StatelessWidget {
  const DirectoryChange({super.key});

  Future<void> selectDirectory(BuildContext context) async {
    try {
      if (Platform.isAndroid) {
        final directoryUri = await BookDownloader().requestDownloadDirectory();
        if (directoryUri == null) return;

        final preferences = await SharedPreferences.getInstance();
        await preferences.setString('downloaded_directory_uri', directoryUri);
        BookDownloader.invalidateDownloadDirectoryCache();
        if (context.mounted) {
          _showMessage(context, 'Download folder selected.');
        }
        return;
      }

    final String? selectedPath = await FilePicker.getDirectoryPath();
    if (selectedPath == null) return;

      final Directory newDirectory = Directory(selectedPath);
      await newDirectory.create(recursive: true);
      final probeFile = File(
        path.join(
          newDirectory.path,
          '.calibre-index-write-test-${DateTime.now().microsecondsSinceEpoch}',
        ),
      );
      await probeFile.writeAsBytes(const [], flush: true);
      await probeFile.delete();

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? oldDirectoryPath = prefs.getString('downloaded_directory');
      await prefs.setString('downloaded_directory', newDirectory.path);
      await prefs.remove('downloaded_directory_uri');
      BookDownloader.invalidateDownloadDirectoryCache();
    if (oldDirectoryPath == null) return;

      final List<Data> dataList = await DataProvider.getAllBooksData();
      for (final element in dataList) {
        final name = element.name;
        final format = element.format;
        if (name == null || format == null) continue;

        final fileName = '$name.${format.toLowerCase()}';
        final source = File(path.join(oldDirectoryPath, fileName));
        if (await source.exists()) {
          await source.rename(path.join(newDirectory.path, fileName));
        }
      }
    } on PlatformException catch (error) {
      if (context.mounted) {
        _showMessage(context, 'Could not select download folder: ${error.message ?? error.code}');
      }
    } on FileSystemException catch (error) {
      if (context.mounted) {
        _showMessage(context, 'Could not use that folder: ${error.message}');
      }
    } on Exception catch (error) {
      if (context.mounted) {
        _showMessage(context, 'Could not change download folder: $error');
      }
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ColorTheme colorTheme = Provider.of<ColorTheme>(context);
    return ListTile(
      leading: Icon(Icons.folder_open_rounded, color: colorTheme.settingsIcon),
      title: const Text('Download directory'),
      subtitle: const Text('Choose a folder for offline books'),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => selectDirectory(context),
    );
  }
}
