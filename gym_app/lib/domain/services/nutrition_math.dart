import '../models/enums.dart';
import '../models/nutrition.dart';

/// Stime sommarie (non consiglio medico).
abstract final class NutritionMath {
  static const Map<ActivityLevel, double> activityFactors = {
    ActivityLevel.sedentary: 1.2,
    ActivityLevel.light: 1.375,
    ActivityLevel.moderate: 1.55,
    ActivityLevel.active: 1.725,
    ActivityLevel.veryActive: 1.9,
  };

  static double? estimateTdee({
    required double? weightKg,
    required double? heightCm,
    required int? ageYears,
    required BiologicalSex? sex,
    required ActivityLevel? activity,
  }) {
    if (weightKg == null ||
        heightCm == null ||
        ageYears == null ||
        weightKg <= 0 ||
        heightCm <= 0 ||
        ageYears <= 0) {
      return null;
    }

    final bmrMale = 10 * weightKg + 6.25 * heightCm - 5 * ageYears + 5;
    final bmrFemale = 10 * weightKg + 6.25 * heightCm - 5 * ageYears - 161;

    final double bmr;
    switch (sex) {
      case BiologicalSex.male:
        bmr = bmrMale;
      case BiologicalSex.female:
        bmr = bmrFemale;
      case BiologicalSex.other:
      case BiologicalSex.unspecified:
      case null:
        bmr = (bmrMale + bmrFemale) / 2;
    }

    final factor = activityFactors[activity ?? ActivityLevel.moderate]!;
    return bmr * factor;
  }

  static CalorieTarget? resolveTarget({
    required double? manualKcalTarget,
    required double? weightKg,
    required double? heightCm,
    required int? ageYears,
    required BiologicalSex? sex,
    required ActivityLevel? activity,
  }) {
    if (manualKcalTarget != null && manualKcalTarget > 0) {
      return CalorieTarget(
        kcal: manualKcalTarget,
        source: TargetSource.manual,
      );
    }
    final estimated = estimateTdee(
      weightKg: weightKg,
      heightCm: heightCm,
      ageYears: ageYears,
      sex: sex,
      activity: activity,
    );
    if (estimated == null) return null;
    return CalorieTarget(kcal: estimated, source: TargetSource.estimated);
  }

  /// Stima macro da peso + kcal target (o TDEE).
  /// Proteine ~1.6 g/kg, grassi ~0.9 g/kg, resto carboidrati, fibre ~14 g/1000 kcal (min 25).
  static MacroTargets? estimateMacros({
    required double? weightKg,
    required double? heightCm,
    required int? ageYears,
    required BiologicalSex? sex,
    required ActivityLevel? activity,
    double? kcalOverride,
  }) {
    if (weightKg == null || weightKg <= 0) return null;
    final kcal = kcalOverride ??
        estimateTdee(
          weightKg: weightKg,
          heightCm: heightCm,
          ageYears: ageYears,
          sex: sex,
          activity: activity,
        );
    if (kcal == null) return null;

    final protein = weightKg * 1.6;
    final fat = weightKg * 0.9;
    final carbs = ((kcal - protein * 4 - fat * 9) / 4).clamp(50, 800);
    final fiber = (kcal / 1000 * 14).clamp(25, 45);

    return MacroTargets(
      proteinG: protein,
      carbsG: carbs.toDouble(),
      fatG: fat,
      fiberG: fiber.toDouble(),
      source: TargetSource.estimated,
    );
  }

  static MacroTargets? resolveMacros({
    required double? weightKg,
    required double? heightCm,
    required int? ageYears,
    required BiologicalSex? sex,
    required ActivityLevel? activity,
    double? kcalTarget,
    double? manualProteinG,
    double? manualCarbsG,
    double? manualFatG,
    double? manualFiberG,
    required bool useManualMacros,
  }) {
    if (useManualMacros &&
        manualProteinG != null &&
        manualCarbsG != null &&
        manualFatG != null &&
        manualFiberG != null &&
        manualProteinG > 0 &&
        manualCarbsG > 0 &&
        manualFatG > 0 &&
        manualFiberG > 0) {
      return MacroTargets(
        proteinG: manualProteinG,
        carbsG: manualCarbsG,
        fatG: manualFatG,
        fiberG: manualFiberG,
        source: TargetSource.manual,
      );
    }

    return estimateMacros(
      weightKg: weightKg,
      heightCm: heightCm,
      ageYears: ageYears,
      sex: sex,
      activity: activity,
      kcalOverride: kcalTarget,
    );
  }

  static double entryKcal({
    required double kcalPer100g,
    required double grams,
  }) {
    return kcalPer100g * (grams / 100);
  }

  static double entryMacro({required double? per100g, required double grams}) {
    return ((per100g ?? 0) * grams) / 100;
  }
}
