import 'package:calibre_carte/helpers/goodreads_links.dart';
import 'package:material_ui/material_ui.dart';

class GoodreadsLinkText extends StatelessWidget {
  final String text;
  final String query;
  final bool enabled;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  const GoodreadsLinkText({
    super.key,
    required this.text,
    required this.query,
    required this.enabled,
    this.style,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveStyle =
        enabled ? style?.copyWith(decoration: TextDecoration.underline) : style;
    final label = Text(
      text,
      style: effectiveStyle,
      maxLines: maxLines,
      overflow: overflow,
    );
    if (!enabled || query.trim().isEmpty) return label;
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: () => openGoodreadsSearch(context, query: query),
      child: label,
    );
  }
}
