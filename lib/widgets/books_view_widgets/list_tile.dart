import 'package:calibre_carte/helpers/slide_transition_route.dart';
import 'package:calibre_carte/models/books.dart';
import 'package:calibre_carte/providers/book_details_navigation_provider.dart';
import 'package:calibre_carte/providers/list_tile.dart';
import 'package:calibre_carte/screens/book_details_screen.dart';
import 'package:calibre_carte/widgets/book_details_cover_image.dart';
import 'package:calibre_carte/widgets/download_icon.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class CoolTile extends StatelessWidget {
  final int index;
  final List<Books> books;
  final bool matchOriginalCoverSize;

  const CoolTile(
    this.index,
    this.books, {
    this.matchOriginalCoverSize = true,
  });

  void _viewBookDetails(
    Books book,
    BuildContext context,
    VoidCallback refreshTile,
  ) {
    final int? bookId = book.id;
    if (bookId == null) return;

    final navigation =
        Provider.of<BookDetailsNavigation>(context, listen: false);
    navigation.bookID = bookId;
    navigation.booksList = books;
    navigation.index = index;
    Navigator.of(context)
        .push(
          SlideRightRoute(
            page: BookDetailsScreen(
              bookId: bookId,
              refreshTile: refreshTile,
            ),
          ),
        )
        .then((_) => navigation.bookID = null);
  }

  @override
  Widget build(BuildContext context) {
    final book = books[index];
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final listTileProvider =
        Provider.of<ListTileProvider>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        key: ValueKey(book.id ?? index),
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLow,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        child: InkWell(
          onTap: () => _viewBookDetails(
            book,
            context,
            listTileProvider.refreshTile,
          ),
          child: SizedBox(
            height: 144,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BookDetailsCoverImage(
                      book.id,
                      book.path,
                      124,
                      83,
                      fit: matchOriginalCoverSize
                          ? BoxFit.contain
                          : BoxFit.cover,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 16, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          book.title ?? 'Untitled',
                          style: theme.textTheme.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          book.author_sort?.isNotEmpty == true
                              ? book.author_sort!
                              : 'Unknown author',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'CALIBRE LIBRARY',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.primary,
                                letterSpacing: 0.8,
                              ),
                            ),
                            Consumer<ListTileProvider>(
                              builder: (context, provider, child) =>
                                  DownloadIcon(book.id),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
