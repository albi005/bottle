import 'package:flutter/material.dart';

import 'package:bottle/app.dart';
import 'package:bottle/di/injection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await configureDependencies();

  runApp(const BottleApp());
}
