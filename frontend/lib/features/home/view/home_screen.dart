import 'package:flutter/material.dart';

import '../../../resources/strings.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(homeTitle)),
      body: const Center(child: Text(homeWelcome)),
    );
  }
}
