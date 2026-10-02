# Security — Gym

## Segnalare una vulnerabilità

Se trovi un problema di sicurezza in Gym (Android o iOS), **non** aprire una issue pubblica con dettagli sfruttabili.

Scrivi a: **security@gym.app**  
(sostituire con casella reale prima del go-live; deve essere letta entro 2 giorni lavorativi.)

Includi:

- versione app (`Impostazioni` / `pubspec` version)
- piattaforma (Android / iOS) e OS
- passi per riprodurre
- impatto stimato

## Risposta attesa

1. Conferma di ricezione entro 2 giorni lavorativi
2. Valutazione e, se confermato, fix nella prossima release firmata
3. Credit opzionale se richiesto

## Notifiche autorità (CRA art. 14)

In caso di vulnerabilità sfruttata attivamente o incidente grave sulla sicurezza del prodotto:

- avviso al CSIRT coordinatore / ENISA entro **24 ore**
- notifica entro **72 ore**
- rapporto finale secondo i tempi di regolamento

Responsabile operativo: da nominare prima dell’immissione sul mercato UE.

## Ambito v1

Gym è offline-first: schede, misure e spesa restano sul device. Non ci sono account cloud né backend obbligatorio in v1.

Dati relativi a salute (peso, altezza, alimentazione, allenamenti): restano in SQLite locale nella sandbox dell’app. Niente upload silenzioso; crash report senza contenuti sensibili.
