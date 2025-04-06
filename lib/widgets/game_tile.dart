import 'package:flutter/material.dart';
import 'package:warhammer_bloodpixels/constants/game_constants.dart';
import 'package:warhammer_bloodpixels/widgets/combat_tooltip.dart';
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
  final Map<Offset, UnitActions> unitActionsMap; // Define this property

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
    required this.unitActionsMap,
  }) : super(key: key);

  @override
  _GameTileState createState() => _GameTileState();
}

class _GameTileState extends State<GameTile> {
  OverlayEntry? _tooltipOverlay;
  bool _isHovering = false;

  @override
  void dispose() {
    _hideTooltip();
    super.dispose();
  }

  void _showTooltip(BuildContext context) {
    if (widget.unit == null || !_isHovering) return;
    if (widget.unit!.faction == widget.currentTurn) return;

    bool shouldShowTooltip = false;
    String tooltipTitle = "";
    List<Widget> tooltipContent = [];

    switch (widget.actionMode) {
      case ActionMode.attack:
        shouldShowTooltip =
            widget.inAttackRange && widget.unit!.faction != widget.currentTurn;
        if (shouldShowTooltip) {
          tooltipTitle = "Ataque a Distancia";
          int attackerBS = widget.currentTurn == 'space_marine' ? 3 : 4;
          int targetSave = widget.unit!.faction == 'space_marine' ? 3 : 5;
          tooltipContent = [
            _buildTooltipRow(
              Icons.arrow_forward,
              Colors.red[300],
              "${attackerBS}+ impacta, 1-${attackerBS - 1} falla",
            ),
            const SizedBox(height: 6),
            _buildTooltipRow(
              Icons.shield,
              Colors.blue[300],
              "${targetSave}+ salva",
            ),
          ];
        }
        break;
      case ActionMode.charge:
        shouldShowTooltip =
            widget.inChargeRange && widget.unit!.faction != widget.currentTurn;
        if (shouldShowTooltip && widget.selectedTilePosition != null) {
          double distance = _calculateDistance();
          if (distance > 0) {
            tooltipTitle = "Carga";
            tooltipContent = [
              _buildTooltipRow(
                Icons.casino,
                Colors.purple[300],
                "Tirada 2D6 ≥ ${distance.ceil()}",
              ),
            ];
          }
        }
        break;
      case ActionMode.melee:
        shouldShowTooltip =
            _isEngaged() && widget.unit!.faction != widget.currentTurn;
        if (shouldShowTooltip) {
          tooltipTitle = "Combate Cuerpo a Cuerpo";
          int attackerWS = widget.currentTurn == 'space_marine' ? 3 : 4;
          int targetSave = widget.unit!.faction == 'space_marine' ? 3 : 5;
          tooltipContent = [
            _buildTooltipRow(
              Icons.sports_kabaddi,
              Colors.amber[300],
              "${attackerWS}+ impacta, 1-${attackerWS - 1} falla",
            ),
            const SizedBox(height: 6),
            _buildTooltipRow(
              Icons.shield,
              Colors.blue[300],
              "${targetSave}+ salva",
            ),
          ];
        }
        break;
      default:
        shouldShowTooltip = false;
    }

    if (!shouldShowTooltip || tooltipContent.isEmpty) return;

    _hideTooltip();

    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset position = box.localToGlobal(Offset.zero);
    final Size size = box.size;

    _tooltipOverlay = OverlayEntry(
      builder:
          (context) => Positioned(
            left: position.dx + size.width,
            top: position.dy,
            child: CombatTooltip(title: tooltipTitle, content: tooltipContent),
          ),
    );

    Overlay.of(context).insert(_tooltipOverlay!);
  }

  Widget _buildTooltipRow(IconData icon, Color? iconColor, String text) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text, style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  void _hideTooltip() {
    _tooltipOverlay?.remove();
    _tooltipOverlay = null;
  }

  double _calculateDistance() {
    if (widget.selectedTilePosition == null) return 0;

    int selectedRow = widget.selectedTilePosition!.dy.toInt();
    int selectedCol = widget.selectedTilePosition!.dx.toInt();

    return sqrt(
      pow(widget.row - selectedRow, 2) + pow(widget.col - selectedCol, 2),
    );
  }

  bool _isEngaged() {
    if (widget.unit == null) return false;

    final directions = [
      [0, 1],
      [1, 0],
      [0, -1],
      [-1, 0],
      [1, 1],
      [1, -1],
      [-1, 1],
      [-1, -1],
    ];

    for (final dir in directions) {
      final newRow = widget.row + dir[0];
      final newCol = widget.col + dir[1];

      if (newRow >= 0 &&
          newRow < GameConstants.BOARD_ROWS &&
          newCol >= 0 &&
          newCol < GameConstants.BOARD_COLS) {
        final neighbor = widget.board[newRow][newCol];
        if (neighbor != null &&
            neighbor.faction != widget.unit!.faction &&
            neighbor.hp > 0) {
          return true;
        }
      }
    }
    return false;
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
        setState(() {
          _isHovering = true;
        });
        _showTooltip(context);
      },
      onExit: (_) {
        setState(() {
          _isHovering = false;
        });
        _hideTooltip();
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
                  _isEngaged())
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
              if (widget.unit != null && widget.unit!.hp > 0)
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Row(
                    children: [
                      _buildActionDot(
                        widget
                                .unitActionsMap[Offset(
                                  widget.col.toDouble(),
                                  widget.row.toDouble(),
                                )]
                                ?.hasMoved ==
                            true,
                      ),
                      const SizedBox(width: 2),
                      _buildActionDot(
                        widget
                                .unitActionsMap[Offset(
                                  widget.col.toDouble(),
                                  widget.row.toDouble(),
                                )]
                                ?.hasAttacked ==
                            true,
                      ),
                    ],
                  ),
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
                unit.faction == 'space_marine' ? Colors.green : Colors.red,
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

  Widget _buildActionDot(bool isUsed) {
    // Verificar si quedan acciones disponibles para esta unidad
    bool noActionsLeft = false;

    if (widget.unitActionsMap.containsKey(
      Offset(widget.col.toDouble(), widget.row.toDouble()),
    )) {
      noActionsLeft =
          widget
              .unitActionsMap[Offset(
                widget.col.toDouble(),
                widget.row.toDouble(),
              )]!
              .remainingActions <=
          0;
    }

    // Si no quedan acciones, el punto debe estar apagado independientemente de la acción específica
    bool shouldBeGrey = isUsed || noActionsLeft;

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color:
            shouldBeGrey
                ? Colors.grey.withOpacity(0.5)
                : widget.unit!.faction == 'space_marine'
                ? Colors.blue
                : Colors.red,
        border: Border.all(color: Colors.white.withOpacity(0.7), width: 1),
      ),
    );
  }
}
