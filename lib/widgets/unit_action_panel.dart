import 'package:flutter/material.dart';
import '../models/unit.dart';

class UnitActionPanel extends StatelessWidget {
  final Function() onMoveSelected;
  final Function() onAttackSelected;
  final Function() onChargeSelected;
  final Function() onMeleeSelected;
  final Function() onCancelSelected;
  final Unit selectedUnit;
  final bool isEngaged;

  const UnitActionPanel({
    Key? key,
    required this.onMoveSelected,
    required this.onAttackSelected,
    required this.onChargeSelected,
    required this.onMeleeSelected,
    required this.onCancelSelected,
    required this.selectedUnit,
    required this.isEngaged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isSpaceMarine = selectedUnit.type == 'space_marine';
    final Color mainColor =
        isSpaceMarine ? const Color(0xFF0B1E36) : const Color(0xFF3A0D0D);

    return Container(
      width: 40,
      decoration: BoxDecoration(
        color: Colors.black87,
        border: Border.all(color: mainColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: mainColor.withOpacity(0.6),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildActionButton(
            icon: Icons.directions_walk,
            color: const Color(0xFF0B1E36),
            onTap: onMoveSelected,
            enabled: !isEngaged,
          ),
          _buildActionButton(
            icon: Icons.gps_fixed,
            color: const Color(0xFF600000),
            onTap: onAttackSelected,
            enabled: true,
          ),
          _buildActionButton(
            icon: Icons.sports_martial_arts,
            color: const Color(0xFF143400),
            onTap: onChargeSelected,
            enabled: true,
          ),
          _buildActionButton(
            icon: Icons.sports_kabaddi,
            color: const Color(0xFF3A0D0D),
            onTap: onMeleeSelected,
            enabled: isEngaged,
          ),
          const Divider(height: 1, color: Color(0xFF444444)),
          _buildActionButton(
            icon: Icons.close,
            color: Colors.grey.shade800,
            onTap: onCancelSelected,
            enabled: true,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required Function() onTap,
    required bool enabled,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      child: Container(
        width: double.infinity,
        height: 40,
        decoration: BoxDecoration(
          color: enabled ? color : Colors.black54,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade900, width: 1),
          ),
        ),
        child: Stack(
          children: [
            if (!enabled)
              Positioned.fill(
                child: Container(color: Colors.black.withOpacity(0.7)),
              ),
            Center(
              child: Icon(
                icon,
                color: Colors.white.withOpacity(enabled ? 1.0 : 0.4),
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
