import 'package:drift/drift.dart';

import '../db/app_database.dart';
import '../../domain/models/body.dart';
import '../../domain/models/enums.dart';

class BodyRepository {
  BodyRepository(this._db);

  final AppDatabase _db;

  Stream<BodyProfileView?> watchProfile() {
    return (_db.select(_db.bodyProfiles)..where((t) => t.id.equals('local')))
        .watch()
        .map((rows) {
      if (rows.isEmpty) return null;
      final row = rows.first;
      return BodyProfileView(
        id: row.id,
        weightKg: row.weightKg,
        heightCm: row.heightCm,
        ageYears: row.ageYears,
        sex: parseSex(row.sex),
        activity: parseActivity(row.activity),
        manualKcalTarget: row.manualKcalTarget,
        manualProteinG: row.manualProteinG,
        manualCarbsG: row.manualCarbsG,
        manualFatG: row.manualFatG,
        manualFiberG: row.manualFiberG,
        updatedAt: row.updatedAt,
      );
    });
  }

  Future<void> upsertProfile({
    double? weightKg,
    double? heightCm,
    int? ageYears,
    BiologicalSex? sex,
    ActivityLevel? activity,
    double? manualKcalTarget,
    bool clearManualTarget = false,
    double? manualProteinG,
    double? manualCarbsG,
    double? manualFatG,
    double? manualFiberG,
    bool clearManualMacros = false,
  }) async {
    await _db.into(_db.bodyProfiles).insertOnConflictUpdate(
          BodyProfilesCompanion(
            id: const Value('local'),
            weightKg: Value(weightKg),
            heightCm: Value(heightCm),
            ageYears: Value(ageYears),
            sex: Value(sex?.name),
            activity: Value(activity?.name),
            manualKcalTarget: clearManualTarget
                ? const Value(null)
                : Value(manualKcalTarget),
            manualProteinG: clearManualMacros
                ? const Value(null)
                : Value(manualProteinG),
            manualCarbsG:
                clearManualMacros ? const Value(null) : Value(manualCarbsG),
            manualFatG:
                clearManualMacros ? const Value(null) : Value(manualFatG),
            manualFiberG:
                clearManualMacros ? const Value(null) : Value(manualFiberG),
            updatedAt: Value(DateTime.now().toUtc()),
          ),
        );
  }
}
