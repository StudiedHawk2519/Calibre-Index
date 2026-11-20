import 'package:calibre_carte/models/books.dart';
import 'package:calibre_carte/models/ratings.dart';
import 'package:calibre_carte/widgets/details_screen_widgets/rating.dart';
import 'package:calibre_carte/widgets/goodreads_link_text.dart';
import 'package:material_ui/material_ui.dart';

class BookDetailsText extends StatelessWidget {
  final double width;
  final Books bookDetails;
  final String authorText;
  final Ratings? rating;
  final Map<String, String> pinnedMetadata;
  final bool goodreadsEnabled;
  final VoidCallback onShowAllMetadata;

  const BookDetailsText(
    this.width,
    this.bookDetails,
    this.authorText,
    this.rating,
    this.pinnedMetadata,
    this.goodreadsEnabled,
    this.onShowAllMetadata,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GoodreadsLinkText(
              text: bookDetails.title ?? 'Untitled',
              query: bookDetails.isbn?.isNotEmpty == true
                  ? bookDetails.isbn!
                  : bookDetails.title ?? '',
              enabled: goodreadsEnabled,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            GoodreadsLinkText(
              text: authorText.isEmpty ? 'Unknown author' : authorText,
              query: authorText,
              enabled: goodreadsEnabled,
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
            for (final entry in pinnedMetadata.entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        entry.key,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          if (entry.value == 'Yes' || entry.value == 'No') ...[
                            Icon(
                              entry.value == 'Yes'
                                  ? Icons.check_circle_outline_rounded
                                  : Icons.cancel_outlined,
                              size: 18,
                              color: entry.value == 'Yes'
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                          ],
                          Expanded(child: Text(entry.value)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonalIcon(
                onPressed: onShowAllMetadata,
                icon: const Icon(Icons.list_alt_rounded),
                label: const Text('All metadata'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
