import 'package:flutter/material.dart';

class MuscleFlowUtils {
  static Color getColor(double load) {
    if (load <= 20) return Colors.greenAccent[400]!; // RECOVERED
    if (load <= 50) return Colors.yellow[600]!; // ACTIVE
    if (load <= 80) return Colors.orange[800]!; // FATIGUED
    return Colors.redAccent[700]!; // OVERLOADED
  }

  static String getStatus(double load) {
    if (load <= 20) return 'Recuperado';
    if (load <= 50) return 'Activo';
    if (load <= 80) return 'Fatigado';
    return 'Sobrecarga';
  }

  static String mapMuscleToSvgId(String muscleName) {
    final normalizedName = muscleName.trim();
    final map = {
      'Pecho': 'chest',
      'Abdominales': 'abs',
      'Oblicuos': 'obliques',
      'Deltoides Anterior': 'shoulders', 
      'Deltoides Posterior': 'shoulders', 
      'Bíceps': 'biceps',
      'Tríceps': 'triceps',
      'Antebrazos': 'forearms',
      'Cuádriceps': 'quads',
      'Isquiotibiales': 'hamstrings',
      'Glúteos': 'glutes',
      'Gemelos': 'calves',
      'Trapecios': 'traps', 
      'Trapecio Inferior': 'traps',
      'Romboides': 'traps',
      'Dorsales': 'lats',
      'Lumbares': 'lower_back',
      'Aductores': 'adductors',
      'Tibial Anterior': 'calves',
    };
    return map[normalizedName] ?? normalizedName.toLowerCase();
  }
}
