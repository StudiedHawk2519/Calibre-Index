import 'package:calibre_carte/helpers/book_downloader.dart';
import 'package:calibre_carte/models/books.dart';
import 'package:calibre_carte/widgets/details_screen_widgets/open_format_dialog.dart';
import 'package:calibre_carte/widgets/details_screen_widgets/select_format_dialog.dart';
import 'package:material_ui/material_ui.dart';

class DetailsSidebar extends StatelessWidget {
  final double height;
  final int bookId;
  final Books bookDetails;
  final bool downloaded;
  final List<Map<String, String>> dataFormatsFileNameMap;
  final VoidCallback checkCopies;

  const DetailsSidebar({
    super.key,
    required this.height,
    required this.dataFormatsFileNameMap,
    required this.downloaded,
    required this.bookId,
    required this.bookDetails,
    required this.checkCopies,
  });

  Future<void> _deleteAllLocalCopies() async {
    final downloader = BookDownloader();
    for (final file in dataFormatsFileNameMap) {
      await downloader.checkAndDeleteIfDownloadedFilesExists(file['name']!);
    }
    checkCopies();
  }

  Future<void> _startDownload(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => SelectFormatDialog(bookId, bookDetails.path),
    );
    if (!context.mounted) return;
    checkCopies();
    if (result != null && result != 'Download Finished!') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result)),
      );
    }
  }

  Widget _action(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color background,
    required Color foreground,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final contentColor =
        enabled ? foreground : scheme.onSurface.withValues(alpha: 0.38);
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Material(
          color: enabled ? background : scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Icon(icon, size: 22, color: contentColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: contentColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
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
      height: height,
      child: Column(
        children: [
          _action(
            context,
            icon: Icons.download_rounded,
            label: 'Download',
            background: scheme.primaryContainer,
            foreground: scheme.onPrimaryContainer,
            onTap: () => _startDownload(context),
          ),
          _action(
            context,
            icon: Icons.menu_book_rounded,
            label: 'Open book',
            background: scheme.tertiaryContainer,
            foreground: scheme.onTertiaryContainer,
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
          _action(
            context,
            icon: Icons.delete_outline_rounded,
            label: 'Remove offline',
            background: scheme.errorContainer,
            foreground: scheme.onErrorContainer,
            onTap: _deleteAllLocalCopies,
            enabled: downloaded,
          ),
        ],
      ),
    );
  }
}
