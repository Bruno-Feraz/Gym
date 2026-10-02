import '../models/enums.dart';
import '../models/nutrition.dart';

/// Policy alert spesa (PRD §6.3 / TSD §6.3).
abstract final class AlertPolicy {
  static ShoppingAlertKind evaluate({
    required double? targetKcal,
    required double listTotalKcal,
    AlertThresholds thresholds = const AlertThresholds(),
  }) {
    if (targetKcal == null || targetKcal <= 0) {
      return ShoppingAlertKind.none;
    }
    if (listTotalKcal > targetKcal * thresholds.overRatio) {
      return ShoppingAlertKind.over;
    }
    if (listTotalKcal < targetKcal * thresholds.underRatio) {
      return ShoppingAlertKind.under;
    }
    return ShoppingAlertKind.none;
  }
}
