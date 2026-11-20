import 'package:calibre_carte/helpers/cache_invalidator.dart';
import 'package:calibre_carte/helpers/data_provider.dart';
import 'package:calibre_carte/models/data.dart';
import 'package:calibre_carte/providers/color_theme_provider.dart';
import 'package:calibre_carte/providers/update_provider.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'downloading_progress.dart';

class SelectFormatDialog extends StatefulWidget {
  final int? bookId;
  final String? relativePath;

  const SelectFormatDialog(this.bookId, this.relativePath, {super.key});

  @override
  _SelectFormatDialogState createState() => _SelectFormatDialogState();
}

class _SelectFormatDialogState extends State<SelectFormatDialog> {
  Future? myFuture;
  List<Map<String, String?>> dataFormatsFileNameMap = [];

  Future<void> deleteToken() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    await pref.remove('token');
    await pref.remove('dropbox_refresh_token');
    await pref.remove('dropbox_token_expiry');
  }

  Future<void> getBookDataFormats() async {
    List<Data> dataList = await DataProvider.getDataByBookID(widget.bookId);

    dataList.forEach((element) {
      String fileNameWithExtension =
          element.name! + '.' + element.format!.toLowerCase();
      Map<String, String?> tempMap = {
        "format": element.format,
        "name": fileNameWithExtension
      };
      dataFormatsFileNameMap.add(tempMap);
    });
  }

  Future<void> bookDownloader(
    String fileName,
    BuildContext context,
    VoidCallback logout,
  ) async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) =>
          DownloadingProgress(widget.relativePath, fileName, logout),
    );
    if (context.mounted) Navigator.of(context).pop(result);
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    myFuture = getBookDataFormats();
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
    Update update = Provider.of(context);
    ColorTheme colorTheme = Provider.of(context);
    return FutureBuilder(
      future: myFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(textScaleFactor(context))),
            child: AlertDialog(
              backgroundColor: colorTheme.alertBoxColor,
              title: Text("Select Format",
                  style: TextStyle(color: colorTheme.headerText)),
              content: Column(
                children: dataFormatsFileNameMap.map((element) {
                  return TextButton(
                    child: Text(element["format"]!,
                        style: TextStyle(color: colorTheme.headerText)),
                    onPressed: () async {
                      await bookDownloader(element["name"]!, context, () async {
                        await deleteToken();
                        await CacheInvalidator.invalidateImagesCache();
                        await CacheInvalidator.invalidateDatabaseCache();
                        if (!mounted) return;
                        update.changeTokenState(false);
                        update.updateFlagState(true);
                      });
                    },
                  );
                }).toList() as List<Widget>,
                mainAxisSize: MainAxisSize.min,
              ),
            ),
          );
        } else {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }
}
