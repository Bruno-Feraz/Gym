# TSD — Gym

Technical Specification Document per l’app Flutter **Gym** (Android + iOS).

**Versione:** 0.7  
**Stato:** Fase 4 docs + SBOM; firma store pendente
**PRD di riferimento:** `PRD.md`  
**Stack:** Flutter 3.x, Dart 3.x, SQLite locale  
**Scope v1:** Palestra + Corpo/calorie + Spesa con alert; offline-first; logo G bianca su nero

---

## 1. Obiettivo tecnico

Specificare come implementare:

1. shell UI a 3 tab + profilo/misure
2. persistenza locale tipizzata
3. domain model (schede, esercizi, sessioni, alimenti, lista spesa)
4. calcolo target kcal (stima o manuale)
5. policy alert spesa (popup sopra/sotto soglia)
6. grafici progressione carichi
7. brand assets (icona / splash)

Fuori da questo TSD v0.1: sync cloud, account, wearable, IAP.

---

## 2. Decisioni fondamentali

| Area | Scelta |
| --- | --- |
| UI toolkit | Flutter Material 3, tema custom dark |
| State | Riverpod (Notifier / AsyncNotifier) |
| Navigazione | `go_router` + `StatefulShellRoute` (bottom nav) |
| DB | Drift (SQLite) |
| ID | UUID v4 string |
| Date | UTC in storage; local in UI |
| Unità v1 | kg, cm, kcal, g |
| Grafici | `fl_chart` |
| Path app | `gym_app/` |
| Brand | `Gym/brand/logo.svg`, `logo-gym.png` |

### 2.1 Coordinate prodotto ↔ codice

```text
Gym/
  gymapp.md          # idea
  PRD.md
  TSD.md             # questo documento
  brand/
    logo.svg
    logo-gym.png
  gym_app/           # Flutter project
```

---

## 3. Architettura a layer

```text
presentation/     # screens, widgets, theme
application/      # Riverpod notifiers / use cases
domain/           # entities, value objects, pure logic
data/             # Drift DAOs, repositories, mappers
```

Regole:

- `presentation` non parla a Drift
- `domain` non importa Flutter UI
- calorie e alert = funzioni pure in `domain/` (testabili senza widget)

```text
UI → Notifier → Repository → DAO/DB
         ↘ Domain services (NutritionMath, AlertPolicy, Progression)
```

---

## 4. Struttura package Flutter

```text
gym_app/
  lib/
    main.dart
    app.dart
    router.dart
    theme/
      app_theme.dart
      tokens.dart
    features/
      shell/
      workout/
      body/
      shopping/
      settings/
    domain/
      models/
      services/
    data/
      db/
      repositories/
    shared/
      widgets/
      utils/
  assets/
    brand/
      logo.png
      logo.svg
  test/
    domain/
    data/
```

---

## 5. Modello dati (domain)

### 5.1 Entità principali

```dart
class WorkoutPlan {
  final String id;
  final String title;           // nome libero oppure label giorno
  final WorkoutPlanKind kind;   // named | weekday
  final int? weekday;           // 1=lun … 7=dom se kind=weekday
  final DateTime createdAt;
  final DateTime updatedAt;
}

enum WorkoutPlanKind { named, weekday }

class Exercise {
  final String id;
  final String name;
  final bool isCustom;
}

class PlanExercise {
  final String id;
  final String planId;
  final String exerciseId;
  final int sortOrder;
  final int targetSets;
  final int targetReps;         // v1: singolo target; range in v1.1
  final double? targetWeightKg; // template scheda
}

class WorkoutSession {
  final String id;
  final String planId;
  final DateTime performedAt;
  final String? note;
}

class SessionSet {
  final String id;
  final String sessionId;
  final String exerciseId;
  final int setIndex;
  final int reps;
  final double weightKg;
}

class BodyProfile {
  final String id;              // singolo profilo locale
  final double? weightKg;
  final double? heightCm;
  final int? ageYears;
  final BiologicalSex? sex;
  final ActivityLevel? activity;
  final double? manualKcalTarget; // se valorizzato, ha priorità sulla stima
  final DateTime updatedAt;
}

enum BiologicalSex { female, male, other, unspecified }

enum ActivityLevel { sedentary, light, moderate, active, veryActive }

class FoodItem {
  final String id;
  final String name;
  final bool isCustom;
  final double kcalPer100g;
  final double? proteinPer100g;
  final double? carbsPer100g;
  final double? fatPer100g;
}

class ShoppingList {
  final String id;
  final String title;           // es. "Spesa oggi"
  final DateTime createdAt;
}

class ShoppingEntry {
  final String id;
  final String listId;
  final String foodId;
  final double grams;
  final bool checked;
}
```

