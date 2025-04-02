import 'package:flutter/material.dart';
import '../models/unit.dart';

class GameTile extends StatelessWidget {
  final int row;
  final int col;
  final Unit? unit;
  final bool isSelected;
  final bool inMoveRange;
  final bool inAttackRange;
  final bool hasActed;
  final Function(int, int) onTap;

  const GameTile({
    Key? key,
    required this.row,
    required this.col,
    required this.unit,
    required this.isSelected,
    required this.inMoveRange,
    required this.inAttackRange,
    required this.hasActed,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(row, col),
      child: Container(
        decoration: BoxDecoration(
          image: const DecorationImage(
            image: AssetImage('assets/tile.png'),
            fit: BoxFit.cover,
          ),
          border: Border.all(color: Colors.black),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: Colors.yellowAccent,
                      blurRadius: 5,
                      spreadRadius: 1,
                    ),
                  ]
                  : [],
        ),
        child: Stack(
          children: [
            // Blue highlight for movement range
            if (inMoveRange)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
              ),

            // Red highlight for attack range
            if (inAttackRange)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
              ),

            // Unit display
            if (unit != null)
              Opacity(
                opacity: hasActed ? 0.4 : 1.0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(child: Image.asset('assets/${unit!.type}.png')),
                    const SizedBox(height: 2),
                    _buildHealthBar(unit!),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthBar(Unit unit) {
    return SizedBox(
      height: 10,
      width: 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: unit.hp / unit.maxHp,
              backgroundColor: Colors.black26,
              valueColor: AlwaysStoppedAnimation<Color>(
                unit.type == 'space_marine' ? Colors.green : Colors.red,
              ),
              minHeight: 10,
            ),
          ),
          Text(
            '${unit.hp}',
            style: const TextStyle(
              fontSize: 8,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
