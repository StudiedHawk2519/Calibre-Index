import 'package:calibre_carte/helpers/metadata_cacher.dart';
import 'package:calibre_carte/providers/color_theme_provider.dart';
import 'package:calibre_carte/providers/update_provider.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class RefreshButton extends StatelessWidget {
  final VoidCallback logout;

  const RefreshButton(this.logout, {super.key});

  @override
  Widget build(BuildContext context) {
    final update = Provider.of<Update>(context, listen: false);
    final colorTheme = Provider.of<ColorTheme>(context);
    return ListTile(
      leading: Icon(Icons.refresh_rounded, color: colorTheme.settingsIcon),
      title: const Text('Refresh library'),
      onTap: () {
          showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return PopScope(
                    canPop: false,
                    child: SimpleDialog(
                        key: UniqueKey(),
                        backgroundColor:
                            Theme.of(context).colorScheme.surfaceContainerHigh,
                        children: <Widget>[
                          Center(
                            child: Column(children: [
                              CircularProgressIndicator(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Text("Refreshing library")
                            ]),
                          )
                        ]));
              });

          Future<int> m = MetadataCacher().downloadAndCacheMetadata();

          m.then((value) {
            if (value == 1) {
//                                print("Donwloading finished");
              update.updateFlagState(true);
              Navigator.of(context).pop();
            } else {
              if (value == 0) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text("No internet"),
                ));
              } else {
                Navigator.of(context).pop();
                logout();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text("Authentication expired. Please login again"),
                ));
              }
            }
          });

//                            Showing a dialog till the snackbar thing works

//                            TODO: This is not working.
      },
    );
  }
}
