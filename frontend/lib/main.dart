import 'package:flutter/material.dart';
import 'package:frontend/core/network/token_storage.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bool hasTokens = await TokenStorage().hasTokens();
  runApp(App(isLoggedIn: hasTokens));
}
