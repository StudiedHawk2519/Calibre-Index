import 'package:calibre_carte/providers/color_theme_provider.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DarkMode extends StatelessWidget {
  const DarkMode({super.key});

  Future<void> _saveDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', value);
  }

  @override
  Widget build(BuildContext context) {
    final ColorTheme colorTheme = Provider.of<ColorTheme>(context);
    final scheme = Theme.of(context).colorScheme;

    return SwitchListTile(
      secondary: Icon(Icons.dark_mode_rounded, color: scheme.primary),
      title: const Text('Dark theme'),
      subtitle: const Text('Use the dark version of your color palette'),
      value: colorTheme.darkMode,
      onChanged: (value) async {
        await _saveDarkMode(value);
        if (value) {
          colorTheme.darkModeOn();
        } else {
          colorTheme.darkModeOff();
        }
      },
    );
  }
}
