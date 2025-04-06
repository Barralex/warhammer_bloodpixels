import 'package:flutter/material.dart';
import 'dart:math';
import '../models/game_state.dart';
import '../models/unit.dart';
import '../widgets/game_tile.dart';
import '../widgets/battle_log_panel.dart';
import '../widgets/unit_action_panel.dart';
import '../constants/game_constants.dart';
import '../widgets/unit_info_panel.dart';

class GameBoard extends StatefulWidget {
  @override
  _GameBoardState createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  late GameState gameState;
  OverlayEntry? _currentMenuOverlay;

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
            (context) => AlertDialog(
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
    _currentMenuOverlay?.remove();
    _currentMenuOverlay = null;

    Unit? unit = gameState.board[row][col];
    Offset tappedOffset = Offset(col.toDouble(), row.toDouble());

    if (gameState.actionMode == ActionMode.move &&
        gameState.moveRange.contains(tappedOffset) &&
        unit == null) {
      gameState.moveUnit(row, col);
      gameState.setActionMode(ActionMode.none);
      _checkVictoryCondition(context);
      return;
    }

    if (gameState.actionMode == ActionMode.charge &&
        unit?.faction != gameState.currentTurn &&
        !(gameState.unitActionsMap[gameState.selectedTileOffset]?.hasCharged ??
            false)) {
      await gameState.attemptCharge(row, col, context);
      gameState.setActionMode(ActionMode.none);
      _checkVictoryCondition(context);
      return;
    }

    if (gameState.actionMode == ActionMode.attack &&
        gameState.attackRange.contains(tappedOffset) &&
        unit?.faction != gameState.currentTurn) {
      gameState.attack(row, col, context);
      gameState.setActionMode(ActionMode.none);
      _checkVictoryCondition(context);
      return;
    }

    if (gameState.actionMode == ActionMode.melee &&
        unit?.faction != gameState.currentTurn) {
      double distance = _calculateDistance(
        gameState.selectedTile!.dy.toInt(),
        gameState.selectedTile!.dx.toInt(),
        row,
        col,
      );

      if (distance <= GameConstants.ENGAGEMENT_RANGE) {
        gameState.performMeleeAttack(row, col, context);
        gameState.setActionMode(ActionMode.none);
        _checkVictoryCondition(context);
        return;
      }
    }

    if (unit != null) {
      gameState.selectTile(row, col);

      if (unit.faction == gameState.currentTurn &&
          !gameState.actedUnits.contains(tappedOffset)) {
        _showUnitActionPanel(context, row, col);
      }
    } else {
      gameState.clearSelection();
    }
  }

  void _showUnitActionPanel(BuildContext context, int row, int col) {
    _currentMenuOverlay?.remove();

    if (gameState.selectedTile == null) return;

    final selectedRow = gameState.selectedTile!.dy.toInt();
    final selectedCol = gameState.selectedTile!.dx.toInt();
    final selectedUnit = gameState.board[selectedRow][selectedCol]!;

    bool isEngaged = _isEngaged(selectedRow, selectedCol);

    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset position = box.localToGlobal(Offset.zero);
    final double cellWidth = box.size.width / GameConstants.BOARD_COLS;
    final double cellHeight = box.size.height / GameConstants.BOARD_ROWS;

    final double boardLeft = position.dx;
    final double boardRight = position.dx + box.size.width;
    final double boardTop = position.dy;
    final double boardBottom = position.dy + box.size.height;

    const double panelWidth = 40;

    double panelX = ((selectedCol + 1) * cellWidth) + position.dx;

    if (panelX + panelWidth > boardRight) {
      panelX = (selectedCol * cellWidth) - panelWidth + position.dx;
    }

    if (panelX < boardLeft) {
      panelX = (selectedCol * cellWidth) + position.dx;
    }

    const double buttonHeight = 40;
    const double buttonCount = 5;
    const double panelHeight = buttonHeight * buttonCount;

    double panelY =
        (selectedRow * cellHeight) +
        (cellHeight / 2) -
        (panelHeight / 2) +
        position.dy;

    if (panelY < boardTop) {
      panelY = boardTop;
    }

    if (panelY + panelHeight > boardBottom) {
      panelY = boardBottom - panelHeight;
    }

    OverlayState? overlay = Overlay.of(context);

    _currentMenuOverlay = OverlayEntry(
      builder:
          (context) => Positioned(
            left: panelX,
            top: panelY,
            child: Material(
              color: Colors.transparent,
              child: UnitActionPanel(
                selectedUnit: selectedUnit,
                isEngaged: isEngaged,
                unitActionsMap: gameState.unitActionsMap, // Add this argument
                selectedTileOffset:
                    gameState.selectedTile!, // Add this argument
                onMoveSelected: () {
                  if (!isEngaged) {
                    gameState.setActionMode(ActionMode.move);
                    _currentMenuOverlay?.remove();
                    _currentMenuOverlay = null;
                  } else {
                    gameState.battleLog.add(
                      'Unidad trabada en combate. No puede moverse.',
                    );
                    gameState.notifyListeners();
                    _currentMenuOverlay?.remove();
                    _currentMenuOverlay = null;
                  }
                },
                onAttackSelected: () {
                  gameState.setActionMode(ActionMode.attack);
                  _currentMenuOverlay?.remove();
                  _currentMenuOverlay = null;
                },
                onChargeSelected: () {
                  gameState.setActionMode(ActionMode.charge);
                  _currentMenuOverlay?.remove();
                  _currentMenuOverlay = null;
                },
                onMeleeSelected: () {
                  if (isEngaged) {
                    gameState.setActionMode(ActionMode.melee);
                    _currentMenuOverlay?.remove();
                    _currentMenuOverlay = null;
                  } else {
                    gameState.battleLog.add(
                      'No hay enemigos a 1" o menos para combatir.',
                    );
                    gameState.notifyListeners();
                    _currentMenuOverlay?.remove();
                    _currentMenuOverlay = null;
                  }
                },
                onCancelSelected: () {
                  gameState.clearSelection();
                  _currentMenuOverlay?.remove();
                  _currentMenuOverlay = null;
                },
              ),
            ),
          ),
    );

    overlay.insert(_currentMenuOverlay!);
  }

