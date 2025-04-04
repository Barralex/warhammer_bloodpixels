import 'package:flutter/material.dart';
import 'dart:math';
import '../models/game_state.dart';
import '../models/unit.dart';
import '../widgets/game_tile.dart';
import '../widgets/dice_roller.dart';
import '../widgets/battle_log_panel.dart';
import '../widgets/radial_menu.dart'; // Importar el menú radial

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

  void _checkVictoryCondition(BuildContext context) {
    final allUnits =
        gameState.board.expand((row) => row).whereType<Unit>().toList();

    final hasTyranids = allUnits.any((u) => u.type == 'tyranid' && u.hp > 0);
    final hasMarines = allUnits.any(
      (u) => u.type == 'space_marine' && u.hp > 0,
    );

    if (!hasTyranids || !hasMarines) {
      String winner = hasTyranids ? "Tiranidos" : "Space Marines";
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (_) => AlertDialog(
              title: Text('Victoria'),
              content: Text('$winner han ganado la batalla.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      gameState = GameState();
                    });
                  },
                  child: const Text('Reiniciar juego'),
                ),
              ],
            ),
      );
    }
  }

  void _onTileTapped(int row, int col) async {
    Unit? unit = gameState.board[row][col];
    Offset tappedOffset = Offset(col.toDouble(), row.toDouble());

    // Si ya estamos en modo movimiento y clicamos en un espacio válido
    if (gameState.actionMode == ActionMode.move &&
        gameState.moveRange.contains(tappedOffset) &&
        unit == null) {
      gameState.moveUnit(row, col);
      gameState.setActionMode(ActionMode.none);
      _checkVictoryCondition(context);
      return;
    }

    // Si ya estamos en modo carga y clicamos un enemigo válido
    if (gameState.actionMode == ActionMode.charge &&
        unit?.type != gameState.currentTurn) {
      await gameState.attemptCharge(row, col, context);
      gameState.setActionMode(ActionMode.none);
      _checkVictoryCondition(context);
      return;
    }

    // Si ya estamos en modo ataque y clicamos un enemigo válido
    if (gameState.actionMode == ActionMode.attack &&
        gameState.attackRange.contains(tappedOffset) &&
        unit?.type != gameState.currentTurn) {
      gameState.attack(row, col, context);
      gameState.setActionMode(ActionMode.none);
      _checkVictoryCondition(context);
      return;
    }

    // Seleccionar una unidad amiga que no haya actuado
    if (unit?.type == gameState.currentTurn &&
        !gameState.actedUnits.contains(tappedOffset)) {
      gameState.selectTile(row, col);
      // Mostrar menú radial
      _showRadialMenu(context, row, col);
    } else {
      // Si clicamos en cualquier otra parte, limpiamos selección
      gameState.clearSelection();
    }
  }

  void _showRadialMenu(BuildContext context, int row, int col) {
    final selectedRow = gameState.selectedTile!.dy.toInt();
    final selectedCol = gameState.selectedTile!.dx.toInt();
    final selectedUnit = gameState.board[selectedRow][selectedCol]!;

    // Comprobar si la unidad está trabada en combate
    bool isLockedInCombat = _isEngaged(selectedRow, selectedCol);

    // Calcular posición en pantalla para el menú
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset position = box.localToGlobal(Offset.zero);
    final cellWidth = box.size.width / 14;
    final cellHeight = box.size.height / 10;

    final double menuSize = 150;
    final menuX = ((col * cellWidth) + position.dx + (cellWidth / 2)).clamp(
      position.dx + menuSize / 2,
      position.dx + box.size.width - menuSize / 2,
    );
    final menuY = ((row * cellHeight) + position.dy + (cellHeight / 2)).clamp(
      position.dy + menuSize / 2,
      position.dy + box.size.height - menuSize / 2,
    );

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
        return Stack(
          children: [
            Positioned(
              left: menuX - 75,
              top: menuY - 75,
              child: RadialMenu(
                onMoveSelected: () {
                  if (!isLockedInCombat) {
                    gameState.setActionMode(ActionMode.move);
                    Navigator.of(context).pop();
                  } else {
                    // Registrar en el log en lugar de mostrar SnackBar
                    gameState.battleLog.add(
                      'Unidad trabada en combate. No puede moverse.',
                    );
                    gameState.notifyListeners();
                    Navigator.of(context).pop();
                  }
                },
                onAttackSelected: () {
                  gameState.setActionMode(ActionMode.attack);
                  Navigator.of(context).pop();
                },
                onChargeSelected: () {
                  if (selectedUnit.type == gameState.currentTurn) {
                    final selectedRow = gameState.selectedTile!.dy.toInt();
                    final selectedCol = gameState.selectedTile!.dx.toInt();

                    final range = <Offset>{};
                    for (int r = 0; r < 10; r++) {
                      for (int c = 0; c < 14; c++) {
                        final distance = sqrt(
                          pow(r - selectedRow, 2) + pow(c - selectedCol, 2),
                        );
                        if (distance <= 12) {
                          range.add(Offset(c.toDouble(), r.toDouble()));
                        }
                      }
                    }

                    gameState.attackRange = range.toList();
                    gameState.setActionMode(ActionMode.charge);
                    Navigator.of(context).pop();
                  }
                },
                onEndTurnSelected: () {
                  gameState.clearSelection();
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        );
      },
    );
  }

  bool _isEngaged(int row, int col) {
    final type = gameState.board[row][col]?.type;
    if (type == null) return false;

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
          newRow < 10 &&
          newCol >= 0 &&
          newCol < 14 &&
          gameState.board[newRow][newCol] != null &&
          gameState.board[newRow][newCol]!.type != type &&
          gameState.board[newRow][newCol]!.hp > 0) {
        return true;
      }
    }
    return false;
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
      _checkVictoryCondition(context);
    });
  }

  Widget _buildTurnBanner() {
    bool isMarineTurn = gameState.currentTurn == 'space_marine';
    String factionName = isMarineTurn ? "Space Marines" : "Tiranidos";
    String imageAsset =
        isMarineTurn ? 'assets/space_marine.png' : 'assets/tyranid.png';

    Color backgroundColor =
        isMarineTurn
            ? const Color(0xFF0B1E36) // azul oscuro marines
            : const Color(0xFF3A0D0D); // rojo púrpura tiránidos

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(imageAsset, width: 32, height: 32),
          const SizedBox(width: 12),
          Text(
            'Turno ${gameState.turnNumber}  –  $factionName',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(width: 12),
          Image.asset(imageAsset, width: 32, height: 32),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.brown[800],
        title: _buildTurnBanner(),
        centerTitle: true,
      ),
      body: Row(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              color: const Color(0xFFF5F5DC),
              child: Center(
                child: AspectRatio(
                  aspectRatio: 14 / 10,
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
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
                        actionMode:
                            gameState.actionMode, // Añadir este parámetro
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          BattleLogPanel(logLines: gameState.battleLog),
        ],
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
