import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({
    super.key,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    // Hier kannst du später ein echtes Logo einsetzen
    // Für jetzt verwenden wir ein Platzhalter-Widget
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .primary
            .withAlpha(204), // 0.8 * 255 = 204
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          Icons.eco_rounded,
          size: size * 0.6,
          color: Colors.white,
        ),
      ),
    );
  }
}
