import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/resources/strings.dart';

class PhotosScreen extends StatelessWidget {
  const PhotosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          photosTitle,
          style: TextStyle(
            fontSize: Theme.of(context).textTheme.headlineSmall?.fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.heart),
            onPressed: () {
              // TODO: Implement favorites functionality
            },
          ),
          IconButton(
            icon: const Icon(LucideIcons.bell),
            onPressed: () {
              // TODO: Implement notifications functionality
            },
          ),
        ],
      ),
      body: const Center(child: Text('Photos will be displayed here')),
    );
  }
}
