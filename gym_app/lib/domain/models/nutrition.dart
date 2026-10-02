import 'enums.dart';

class CalorieTarget {
  const CalorieTarget({required this.kcal, required this.source});

  final double kcal;
  final TargetSource source;
}

class MacroTargets {
  const MacroTargets({
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.fiberG,
    required this.source,
  });

  final double proteinG;
  final double carbsG;
  final double fatG;
  final double fiberG;
  final TargetSource source;
}

class AlertThresholds {
  const AlertThresholds({
    this.overRatio = 1.10,
    this.underRatio = 0.80,
  });

  final double overRatio;
  final double underRatio;
}
