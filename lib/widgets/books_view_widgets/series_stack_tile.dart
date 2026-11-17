import 'package:calibre_carte/models/book_display_group.dart';
import 'package:calibre_carte/widgets/book_details_cover_image.dart';
import 'package:material_ui/material_ui.dart';

class SeriesStackTile extends StatelessWidget {
  final BookDisplayGroup group;
  final double coverCornerRadius;
  final bool expanded;
  final VoidCallback onTap;

  const SeriesStackTile({
    super.key,
    required this.group,
    required this.coverCornerRadius,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.all(6),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(coverCornerRadius),
      ),
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _SeriesCoverStack(
              group: group,
              coverCornerRadius: coverCornerRadius,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xCC000000)],
                  stops: [0.45, 1],
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Text(
                group.seriesName ?? 'Series',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surface.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Text(
                    '${group.books.length}',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: Icon(
                expanded
                    ? Icons.expand_less_rounded
                    : Icons.layers_rounded,
                color: Colors.white,
                shadows: const [Shadow(blurRadius: 8)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SeriesListStackTile extends StatelessWidget {
  final BookDisplayGroup group;
  final double coverCornerRadius;
  final bool expanded;
  final VoidCallback onTap;

  const SeriesListStackTile({
    super.key,
    required this.group,
    required this.coverCornerRadius,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                SizedBox(
                  width: 58,
                  height: 86,
                  child: _SeriesCoverStack(
                    group: group,
                    coverCornerRadius: coverCornerRadius,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.seriesName ?? 'Series',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${group.books.length} books'
                        '${group.author?.isNotEmpty == true ? ' · ${group.author}' : ''}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  expanded
                      ? Icons.expand_less_rounded
                      : Icons.layers_rounded,
                  color: scheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SeriesCoverStack extends StatelessWidget {
  final BookDisplayGroup group;
  final double coverCornerRadius;

  const _SeriesCoverStack({
    required this.group,
    required this.coverCornerRadius,
  });

  @override
  Widget build(BuildContext context) {
    final covers = group.books.take(3).toList().reversed.toList();
    return ClipRRect(
      borderRadius: BorderRadius.circular(coverCornerRadius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          for (var index = 0; index < covers.length; index++)
            Positioned(
              left: 0,
              top: 0,
              right: index * 6.0,
              bottom: index * 6.0,
              child: BookDetailsCoverImage(
                covers[index].id,
                covers[index].path,
                null,
                null,
                fit: BoxFit.cover,
              ),
            ),
        ],
      ),
    );
  }
}
