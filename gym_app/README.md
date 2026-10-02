# Gym

App Flutter (Android + iOS) per allenamento, dieta e spesa alimentare.

Documentazione: `../PRD.md`, `../TSD.md`, `../CHECKLIST-MVP.md`, `../STORE-LISTING.md`, `../RELEASE-CHECKLIST.md`.

## Avvio

```bash
cd gym_app
flutter pub get
flutter run
```

Preview browser (non prodotto store):

```bash
flutter run -d chrome --web-port=5180
```

Dopo modifiche schema Drift:

```bash
dart run build_runner build
```

SBOM release:

```bash
dart run scripts/generate_sbom.dart
```

Icone / splash (dopo cambio logo):

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

## Stato

**Fase 4** — polish e preparazione release (`0.2.0+2`). Firma store ancora da fare.
