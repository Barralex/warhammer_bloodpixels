import 'package:flutter/material.dart';
import '../models/unit.dart';

class UnitInfoPanel extends StatelessWidget {
  final Unit? selectedUnit;

  const UnitInfoPanel({super.key, this.selectedUnit});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(top: 10, bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade800, width: 2),
      ),
      child: selectedUnit == null ? _buildEmptyState() : _buildUnitInfo(),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          'Selecciona una miniatura para ver su información',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white60, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildUnitInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encabezado con imagen y nombre
        _buildHeader(),

        // Estadísticas
        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatRow(
                'Heridas',
                '${selectedUnit!.hp}/${selectedUnit!.maxHp}',
              ),
              _buildStatRow('Movimiento', '${selectedUnit!.movement}"'),
              _buildStatRow('Rango de ataque', '${selectedUnit!.attackRange}"'),
              _buildStatRow('Rango de carga', '${selectedUnit!.chargeRange}"'),
              _buildStatRow('Daño', '${selectedUnit!.damage}'),
              _buildStatRow('BS', '${selectedUnit!.weaponBS}+'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    String assetPath = '';
    String unitName = '';

    switch (selectedUnit!.type) {
      case 'space_marine':
        assetPath = 'assets/space_marine.png';
        unitName = 'Space Marine';
        break;
      case 'tyranid':
        assetPath = 'assets/tyranids/default.png';
        unitName = 'Tiránido';
        break;
      case 'reaper_swarm':
        assetPath = 'assets/reaper_swarm.png';
        unitName = 'Reaper Swarm';
        break;
      default:
        assetPath = 'assets/skull.png';
        unitName = 'Desconocido';
    }

    return Container(
      color:
          selectedUnit!.faction == 'space_marine'
              ? const Color(0xFF0B1E36)
              : const Color(0xFF3A0D0D),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Image.asset(assetPath, width: 50, height: 50),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              unitName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
