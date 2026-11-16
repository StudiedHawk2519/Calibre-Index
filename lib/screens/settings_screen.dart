import 'package:calibre_carte/screens/about_us.dart';
import 'package:calibre_carte/screens/instructions_screen.dart';
import 'package:calibre_carte/screens/license.dart';
import 'package:calibre_carte/screens/privacy_policy.dart';
import 'package:calibre_carte/widgets/settings_screen_widgets/cloud_settings.dart';
import 'package:calibre_carte/widgets/settings_screen_widgets/cover_size_toggle.dart';
import 'package:calibre_carte/widgets/settings_screen_widgets/dark_mode_toggle.dart';
import 'package:calibre_carte/widgets/settings_screen_widgets/directorychange_button.dart';
import 'package:calibre_carte/widgets/settings_screen_widgets/search_dropdown.dart';
import 'package:material_ui/material_ui.dart';

class SettingsNew extends StatelessWidget {
  static const routeName = '/settings';

  const SettingsNew({super.key});

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 24, 8, 10),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }

  Widget _settingsCard(BuildContext context, Widget child) {
    final scheme = Theme.of(context).colorScheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(24),
    );
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Material(
        color: Colors.transparent,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }

  Widget _infoTile(
    BuildContext context,
    String title,
    IconData icon,
    Widget screen,
  ) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => screen),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        _sectionTitle(context, 'Cloud library'),
        _settingsCard(context, const CloudSettings()),
        _sectionTitle(context, 'Library preferences'),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
          child: Text(
            'Search your library by title, author, or tags.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        _settingsCard(context, const SearchDropdown()),
        _sectionTitle(context, 'Appearance'),
        _settingsCard(context, const DarkMode()),
        const SizedBox(height: 8),
        _settingsCard(context, const CoverSizeToggle()),
        _sectionTitle(context, 'Downloads'),
        _settingsCard(context, const DirectoryChange()),
        _sectionTitle(context, 'About'),
        _settingsCard(
          context,
          Column(
            children: [
              _infoTile(
                context,
                'About Calibre Index',
                Icons.auto_stories_rounded,
                AboutUs(),
              ),
              const Divider(height: 1, indent: 56),
              _infoTile(
                context,
                'Privacy policy',
                Icons.privacy_tip_outlined,
                PrivacyPolicy(),
              ),
              const Divider(height: 1, indent: 56),
              _infoTile(
                context,
                'Usage instructions',
                Icons.help_outline_rounded,
                Instructions(),
              ),
              const Divider(height: 1, indent: 56),
              _infoTile(
                context,
                'License',
                Icons.info_outline_rounded,
                License(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
