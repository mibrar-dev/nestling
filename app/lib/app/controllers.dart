import 'package:flutter/material.dart';

enum AppMode { parent, kid }

class AppModeController extends ChangeNotifier {
  new();

  AppMode mode = AppMode.parent;

  bool get isKid => mode == AppMode.kid;

  void selectMode(AppMode value) {
    if (mode == value) {
      return;
    }
    mode = value;
    notifyListeners();
  }
}

class ThemeModeController extends ChangeNotifier {
  new();

  ThemeMode mode = ThemeMode.system;

  void selectMode(ThemeMode value) {
    if (mode == value) {
      return;
    }
    mode = value;
    notifyListeners();
  }
}
