import 'package:flutter/material.dart';

class CombatTooltip extends StatelessWidget {
  final String title;
  final List<Widget> content;

  const CombatTooltip({super.key, required this.title, required this.content});

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
            const Divider(color: Colors.white30),
            ...content,
          ],
        ),
      ),
    );
  }
}
