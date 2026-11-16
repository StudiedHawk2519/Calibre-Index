import 'package:calibre_carte/helpers/book_downloader.dart';
import 'package:calibre_carte/models/books.dart';
import 'package:calibre_carte/widgets/details_screen_widgets/open_format_dialog.dart';
import 'package:calibre_carte/widgets/details_screen_widgets/select_format_dialog.dart';
import 'package:material_ui/material_ui.dart';

class DetailsSidebar extends StatelessWidget {
  final int bookId;
  final Books bookDetails;
  final bool downloaded;
  final List<Map<String, String>> dataFormatsFileNameMap;
  final VoidCallback checkCopies;

  const DetailsSidebar({
    super.key,
    required this.dataFormatsFileNameMap,
    required this.downloaded,
    required this.bookId,
    required this.bookDetails,
    required this.checkCopies,
  });

  Future<void> _deleteAllLocalCopies() async {
    final BookDownloader downloader = BookDownloader();
    for (final file in dataFormatsFileNameMap) {
      await downloader.checkAndDeleteIfDownloadedFilesExists(file['name']!);
    }
    checkCopies();
  }

  Widget _actionTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color containerColor,
    required Color foregroundColor,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final Color background =
        enabled ? containerColor : scheme.surfaceContainerLow;
    final Color content =
        enabled ? foregroundColor : scheme.onSurface.withValues(alpha: 0.38);

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(22),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 28, color: content),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: content,
                        fontWeight: FontWeight.w600,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 96,
      child: Row(
        children: [
          _actionTile(
            context,
            icon: Icons.download_rounded,
            label: 'Download',
            containerColor: scheme.primaryContainer,
            foregroundColor: scheme.onPrimaryContainer,
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => SelectFormatDialog(bookId, bookDetails.path),
              ).then((_) => checkCopies());
            },
          ),
          _actionTile(
            context,
            icon: Icons.menu_book_rounded,
            label: 'Open book',
            containerColor: scheme.tertiaryContainer,
            foregroundColor: scheme.onTertiaryContainer,
            onTap: () => showDialog(
              context: context,
              builder: (_) => OpenFormatDialog(
                bookId,
                bookDetails.path,
                context,
              ),
            ),
            enabled: downloaded,
          ),
          _actionTile(
            context,
            icon: Icons.delete_outline_rounded,
            label: 'Remove offline',
            containerColor: scheme.errorContainer,
            foregroundColor: scheme.onErrorContainer,
            onTap: _deleteAllLocalCopies,
            enabled: downloaded,
          ),
        ],
      ),
    );
  }
}
