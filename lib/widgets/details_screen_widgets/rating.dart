import 'package:material_ui/material_ui.dart';

class StarRating extends StatelessWidget {
  final double rating;
  final double width;

  const StarRating(this.rating, this.width, {super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: width,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          5,
          (index) => Icon(
            index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
            color: index < rating ? scheme.tertiary : scheme.outlineVariant,
          ),
        ),
      ),
    );
  }
}
