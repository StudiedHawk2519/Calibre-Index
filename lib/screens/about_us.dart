import 'package:calibre_carte/providers/color_theme_provider.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

class AboutUs extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    ColorTheme colorTheme = Provider.of(context);
    return Scaffold(
      backgroundColor: colorTheme.descriptionBackground,
      appBar: AppBar(title: const Text('About Calibre Index')),
      body: Container(
        margin: EdgeInsets.fromLTRB(20, 20, 10, 10),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Container(
//                decoration: BoxDecoration(
//                    border: Border.all(width: 2, color: Color(0xffFED962))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      "Authors: ",
                      style: TextStyle(color: Colors.grey, fontSize: 25),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Text("Ekansh Jain, Prerna Dave",
                        style: TextStyle(
                            color: colorTheme.headerText, fontSize: 20))
                  ],
                ),
              ),
              SizedBox(
                height: 40,
              ),
              Container(
//                decoration: BoxDecoration(
//                    border: Border.all(width: 2, color: Color(0xffFED962))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      "Contact: ",
                      style: TextStyle(color: Colors.grey, fontSize: 25),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Text("calibre.carte@gmail.com",
                        style: TextStyle(
                            color: colorTheme.headerText, fontSize: 20))
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
