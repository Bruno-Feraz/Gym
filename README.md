# Gym

App mobile per allenamento, dieta e spesa alimentare: schede palestra con progressione carichi, piano calorie e lista della spesa con check nutrizionale.

Piattaforme: **Android** e **iOS** (Flutter). Offline-first in v1.

## Certificazione d'uso

**Uso privato / personale soltanto. Uso commerciale vietato.**  
Vedi [`LICENSE`](LICENSE).

> Disclaimer: le stime caloriche sono indicative, non diagnosi medica.

## Stack

- Flutter + Riverpod + GoRouter
- Drift (SQLite locale)
- fl_chart (progressioni)

## Sezioni

| Tab | Contenuto |
| --- | --- |
| **Palestra** | Schede, esercizi, serie, ripetizioni, peso |
| **Dieta** | Fabbisogno e corpo |
| **Spesa** | Lista con valori nutrizionali e alert sul target |

## Avvio

```bash
cd gym_app
flutter pub get
flutter run
```

Dopo modifiche schema Drift:

```bash
dart run build_runner build
```

## Struttura

```text
Gym/
├── PRD.md / TSD.md
├── brand/
├── CHECKLIST-MVP.md
├── STORE-LISTING.md
├── RELEASE-CHECKLIST.md
└── gym_app/
    ├── lib/
    ├── android/ ios/
    └── release/
```

## Documentazione

- [`PRD.md`](PRD.md) · [`TSD.md`](TSD.md)
- [`gym_app/README.md`](gym_app/README.md)
- [`gym_app/SECURITY.md`](gym_app/SECURITY.md)

## Autore

Bruno Feraz
