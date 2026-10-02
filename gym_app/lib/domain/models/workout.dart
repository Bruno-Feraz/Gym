import '../models/enums.dart';

class WorkoutPlanView {
  const WorkoutPlanView({
    required this.id,
    required this.title,
    required this.kind,
    this.weekday,
    required this.exerciseCount,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final WorkoutPlanKind kind;
  final int? weekday;
  final int exerciseCount;
  final DateTime updatedAt;

  String get subtitle {
    if (kind == WorkoutPlanKind.weekday && weekday != null) {
      return weekdayLabel(weekday!);
    }
    return '$exerciseCount esercizi';
  }
}

class PlanExerciseView {
  const PlanExerciseView({
    required this.id,
    required this.exerciseId,
    required this.exerciseName,
    required this.sortOrder,
    required this.targetSets,
    required this.targetReps,
    this.targetWeightKg,
  });

  final String id;
  final String exerciseId;
  final String exerciseName;
  final int sortOrder;
  final int targetSets;
  final int targetReps;
  final double? targetWeightKg;
}

class ExerciseOption {
  const ExerciseOption({
    required this.id,
    required this.name,
    required this.isCustom,
  });

  final String id;
  final String name;
  final bool isCustom;
}

class ProgressPoint {
  const ProgressPoint({
    required this.performedAt,
    required this.maxWeightKg,
    required this.volume,
    required this.sessionId,
  });

  final DateTime performedAt;
  final double maxWeightKg;
  final double volume;
  final String sessionId;
}

String weekdayLabel(int weekday) {
  const labels = {
    1: 'Lunedì',
    2: 'Martedì',
    3: 'Mercoledì',
    4: 'Giovedì',
    5: 'Venerdì',
    6: 'Sabato',
    7: 'Domenica',
  };
  return labels[weekday] ?? 'Giorno $weekday';
}

WorkoutPlanKind parsePlanKind(String raw) {
  return raw == 'weekday' ? WorkoutPlanKind.weekday : WorkoutPlanKind.named;
}

String planKindToDb(WorkoutPlanKind kind) {
  return kind == WorkoutPlanKind.weekday ? 'weekday' : 'named';
}
