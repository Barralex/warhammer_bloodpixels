import 'package:flutter/material.dart';
import 'dart:math';
import '../models/game_state.dart';
import '../models/unit.dart';
import '../widgets/game_tile.dart';
import '../widgets/dice_roller.dart';

class GameBoard extends StatefulWidget {
  @override
  _GameBoardState createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  late GameState gameState;

  @override
  void initState() {
    super.initState();
    gameState = GameState();
    gameState.addListener(() {
      setState(() {});
    });
  }

  void _onTileTapped(int row, int col) async {
    Unit? unit = gameState.board[row][col];
    Offset tappedOffset = Offset(col.toDouble(), row.toDouble());

    // Selected a friendly unit
    if (unit?.type == gameState.currentTurn &&
        !gameState.actedUnits.contains(tappedOffset)) {
      gameState.selectTile(row, col);
    }
    // Move to empty tile
    else if (gameState.selectedTile != null && unit == null) {
      final selected = gameState.selectedTile!;
      final selectedRow = selected.dy.toInt();
      final selectedCol = selected.dx.toInt();
      final Unit selectedUnit = gameState.board[selectedRow][selectedCol]!;

      bool isLockedInCombat = false;
      final adjacentOffsets = [
        Offset(0, 1),
        Offset(1, 0),
        Offset(0, -1),
        Offset(-1, 0),
      ];

      for (final offset in adjacentOffsets) {
        final newRow = selectedRow + offset.dy.toInt();
        final newCol = selectedCol + offset.dx.toInt();

        if (newRow >= 0 &&
            newRow < 10 &&
            newCol >= 0 &&
            newCol < 14 &&
            gameState.board[newRow][newCol] != null &&
            gameState.board[newRow][newCol]!.type != selectedUnit.type &&
            gameState.board[newRow][newCol]!.hp > 0) {
          isLockedInCombat = true;
          break;
        }
      }

      if (isLockedInCombat) {
        return; // No puede moverse
      }

      if (gameState.moveRange.contains(tappedOffset)) {
        gameState.moveUnit(row, col);
      }
    }
    // Attack enemy unit
    else if (gameState.selectedTile != null &&
        unit?.type != gameState.currentTurn &&
        unit != null) {
      int selectedRow = gameState.selectedTile!.dy.toInt();
      int selectedCol = gameState.selectedTile!.dx.toInt();
      Unit attacker = gameState.board[selectedRow][selectedCol]!;

      double distance = _calculateDistance(selectedRow, selectedCol, row, col);

      // Normal attack
      if (distance <= attacker.attackRange) {
        gameState.attack(row, col, context);
      }
      // Attempt charge (Tyranid specific)
      else if (attacker.type == 'tyranid' &&
          attacker.attackRange == 1 &&
          distance <= 12) {
        int chargeRoll = await roll2D6(context, distance: distance.round());

        if (chargeRoll >= distance) {
          _handleSuccessfulCharge(row, col, selectedRow, selectedCol);
        } else {
          // Failed charge
          setState(() {
            gameState.actedUnits.add(
              Offset(selectedCol.toDouble(), selectedRow.toDouble()),
            );
            gameState.clearSelection();
          });
        }
      }
    }
  }

  double _calculateDistance(int fromRow, int fromCol, int toRow, int toCol) {
    return sqrt(pow(toRow - fromRow, 2) + pow(toCol - fromCol, 2));
  }

  void _handleSuccessfulCharge(
    int targetRow,
    int targetCol,
    int selectedRow,
    int selectedCol,
  ) {
    Unit attacker = gameState.board[selectedRow][selectedCol]!;

    // Perform attack manually since we're in a special case
    Unit target = gameState.board[targetRow][targetCol]!;
    target.hp -= attacker.damage;

    if (target.hp <= 0) {
      target.hp = 0;
    }

    // Set initial position for the attacker
    Offset finalOffset = Offset(selectedCol.toDouble(), selectedRow.toDouble());

    // Try to move to target position if empty
    if (gameState.board[targetRow][targetCol] == null) {
      gameState.board[targetRow][targetCol] = attacker;
      gameState.board[selectedRow][selectedCol] = null;
      finalOffset = Offset(targetCol.toDouble(), targetRow.toDouble());
    } else {
      // Find adjacent spot
      final directions = [
        [0, 1],
        [1, 0],
        [0, -1],
        [-1, 0],
        [-1, -1],
        [-1, 1],
        [1, -1],
        [1, 1],
      ];

      for (var dir in directions) {
        int newRow = targetRow + dir[0];
        int newCol = targetCol + dir[1];

        if (newRow >= 0 &&
            newRow < 10 &&
            newCol >= 0 &&
            newCol < 14 &&
            gameState.board[newRow][newCol] == null) {
          gameState.board[newRow][newCol] = attacker;
          gameState.board[selectedRow][selectedCol] = null;
          finalOffset = Offset(newCol.toDouble(), newRow.toDouble());
          break;
        }
      }
    }

    setState(() {
      gameState.actedUnits.add(finalOffset);
      gameState.clearSelection();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.brown[800],
        title: Text(
          gameState.currentTurn == 'space_marine'
              ? "Space Marines' Turn"
              : "Tyranids' Turn",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Container(
        color: const Color(0xFFF5F5DC),
        child: Center(
          child: AspectRatio(
            aspectRatio: 14 / 10,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 14,
                childAspectRatio: 1,
              ),
              itemCount: 140,
              itemBuilder: (context, index) {
                int row = index ~/ 14;
                int col = index % 14;
                Unit? unit = gameState.board[row][col];
                bool isSelected =
                    gameState.selectedTile?.dx == col &&
                    gameState.selectedTile?.dy == row;

                return GameTile(
                  row: row,
                  col: col,
                  unit: unit,
                  isSelected: isSelected,
                  inMoveRange: gameState.moveRange.contains(
                    Offset(col.toDouble(), row.toDouble()),
                  ),
                  inAttackRange: gameState.attackRange.contains(
                    Offset(col.toDouble(), row.toDouble()),
                  ),
                  hasActed: gameState.actedUnits.contains(
                    Offset(col.toDouble(), row.toDouble()),
                  ),
                  onTap: _onTileTapped,
                  board: gameState.board,
                );
              },
            ),
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 12, right: 12),
        child: ElevatedButton.icon(
          onPressed: () => gameState.endTurn(),
          icon: const Icon(Icons.shield_moon, size: 20),
          label: const Text(
            'Finalizar Turno',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              fontSize: 14,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2C2C2C),
            foregroundColor: Colors.white,
            elevation: 10,
            shadowColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFF555555), width: 2),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    gameState.dispose();
    super.dispose();
  }
}
