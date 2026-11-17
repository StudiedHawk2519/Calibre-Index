import 'package:calibre_carte/providers/update_provider.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class CoverSizeToggle extends StatelessWidget {
  const CoverSizeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final update = Provider.of<Update>(context);
    final scheme = Theme.of(context).colorScheme;

    return SwitchListTile(
      secondary:
          Icon(Icons.photo_size_select_large_rounded, color: scheme.primary),
      title: const Text('Match original cover size'),
      subtitle: const Text('Keep the cover proportions without cropping'),
      value: update.matchOriginalCoverSize,
      onChanged: update.changeMatchOriginalCoverSize,
    );
  }
}
