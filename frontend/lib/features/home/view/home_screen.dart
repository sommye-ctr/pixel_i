import 'package:flutter/material.dart';
import 'package:frontend/core/widgets/custom_nav_bar.dart';
import 'package:frontend/features/events/views/events_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/resources/strings.dart';
import '../../photos/view/photos_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const PhotosScreen(),
    const Center(child: Text('Search')),
    const EventsScreen(),
    const Center(child: Text('Profile')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: _selectedIndex, children: _screens),
          Align(
            alignment: Alignment.bottomCenter,
            child: CustomBottomNavBar(
              (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
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
          ),
        ],
      ),
    );
  }
}
