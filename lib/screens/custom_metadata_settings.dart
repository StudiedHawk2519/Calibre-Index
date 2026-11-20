import 'package:calibre_carte/helpers/book_metadata_provider.dart';
import 'package:calibre_carte/providers/update_provider.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class CustomMetadataSettings extends StatefulWidget {
  const CustomMetadataSettings({super.key});

  @override
  State<CustomMetadataSettings> createState() => _CustomMetadataSettingsState();
}

class _CustomMetadataSettingsState extends State<CustomMetadataSettings> {
  late final Future<List<String>> _columns =
      BookMetadataProvider.getCustomColumnNames();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final update = Provider.of<Update>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Pinned custom metadata')),
      body: FutureBuilder<List<String>>(
        future: _columns,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Could not load custom columns: ${snapshot.error}'),
              ),
            );
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final columns = snapshot.data ?? const <String>[];
          if (columns.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No custom columns were found in this Calibre library.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Text(
                  'Choose which custom fields appear below the rating on book details.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ),
              for (final column in columns)
                CheckboxListTile(
                  value: update.pinnedCustomMetadata.contains(column),
                  title: Text(column),
                  secondary: Icon(
                    Icons.label_outline_rounded,
                    color: scheme.primary,
                  ),
                  onChanged: (pinned) {
                    if (pinned != null) {
                      update.togglePinnedCustomMetadata(column, pinned);
                    }
                  },
                ),
            ],
          );
        },
      ),
    );
  }
}
