import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/tournament_model.dart';

class TournamentSelector extends StatelessWidget {
  final List<TournamentModel> tournaments;
  final TournamentModel? selected;
  final ValueChanged<TournamentModel?> onChanged;

  const TournamentSelector({super.key, required this.tournaments, this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding : EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.divider),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<TournamentModel>(
          value: selected,
          dropdownColor: AppColors.surfaceAlt,
          style: TextStyle(color: AppColors.onSurface),
          hint: Text('Selecciona torneo', style: TextStyle(color: AppColors.hint)),
          isExpanded: true,
          items: tournaments.map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
