import 'package:flutter/material.dart';

class AppAssets {
  AppAssets._();

  static const String logoApp = 'assets/images/logo_app.png';
  static const String logoDark = 'assets/images/futcup_logo_letrablanca.png';
  static const String logoLight = 'assets/images/futcup_logo_letranegra.png';

  static String logoForTheme(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark ? logoDark : logoLight;
  }
}
