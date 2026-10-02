import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/workout.dart';

const _uuid = Uuid();

class WorkoutRepository {
  WorkoutRepository(this._db);

  final AppDatabase _db;

  Stream<List<WorkoutPlanView>> watchPlans() {
    final plansQuery = _db.select(_db.workoutPlans)
      ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]);

    // Un solo round-trip per i conteggi (niente N+1 per scheda).
    return plansQuery.watch().asyncMap((plans) async {
      if (plans.isEmpty) return <WorkoutPlanView>[];
      final allLinks = await _db.select(_db.planExercises).get();
      final counts = <String, int>{};
      for (final link in allLinks) {
        counts[link.planId] = (counts[link.planId] ?? 0) + 1;
      }
      return [
        for (final plan in plans)
          WorkoutPlanView(
            id: plan.id,
            title: plan.title,
            kind: parsePlanKind(plan.kind),
            weekday: plan.weekday,
            exerciseCount: counts[plan.id] ?? 0,
            updatedAt: plan.updatedAt,
          ),
      ];
    });
  }

  Future<WorkoutPlan?> getPlan(String id) {
    return (_db.select(_db.workoutPlans)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Stream<List<PlanExerciseView>> watchPlanExercises(String planId) {
    final query = _db.select(_db.planExercises).join([
      innerJoin(
        _db.exercises,
        _db.exercises.id.equalsExp(_db.planExercises.exerciseId),
      ),
    ])
      ..where(_db.planExercises.planId.equals(planId))
      ..orderBy([OrderingTerm.asc(_db.planExercises.sortOrder)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        final pe = row.readTable(_db.planExercises);
        final ex = row.readTable(_db.exercises);
        return PlanExerciseView(
          id: pe.id,
          exerciseId: pe.exerciseId,
          exerciseName: ex.name,
          sortOrder: pe.sortOrder,
          targetSets: pe.targetSets,
          targetReps: pe.targetReps,
          targetWeightKg: pe.targetWeightKg,
        );
      }).toList();
    });
  }

  Stream<List<ExerciseOption>> watchExercises({String? query}) {
    final q = _db.select(_db.exercises)
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);
    return q.watch().map((rows) {
      var list = rows
          .map(
            (e) => ExerciseOption(
              id: e.id,
              name: e.name,
              isCustom: e.isCustom,
            ),
          )
          .toList();
      if (query != null && query.trim().isNotEmpty) {
        final lower = query.trim().toLowerCase();
        list = list
            .where((e) => e.name.toLowerCase().contains(lower))
            .toList();
      }
      return list;
    });
  }

  Future<List<ExerciseOption>> listExercises() async {
    final rows = await (_db.select(_db.exercises)
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
    return rows
        .map(
          (e) => ExerciseOption(
            id: e.id,
            name: e.name,
            isCustom: e.isCustom,
          ),
        )
        .toList();
  }

  Future<String> createPlan({
    required String title,
    required WorkoutPlanKind kind,
    int? weekday,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now().toUtc();
    await _db.into(_db.workoutPlans).insert(
          WorkoutPlansCompanion.insert(
            id: id,
            title: title.trim(),
            kind: planKindToDb(kind),
            weekday: Value(kind == WorkoutPlanKind.weekday ? weekday : null),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  Future<void> updatePlan({
    required String id,
    required String title,
    required WorkoutPlanKind kind,
    int? weekday,
  }) async {
    await (_db.update(_db.workoutPlans)..where((t) => t.id.equals(id))).write(
      WorkoutPlansCompanion(
        title: Value(title.trim()),
        kind: Value(planKindToDb(kind)),
        weekday: Value(kind == WorkoutPlanKind.weekday ? weekday : null),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  Future<void> deletePlan(String id) async {
    await (_db.delete(_db.workoutPlans)..where((t) => t.id.equals(id))).go();
  }

  Future<String> addCustomExercise(String name) async {
    final id = _uuid.v4();
    await _db.into(_db.exercises).insert(
          ExercisesCompanion.insert(
            id: id,
            name: name.trim(),
            isCustom: const Value(true),
          ),
        );
    return id;
  }

  Future<String> addExerciseToPlan({
    required String planId,
    required String exerciseId,
    int targetSets = 3,
    int targetReps = 10,
    double? targetWeightKg,
  }) async {
    final existing = await (_db.select(_db.planExercises)
          ..where((t) => t.planId.equals(planId)))
        .get();
    final sortOrder = existing.length;
    final id = _uuid.v4();
    await _db.into(_db.planExercises).insert(
          PlanExercisesCompanion.insert(
            id: id,
            planId: planId,
            exerciseId: exerciseId,
            sortOrder: sortOrder,
            targetSets: Value(targetSets),
            targetReps: Value(targetReps),
            targetWeightKg: Value(targetWeightKg),
          ),
        );
    await _touchPlan(planId);
    return id;
  }

  Future<void> updatePlanExercise({
    required String id,
    required int targetSets,
    required int targetReps,
    double? targetWeightKg,
  }) async {
    final row = await (_db.select(_db.planExercises)
          ..where((t) => t.id.equals(id)))
        .getSingle();
    await (_db.update(_db.planExercises)..where((t) => t.id.equals(id))).write(
      PlanExercisesCompanion(
        targetSets: Value(targetSets),
        targetReps: Value(targetReps),
        targetWeightKg: Value(targetWeightKg),
      ),
    );
    await _touchPlan(row.planId);
  }

  Future<void> removePlanExercise(String id) async {
    final row = await (_db.select(_db.planExercises)
          ..where((t) => t.id.equals(id)))
        .getSingle();
    await (_db.delete(_db.planExercises)..where((t) => t.id.equals(id))).go();
    await _touchPlan(row.planId);
  }

  Future<String> startSession(String planId) async {
    final id = _uuid.v4();
    await _db.into(_db.workoutSessions).insert(
          WorkoutSessionsCompanion.insert(
            id: id,
            planId: planId,
            performedAt: DateTime.now().toUtc(),
          ),
        );
    return id;
  }

  Future<WorkoutSession?> getSession(String id) {
    return (_db.select(_db.workoutSessions)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<void> saveSessionSets({
    required String sessionId,
    required List<SessionSetInput> sets,
  }) async {
    await _db.transaction(() async {
      await (_db.delete(_db.sessionSets)
            ..where((t) => t.sessionId.equals(sessionId)))
          .go();
      for (final s in sets) {
        await _db.into(_db.sessionSets).insert(
              SessionSetsCompanion.insert(
                id: _uuid.v4(),
                sessionId: sessionId,
                exerciseId: s.exerciseId,
                setIndex: s.setIndex,
                reps: s.reps,
                weightKg: s.weightKg,
              ),
            );
      }
    });
  }

  Future<List<SessionSet>> getSessionSets(String sessionId) {
    return (_db.select(_db.sessionSets)
          ..where((t) => t.sessionId.equals(sessionId))
          ..orderBy([
            (t) => OrderingTerm.asc(t.exerciseId),
            (t) => OrderingTerm.asc(t.setIndex),
          ]))
        .get();
  }

  Stream<List<ProgressPoint>> watchProgress(String exerciseId) {
    final query = _db.select(_db.sessionSets).join([
      innerJoin(
        _db.workoutSessions,
        _db.workoutSessions.id.equalsExp(_db.sessionSets.sessionId),
      ),
    ])
      ..where(_db.sessionSets.exerciseId.equals(exerciseId))
      ..orderBy([OrderingTerm.asc(_db.workoutSessions.performedAt)]);

    return query.watch().map((rows) {
      final bySession = <String, List<SessionSet>>{};
      final sessionDates = <String, DateTime>{};
      for (final row in rows) {
        final set = row.readTable(_db.sessionSets);
        final session = row.readTable(_db.workoutSessions);
        bySession.putIfAbsent(session.id, () => []).add(set);
        sessionDates[session.id] = session.performedAt;
      }
      final points = <ProgressPoint>[];
      for (final entry in bySession.entries) {
        final sets = entry.value;
        final maxW =
            sets.map((s) => s.weightKg).fold<double>(0, (a, b) => a > b ? a : b);
        final volume =
            sets.fold<double>(0, (a, s) => a + (s.reps * s.weightKg));
        points.add(
          ProgressPoint(
            performedAt: sessionDates[entry.key]!,
            maxWeightKg: maxW,
            volume: volume,
            sessionId: entry.key,
          ),
        );
      }
      points.sort((a, b) => a.performedAt.compareTo(b.performedAt));
      return points;
    });
  }

  Future<String?> getExerciseName(String exerciseId) async {
    final row = await (_db.select(_db.exercises)
          ..where((t) => t.id.equals(exerciseId)))
        .getSingleOrNull();
    return row?.name;
  }

  Future<void> _touchPlan(String planId) async {
    await (_db.update(_db.workoutPlans)..where((t) => t.id.equals(planId)))
        .write(
      WorkoutPlansCompanion(updatedAt: Value(DateTime.now().toUtc())),
    );
  }
}

class SessionSetInput {
  const SessionSetInput({
    required this.exerciseId,
    required this.setIndex,
    required this.reps,
    required this.weightKg,
  });

  final String exerciseId;
  final int setIndex;
  final int reps;
  final double weightKg;
}
