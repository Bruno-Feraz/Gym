import 'package:flutter_test/flutter_test.dart';

import 'package:gym_app/domain/models/enums.dart';
import 'package:gym_app/domain/services/alert_policy.dart';
import 'package:gym_app/domain/services/nutrition_math.dart';

void main() {
  group('NutritionMath', () {
    test('risolve target manuale con priorità', () {
      final target = NutritionMath.resolveTarget(
        manualKcalTarget: 2200,
        weightKg: 80,
        heightCm: 180,
        ageYears: 30,
        sex: BiologicalSex.male,
        activity: ActivityLevel.moderate,
      );
      expect(target, isNotNull);
      expect(target!.kcal, 2200);
      expect(target.source, TargetSource.manual);
    });

    test('stima TDEE con dati completi', () {
      final target = NutritionMath.resolveTarget(
        manualKcalTarget: null,
        weightKg: 80,
        heightCm: 180,
        ageYears: 30,
        sex: BiologicalSex.male,
        activity: ActivityLevel.moderate,
      );
      expect(target, isNotNull);
      expect(target!.source, TargetSource.estimated);
      expect(target.kcal, greaterThan(2000));
    });

    test('stima macro con proteine e fibre', () {
      final macros = NutritionMath.estimateMacros(
        weightKg: 80,
        heightCm: 180,
        ageYears: 30,
        sex: BiologicalSex.male,
        activity: ActivityLevel.moderate,
      );
      expect(macros, isNotNull);
      expect(macros!.proteinG, closeTo(128, 0.1));
      expect(macros.fiberG, greaterThanOrEqualTo(25));
      expect(macros.carbsG, greaterThan(50));
    });

    test('entryKcal proporzionale ai grammi', () {
      expect(
        NutritionMath.entryKcal(kcalPer100g: 100, grams: 50),
        50,
      );
    });
  });

  group('AlertPolicy', () {
    test('nessun alert senza target', () {
      expect(
        AlertPolicy.evaluate(targetKcal: null, listTotalKcal: 3000),
        ShoppingAlertKind.none,
      );
    });

    test('over sopra 110%', () {
      expect(
        AlertPolicy.evaluate(targetKcal: 2000, listTotalKcal: 2300),
        ShoppingAlertKind.over,
      );
    });

    test('under sotto 80%', () {
      expect(
        AlertPolicy.evaluate(targetKcal: 2000, listTotalKcal: 1000),
        ShoppingAlertKind.under,
      );
    });

    test('dentro fascia = none', () {
      expect(
        AlertPolicy.evaluate(targetKcal: 2000, listTotalKcal: 2000),
        ShoppingAlertKind.none,
      );
    });
  });
}
