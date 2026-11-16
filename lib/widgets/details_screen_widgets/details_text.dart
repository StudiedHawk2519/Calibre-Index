import 'package:calibre_carte/helpers/slide_left_transition.dart';
import 'package:calibre_carte/helpers/slide_transition_route.dart';
import 'package:calibre_carte/models/books.dart';
import 'package:calibre_carte/models/publishers.dart';
import 'package:calibre_carte/models/ratings.dart';
import 'package:calibre_carte/providers/book_details_navigation_provider.dart';
import 'package:calibre_carte/providers/list_tile.dart';
import 'package:calibre_carte/screens/book_details_screen.dart';
import 'package:calibre_carte/widgets/details_screen_widgets/rating.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class BookDetailsText extends StatelessWidget {
  final double width;
  final Books bookDetails;
  final String authorText;
  final Ratings? rating;
  final Publishers? publishers;

  const BookDetailsText(
    this.width,
    this.bookDetails,
    this.authorText,
    this.rating,
    this.publishers,
  );

  void gotoNextBook(BuildContext context, VoidCallback refreshTile) {
    BookDetailsNavigation bn =
        Provider.of<BookDetailsNavigation>(context, listen: false);

    final books = bn.booksList;
    if (books == null || books.isEmpty) return;

    final int nextIndex = (bn.index + 1) % books.length;
    final int? bookId = books[nextIndex].id;
    if (bookId == null) return;
    bn.index = nextIndex;

    Navigator.of(context).pushReplacement(
      SlideRightRoute(
        page: BookDetailsScreen(bookId: bookId, refreshTile: refreshTile),
      ),
    );
  }

  void gotoPrevBook(BuildContext context, VoidCallback refreshTile) {
    BookDetailsNavigation bn =
        Provider.of<BookDetailsNavigation>(context, listen: false);

    final books = bn.booksList;
    if (books == null || books.isEmpty) return;

    final int previousIndex = (bn.index - 1 + books.length) % books.length;
    final int? bookId = books[previousIndex].id;
    if (bookId == null) return;
    bn.index = previousIndex;

    Navigator.of(context).pushReplacement(
      SlideLeftRoute(
        page: BookDetailsScreen(bookId: bookId, refreshTile: refreshTile),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final listTileProvider =
        Provider.of<ListTileProvider>(context, listen: false);
    final publishedDate = bookDetails.pubdate;

    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              bookDetails.title ?? 'Untitled',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              authorText.isEmpty ? 'Unknown author' : authorText,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (publishers?.name != null || publishedDate != null) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (publishers?.name != null)
                    Chip(
                      avatar: const Icon(Icons.business_rounded, size: 18),
                      label: Text(publishers!.name!),
                    ),
                  if (publishedDate != null)
                    Chip(
                      avatar:
                          const Icon(Icons.calendar_month_rounded, size: 18),
                      label: Text(
                        publishedDate.length >= 10
                            ? publishedDate.substring(0, 10)
                            : publishedDate,
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Center(
              child: StarRating(
                ((rating?.rating ?? 10) / 2).toDouble(),
                width,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton.filledTonal(
                  tooltip: 'Previous book',
                  onPressed: () => gotoPrevBook(
                    context,
                    listTileProvider.refreshTile,
                  ),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: 'Next book',
                  onPressed: () => gotoNextBook(
                    context,
                    listTileProvider.refreshTile,
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
