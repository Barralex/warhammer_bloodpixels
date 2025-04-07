import 'package:flutter/material.dart';
import 'dart:math';
import 'unit.dart';
import '../constants/game_constants.dart';

enum ActionMode { none, move, attack, charge, melee }

class GameState extends ChangeNotifier {
  ActionMode actionMode = ActionMode.none;
  int turnNumber = 1;
  List<List<Unit?>> board = List.generate(
    GameConstants.BOARD_ROWS,
    (index) => List.filled(GameConstants.BOARD_COLS, null),
  );
  Offset? selectedTile;
  List<Offset> chargeRange = [];
  String currentTurn = 'space_marine';
  List<Offset> moveRange = [];
  List<Offset> attackRange = [];
  Set<Offset> actedUnits = {};
  List<String> battleLog = [];
  bool isInfoMode = false;
  Map<Offset, int> remainingActions =
      {}; // Rastrear acciones restantes por unidad
  Map<Offset, UnitActions> unitActionsMap = {};

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

    // 10 Termagantes en fila 0
    for (int i = 0; i < 10; i++) {
      board[0][i] = Unit("tyranid");
    }

    // 1 Enjambre Devorador
    board[0][10] = Unit("reaper_swarm");

    // 4 Marines Infernus en la última fila
    for (int i = 0; i < 4; i++) {
      board[GameConstants.BOARD_ROWS - 1][i] = Unit("space_marine");
    }