### 5.2 Schema Drift (tabelle)

```text
workout_plans(id, title, kind, weekday NULL, created_at, updated_at)
exercises(id, name, is_custom)
plan_exercises(id, plan_id, exercise_id, sort_order, target_sets, target_reps, target_weight_kg NULL)
workout_sessions(id, plan_id, performed_at, note NULL)
session_sets(id, session_id, exercise_id, set_index, reps, weight_kg)
body_profile(id, weight_kg, height_cm, age_years, sex, activity, manual_kcal_target, updated_at)
food_items(id, name, is_custom, kcal_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g)
shopping_lists(id, title, created_at)
shopping_entries(id, list_id, food_id, grams, checked)
app_settings(key, value)  -- soglie alert, unità, ecc.
```

Indici: `session_sets(exercise_id, session_id)`, `shopping_entries(list_id)`, `plan_exercises(plan_id, sort_order)`.

Foreign key ON DELETE CASCADE dove ha senso (entry → list; plan_exercises → plan).

---

## 6. Logica di dominio

### 6.1 Target calorico

Priorità:

1. se `manualKcalTarget != null` → usa quello
2. altrimenti stima Harris–Benedict rivista (Mifflin–St Jeor) × fattore attività
3. se dati insufficienti → nessun target; UI chiede impostazione; **nessun popup spesa**

```text
BMR_male   = 10*w + 6.25*h - 5*age + 5
BMR_female = 10*w + 6.25*h - 5*age - 161
TDEE       = BMR * activityFactor
```

Fattori attività (standard):

| Level | Factor |
| --- | --- |
| sedentary | 1.2 |
| light | 1.375 |
| moderate | 1.55 |
| active | 1.725 |
| veryActive | 1.9 |

`other` / `unspecified`: default formula male o media delle due — **decisione implementativa:** media aritmetica BMR m/f se sesso non specificato.

Output: `CalorieTarget { double kcal; TargetSource source; }` con `source = manual | estimated`.

### 6.2 Nutrizione lista spesa

```text
entryKcal = food.kcalPer100g * (grams / 100)
listTotalKcal = sum(entryKcal)  // v1: tutte le entry della lista attiva (checked e non)
```

Opzione settings (default OFF): “conta solo non ancora presi” — se ON, somma solo `checked == false`.

### 6.3 Alert policy

```dart
class AlertThresholds {
  final double overRatio;  // default 1.10
  final double underRatio; // default 0.80
}

enum ShoppingAlertKind { none, over, under }

ShoppingAlertKind evaluate({
  required double? targetKcal,
  required double listTotalKcal,
  required AlertThresholds t,
}) {
  if (targetKcal == null || targetKcal <= 0) return none;
  if (listTotalKcal > targetKcal * t.overRatio) return over;
  if (listTotalKcal < targetKcal * t.underRatio) return under;
  return none;
}
```

**Quando valutare:** dopo persist di add/edit/delete/quantity su `ShoppingEntry` (debounce 300 ms).  
**Come mostrare:** un solo `showDialog` alla volta; non ripetere lo stesso `kind` finché totale non rientra e poi riesce di nuovo (flag `lastShownKind` in memoria sessione).

