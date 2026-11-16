import 'package:calibre_carte/providers/update_provider.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CoverSizeToggle extends StatelessWidget {
  const CoverSizeToggle({super.key});

  Future<void> _savePreference(bool value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('matchOriginalCoverSize', value);
  }

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
      onChanged: (value) async {
        await _savePreference(value);
        update.changeMatchOriginalCoverSize(value);
      },
    );
  }
}
