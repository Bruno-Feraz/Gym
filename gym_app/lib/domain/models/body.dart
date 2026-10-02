import '../models/enums.dart';
import '../models/nutrition.dart';
import '../services/nutrition_math.dart';

class BodyProfileView {
  const BodyProfileView({
    required this.id,
    this.weightKg,
    this.heightCm,
    this.ageYears,
    this.sex,
    this.activity,
    this.manualKcalTarget,
    this.manualProteinG,
    this.manualCarbsG,
    this.manualFatG,
    this.manualFiberG,
    required this.updatedAt,
  });

  final String id;
  final double? weightKg;
  final double? heightCm;
  final int? ageYears;
  final BiologicalSex? sex;
  final ActivityLevel? activity;
  final double? manualKcalTarget;
  final double? manualProteinG;
  final double? manualCarbsG;
  final double? manualFatG;
  final double? manualFiberG;
  final DateTime updatedAt;

  bool get hasManualMacros =>
      manualProteinG != null &&
      manualCarbsG != null &&
      manualFatG != null &&
      manualFiberG != null;

  CalorieTarget? get resolvedTarget => NutritionMath.resolveTarget(
        manualKcalTarget: manualKcalTarget,
        weightKg: weightKg,
        heightCm: heightCm,
        ageYears: ageYears,
        sex: sex,
        activity: activity,
      );

  MacroTargets? get resolvedMacros => NutritionMath.resolveMacros(
        weightKg: weightKg,
        heightCm: heightCm,
        ageYears: ageYears,
        sex: sex,
        activity: activity,
        kcalTarget: resolvedTarget?.kcal,
        manualProteinG: manualProteinG,
        manualCarbsG: manualCarbsG,
        manualFatG: manualFatG,
        manualFiberG: manualFiberG,
        useManualMacros: hasManualMacros,
      );
}

BiologicalSex? parseSex(String? raw) {
  if (raw == null) return null;
  return BiologicalSex.values.cast<BiologicalSex?>().firstWhere(
        (e) => e?.name == raw,
        orElse: () => null,
      );
}

ActivityLevel? parseActivity(String? raw) {
  if (raw == null) return null;
  return ActivityLevel.values.cast<ActivityLevel?>().firstWhere(
        (e) => e?.name == raw,
        orElse: () => null,
      );
}