    // 1 Sargento Infernus
    board[GameConstants.BOARD_ROWS - 1][4] = Unit("sergeant");
  }

  List<Offset> _calculateChargeRange(int row, int col, Unit unit) {
    List<Offset> result = [];
    for (int r = 0; r < GameConstants.BOARD_ROWS; r++) {
      for (int c = 0; c < GameConstants.BOARD_COLS; c++) {
        double distance = sqrt(pow(r - row, 2) + pow(c - col, 2));
        // Dentro del rango de carga (12")
        if (distance <= GameConstants.CHARGE_RANGE && distance > 1) {
          result.add(Offset(c.toDouble(), r.toDouble()));
        }
      }
    }
    return result;
  }

  void selectTile(int row, int col) {
    Offset tappedOffset = Offset(col.toDouble(), row.toDouble());
    Unit? unit = board[row][col];

    if (unit == null) {
      clearSelection();
      return;
    }

    isInfoMode = unit.faction != currentTurn;
    selectedTile = tappedOffset;

    if (unit.faction == currentTurn && !actedUnits.contains(tappedOffset)) {
      // Initialize remaining actions to 4 for the selected unit
      remainingActions[tappedOffset] = 4; // Changed from 2 to 4
      moveRange = [];
      attackRange = [];
    }

    notifyListeners();
  }

  void moveUnit(int targetRow, int targetCol) {
    if (selectedTile == null) return;

    int selectedRow = selectedTile!.dy.toInt();
    int selectedCol = selectedTile!.dx.toInt();
    Offset unitPos = Offset(selectedCol.toDouble(), selectedRow.toDouble());

    // Check if the unit can move
    if (!canPerformAction(unitPos, ActionMode.move)) {
      battleLog.add('La unidad ya no puede moverse.');
      notifyListeners();
      return;
    }

    double distance = sqrt(
      pow(targetRow - selectedRow, 2) + pow(targetCol - selectedCol, 2),
    );

    if (distance <= board[selectedRow][selectedCol]!.movement) {
      // Consume an action before moving
      useAction(unitPos, ActionMode.move);

      // Move the unit
      board[targetRow][targetCol] = board[selectedRow][selectedCol];
      board[selectedRow][selectedCol] = null;

      // Update the position in the action map
      Offset newPos = Offset(targetCol.toDouble(), targetRow.toDouble());
      if (unitActionsMap.containsKey(unitPos)) {
        unitActionsMap[newPos] = unitActionsMap[unitPos]!;
        unitActionsMap.remove(unitPos);

        // If the unit is in actedUnits, update its position
        if (actedUnits.contains(unitPos)) {
          actedUnits.remove(unitPos);
          actedUnits.add(newPos);
        }
      }

      battleLog.add(
        'Unidad movida. Acciones restantes: ${unitActionsMap[newPos]!.remainingActions}',
      );
      clearSelection();
    }
  }

  void attack(int targetRow, int targetCol, BuildContext context) async {
    if (selectedTile == null) return;

    int selectedRow = selectedTile!.dy.toInt();
    int selectedCol = selectedTile!.dx.toInt();
    Offset unitPos = Offset(selectedCol.toDouble(), selectedRow.toDouble());

    // Check if the unit can attack
    if (!canPerformAction(unitPos, ActionMode.attack)) {
      battleLog.add('La unidad ya no puede atacar.');
      notifyListeners();
      return;
    }

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

      // Consume an action before attacking
      useAction(unitPos, ActionMode.attack);

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
    Offset unitPos = Offset(selectedCol.toDouble(), selectedRow.toDouble());
    Unit attacker = board[selectedRow][selectedCol]!;
    Unit? target = board[targetRow][targetCol];

    // Check if the unit can charge
    if (!canPerformAction(unitPos, ActionMode.charge)) {
      battleLog.add('La unidad ya no puede cargar en este turno.');
      notifyListeners();
      return;
    }

    // Verify that there is an enemy to charge
    if (target == null || target.faction == attacker.faction) return;

    double distance = sqrt(
      pow(targetRow - selectedRow, 2) + pow(targetCol - selectedCol, 2),
    );

    // Allow charges to units within range
    if (distance <= GameConstants.CHARGE_RANGE && distance > 1) {
      int chargeRoll = await _simulateRoll2D6(
        context,
        distance: distance.round(),
      );

      battleLog.add('Distancia de carga: $distance, Tirada: $chargeRoll');

      if (chargeRoll >= distance) {
        // Consume an action before the charge
        useAction(unitPos, ActionMode.charge);

        // Move the attacking unit near the target
        Offset finalOffset = _findAdjacentSpot(
          selectedRow,
          selectedCol,
          targetRow,
          targetCol,
          attacker,
        );

        // Transfer the action state to the new position
        if (unitActionsMap.containsKey(unitPos)) {
          unitActionsMap[finalOffset] = unitActionsMap[unitPos]!;
          unitActionsMap.remove(unitPos);

          // Update position in actedUnits if necessary
          if (actedUnits.contains(unitPos)) {
            actedUnits.remove(unitPos);
            actedUnits.add(finalOffset);
          }
        }

        battleLog.add(
          '¡Carga exitosa! Ahora puedes atacar en combate cuerpo a cuerpo. Acciones restantes: ${unitActionsMap[finalOffset]!.remainingActions}',
        );
      } else {
        // Consume an action even if the charge fails
        useAction(unitPos, ActionMode.charge);
        battleLog.add(
          'Carga fallida. Acciones restantes: ${unitActionsMap[unitPos]!.remainingActions}',
        );
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
          newRow < GameConstants.BOARD_ROWS &&
          newCol >= 0 &&
          newCol < GameConstants.BOARD_COLS &&
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
    Offset unitPos = Offset(selectedCol.toDouble(), selectedRow.toDouble());

    // Check if the unit can perform melee attack
    if (!canPerformAction(unitPos, ActionMode.melee)) {
      battleLog.add('La unidad ya no puede atacar en combate cuerpo a cuerpo.');
      notifyListeners();
      return;
    }

    Unit attacker = board[selectedRow][selectedCol]!;
    Unit target = board[targetRow][targetCol]!;

    // Verificar que están a 1" de distancia
    double distance = sqrt(
      pow(targetRow - selectedRow, 2) + pow(targetCol - selectedCol, 2),
    );

    if (distance <= GameConstants.ENGAGEMENT_RANGE) {
      // Consume an action before attacking
      useAction(unitPos, ActionMode.melee);

      // Número de ataques según el tipo de unidad
      int numAttacks =
          attacker.faction == 'space_marine'
              ? 2
              : (attacker.faction == 'tyranid')
              ? 1
              : 1;

      battleLog.add(
        '${attacker.faction == 'space_marine' ? 'Marine' : 'Tiranido'} realiza $numAttacks ataques cuerpo a cuerpo',
      );

      int successfulHits = 0;
      List<int> hitRolls = [];

      // Tiradas para impactar en combate (más sencillo de impactar en cuerpo a cuerpo)
      for (int i = 0; i < numAttacks; i++) {
        int hitRoll = Random().nextInt(GameConstants.DICE_SIDES) + 1;
        hitRolls.add(hitRoll);

        // En combate cuerpo a cuerpo, impacta con 3+ para marines y 4+ para tiránidos
        int hitTarget = attacker.faction == 'space_marine' ? 3 : 4;
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
          int saveRoll = Random().nextInt(GameConstants.DICE_SIDES) + 1;
          saveRolls.add(saveRoll);

          // Salva en 5+ para tiránidos, 3+ para marines
          int saveTarget = target.faction == 'space_marine' ? 3 : 5;
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
            attacker.faction == 'space_marine' ? 'Marine' : 'Tiranido';
        String targetType =
            target.faction == 'space_marine' ? 'Marine' : 'Tiranido';

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
    int numAttacks = attacker.faction == 'space_marine' ? 2 : 1;
    int successfulHits = 0;

    List<int> hitRolls = [];

    // Tiradas para impactar
    for (int i = 0; i < numAttacks; i++) {
      int hitRoll = Random().nextInt(GameConstants.DICE_SIDES) + 1;
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
        int saveRoll = Random().nextInt(GameConstants.DICE_SIDES) + 1;
        saveRolls.add(saveRoll);

        // Salva en 5+ para tiránidos, 3+ para marines
        int saveTarget = target.faction == 'space_marine' ? 3 : 5;
        battleLog.add(
          'Objetivo (${target.faction}) necesita $saveTarget+ para salvar',
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
          attacker.faction == 'space_marine' ? 'Marine' : 'Tiranido';
      String targetType =
          target.faction == 'space_marine' ? 'Marine' : 'Tiranido';

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

    // Reset all actions at the end of the turn
    unitActionsMap.clear();
    actedUnits.clear();

    clearSelection();
    notifyListeners();
  }

  List<Offset> _calculateMoveRange(int row, int col, Unit unit) {
    List<Offset> result = [];
    for (int i = -unit.movement; i <= unit.movement; i++) {
      for (int j = -unit.movement; j <= unit.movement; j++) {
        int newRow = row + i;
        int newCol = col + j;
        if (newRow >= 0 &&
            newRow < GameConstants.BOARD_ROWS &&
            newCol >= 0 &&
            newCol < GameConstants.BOARD_COLS) {
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
        if (newRow >= 0 &&
            newRow < GameConstants.BOARD_ROWS &&
            newCol >= 0 &&
            newCol < GameConstants.BOARD_COLS) {
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
    int d1 = Random().nextInt(GameConstants.DICE_SIDES) + 1;
    int d2 = Random().nextInt(GameConstants.DICE_SIDES) + 1;
    int total = d1 + d2;

    battleLog.add(
      'Carga: tirada $d1 + $d2 = $total contra distancia $distance',
    );
    battleLog.add(total >= distance ? 'Carga exitosa.' : 'Carga fallida.');

    notifyListeners();
    return total;
  }

  bool _isEngaged(int row, int col) {
    final unit = board[row][col];
    if (unit == null) return false;

    for (int i = -1; i <= 1; i++) {
      for (int j = -1; j <= 1; j++) {
        if (i == 0 && j == 0) continue;
        int newRow = row + i;
        int newCol = col + j;
        if (newRow >= 0 &&
            newRow < GameConstants.BOARD_ROWS &&
            newCol >= 0 &&
            newCol < GameConstants.BOARD_COLS) {
          final neighbor = board[newRow][newCol];
          if (neighbor != null && neighbor.faction != unit.faction) {
            return true;
          }
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
    final attacker = board[attackerRow][attackerCol];
    if (attacker == null) return false;

    for (int i = -1; i <= 1; i++) {
      for (int j = -1; j <= 1; j++) {
        if (i == 0 && j == 0) continue;
        int newRow = attackerRow + i;
        int newCol = attackerCol + j;
        if (newRow >= 0 &&
            newRow < GameConstants.BOARD_ROWS &&
            newCol >= 0 &&
            newCol < GameConstants.BOARD_COLS &&
            !(newRow == targetRow && newCol == targetCol)) {
          final neighbor = board[newRow][newCol];
          if (neighbor != null && neighbor.faction != attacker.faction) {
            return true;
          }
        }
      }
    }
    return false;
  }

  void initializeUnitActions(Offset unitPosition) {
    unitActionsMap.putIfAbsent(unitPosition, () => UnitActions());
  }

  void resetUnitActions() {
    unitActionsMap.clear();
  }

  void markUnitAction(Offset unitPosition, ActionMode action) {
    if (unitActionsMap.containsKey(unitPosition)) {
      switch (action) {
        case ActionMode.move:
          unitActionsMap[unitPosition]!.hasMoved = true;
          break;
        case ActionMode.attack:
          unitActionsMap[unitPosition]!.hasAttacked = true;
          break;
        case ActionMode.charge:
          unitActionsMap[unitPosition]!.hasCharged = true;
          break;
        case ActionMode.melee:
          unitActionsMap[unitPosition]!.hasFought = true;
          break;
        default:
          break;
      }
      notifyListeners();
    }
  }

  Offset? get selectedTileOffset => selectedTile;

  void ensureUnitActions(Offset unitPosition) {
    unitActionsMap.putIfAbsent(unitPosition, () => UnitActions());
  }

  bool canPerformAction(Offset unitPosition, ActionMode actionType) {
    ensureUnitActions(unitPosition);

    UnitActions actions = unitActionsMap[unitPosition]!;

    // If no actions remain, the unit cannot act
    if (!actions.canAct) return false;

    // Check specific restrictions
    switch (actionType) {
      case ActionMode.move:
        return !actions.hasMoved;
      case ActionMode.attack:
        return !actions.hasAttacked;
      case ActionMode.charge:
        return !actions.hasCharged;
      case ActionMode.melee:
        return !actions.hasFought;
      default:
        return true;
    }
  }

  bool useAction(Offset unitPosition, ActionMode actionType) {
    if (!canPerformAction(unitPosition, actionType)) return false;

    UnitActions actions = unitActionsMap[unitPosition]!;

    // Consume an action
    if (!actions.useAction()) return false;

    // Mark the type of action used
    switch (actionType) {
      case ActionMode.move:
        actions.hasMoved = true;
        break;
      case ActionMode.attack:
        actions.hasAttacked = true;
        break;
      case ActionMode.charge:
        actions.hasCharged = true;
        break;
      case ActionMode.melee:
        actions.hasFought = true;
        break;
      default:
        break;
    }

    // If no actions remain, add to the list of acted units
    if (actions.remainingActions <= 0) {
      actedUnits.add(unitPosition);
    }

    notifyListeners();
    return true;
  }
}

class UnitActions {
  bool hasMoved = false;
  bool hasAttacked = false;
  bool hasCharged = false;
  bool hasFought = false;
  int remainingActions = 4; // Changed from 2 to 4

  // A unit can act if it has remaining actions
  bool get canAct => remainingActions > 0;

  // Consume an action if possible
  bool useAction() {
    if (remainingActions > 0) {
      remainingActions--;
      return true;
    }
    return false;
  }

  UnitActions();
}
