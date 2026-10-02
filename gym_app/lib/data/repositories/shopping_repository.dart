import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';
import '../../domain/models/nutrition.dart';
import '../../domain/models/shopping.dart';

const _uuid = Uuid();

class ShoppingRepository {
  ShoppingRepository(this._db);

  final AppDatabase _db;

  Stream<ShoppingList?> watchActiveList() {
    final q = _db.select(_db.shoppingLists)
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(1);
    return q.watch().map((rows) => rows.isEmpty ? null : rows.first);
  }

  Stream<List<ShoppingEntryView>> watchEntries(String listId) {
    final query = _db.select(_db.shoppingEntries).join([
      innerJoin(
        _db.foodItems,
        _db.foodItems.id.equalsExp(_db.shoppingEntries.foodId),
      ),
    ])
      ..where(_db.shoppingEntries.listId.equals(listId))
      ..orderBy([OrderingTerm.asc(_db.foodItems.name)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        final e = row.readTable(_db.shoppingEntries);
        final f = row.readTable(_db.foodItems);
        return ShoppingEntryView(
          id: e.id,
          foodId: e.foodId,
          foodName: f.name,
          grams: e.grams,
          checked: e.checked,
          kcalPer100g: f.kcalPer100g,
          proteinPer100g: f.proteinPer100g,
          carbsPer100g: f.carbsPer100g,
          fatPer100g: f.fatPer100g,
          fiberPer100g: f.fiberPer100g,
        );
      }).toList();
    });
  }

  Stream<List<FoodOption>> watchFoods() {
    final q = _db.select(_db.foodItems)
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);
    return q.watch().map(
          (rows) => rows
              .map(
                (f) => FoodOption(
                  id: f.id,
                  name: f.name,
                  isCustom: f.isCustom,
                  kcalPer100g: f.kcalPer100g,
                  proteinPer100g: f.proteinPer100g,
                  carbsPer100g: f.carbsPer100g,
                  fatPer100g: f.fatPer100g,
                  fiberPer100g: f.fiberPer100g,
                ),
              )
              .toList(),
        );
  }

  Future<String> ensureActiveList() async {
    final existing = await (_db.select(_db.shoppingLists)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(1))
        .get();
    if (existing.isNotEmpty) return existing.first.id;
    final id = _uuid.v4();
    await _db.into(_db.shoppingLists).insert(
          ShoppingListsCompanion.insert(
            id: id,
            title: 'Spesa oggi',
            createdAt: DateTime.now().toUtc(),
          ),
        );
    return id;
  }

  Future<String> addCustomFood({
    required String name,
    required double kcalPer100g,
    double? proteinPer100g,
    double? carbsPer100g,
    double? fatPer100g,
    double? fiberPer100g,
  }) async {
    final id = _uuid.v4();
    await _db.into(_db.foodItems).insert(
          FoodItemsCompanion.insert(
            id: id,
            name: name.trim(),
            isCustom: const Value(true),
            kcalPer100g: kcalPer100g,
            proteinPer100g: Value(proteinPer100g),
            carbsPer100g: Value(carbsPer100g),
            fatPer100g: Value(fatPer100g),
            fiberPer100g: Value(fiberPer100g),
          ),
        );
    return id;
  }

  Future<String> addEntry({
    required String listId,
    required String foodId,
    required double grams,
  }) async {
    final id = _uuid.v4();
    await _db.into(_db.shoppingEntries).insert(
          ShoppingEntriesCompanion.insert(
            id: id,
            listId: listId,
            foodId: foodId,
            grams: grams,
          ),
        );
    return id;
  }

  Future<void> updateEntryGrams(String id, double grams) async {
    await (_db.update(_db.shoppingEntries)..where((t) => t.id.equals(id)))
        .write(ShoppingEntriesCompanion(grams: Value(grams)));
  }

  Future<void> setChecked(String id, bool checked) async {
    await (_db.update(_db.shoppingEntries)..where((t) => t.id.equals(id)))
        .write(ShoppingEntriesCompanion(checked: Value(checked)));
  }

  Future<void> deleteEntry(String id) async {
    await (_db.delete(_db.shoppingEntries)..where((t) => t.id.equals(id))).go();
  }

  Future<AlertThresholds> loadThresholds() async {
    final rows = await _db.select(_db.appSettings).get();
    final map = {for (final r in rows) r.key: r.value};
    return AlertThresholds(
      overRatio: double.tryParse(map['alert_over_ratio'] ?? '') ?? 1.10,
      underRatio: double.tryParse(map['alert_under_ratio'] ?? '') ?? 0.80,
    );
  }

  Future<double> totalKcal(String listId) async {
    final entries = await (_db.select(_db.shoppingEntries).join([
      innerJoin(
        _db.foodItems,
        _db.foodItems.id.equalsExp(_db.shoppingEntries.foodId),
      ),
    ])
          ..where(_db.shoppingEntries.listId.equals(listId)))
        .get();
    var total = 0.0;
    for (final row in entries) {
      final e = row.readTable(_db.shoppingEntries);
      final f = row.readTable(_db.foodItems);
      total += f.kcalPer100g * (e.grams / 100);
    }
    return total;
  }
}
