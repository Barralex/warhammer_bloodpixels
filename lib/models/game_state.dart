import 'package:flutter/material.dart';
import 'dart:math';
import 'unit.dart';
import '../widgets/battle_log_panel.dart';

class GameState extends ChangeNotifier {
  int turnNumber = 1;
  List<List<Unit?>> board = List.generate(10, (index) => List.filled(14, null));
  Offset? selectedTile;
  String currentTurn = 'space_marine';
  List<Offset> moveRange = [];
  List<Offset> attackRange = [];
  Set<Offset> actedUnits = {};
  List<String> battleLog = [];

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
      bool attackerEngaged = _isEngaged(selectedRow, selectedCol);
      bool targetProtected = _enemyAdjacentToTarget(
        selectedRow,
        selectedCol,
        targetRow,
        targetCol,
      );

      if (attackerEngaged || targetProtected) {
        battleLog.add('¡Disparo no permitido! Unidad en combate cercano.');
        clearSelection();
        notifyListeners();
        return;
      }

      _performAttack(selectedRow, selectedCol, targetRow, targetCol, context);
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
      int chargeRoll = await _simulateRoll2D6(
        context,
        distance: distance.round(),
      );

      if (chargeRoll >= distance) {
        _performAttack(selectedRow, selectedCol, targetRow, targetCol, context);

        Offset finalOffset = Offset(
          selectedCol.toDouble(),
          selectedRow.toDouble(),
        );

        if (board[targetRow][targetCol] == null) {
          board[targetRow][targetCol] = attacker;
          board[selectedRow][selectedCol] = null;
          finalOffset = Offset(targetCol.toDouble(), targetRow.toDouble());
        } else {
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

    return Offset(selectedCol.toDouble(), selectedRow.toDouble());
  }

  Future<void> _performAttack(
    int selectedRow,
    int selectedCol,
    int targetRow,
    int targetCol,
    BuildContext context,
  ) async {
    Unit attacker = board[selectedRow][selectedCol]!;
    Unit target = board[targetRow][targetCol]!;

    // Número de ataques (2 para marines con bólter)
    int numAttacks = attacker.type == 'space_marine' ? 2 : 1;
    int successfulHits = 0;

    List<int> hitRolls = [];

    // Tiradas para impactar
    for (int i = 0; i < numAttacks; i++) {
      int hitRoll = Random().nextInt(6) + 1;
      hitRolls.add(hitRoll);

      // Comprueba si impacta (BS o mejor)
      if (hitRoll >= attacker.weaponBS) {
        successfulHits++;
      }
    }

    battleLog.add('$numAttacks ataques: Tiradas ${hitRolls.join(', ')}');
    battleLog.add('Impactos: $successfulHits');

    // Tiradas de salvación
    int savedWounds = 0;
    if (successfulHits > 0) {
      List<int> saveRolls = [];
      for (int i = 0; i < successfulHits; i++) {
        int saveRoll = Random().nextInt(6) + 1;
        saveRolls.add(saveRoll);

        // Salva en 5+ para tiránidos, 3+ para marines
        int saveTarget = target.type == 'space_marine' ? 3 : 5;
        battleLog.add(
          'Objetivo (${target.type}) necesita $saveTarget+ para salvar',
        );
        if (saveRoll >= saveTarget) {
          savedWounds++;
        }
      }

      battleLog.add('Salvación: Tiradas ${saveRolls.join(', ')}');
      battleLog.add('Salvados: $savedWounds');
    }

    // Aplica daño
    int woundsToApply = successfulHits - savedWounds;
    if (woundsToApply > 0) {
      target.hp -= woundsToApply * attacker.damage;

      // Registra el ataque
      String attackerType =
          attacker.type == 'space_marine' ? 'Marine' : 'Tiranido';
      String targetType = target.type == 'space_marine' ? 'Marine' : 'Tiranido';

      battleLog.add('$attackerType causa $woundsToApply heridas a $targetType');

      if (target.hp <= 0) {
        target.hp = 0;
        battleLog.add('$targetType muere ☠️');
      }
    } else {
      battleLog.add('¡Todos los ataques fueron salvados!');
    }

    actedUnits.add(Offset(selectedCol.toDouble(), selectedRow.toDouble()));
    battleLog.add('---');
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
    if (currentTurn == 'space_marine') {
      turnNumber++;
    }
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

  Future<int> _simulateRoll2D6(
    BuildContext context, {
    required int distance,
  }) async {
    int d1 = Random().nextInt(6) + 1;
    int d2 = Random().nextInt(6) + 1;
    int total = d1 + d2;

    battleLog.add(
      'Carga: tirada $d1 + $d2 = $total contra distancia $distance',
    );
    battleLog.add(total >= distance ? 'Carga exitosa.' : 'Carga fallida.');

    notifyListeners();
    return total;
  }

  bool _isEngaged(int row, int col) {
    final type = board[row][col]?.type;
    if (type == null) return false;

    for (int i = -1; i <= 1; i++) {
      for (int j = -1; j <= 1; j++) {
        if (i == 0 && j == 0) continue;
        int newRow = row + i;
        int newCol = col + j;
        if (newRow >= 0 &&
            newRow < 10 &&
            newCol >= 0 &&
            newCol < 14 &&
            board[newRow][newCol]?.type != null &&
            board[newRow][newCol]!.type != type) {
          return true;
        }
      }
    }
    return false;
  }

  bool _enemyAdjacentToTarget(
    int attackerRow,
    int attackerCol,
    int targetRow,
    int targetCol,
  ) {
    final attackerType = board[attackerRow][attackerCol]?.type;
    if (attackerType == null) return false;

    for (int i = -1; i <= 1; i++) {
      for (int j = -1; j <= 1; j++) {
        if (i == 0 && j == 0) continue;
        int newRow = attackerRow + i;
        int newCol = attackerCol + j;
        if (newRow >= 0 &&
            newRow < 10 &&
            newCol >= 0 &&
            newCol < 14 &&
            !(newRow == targetRow && newCol == targetCol) &&
            board[newRow][newCol]?.type != null &&
            board[newRow][newCol]!.type != attackerType) {
          return true;
        }
      }
    }
    return false;
  }
}
