import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:frontend/core/resources/style.dart';

class CustomBottomNavBar extends StatefulWidget {
  final Function(int index) onChanged;
  final Key? bottomNavigationKey;
  final List<BottomNavigationBarItem> items;
  const CustomBottomNavBar(
    this.onChanged, {
    super.key,
    this.bottomNavigationKey,
    required this.items,
  });

  @override
  State<CustomBottomNavBar> createState() => _CustomBottomNavBarState();
}

class _CustomBottomNavBarState extends State<CustomBottomNavBar> {
  int _pageIndex = 0;

  void onBottomNavChanged(int index) {
    setState(() => _pageIndex = index);
    widget.onChanged(index);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      left: false,
      right: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
        child: ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(largeRoundEdgeRadius)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Opacity(
              opacity: 0.5,
              child: BottomNavigationBar(
                key: widget.bottomNavigationKey,
                elevation: 16,
                backgroundColor: Colors.blueGrey.shade100,
                currentIndex: _pageIndex,
                showUnselectedLabels: true,
                type: BottomNavigationBarType.shifting,
                onTap: onBottomNavChanged,
                items: widget.items,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
