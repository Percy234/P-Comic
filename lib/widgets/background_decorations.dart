import 'package:flutter/material.dart';

class BackgroundDecorations extends StatelessWidget {
  const BackgroundDecorations({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final double orangeOpacity = isDark ? 0.50 : 0.60;
    final double blueOpacity = isDark ? 0.48 : 0.58;
    final double redOpacity = isDark ? 0.48 : 0.58;
    final screenSize = MediaQuery.of(context).size;

    return RepaintBoundary(
      child: OverflowBox(
        minWidth: screenSize.width,
        maxWidth: screenSize.width,
        minHeight: screenSize.height,
        maxHeight: screenSize.height,
        alignment: Alignment.topCenter,
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
                  color: Colors.orange.withValues(alpha: orangeOpacity),
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
                  color: Colors.blue.withValues(alpha: blueOpacity),
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
                  color: Colors.red.withValues(alpha: redOpacity),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