Copy popup:

- over: “La lista supera il fabbisogno (~X kcal vs target Y).”
- under: “La lista è molto sotto il fabbisogno (~X kcal vs target Y).”

CTA: Chiudi | Vai a Dieta (target).

### 6.4 Progressione

Per `exerciseId`:

```text
punti = session_sets ordinati per session.performedAt
y = weightKg (ultimo set della sessione, o max weight della sessione — default: max weight)
volume = sum(reps * weightKg) per sessione
```

UI: line chart peso nel tempo; sotto lista sessioni.

---

## 7. Navigazione e schermate

```text
/                           → redirect /workout
/workout                    → lista schede
/workout/new
/workout/:planId
/workout/:planId/session    → registra sessione
/workout/exercise/:id/progress
/body                       → misure + target kcal
/shopping                   → lista attiva
/shopping/add
/settings
```

Bottom nav: **Palestra** | **Dieta** | **Spesa**. Impostazioni da icona in app bar.

---

## 8. UI / theme

### 8.1 Token

```dart
// tokens.dart (valori indicativi)
bg:            Color(0xFF000000)
surface:       Color(0xFF121212)
surfaceHigh:   Color(0xFF1E1E1E)
text:          Color(0xFFFFFFFF)
textMuted:     Color(0xFF9E9E9E)
accent:        Color(0xFFE8E8E8) // o verde sobrio da decidere in PRD aperti
warning:       Color(0xFFFFB020)
danger:        Color(0xFFE5484D)
radius:        8
```

### 8.2 Componenti condivisi

- `AppScaffold` (app bar + logo G compatto opzionale)
- `EmptyState`
- `ConfirmDeleteDialog`
- `ShoppingAlertDialog`
- `NumberField` (peso, reps, grammi)
- `PrimaryButton` / `GhostButton`

### 8.3 Brand assets

| Uso | File | Note |
| --- | --- | --- |
| Repo brand | `Gym/brand/logo.svg` | sorgente vettoriale |
| Repo brand | `Gym/brand/logo-gym.png` | raster 1:1 |
| Flutter | `gym_app/assets/brand/` | copia in pubspec |
| Android | adaptive icon foreground G su nero | |
| iOS | AppIcon set | |
| Splash | sfondo nero + G bianca centrata | `flutter_native_splash` |

---

## 9. Seed dati

All’avvio se DB vuoto:

- ~30 esercizi comuni (panca, squat, stacco, rematore, …)
- ~40 alimenti base (per 100 g: petto pollo, riso, uova, olio, …) con kcal (± macro se noti)

File seed: `assets/seed/exercises.json`, `assets/seed/foods.json`.

---

## 10. Repository API (contratti)

```dart
abstract class WorkoutRepository {
  Stream<List<WorkoutPlan>> watchPlans();
  Future<WorkoutPlan> createPlan(...);
  Future<void> updatePlan(...);
  Future<void> deletePlan(String id);
  Future<void> setPlanExercises(String planId, List<PlanExercise> items);
  Future<WorkoutSession> startSession(String planId);
  Future<void> saveSets(String sessionId, List<SessionSet> sets);
  Stream<List<SessionSet>> watchProgress(String exerciseId);
}

abstract class BodyRepository {
  Stream<BodyProfile?> watchProfile();
  Future<void> upsertProfile(BodyProfile profile);
  CalorieTarget resolveTarget(BodyProfile profile); // domain service dietro
}

abstract class ShoppingRepository {
  Stream<ShoppingList?> watchActiveList();
  Stream<List<ShoppingEntryView>> watchEntries(String listId);
  Future<void> addEntry(...);
  Future<void> updateEntry(...);
  Future<void> deleteEntry(...);
  Future<double> totalKcal(String listId);
}
```

---

## 11. Testing

