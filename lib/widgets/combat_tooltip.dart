import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class CombatTooltip extends StatelessWidget {
  final String title;
  final List<Widget> content;
  final String? animationAsset;

  const CombatTooltip({
    super.key,
    required this.title,
    required this.content,
    this.animationAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4.0,
      borderRadius: BorderRadius.circular(6),
      color: Colors.black.withOpacity(0.9),
      child: Container(
        padding: const EdgeInsets.all(10),
        width: 200,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            if (animationAsset != null)
              Lottie.asset(
                animationAsset!,
                width: 180,
                height: 120,
                fit: BoxFit.contain,
              ),
            const Divider(color: Colors.white30),
            ...content,
          ],
        ),
      ),
    );
  }
}
