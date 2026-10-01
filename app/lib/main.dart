import 'package:flutter/material.dart';
import 'package:nestling/app/app.dart';
import 'package:nestling/app/di.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const NestlingApp());
}
