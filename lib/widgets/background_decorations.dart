import 'package:flutter/material.dart';

class BackgroundDecorations extends StatelessWidget {
  const BackgroundDecorations({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final double orangeOpacity = isDark ? 0.48 : 0.58;
    final double blueOpacity = isDark ? 0.47 : 0.55;
    final double redOpacity = isDark ? 0.47 : 0.56;

    return RepaintBoundary(
      child: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // ignore: deprecated_member_use
                color: Colors.orange.withOpacity(orangeOpacity),
              ),
            ),
          ),
          Positioned(
            top: 70,
            left: -150,
            child: Container(
              width: 600,
              height: 600,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // ignore: deprecated_member_use
                color: Colors.blue.withOpacity(blueOpacity),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            right: -150,
            child: Container(
              width: 450,
              height: 450,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // ignore: deprecated_member_use
                color: Colors.red.withOpacity(redOpacity),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
