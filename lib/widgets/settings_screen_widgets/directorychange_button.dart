import 'dart:io';

import 'package:calibre_carte/helpers/data_provider.dart';
import 'package:calibre_carte/models/data.dart';
import 'package:calibre_carte/providers/color_theme_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DirectoryChange extends StatelessWidget {
  const DirectoryChange({super.key});

  Future<void> selectDirectory() async {
    final String? selectedPath = await FilePicker.getDirectoryPath();
    if (selectedPath == null) return;

    final Directory newDirectory = Directory(selectedPath);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? oldDirectoryPath = prefs.getString("downloaded_directory");
    await prefs.setString("downloaded_directory", newDirectory.path);
    if (oldDirectoryPath == null) return;

    List<Data> dataList = await DataProvider.getAllBooksData();
    for (final element in dataList) {
      String fNameWithExt = element.name! + '.' + element.format!.toLowerCase();
      String pathToSearch = oldDirectoryPath + '/$fNameWithExt';
      String pathToMove = newDirectory.path + '/$fNameWithExt';
      if (File(pathToSearch).existsSync()) {
        File(pathToSearch).renameSync(pathToMove);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorTheme colorTheme = Provider.of<ColorTheme>(context);
    return ListTile(
      leading: Icon(Icons.folder_open_rounded, color: colorTheme.settingsIcon),
      title: const Text('Download directory'),
      subtitle: const Text('Choose where offline books are saved'),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: selectDirectory,
    );
  }
}
