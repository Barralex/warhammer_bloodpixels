import 'package:flutter/material.dart';
import 'dart:math';
import 'unit.dart';

class GameState extends ChangeNotifier {
  List<List<Unit?>> board = List.generate(10, (index) => List.filled(14, null));
  Offset? selectedTile;
  String currentTurn = 'space_marine';
  List<Offset> moveRange = [];
  List<Offset> attackRange = [];
  Set<Offset> actedUnits = {};

  GameState() {
    _initializeBoard();
  }

  void _initializeBoard() {
    actedUnits = {};
    for (int i = 0; i < 5; i++) {
      board[0][i] = Unit("tyranid");
    }
    for (int i = 0; i < 3; i++) {
      board[9][i] = Unit("space_marine");
    }
  }

  void selectTile(int row, int col) {
    Offset tappedOffset = Offset(col.toDouble(), row.toDouble());
    Unit? unit = board[row][col];

    if (unit?.type == currentTurn && actedUnits.contains(tappedOffset)) {
      return;
    }

    if (unit?.type == currentTurn) {
      selectedTile = Offset(col.toDouble(), row.toDouble());
      moveRange = _calculateMoveRange(row, col, unit!);
      attackRange = _calculateAttackRange(row, col, unit);
      notifyListeners();
    }
  }

  void moveUnit(int targetRow, int targetCol) {
    if (selectedTile == null) return;

    int selectedRow = selectedTile!.dy.toInt();
    int selectedCol = selectedTile!.dx.toInt();

    double distance = sqrt(
      pow(targetRow - selectedRow, 2) + pow(targetCol - selectedCol, 2),
    );

    if (distance <= board[selectedRow][selectedCol]!.movement) {
      board[targetRow][targetCol] = board[selectedRow][selectedCol];
      board[selectedRow][selectedCol] = null;

      actedUnits.add(Offset(targetCol.toDouble(), targetRow.toDouble()));
      clearSelection();
    }
  }

  void attack(int targetRow, int targetCol, BuildContext context) async {
    if (selectedTile == null) return;

    int selectedRow = selectedTile!.dy.toInt();
    int selectedCol = selectedTile!.dx.toInt();
    Unit attacker = board[selectedRow][selectedCol]!;
    Unit target = board[targetRow][targetCol]!;

    double distance = sqrt(
      pow(targetRow - selectedRow, 2) + pow(targetCol - selectedCol, 2),
    );

    if (distance <= attacker.attackRange) {
      _performAttack(selectedRow, selectedCol, targetRow, targetCol);
      clearSelection();
    }
  }

  Future<void> attemptCharge(
    int targetRow,
    int targetCol,
    BuildContext context,
  ) async {
    if (selectedTile == null) return;

    int selectedRow = selectedTile!.dy.toInt();
    int selectedCol = selectedTile!.dx.toInt();
    Unit attacker = board[selectedRow][selectedCol]!;

    double distance = sqrt(
      pow(targetRow - selectedRow, 2) + pow(targetCol - selectedCol, 2),
    );

    if (attacker.type == 'tyranid' &&
        attacker.attackRange == 1 &&
        distance <= 12) {
      // We'll need to move the dice roller code or implement a callback
      // For now, let's simulate the roll
      int chargeRoll = await _simulateRoll2D6(
        context,
        distance: distance.round(),
      );

      if (chargeRoll >= distance) {
        _performAttack(selectedRow, selectedCol, targetRow, targetCol);

        Offset finalOffset = Offset(
          selectedCol.toDouble(),
          selectedRow.toDouble(),
        );

        if (board[targetRow][targetCol] == null) {
          board[targetRow][targetCol] = attacker;
          board[selectedRow][selectedCol] = null;
          finalOffset = Offset(targetCol.toDouble(), targetRow.toDouble());
        } else {
          // Find adjacent spot
          finalOffset = _findAdjacentSpot(
            selectedRow,
            selectedCol,
            targetRow,
            targetCol,
            attacker,
          );
        }

        actedUnits.add(finalOffset);
      } else {
        actedUnits.add(Offset(selectedCol.toDouble(), selectedRow.toDouble()));
      }

      clearSelection();
    }
  }

  Offset _findAdjacentSpot(
    int selectedRow,
    int selectedCol,
    int targetRow,
    int targetCol,
    Unit attacker,
  ) {
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
          board[newRow][newCol] == null) {
        board[newRow][newCol] = attacker;
        board[selectedRow][selectedCol] = null;
        return Offset(newCol.toDouble(), newRow.toDouble());
      }
    }

    // If no spot found, don't move
    return Offset(selectedCol.toDouble(), selectedRow.toDouble());
  }

  void _performAttack(
    int selectedRow,
    int selectedCol,
    int targetRow,
    int targetCol,
  ) {
    Unit attacker = board[selectedRow][selectedCol]!;
    Unit target = board[targetRow][targetCol]!;

    target.hp -= attacker.damage;

    if (target.hp <= 0) {
      target.hp = 0;
    }

    actedUnits.add(Offset(selectedCol.toDouble(), selectedRow.toDouble()));
    notifyListeners();
  }

  void clearSelection() {
    selectedTile = null;
    moveRange = [];
    attackRange = [];
    notifyListeners();
  }

  void endTurn() {
    currentTurn = currentTurn == 'space_marine' ? 'tyranid' : 'space_marine';
    actedUnits.clear();
    notifyListeners();
  }

  List<Offset> _calculateMoveRange(int row, int col, Unit unit) {
    List<Offset> result = [];
    for (int i = -unit.movement; i <= unit.movement; i++) {
      for (int j = -unit.movement; j <= unit.movement; j++) {
        int newRow = row + i;
        int newCol = col + j;
        if (newRow >= 0 && newRow < 10 && newCol >= 0 && newCol < 14) {
          if (sqrt(i * i + j * j) <= unit.movement) {
            result.add(Offset(newCol.toDouble(), newRow.toDouble()));
          }
        }
      }
    }
    return result;
  }

  List<Offset> _calculateAttackRange(int row, int col, Unit unit) {
    List<Offset> result = [];
    for (int i = -unit.attackRange; i <= unit.attackRange; i++) {
      for (int j = -unit.attackRange; j <= unit.attackRange; j++) {
        int newRow = row + i;
        int newCol = col + j;
        if (newRow >= 0 && newRow < 10 && newCol >= 0 && newCol < 14) {
          if (sqrt(i * i + j * j) <= unit.attackRange) {
            result.add(Offset(newCol.toDouble(), newRow.toDouble()));
          }
        }
      }
    }
    return result;
  }

  // Temporary method to simulate dice rolling until we refactor dice_roller
  Future<int> _simulateRoll2D6(
    BuildContext context, {
    required int distance,
  }) async {
    // In a complete implementation, this would call your dice_roller
    return Random().nextInt(6) + Random().nextInt(6) + 2; // 2d6
  }
}
