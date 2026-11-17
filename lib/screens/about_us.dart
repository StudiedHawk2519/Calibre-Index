import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutUs extends StatelessWidget {
  const AboutUs({super.key});

  Future<void> _openGithub(BuildContext context) async {
    final uri = Uri.https('github.com', '/StudiedHawk2519');
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
          context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open GitHub.')),
        );
      }
    } on Exception catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open GitHub: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('About Calibre Index')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: scheme.surfaceContainerHigh,
            child: const ListTile(
              leading: Icon(Icons.person_rounded),
              title: Text('Author'),
              subtitle: Text('StudiedHawk2519'),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Contacts',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Card(
            color: scheme.surfaceContainerHigh,
            child: ListTile(
              leading: const Icon(Icons.code_rounded),
              title: const Text('GitHub'),
              subtitle: const Text('github.com/StudiedHawk2519'),
              trailing: const Icon(Icons.open_in_new_rounded),
              onTap: () => _openGithub(context),
            ),
          ),
        ],
      ),
    );
  }
}
