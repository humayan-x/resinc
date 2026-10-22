import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/theme/system_ui.dart';

export 'app/app.dart' show ResincApp;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemUiConfig.configureOverlayStyle();
  runApp(const ResincApp());
}
