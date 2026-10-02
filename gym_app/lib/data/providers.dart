import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import '../data/db/seed.dart';
import '../data/repositories/body_repository.dart';
import '../data/repositories/shopping_repository.dart';
import '../data/repositories/workout_repository.dart';
import '../domain/models/body.dart';
import '../domain/models/shopping.dart';
import '../domain/models/workout.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError('databaseProvider overridden in main');
});

final seedReadyProvider = FutureProvider<void>((ref) async {
  final db = ref.watch(databaseProvider);
  await ensureSeedData(db);
});

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  return WorkoutRepository(ref.watch(databaseProvider));
});

final bodyRepositoryProvider = Provider<BodyRepository>((ref) {
  return BodyRepository(ref.watch(databaseProvider));
});

final shoppingRepositoryProvider = Provider<ShoppingRepository>((ref) {
  return ShoppingRepository(ref.watch(databaseProvider));
});

final bodyProfileProvider = StreamProvider<BodyProfileView?>((ref) {
  return ref.watch(bodyRepositoryProvider).watchProfile();
});

final plansProvider = StreamProvider<List<WorkoutPlanView>>((ref) {
  return ref.watch(workoutRepositoryProvider).watchPlans();
});

final planExercisesProvider =
    StreamProvider.family<List<PlanExerciseView>, String>((ref, planId) {
  return ref.watch(workoutRepositoryProvider).watchPlanExercises(planId);
});

/// Catalogo esercizi: caricato on-demand (picker), non in home.
final exercisesProvider = StreamProvider.autoDispose<List<ExerciseOption>>((ref) {
  return ref.watch(workoutRepositoryProvider).watchExercises();
});

final progressProvider =
    StreamProvider.autoDispose.family<List<ProgressPoint>, String>(
        (ref, exerciseId) {
  return ref.watch(workoutRepositoryProvider).watchProgress(exerciseId);
});

/// Catalogo alimenti: solo mentre è aperto il picker spesa.
final foodsProvider = StreamProvider.autoDispose<List<FoodOption>>((ref) {
  return ref.watch(shoppingRepositoryProvider).watchFoods();
});

final shoppingEntriesProvider =
    StreamProvider.family<List<ShoppingEntryView>, String>((ref, listId) {
  return ref.watch(shoppingRepositoryProvider).watchEntries(listId);
});
