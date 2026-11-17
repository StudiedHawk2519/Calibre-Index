import 'package:calibre_carte/models/books.dart';
import 'package:calibre_carte/models/publishers.dart';
import 'package:calibre_carte/models/ratings.dart';
import 'package:calibre_carte/widgets/details_screen_widgets/rating.dart';
import 'package:material_ui/material_ui.dart';

class BookDetailsText extends StatelessWidget {
  final double width;
  final Books bookDetails;
  final String authorText;
  final Ratings? rating;
  final Publishers? publishers;
  final VoidCallback onShowAllMetadata;

  const BookDetailsText(
    this.width,
    this.bookDetails,
    this.authorText,
    this.rating,
    this.publishers,
    this.onShowAllMetadata,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: StarRating(
                ((rating?.rating ?? 0) / 2).toDouble(),
                width,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              runSpacing: 4,
              children: [
                if (publishers?.name != null)
                  Chip(
                    avatar: const Icon(Icons.business_rounded, size: 18),
                    label: Text(publishers!.name!),
                  ),
                if (publishedDate != null)
                  Chip(
                    avatar: const Icon(Icons.calendar_month_rounded, size: 18),
                    label: Text(
                      publishedDate.length >= 10
                          ? publishedDate.substring(0, 10)
                          : publishedDate,
                    ),
                  ),
                IconButton.filledTonal(
                  tooltip: 'Show all book metadata',
                  onPressed: onShowAllMetadata,
                  icon: const Icon(Icons.table_view_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
