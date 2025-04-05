import 'package:flutter/material.dart';
import 'package:warhammer_bloodpixels/constants/game_constants.dart';
import '../models/unit.dart';
import '../models/game_state.dart';
import 'dart:math';

class GameTile extends StatefulWidget {
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
  final String currentTurn;
  final Offset? selectedTile; // Asegúrate de añadir esta propiedad al widget
  final Offset? selectedTilePosition; // Añade esta propiedad al widget

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
    required this.currentTurn,
    this.selectedTile,
    this.selectedTilePosition,
  }) : super(key: key);

  @override
  _GameTileState createState() => _GameTileState();
}

class _GameTileState extends State<GameTile> {
  OverlayEntry? _tooltipOverlay;

  void _showAttackTooltip(BuildContext context) {
    if (widget.unit == null) return;
    if (widget.unit!.faction == widget.currentTurn) return;

    // Añadir protección para evitar mostrar el tooltip durante actualizaciones
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;

      String title;
      List<Widget> content = [];

      if (widget.actionMode == ActionMode.attack) {
        title = "Predicción de Ataque";
        int attackerBS = widget.currentTurn == 'space_marine' ? 3 : 4;
        int targetSave = widget.unit!.faction == 'space_marine' ? 3 : 5;

        content = [
          Row(
            children: [
              Icon(Icons.arrow_forward, color: Colors.red[300], size: 16),
              SizedBox(width: 6),
              Text(
                "${attackerBS}+ impacta, 1-${attackerBS - 1} falla",
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.shield, color: Colors.blue[300], size: 16),
              SizedBox(width: 6),
              Text(
                "${targetSave}+ salva",
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ];
      } else if (widget.actionMode == ActionMode.charge) {
        title = "Predicción de Carga";
        double distance = 0;
        if (widget.selectedTilePosition != null) {
          distance = sqrt(
            pow(widget.row - widget.selectedTilePosition!.dy, 2) +
                pow(widget.col - widget.selectedTilePosition!.dx, 2),
          );
        }

        if (distance > 0) {
          content = [
            Row(
              children: [
                Icon(Icons.casino, color: Colors.purple[300], size: 16),
                SizedBox(width: 6),
                Text(
                  "Tirada 2D6 ≥ ${distance.ceil()}",
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ];
        } else {
          return;
        }
      } else if (widget.actionMode == ActionMode.melee) {
        title = "Predicción de Combate";
        int attackerWS = widget.currentTurn == 'space_marine' ? 3 : 4;
        int targetSave = widget.unit!.faction == 'space_marine' ? 3 : 5;

        content = [
          Row(
            children: [
              Icon(Icons.sports_kabaddi, color: Colors.amber[300], size: 16),
              SizedBox(width: 6),
              Text(
                "${attackerWS}+ impacta, 1-${attackerWS - 1} falla",
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.shield, color: Colors.blue[300], size: 16),
              SizedBox(width: 6),
              Text(
                "${targetSave}+ salva",
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ];
      } else {
        return;
      }

      if (_tooltipOverlay == null) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final Offset position = box.localToGlobal(Offset.zero);

        _tooltipOverlay = OverlayEntry(
          builder:
              (context) => Positioned(
                left: position.dx + 40,
                top: position.dy,
                child: Material(
                  elevation: 4.0,
                  borderRadius: BorderRadius.circular(6),
                  color: Colors.black.withOpacity(0.9),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    width: 200,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Divider(color: Colors.white30),
                        ...content,
                      ],
                    ),
                  ),
                ),
              ),
        );

        Overlay.of(context).insert(_tooltipOverlay!);
      }
    });
  }

  void _hideAttackTooltip() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tooltipOverlay?.remove();
      _tooltipOverlay = null;
    });
  }

  double _calculateDistance(int targetRow, int targetCol) {
    if (widget.selectedTile == null) return 0;

    int selectedRow = widget.selectedTile!.dy.toInt();
    int selectedCol = widget.selectedTile!.dx.toInt();

    return sqrt(
      pow(targetRow - selectedRow, 2) + pow(targetCol - selectedCol, 2),
    );
  }

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
    return MouseRegion(
      onEnter: (_) {
        print(
          '➡️ HOVER en (${widget.row}, ${widget.col}) '
          'charge? ${widget.inChargeRange} '
          'attack? ${widget.inAttackRange} '
          'engaged? ${_isEngaged(widget.row, widget.col)} '
          'unit: ${widget.unit?.type}',
        );

        // Solo mostrar tooltips si hay una unidad
        if (widget.unit == null) return;

        // Comprobar si debemos mostrar tooltip según el modo
        bool showTooltip = false;

        switch (widget.actionMode) {
          case ActionMode.attack:
            showTooltip =
                widget.inAttackRange &&
                !_isEngaged(widget.row, widget.col) &&
                widget.unit!.faction != widget.currentTurn;
            break;
          case ActionMode.charge:
            showTooltip =
                widget.inChargeRange &&
                widget.unit!.faction != widget.currentTurn;
            break;
          case ActionMode.melee:
            showTooltip =
                _isEngaged(widget.row, widget.col) &&
                widget.unit!.faction != widget.currentTurn;
            break;
          default:
            showTooltip = false;
        }

        if (showTooltip) {
          _showAttackTooltip(context);
        }
      },
      onExit: (_) {
        _hideAttackTooltip();
      },
      child: GestureDetector(
        onTap: () => widget.onTap(widget.row, widget.col),
        child: Container(
          decoration: BoxDecoration(
            image: const DecorationImage(
              image: AssetImage('assets/tile.png'),
              fit: BoxFit.cover,
            ),
            border: Border.all(color: Colors.black),
            boxShadow:
                widget.isSelected
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
              if (widget.inMoveRange &&
                  (widget.actionMode == ActionMode.move ||
                      widget.actionMode == ActionMode.none))
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                ),
              if (widget.inAttackRange &&
                  (widget.actionMode == ActionMode.attack ||
                      widget.actionMode == ActionMode.none))
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                ),
              if (widget.inChargeRange &&
                  widget.actionMode == ActionMode.charge)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                ),
              if (widget.unit != null &&
                  widget.unit!.hp > 0 &&
                  widget.unit!.faction != null && // Añade esta comprobación
                  _isEngaged(widget.row, widget.col))
                const Positioned(
                  top: 4,
                  right: 4,
                  child: Tooltip(
                    message: 'Trabado en combate',
                    child: Icon(Icons.lock, size: 18, color: Colors.redAccent),
                  ),
                ),
              if (widget.unit != null)
                Stack(
                  children: [
                    Opacity(
                      opacity:
                          widget.unit!.hp == 0
                              ? 0.2
                              : (widget.hasActed ? 0.4 : 1.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Image.asset(getAssetPath(widget.unit!.type)),
                          ),
                          const SizedBox(height: 2),
                          _buildHealthBar(widget.unit!),
                        ],
                      ),
                    ),
                    if (widget.unit!.hp == 0)
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
    // Comprobación de null antes de acceder a unit.faction
    if (widget.unit == null) return false;

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
          widget.board[newRow][newCol] != null &&
          widget.board[newRow][newCol]!.faction != widget.unit!.faction &&
          widget.board[newRow][newCol]!.hp > 0) {
        return true;
      }
    }

    return false;
  }
}
