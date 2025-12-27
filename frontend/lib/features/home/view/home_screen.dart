import 'package:flutter/material.dart';
import 'package:frontend/core/widgets/custom_nav_bar.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/resources/strings.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const Center(child: Text(homeWelcome)),
      bottomNavigationBar: CustomBottomNavBar(
        (index) {},
        items: [
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.image),
            label: photosTitle,
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.search),
            label: searchTitle,
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.album),
            label: eventsTitle,
          ),

          BottomNavigationBarItem(
            icon: Icon(LucideIcons.user),
            label: profileTitle,
          ),
        ],
      ),
    );
  }
}