| Livello | Cosa |
| --- | --- |
| Unit | `NutritionMath`, `AlertPolicy`, Mifflin, volume |
| Widget | `ShoppingAlertDialog`, form scheda |
| Integration | Drift in-memory: CRUD piano + sessione + spesa |

Obiettivo Fase 1–3: copertura domain services > 80%.

---

## 12. Sicurezza e privacy (implementazione)

- Nessuna rete obbligatoria in v1; `INTERNET` non richiesto per feature core (se assente analytics)
- Dati salute solo in SQLite sandbox app
- Backup OS: escludere DB da backup cloud OS se possibile (`android:allowBackup` / iOS data protection — valutare)
- Nessun log di peso/alimenti in crash reporter
- Disclaimer mostrato al primo accesso tab Dieta e in Impostazioni

---

## 13. Release tecnica

| Artefatto | Path / tool |
| --- | --- |
| Android | `flutter build appbundle` |
| iOS | `flutter build ipa` |
| SBOM | script da `pubspec.lock` (come Edit) |
| Versioning | `pubspec.yaml` version + build number |
| Checklist | `gym_app/RELEASE-CHECKLIST.md` (da creare in Fase 4) |

Bundle id proposti (da confermare):

- Android: `it.brunoferr.gym`
- iOS: `it.brunoferr.gym`

---

## 14. Dipendenze previste (`pubspec`)

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.x
  go_router: ^14.x
  drift: ^2.x
  sqlite3_flutter_libs: ^0.5.x
  path_provider: ^2.x
  path: ^1.x
  uuid: ^4.x
  fl_chart: ^0.69.x
  intl: ^0.19.x
  flutter_native_splash: ^2.x
  # flutter_launcher_icons: ^0.14.x (dev)

dev_dependencies:
  drift_dev: ^2.x
  build_runner: ^2.x
  flutter_test:
    sdk: flutter
```

Versioni esatte da fissare alla creazione del progetto.

---

## 15. Fasi implementative (tecniche)

### Fase 0 ✅

1. [x] `flutter create gym_app --org it.brunoferr --platforms=android,ios`
2. [x] Tema + router shell (Palestra / Dieta / Spesa)
3. [x] Drift schema + seed exercises/foods
4. [x] Icone / splash da `brand/`

### Fase 1 ✅

1. [x] CRUD `WorkoutPlan` / `PlanExercise`
2. [x] Sessione + `SessionSet`
3. [x] Schermata progressione (chart + storico)
4. [x] Timer Recupero (tra serie / tra esercizi)

### Fase 2 ✅

1. [x] `BodyProfile` UI + persistence
2. [x] `CalorieTarget` service + disclaimer

### Fase 3 ✅

1. [x] Food seed + custom
2. [x] Shopping list + totale
3. [x] `AlertPolicy` + dialog

### Fase 4 ✅ (preparazione)

1. [x] Test suite domain (+ macro)
2. [x] Progressione peso/volume
3. [x] SBOM + SECURITY.md + listing + RELEASE-CHECKLIST
4. [ ] Firma Play / App Store (esterna)

---

## 16. Criteri accettazione tecnici

- [x] App avvia offline (test widget + Chrome preview)
- [x] Persistenza locale Drift
- [x] Alert non scatta senza target; scatta over/under con soglie default
- [x] Progressione peso/volume per esercizio
- [x] Logo G bianca su nero su splash e launcher
- [x] Nessuna API key nel repo
- [ ] Build firmata Android/iOS su device reale

---

## 17. Decisioni aperte (tecniche)

| Tema | Opzioni | Default TSD |
| --- | --- | --- |
| Accent | grigio chiaro vs verde sobrio | grigio chiaro |
| Totale spesa | tutte le entry vs solo unchecked | tutte |
| Periodo target | giorno vs settimana lista | giorno |
| Max weight vs last set in chart | max per sessione | max |
| Bundle id | dominio reale | `it.brunoferr.gym` |
