import 'package:flutter/material.dart';
import 'dart:math';
import 'unit.dart';

enum ActionMode { none, move, attack, charge, melee }

class GameState extends ChangeNotifier {
  ActionMode actionMode = ActionMode.none;
  int turnNumber = 1;
  List<List<Unit?>> board = List.generate(10, (index) => List.filled(14, null));
  Offset? selectedTile;
  List<Offset> chargeRange = [];
  String currentTurn = 'space_marine';
  List<Offset> moveRange = [];
  List<Offset> attackRange = [];
  Set<Offset> actedUnits = {};
  List<String> battleLog = [];

  GameState() {
    _initializeBoard();
  }

  void setActionMode(ActionMode mode) {
    actionMode = mode;

    if (selectedTile != null) {
      int row = selectedTile!.dy.toInt();
      int col = selectedTile!.dx.toInt();
      Unit unit = board[row][col]!;

      if (mode == ActionMode.move) {
        moveRange = _calculateMoveRange(row, col, unit);
        attackRange = [];
        chargeRange = [];
      } else if (mode == ActionMode.attack) {
        attackRange = _calculateAttackRange(row, col, unit);
        moveRange = [];
        chargeRange = [];
      } else if (mode == ActionMode.charge) {
        chargeRange = _calculateChargeRange(row, col, unit);
        moveRange = [];
        attackRange = [];
      } else if (mode == ActionMode.melee) {
        moveRange = [];
        attackRange = [];
        chargeRange = [];
      } else {
        moveRange = [];
        attackRange = [];
        chargeRange = [];
      }
    }

    notifyListeners();
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

  List<Offset> _calculateChargeRange(int row, int col, Unit unit) {
    List<Offset> result = [];
    for (int r = 0; r < 10; r++) {
      for (int c = 0; c < 14; c++) {
        double distance = sqrt(pow(r - row, 2) + pow(c - col, 2));
        // Dentro del rango de carga (12")
        if (distance <= 12 && distance > 1) {
          result.add(Offset(c.toDouble(), r.toDouble()));
        }
      }
    }
    return result;
  }

  void selectTile(int row, int col) {
    Offset tappedOffset = Offset(col.toDouble(), row.toDouble());
    Unit? unit = board[row][col];

    if (unit?.type == currentTurn && actedUnits.contains(tappedOffset)) {
      return;
    }

    if (unit?.type == currentTurn) {
      selectedTile = Offset(col.toDouble(), row.toDouble());
      // No calculamos rangos aquí - esperamos a que el usuario seleccione una acción
      moveRange = [];
      attackRange = [];
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
    Unit? target = board[targetRow][targetCol];

    // Verificar que hay un enemigo para cargar
    if (target == null || target.type == attacker.type) return;

    double distance = sqrt(
      pow(targetRow - selectedRow, 2) + pow(targetCol - selectedCol, 2),
    );

    // Permitir cargas a unidades adyacentes
    if (distance <= 12 && distance > 1) {
      int chargeRoll = await _simulateRoll2D6(
        context,
        distance: distance.round(),
      );

      battleLog.add('Distancia de carga: $distance, Tirada: $chargeRoll');

      if (chargeRoll >= distance) {
        // Ya no hacemos daño aquí, solo movemos la unidad
        // Mover unidad atacante cerca del objetivo
        Offset finalOffset = _findAdjacentSpot(
          selectedRow,
          selectedCol,
          targetRow,
          targetCol,
          attacker,
        );

        actedUnits.add(finalOffset);
        battleLog.add(
          '¡Carga exitosa! Ahora puedes atacar en combate cuerpo a cuerpo.',
        );
      } else {
        actedUnits.add(Offset(selectedCol.toDouble(), selectedRow.toDouble()));
        battleLog.add('Carga fallida');
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

  void performMeleeAttack(int targetRow, int targetCol, BuildContext context) {
    if (selectedTile == null) return;

    int selectedRow = selectedTile!.dy.toInt();
    int selectedCol = selectedTile!.dx.toInt();
    Unit attacker = board[selectedRow][selectedCol]!;
    Unit target = board[targetRow][targetCol]!;

    // Verificar que están a 1" de distancia
    double distance = sqrt(
      pow(targetRow - selectedRow, 2) + pow(targetCol - selectedCol, 2),
    );

    if (distance <= 1.5) {
      // Usamos 1.5 para capturar casillas diagonales
      // Número de ataques según el tipo de unidad
      int numAttacks =
          attacker.type == 'space_marine'
              ? 2
              : (attacker.type == 'tyranid')
              ? 1
              : 1;

      battleLog.add(
        '${attacker.type == 'space_marine' ? 'Marine' : 'Tiranido'} realiza $numAttacks ataques cuerpo a cuerpo',
      );

      int successfulHits = 0;
      List<int> hitRolls = [];

      // Tiradas para impactar en combate (más sencillo de impactar en cuerpo a cuerpo)
      for (int i = 0; i < numAttacks; i++) {
        int hitRoll = Random().nextInt(6) + 1;
        hitRolls.add(hitRoll);

        // En combate cuerpo a cuerpo, impacta con 3+ para marines y 4+ para tiránidos
        int hitTarget = attacker.type == 'space_marine' ? 3 : 4;
        if (hitRoll >= hitTarget) {
          successfulHits++;
        }
      }

      battleLog.add('Tiradas para impactar: ${hitRolls.join(', ')}');
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
          if (saveRoll >= saveTarget) {
            savedWounds++;
          }
        }

        battleLog.add('Tiradas de salvación: ${saveRolls.join(', ')}');
        battleLog.add('Salvados: $savedWounds');
      }

      // Aplica daño
      int woundsToApply = successfulHits - savedWounds;
      if (woundsToApply > 0) {
        target.hp -= woundsToApply * attacker.damage;

        // Registra el ataque
        String attackerType =
            attacker.type == 'space_marine' ? 'Marine' : 'Tiranido';
        String targetType =
            target.type == 'space_marine' ? 'Marine' : 'Tiranido';

        battleLog.add(
          '$attackerType causa $woundsToApply heridas a $targetType en combate cuerpo a cuerpo',
        );

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
    actionMode = ActionMode.none; // Reset del modo de acción
    notifyListeners();
  }

  void endTurn() {
    currentTurn = currentTurn == 'space_marine' ? 'tyranid' : 'space_marine';
    if (currentTurn == 'space_marine') {
      turnNumber++;
    }
    actedUnits.clear();
    clearSelection(); // Limpiar selección al final del turno
    notifyListeners();
  }

  List<Offset> _calculateMoveRange(int row, int col, Unit unit) {
    List<Offset> result = [];
    for (int i = -unit.movement; i <= unit.movement; i++) {
      for (int j = -unit.movement; j <= unit.movement; j++) {
        int newRow = row + i;
        int newCol = col + j;
        if (newRow >= 0 && newRow < 10 && newCol >= 0 && newCol < 14) {
          if (sqrt(i * i + j * j) <= unit.movement &&
              board[newRow][newCol] == null) {
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
            // Cambio clave: incluye TODOS los tiles dentro del rango
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
