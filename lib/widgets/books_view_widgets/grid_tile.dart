import 'package:calibre_carte/models/books.dart';
import 'package:calibre_carte/providers/book_details_navigation_provider.dart';
import 'package:calibre_carte/providers/list_tile.dart';
import 'package:calibre_carte/screens/book_details_screen.dart';
import 'package:calibre_carte/widgets/book_details_cover_image.dart';
import 'package:calibre_carte/widgets/download_icon.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class CalibreGridTile extends StatefulWidget {
  final int index;
  final Books book;
  final List<Books> books;
  final bool matchOriginalCoverSize;

  const CalibreGridTile(
    this.index,
    this.book,
    this.books, {
    this.matchOriginalCoverSize = true,
  });

  @override
  State<CalibreGridTile> createState() => _CalibreGridTileState();
}

class _CalibreGridTileState extends State<CalibreGridTile> {
  void refreshTile() {
    setState(() {});
  }

  void _viewBookDetails(BuildContext context) {
    final int? bookId = widget.book.id;
    if (bookId == null) return;

    final navigation =
        Provider.of<BookDetailsNavigation>(context, listen: false);
    navigation.bookID = bookId;
    navigation.booksList = widget.books;
    navigation.index = widget.index;
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => BookDetailsScreen(
              bookId: bookId,
              refreshTile: refreshTile,
            ),
          ),
        )
        .then((_) => navigation.bookID = null);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      key: ValueKey(widget.book.id ?? widget.index),
      margin: const EdgeInsets.all(8),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      child: InkWell(
        onTap: () => _viewBookDetails(context),
        child: Stack(
          fit: StackFit.expand,
          children: [
            BookDetailsCoverImage(
              widget.book.id,
              widget.book.path,
              null,
              null,
              fit:
                  widget.matchOriginalCoverSize ? BoxFit.contain : BoxFit.cover,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    scheme.scrim.withValues(alpha: 0.76),
                  ],
                  stops: const [0.42, 1],
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Consumer<ListTileProvider>(
                builder: (context, provider, child) =>
                    DownloadIcon(widget.book.id),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.book.title ?? 'Untitled',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.book.author_sort?.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.book.author_sort!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.88),
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
