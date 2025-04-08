import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
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
    switch (selectedUnit!.type) {
      case 'sergeant':
        return Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            gradient: const LinearGradient(
              colors: [Color(0xFF101E30), Color(0xFF1B2C47)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blueAccent.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          width: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FittedBox(
                fit: BoxFit.contain,
                child: Lottie.asset(
                  'assets/animations/space_marine_idle.json',
                  width: 280,
                  height: 300,
                  repeat: true,
                  animate: true,
                  alignment: Alignment.center,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.blueAccent, thickness: 1),
              const SizedBox(height: 8),
              const Text(
                'Sargento Infernus',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        );
      case 'space_marine':
        return _imageHeader('assets/space_marine.png', 'Space Marine');
      case 'tyranid':
        return _imageHeader('assets/tyranids/default.png', 'Tiránido');
      case 'reaper_swarm':
        return _imageHeader('assets/reaper_swarm.png', 'Reaper Swarm');
      default:
        return _imageHeader('assets/skull.png', 'Desconocido');
    }
  }

  Widget _imageHeader(String assetPath, String unitName) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Image.asset(assetPath, width: 60, height: 60),
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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontFamily: 'RobotoMono',
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFamily: 'RobotoMono',
            ),
          ),
        ],
      ),
    );
  }
}
