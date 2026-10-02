# Firma Android — Gym

Keystore locale (non in git se .gitignore attivo):

- File: `android/upload-keystore.jks`
- Alias: `upload`
- Password store/key: vedi `android/key.properties` (locale)

**Conserva backup sicuro del keystore**: senza di esso non potrai aggiornare l’app sullo stesso applicationId su Play Store.

Application id: `it.brunoferr.gym_app`

Build:

```bash
cd gym_app
flutter build appbundle --release
flutter build apk --release
```

Output tipici:

- `build/app/outputs/bundle/release/app-release.aab`
- `build/app/outputs/flutter-apk/app-release.apk`

Copia in `release/` dopo la build.
