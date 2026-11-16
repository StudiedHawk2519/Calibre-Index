import 'package:calibre_carte/providers/color_theme_provider.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class License extends StatelessWidget {
  static const String licenseText =
      "Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the \"Software\"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:";
  static const String licenseText2 =
      "The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.";
  static const String licenseText3 =
      "THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.";

  const License({super.key});

  @override
  Widget build(BuildContext context) {
    ColorTheme colorTheme = Provider.of(context);
    return Scaffold(
      backgroundColor: colorTheme.descriptionBackground,
      appBar: AppBar(title: const Text('License')),
      body: Container(
        padding: EdgeInsets.only(left: 10, top: 30),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Text(
                "Copyright (c) 2019 Ekansh Jain",
                style: TextStyle(color: colorTheme.headerText),
              ),
              SizedBox(
                height: 10,
              ),
              Text(
                "Copyright (c) 2019 Prerna Dave",
                style: TextStyle(color: colorTheme.headerText),
              ),
              SizedBox(
                height: 20,
              ),
              Text(
                licenseText,
                style: TextStyle(color: colorTheme.headerText),
              ),
              SizedBox(
                height: 20,
              ),
              Text(
                licenseText2,
                style: TextStyle(color: colorTheme.headerText),
              ),
              SizedBox(
                height: 20,
              ),
              Text(
                licenseText3,
                style: TextStyle(color: colorTheme.headerText),
              )
            ],
          ),
        ),
      ),
    );
  }
}