  bool _isEngaged(int row, int col) {
    final unit = gameState.board[row][col];
    if (unit == null) return false;

    for (int i = -1; i <= 1; i++) {
      for (int j = -1; j <= 1; j++) {
        if (i == 0 && j == 0) continue; // Skip the current position
        int newRow = row + i;
        int newCol = col + j;
        if (newRow >= 0 &&
            newRow < GameConstants.BOARD_ROWS &&
            newCol >= 0 &&
            newCol < GameConstants.BOARD_COLS) {
          final neighbor = gameState.board[newRow][newCol];
          if (neighbor != null &&
              neighbor.faction != unit.faction &&
              neighbor.hp > 0) {
            return true;
          }
        }
      }
    }
    return false;
  }

  double _calculateDistance(int fromRow, int fromCol, int toRow, int toCol) {
    return sqrt(pow(toRow - fromRow, 2) + pow(toCol - fromCol, 2));
  }

  Widget _buildTurnBanner() {
    bool isMarineTurn = gameState.currentTurn == 'space_marine';
    String factionName = isMarineTurn ? "Space Marines" : "Tiranidos";
    String imageAsset =
        isMarineTurn
            ? 'assets/space_marine.png'
            : 'assets/tyranids/default.png';

    Color backgroundColor =
        isMarineTurn ? const Color(0xFF0B1E36) : const Color(0xFF3A0D0D);

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
      backgroundColor: Colors.black, // Fondo negro para toda la app
      appBar: AppBar(
        backgroundColor: Colors.black, // Barra negra
        elevation: 0, // Sin sombra
        title: _buildTurnBanner(),
        centerTitle: true,
      ),
      body: Row(
        children: [
          // Panel de juego (tablero)
          Expanded(
            flex: 3,
            child: Container(
              color: const Color(0xFF1E1E1E), // Gris oscuro para el tablero
              child: Center(
                child: AspectRatio(
                  aspectRatio:
                      GameConstants.BOARD_COLS / GameConstants.BOARD_ROWS,
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: GameConstants.BOARD_COLS,
                      childAspectRatio: 1,
                    ),
                    itemCount:
                        GameConstants.BOARD_ROWS * GameConstants.BOARD_COLS,
                    itemBuilder: (context, index) {
                      int row = index ~/ GameConstants.BOARD_COLS;
                      int col = index % GameConstants.BOARD_COLS;
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
                        inChargeRange: gameState.chargeRange.contains(
                          Offset(col.toDouble(), row.toDouble()),
                        ),
                        hasActed: gameState.actedUnits.contains(
                          Offset(col.toDouble(), row.toDouble()),
                        ),
                        onTap: _onTileTapped,
                        board: gameState.board,
                        actionMode: gameState.actionMode,
                        currentTurn: gameState.currentTurn,
                        selectedTilePosition:
                            gameState
                                .selectedTile, // Pasa la posición seleccionada
                        unitActionsMap: gameState.unitActionsMap,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          // Panel lateral
          Container(
            width: GameConstants.BATTLE_LOG_PANEL_WIDTH,
            color: Colors.black, // Fondo negro para el panel
            child: Column(
              children: [
                // Panel de info de unidad
                UnitInfoPanel(
                  selectedUnit:
                      gameState.selectedTile != null
                          ? gameState.board[gameState.selectedTile!.dy
                              .toInt()][gameState.selectedTile!.dx.toInt()]
                          : null,
                ),
                // Logs de combate
                Expanded(child: BattleLogPanel(logLines: gameState.battleLog)),
                // Botón de pasar turno simplificado
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () {
                      _currentMenuOverlay?.remove();
                      _currentMenuOverlay = null;
                      gameState.endTurn();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          gameState.currentTurn == 'space_marine'
                              ? const Color(0xFF0B1E36)
                              : const Color(0xFF3A0D0D),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(
                        double.infinity,
                        50,
                      ), // Ancho completo
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'PASAR TURNO',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _currentMenuOverlay?.remove();
    gameState.dispose();
    super.dispose();
  }
}
