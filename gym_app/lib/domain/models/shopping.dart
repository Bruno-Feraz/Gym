import '../services/nutrition_math.dart';

class FoodOption {
  const FoodOption({
    required this.id,
    required this.name,
    required this.isCustom,
    required this.kcalPer100g,
    this.proteinPer100g,
    this.carbsPer100g,
    this.fatPer100g,
    this.fiberPer100g,
  });

  final String id;
  final String name;
  final bool isCustom;
  final double kcalPer100g;
  final double? proteinPer100g;
  final double? carbsPer100g;
  final double? fatPer100g;
  final double? fiberPer100g;
}

class ShoppingEntryView {
  const ShoppingEntryView({
    required this.id,
    required this.foodId,
    required this.foodName,
    required this.grams,
    required this.checked,
    required this.kcalPer100g,
    this.proteinPer100g,
    this.carbsPer100g,
    this.fatPer100g,
    this.fiberPer100g,
  });

  final String id;
  final String foodId;
  final String foodName;
  final double grams;
  final bool checked;
  final double kcalPer100g;
  final double? proteinPer100g;
  final double? carbsPer100g;
  final double? fatPer100g;
  final double? fiberPer100g;

  double get kcal =>
      NutritionMath.entryKcal(kcalPer100g: kcalPer100g, grams: grams);

  double get protein =>
      NutritionMath.entryMacro(per100g: proteinPer100g, grams: grams);
  double get carbs =>
      NutritionMath.entryMacro(per100g: carbsPer100g, grams: grams);
  double get fat =>
      NutritionMath.entryMacro(per100g: fatPer100g, grams: grams);
  double get fiber =>
      NutritionMath.entryMacro(per100g: fiberPer100g, grams: grams);
}
