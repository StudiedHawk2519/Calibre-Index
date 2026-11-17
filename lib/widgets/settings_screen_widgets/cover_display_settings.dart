import 'package:calibre_carte/providers/update_provider.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class CoverTitleToggle extends StatelessWidget {
  const CoverTitleToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final update = Provider.of<Update>(context);
    final scheme = Theme.of(context).colorScheme;
    return SwitchListTile(
      secondary: Icon(Icons.title_rounded, color: scheme.primary),
      title: const Text('Show titles on covers'),
      subtitle: const Text('Overlay book titles in grid view'),
      value: update.showCoverTitles,
      onChanged: update.changeShowCoverTitles,
    );
  }
}

class GridColumnsSetting extends StatelessWidget {
  const GridColumnsSetting({super.key});

  @override
  Widget build(BuildContext context) {
    final update = Provider.of<Update>(context);
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        ListTile(
          leading: Icon(Icons.grid_view_rounded, color: scheme.primary),
          title: const Text('Grid columns'),
          subtitle: Text('${update.gridColumns} books across'),
        ),
        Slider(
          value: update.gridColumns.toDouble(),
          min: 2,
          max: 5,
          divisions: 3,
          label: '${update.gridColumns}',
          onChanged: (value) => update.changeGridColumns(value.round()),
        ),
      ],
    );
  }
}

class CoverCornerRadiusSetting extends StatelessWidget {
  const CoverCornerRadiusSetting({super.key});

  @override
  Widget build(BuildContext context) {
    final update = Provider.of<Update>(context);
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        ListTile(
          leading: Icon(Icons.rounded_corner, color: scheme.primary),
          title: const Text('Cover corner rounding'),
          subtitle: Text('${update.coverCornerRadius.round()} dp'),
        ),
        Slider(
          value: update.coverCornerRadius,
          min: 0,
          max: 40,
          divisions: 8,
          label: '${update.coverCornerRadius.round()} dp',
          onChanged: update.changeCoverCornerRadius,
        ),
      ],
    );
  }
}

class SeriesStackToggle extends StatelessWidget {
  const SeriesStackToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final update = Provider.of<Update>(context);
    final scheme = Theme.of(context).colorScheme;
    return SwitchListTile(
      secondary: Icon(Icons.library_books_rounded, color: scheme.primary),
      title: const Text('Stack books in a series'),
      subtitle: const Text('Tap a series to expand its books'),
      value: update.stackSeries,
      onChanged: update.changeStackSeries,
    );
  }
}
