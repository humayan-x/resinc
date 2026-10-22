import 'package:flutter/material.dart';

/// Shared geometry for navigation and workbench actions.
class FloatingBarFrame extends StatelessWidget {
  final Widget child;
  const FloatingBarFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Align(
      heightFactor: 1,
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: SizedBox(width: 280, height: 60, child: child),
        ),
      ),
    ),
  );
}
