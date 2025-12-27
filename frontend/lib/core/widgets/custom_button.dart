import 'package:flutter/material.dart';
import 'package:frontend/resources/style.dart';

class CustomButton extends StatelessWidget {
  final void Function()? onPressed;
  final Widget child;
  final RoundedButtonType type;

  const CustomButton({
    super.key,
    required this.child,
    required this.onPressed,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    if (type == RoundedButtonType.filled) {
      return ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(largeRoundEdgeRadius),
          ),
        ),
        child: child,
      );
    } else if (type == RoundedButtonType.outlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(largeRoundEdgeRadius),
          ),
        ),
        child: child,
      );
    }
    throw FlutterError("Invalid button type");
  }
}

enum RoundedButtonType { filled, outlined }
