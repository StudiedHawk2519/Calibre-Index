import 'package:calibre_carte/providers/update_provider.dart';
import 'package:calibre_carte/widgets/settings_screen_widgets/dropbox_dropdown.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class CloudSettings extends StatelessWidget {
  const CloudSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final Update update = Provider.of<Update>(context);
    final bool connected = update.tokenExists == true;
    final scheme = Theme.of(context).colorScheme;

    return ExpansionTile(
      leading: Icon(
        connected ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
        color: scheme.primary,
      ),
      title: const Text('Dropbox'),
      subtitle: Text(
        connected ? 'Library connected' : 'Connect a Calibre library',
      ),
      children: const [
        Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: DropboxDropdown(),
        ),
      ],
    );
  }
}
