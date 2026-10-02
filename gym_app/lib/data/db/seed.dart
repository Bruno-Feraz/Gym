import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';

import 'app_database.dart';

const _uuid = Uuid();

Future<void> ensureSeedData(AppDatabase db) async {
  final exerciseCount =
      await db.select(db.exercises).get().then((r) => r.length);
  if (exerciseCount == 0) {
    final raw = await rootBundle.loadString('assets/seed/exercises.json');
    final list = jsonDecode(raw) as List<dynamic>;
    await db.batch((batch) {
      for (final item in list) {
        final map = item as Map<String, dynamic>;
        batch.insert(
          db.exercises,
          ExercisesCompanion.insert(
            id: _uuid.v4(),
            name: map['name'] as String,
            isCustom: const Value(false),
          ),
        );
      }
    });
  }

  await _syncFoodCatalog(db);

  final profiles = await db.select(db.bodyProfiles).get();
  if (profiles.isEmpty) {
    await db.into(db.bodyProfiles).insert(
          BodyProfilesCompanion.insert(
            id: 'local',
            updatedAt: DateTime.now().toUtc(),
          ),
        );
  }

  final lists = await db.select(db.shoppingLists).get();
  if (lists.isEmpty) {
    await db.into(db.shoppingLists).insert(
          ShoppingListsCompanion.insert(
            id: _uuid.v4(),
            title: 'Spesa oggi',
            createdAt: DateTime.now().toUtc(),
          ),
        );
  }

  final settings = await db.select(db.appSettings).get();
  if (settings.isEmpty) {
    await db.batch((batch) {
      batch.insertAll(db.appSettings, [
        AppSettingsCompanion.insert(key: 'alert_over_ratio', value: '1.10'),
        AppSettingsCompanion.insert(key: 'alert_under_ratio', value: '0.80'),
        AppSettingsCompanion.insert(key: 'rest_between_sets_sec', value: '90'),
        AppSettingsCompanion.insert(
          key: 'rest_between_exercises_sec',
          value: '180',
        ),
      ]);
    });
  } else {
    final keys = settings.map((s) => s.key).toSet();
    if (!keys.contains('rest_between_sets_sec')) {
      await db.into(db.appSettings).insert(
            AppSettingsCompanion.insert(
              key: 'rest_between_sets_sec',
              value: '90',
            ),
          );
    }
    if (!keys.contains('rest_between_exercises_sec')) {
      await db.into(db.appSettings).insert(
            AppSettingsCompanion.insert(
              key: 'rest_between_exercises_sec',
              value: '180',
            ),
          );
    }
  }
}

/// Inserisce alimenti mancanti e aggiorna valori (incl. fibre) da seed.
Future<void> _syncFoodCatalog(AppDatabase db) async {
  final raw = await rootBundle.loadString('assets/seed/foods.json');
  final list = jsonDecode(raw) as List<dynamic>;
  final existing = await db.select(db.foodItems).get();
  final byName = {for (final f in existing) f.name: f};

  await db.batch((batch) {
    for (final item in list) {
      final map = item as Map<String, dynamic>;
      final name = map['name'] as String;
      final kcal = (map['kcalPer100g'] as num).toDouble();
      final protein = (map['proteinPer100g'] as num?)?.toDouble();
      final carbs = (map['carbsPer100g'] as num?)?.toDouble();
      final fat = (map['fatPer100g'] as num?)?.toDouble();
      final fiber = (map['fiberPer100g'] as num?)?.toDouble();

      final found = byName[name];
      if (found == null) {
        batch.insert(
          db.foodItems,
          FoodItemsCompanion.insert(
            id: _uuid.v4(),
            name: name,
            isCustom: const Value(false),
            kcalPer100g: kcal,
            proteinPer100g: Value(protein),
            carbsPer100g: Value(carbs),
            fatPer100g: Value(fat),
            fiberPer100g: Value(fiber),
          ),
        );
      } else if (!found.isCustom) {
        batch.update(
          db.foodItems,
          FoodItemsCompanion(
            kcalPer100g: Value(kcal),
            proteinPer100g: Value(protein),
            carbsPer100g: Value(carbs),
            fatPer100g: Value(fat),
            fiberPer100g: Value(fiber),
          ),
          where: (t) => t.id.equals(found.id),
        );
      }
    }
  });
}
