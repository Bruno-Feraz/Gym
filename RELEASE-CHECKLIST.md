# Checklist release — Gym (Android + iOS)

Adattata da `../REGOLE-PRODUZIONE-SVILUPPO.md` §4 / §9 per un’app nativa Flutter.  
Spuntare a ogni build destinata a utenti. Checklist funzionale MVP: `../CHECKLIST-MVP.md`.

## Identità release

- [ ] Versione in `gym_app/pubspec.yaml` (`version: x.y.z+build`) allineata ad Android/iOS
- [ ] Data release e canale (Play internal / App Store TestFlight / APK sideload)
- [ ] Commit git della build annotato
- [ ] Hash SHA-256 di AAB / IPA archiviato in `gym_app/release/`
- [ ] SBOM: da `gym_app/` → `dart run scripts/generate_sbom.dart` → `release/`

## Build e codice

- [ ] `flutter analyze` senza issue
- [ ] `flutter test` ok
- [ ] Nessun segreto / API key nel repo o nel binario
- [ ] Nessun placeholder / TODO / lorem visibile in UI
- [ ] Web solo preview locale (non prodotto store)
- [ ] Dipendenze da `pubspec.lock`; `flutter pub outdated` rivisto

## Firma e distribuzione

- [ ] Android: AAB firmato con keystore di produzione (non debug)
- [ ] iOS: build firmata + upload App Store Connect / TestFlight
- [ ] Bundle id: `it.brunoferr.gym` (confermare dominio reale)
- [ ] Update solo da store ufficiali

## Sicurezza prodotto

- [ ] Contatto vulnerabilità pubblico in `SECURITY.md` (casella monitorata)
- [ ] Crash/log senza PII salute (peso, pasti, note)
- [ ] Permessi minimi (nessuna rete obbligatoria in v1)
- [ ] Periodo di supporto dichiarato (vedi sotto)

## Conformità (locale, no account cloud)

- [ ] Nessun analytics/marketing di terzi prima di consenso (v1: nessuno)
- [ ] Disclaimer stime kcal/macro: non consiglio medico (in-app + listing)
- [ ] Informativa: dati restano sul device
- [ ] CRA / art. 14: procedura notifica in `SECURITY.md`

## Store listing

- [ ] Testi e screenshot in `../STORE-LISTING.md` aggiornati
- [ ] Icona / splash: **G bianca su nero**
- [ ] Classificazione età e dichiarazioni dati salute

## Periodo di supporto (dichiarazione prodotto)

| Voce | Valore |
| --- | --- |
| Prodotto | Gym |
| Supporto sicurezza fino a | **dicembre 2031** (5 anni da prima immissione prevista 2026) |
| Aggiornamenti | Build firmate via Play Store / App Store |

---

Dopo la spunta: archiviare checklist (data + versione) insieme a SBOM e hash in `gym_app/release/`.
