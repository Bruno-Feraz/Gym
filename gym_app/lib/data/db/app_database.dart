import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class WorkoutPlans extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get kind => text()();
  IntColumn get weekday => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Exercises extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class PlanExercises extends Table {
  TextColumn get id => text()();
  TextColumn get planId =>
      text().references(WorkoutPlans, #id, onDelete: KeyAction.cascade)();
  TextColumn get exerciseId => text().references(Exercises, #id)();
  IntColumn get sortOrder => integer()();
  IntColumn get targetSets => integer().withDefault(const Constant(3))();
  IntColumn get targetReps => integer().withDefault(const Constant(10))();
  RealColumn get targetWeightKg => real().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class WorkoutSessions extends Table {
  TextColumn get id => text()();
  TextColumn get planId =>
      text().references(WorkoutPlans, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get performedAt => dateTime()();
  TextColumn get note => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class SessionSets extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId =>
      text().references(WorkoutSessions, #id, onDelete: KeyAction.cascade)();
  TextColumn get exerciseId => text().references(Exercises, #id)();
  IntColumn get setIndex => integer()();
  IntColumn get reps => integer()();
  RealColumn get weightKg => real()();

  @override
  Set<Column> get primaryKey => {id};
}

class BodyProfiles extends Table {
  TextColumn get id => text()();
  RealColumn get weightKg => real().nullable()();
  RealColumn get heightCm => real().nullable()();
  IntColumn get ageYears => integer().nullable()();
  TextColumn get sex => text().nullable()();
  TextColumn get activity => text().nullable()();
  RealColumn get manualKcalTarget => real().nullable()();
  RealColumn get manualProteinG => real().nullable()();
  RealColumn get manualCarbsG => real().nullable()();
  RealColumn get manualFatG => real().nullable()();
  RealColumn get manualFiberG => real().nullable()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class FoodItems extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
  RealColumn get kcalPer100g => real()();
  RealColumn get proteinPer100g => real().nullable()();
  RealColumn get carbsPer100g => real().nullable()();
  RealColumn get fatPer100g => real().nullable()();
  RealColumn get fiberPer100g => real().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class ShoppingLists extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class ShoppingEntries extends Table {
  TextColumn get id => text()();
  TextColumn get listId =>
      text().references(ShoppingLists, #id, onDelete: KeyAction.cascade)();
  TextColumn get foodId => text().references(FoodItems, #id)();
  RealColumn get grams => real()();
  BoolColumn get checked => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(
  tables: [
    WorkoutPlans,
    Exercises,
    PlanExercises,
    WorkoutSessions,
    SessionSets,
    BodyProfiles,
    FoodItems,
    ShoppingLists,
    ShoppingEntries,
    AppSettings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openExecutor());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(foodItems, foodItems.fiberPer100g);
            await m.addColumn(bodyProfiles, bodyProfiles.manualProteinG);
            await m.addColumn(bodyProfiles, bodyProfiles.manualCarbsG);
            await m.addColumn(bodyProfiles, bodyProfiles.manualFatG);
            await m.addColumn(bodyProfiles, bodyProfiles.manualFiberG);
          }
        },
      );

  static AppDatabase open() => AppDatabase();

  static QueryExecutor _openExecutor() {
    return driftDatabase(
      name: 'gym',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
  }
}
