import 'package:calibre_carte/helpers/book_downloader.dart';
import 'package:calibre_carte/helpers/data_provider.dart';
import 'package:calibre_carte/models/data.dart';
import 'package:material_ui/material_ui.dart';

class DownloadIcon extends StatelessWidget {
  final int? bookId;

  const DownloadIcon(this.bookId);

  Future<bool> _checkIfLocalCopyExists() async {
    final List<Data> dataList = await DataProvider.getDataByBookID(bookId);
    final BookDownloader downloader = BookDownloader();

    for (final data in dataList) {
      final String? name = data.name;
      final String? format = data.format;
      if (name == null || format == null) continue;

      final String fileName = '$name.${format.toLowerCase()}';
      if (await downloader.checkIfDownloadedFileExists(fileName)) {
        return true;
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FutureBuilder<bool>(
      future: _checkIfLocalCopyExists(),
      builder: (context, snapshot) {
        if (snapshot.data != true) return const SizedBox.shrink();
        return Tooltip(
          message: 'Available offline',
          child: Icon(
            Icons.download_done_rounded,
            color: scheme.primary,
            size: 20,
          ),
        );
      },
    );
  }
}
