import 'package:flutter/material.dart';

class BattleLogPanel extends StatelessWidget {
  final List<String> logLines;

  const BattleLogPanel({super.key, required this.logLines});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        border: Border(left: BorderSide(color: Colors.grey.shade800, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Registro de Batalla',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 16,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.only(
                bottom: 60,
              ), // espacio para el botón
              itemCount: logLines.length,
              itemBuilder: (context, index) {
                final reversedIndex = logLines.length - 1 - index;
                final line = logLines[reversedIndex];
                final bool showDivider =
                    line.startsWith('Carga') ||
                    line.startsWith('Marine') ||
                    line.startsWith('Tiranido') ||
                    line.startsWith('2 ataques');

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showDivider)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          '------------------------',
                          style: TextStyle(
                            color: Colors.white24,
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        line == '¡Todos los ataques fueron salvados!'
                            ? 'Todos los impactos fueron salvados.'
                            : line,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 13,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
