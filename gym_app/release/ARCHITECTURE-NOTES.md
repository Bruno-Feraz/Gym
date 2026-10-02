# Architettura e performance — note

## Modularità

- `domain/` — modelli e logica pura (calorie, alert, niente Flutter)
- `data/` — Drift + repository
- `features/` — UI per area (workout, body, shopping, settings)
- `shared/widgets/` — componenti riusabili (bottoni, loading, app bar)

## Efficienza

- Catalogo esercizi/alimenti: `StreamProvider.autoDispose` (si chiude fuori dal picker)
- Conteggio esercizi per scheda: un solo fetch, niente N+1
- Timer recupero: si mette in pausa con app in background
- Logo in app bar: `cacheWidth` per non tenere bitmap full-res in RAM
- Release Android: minify + shrink resources
- Nessuna rete / analytics / sync in background

## Logo

Sorgente: `Gym/brand/logo-gym.png` + `logo.svg`  
Propagato a: assets Flutter, splash, launcher Android/iOS, favicon e icone web.
