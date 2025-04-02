import 'dart:math';
import 'package:flutter/material.dart';

Future<int> roll2D6(BuildContext context, {required int distance}) async {
  int die1 = Random().nextInt(6) + 1;
  int die2 = Random().nextInt(6) + 1;
  int total = die1 + die2;
  bool success = total >= distance;

  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Carga cuerpo a cuerpo"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '🎲 $die1 + $die2 = $total',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Necesario: $distance'),
            const SizedBox(height: 8),
            Text(
              success ? '¡Carga exitosa!' : 'Falló la carga',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: success ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      );
    },
  );

  return total;
}
