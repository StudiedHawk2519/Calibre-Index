import 'package:material_ui/material_ui.dart';

class TextStyling {
  bool darkMode;
  TextStyling(this.darkMode);
  static const baseTextStyle = TextStyle();
  static final regularTextStyle = baseTextStyle.copyWith(
      color: const Color(0xffb6b2df),
      fontSize: 9.0,
      fontWeight: FontWeight.w400);
  static final subHeaderTextStyle = regularTextStyle.copyWith(fontSize: 12.0);
  static final headerTextStyle = baseTextStyle.copyWith(
      color: Colors.black, fontSize: 18.0, fontWeight: FontWeight.w600);
}
