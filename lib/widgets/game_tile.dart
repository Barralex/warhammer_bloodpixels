import 'package:flutter/material.dart';
import 'package:warhammer_bloodpixels/constants/game_constants.dart';
import '../models/unit.dart';
import '../models/game_state.dart';

class GameTile extends StatelessWidget {
  final int row;
  final int col;
  final Unit? unit;
  final bool isSelected;
  final bool inMoveRange;
  final bool inAttackRange;
  final bool inChargeRange;
  final bool hasActed;
  final List<List<Unit?>> board;
  final Function(int, int) onTap;
  final ActionMode actionMode;

  const GameTile({
    Key? key,
    required this.row,
    required this.col,
    required this.unit,
    required this.isSelected,
    required this.inMoveRange,
    required this.inAttackRange,
    required this.inChargeRange,
    required this.hasActed,
    required this.board,
    required this.onTap,
    required this.actionMode,
  }) : super(key: key);

  String getAssetPath(String unitType) {
    switch (unitType) {
      case 'tyranid':
        return 'assets/tyranids/default.png';
      case 'reaper_swarm':
        return 'assets/reaper_swarm.png';
      case 'space_marine':
        return 'assets/space_marine.png';
      default:
        return 'assets/$unitType.png';
    }
  }

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
            if (inMoveRange &&
                (actionMode == ActionMode.move ||
                    actionMode == ActionMode.none))
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
              ),
            if (inAttackRange &&
                (actionMode == ActionMode.attack ||
                    actionMode == ActionMode.none))
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
              ),
            if (inChargeRange && actionMode == ActionMode.charge)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
              ),
            if (unit != null && unit!.hp > 0 && _isEngaged(row, col))
              const Positioned(
                top: 4,
                right: 4,
                child: Tooltip(
                  message: 'Trabado en combate',
                  child: Icon(Icons.lock, size: 18, color: Colors.redAccent),
                ),
              ),
            if (unit != null)
              Stack(
                children: [
                  Opacity(
                    opacity: unit!.hp == 0 ? 0.2 : (hasActed ? 0.4 : 1.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(child: Image.asset(getAssetPath(unit!.type))),
                        const SizedBox(height: 2),
                        _buildHealthBar(unit!),
                      ],
                    ),
                  ),
                  if (unit!.hp == 0)
                    Positioned.fill(
                      child: Align(
                        alignment: Alignment.center,
                        child: Image.asset(
                          'assets/skull.png',
                          width: 48,
                          height: 48,
                        ),
                      ),
                    ),
                ],
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

  bool _isEngaged(int row, int col) {
    final adjacentOffsets = [
      Offset(0, 1),
      Offset(1, 0),
      Offset(0, -1),
      Offset(-1, 0),
    ];

    for (final offset in adjacentOffsets) {
      final newRow = row + offset.dy.toInt();
      final newCol = col + offset.dx.toInt();

      if (newRow >= 0 &&
          newRow < GameConstants.BOARD_ROWS &&
          newCol >= 0 &&
          newCol < GameConstants.BOARD_COLS &&
          board[newRow][newCol] != null &&
          board[newRow][newCol]!.faction != unit!.faction &&
          board[newRow][newCol]!.hp > 0) {
        return true;
      }
    }

    return false;
  }
}
