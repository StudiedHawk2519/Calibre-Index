import 'package:calibre_carte/providers/color_theme_provider.dart';
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class Instructions extends StatelessWidget {
  Future<void> _openLink(BuildContext context, Uri uri) async {
    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the link.')),
        );
      }
    } on Exception catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open the link: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ColorTheme colorTheme = Provider.of(context);
    return Scaffold(
      backgroundColor: colorTheme.descriptionBackground,
      appBar: AppBar(title: const Text('Instructions')),
      body: Container(
        margin: EdgeInsets.fromLTRB(20, 20, 10, 10),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    "\u2022",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorTheme.headerText),
                  ),
                  Expanded(
                      child: RichText(
                    text: TextSpan(children: [
                      TextSpan(
                          text:
                              " Before logging in, you should upload your entire Calibre Library folder to dropbox. You can find the location of the folder by clicking on the \"Calibre Library\" button in the Calibre Application.",
                          style: TextStyle(
                              color: colorTheme.headerText, fontSize: 15))
                    ]),
                  ))
                ],
              ),
              SizedBox(
                height: 20,
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    "\u2022",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorTheme.headerText),
                  ),
                  Expanded(
                      child: RichText(
                    text: TextSpan(children: [
                      TextSpan(
                          text:
                              " You can read more about how to export and move Calibre's libraries ",
                          style: TextStyle(
                              color: colorTheme.headerText, fontSize: 15)),
                      TextSpan(
                          text: "here.",
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => _openLink(
                                  context,
                                  Uri.parse(
                                    'https://blog.calibre-ebook.com/2017/01/how-to-backup-move-and-export-your.html',
                                  ),
                                ),
                          style: TextStyle(color: Colors.blue, fontSize: 15)),
                    ]),
                  ))
                ],
              ),
              SizedBox(
                height: 20,
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    "\u2022",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorTheme.headerText),
                  ),
                  Expanded(
                      child: RichText(
                    text: TextSpan(children: [
                      TextSpan(
                          text:
                              " For the best experience with Calibre Index, download e-book metadata and covers using Calibre. You can find the instructions to download and edit metadata",
                          style: TextStyle(
                              color: colorTheme.headerText, fontSize: 15)),
                      TextSpan(
                          text: " here.",
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => _openLink(
                                  context,
                                  Uri.parse(
                                    'https://manual.calibre-ebook.com/metadata.html#id2',
                                  ),
                                ),
                          style: TextStyle(color: Colors.blue, fontSize: 15)),
                    ]),
                  ))
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
