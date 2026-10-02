# PRD — Gym

App mobile per allenamento, dieta e spesa alimentare: schede palestra con progressione carichi, piano calorie e lista della spesa con check nutrizionale in tempo reale.

**Stato:** bozza v0.7 — Fase 4 preparazione release (firma store pendente)  
**Nome lavoro:** Gym  
**Logo:** lettera **G** bianca su sfondo nero (`brand/logo.svg`, `brand/logo-gym.png`)  
**Piattaforme:** Android + iOS  
**Stack:** Flutter (confermato)  
**Utente:** chi si allena in palestra e vuole scheda, calorie e spesa in un’unica app, senza clutter  
**UI:** clean, professionale, minimale

Fonte idea: `gymapp.md`. Vincoli di rilascio, sicurezza e conformità: `../REGOLE-PRODUZIONE-SVILUPPO.md` (in particolare §3 isolamento dati, §4 software, §5 legale / privacy salute).

---

## 1. Perché esiste

Chi si allena tiene scheda, dieta e spesa in tre posti diversi (WhatsApp, note, fogli). Gym unifica il ciclo utile:

- definire allenamenti (per giorno o per nome) con esercizi, serie, ripetizioni e peso
- vedere la progressione dei carichi nel tempo
- impostare fabbisogno calorico (stima da antropometria o target manuale)
- costruire la lista della spesa con valori nutrizionali
- ricevere un alert se la spesa supera o scende troppo rispetto al fabbisogno

Se una funzione non serve a chiudere scheda → dieta → spesa, **non entra** in v1.

---

## 2. Principi

1. **Mobile nativo Android + iOS.** Un codebase Flutter; niente dipendenza obbligatoria da browser.
2. **Tre sezioni, un prodotto.** Palestra | Dieta / corpo | Spesa. Navigazione chiara, zero menu annidati.
3. **Poche azioni, prevedibili.** Aggiungi, modifica, elimina, spunta, vedi progressione.
4. **Dati sul device in v1.** Offline-first; account/cloud = post-MVP.
5. **Numeri onesti.** Stima calorica sommaria (non diagnosi medica); disclaimer in-app.
6. **Alert utili, non spam.** Popup solo quando la spesa esce dalla fascia rispetto al target.
7. **UI clean / professionale / minimale.** Nero, bianco, grigi; accento unico; niente clutter.
8. **Logo = G.** Identità visiva: **G bianca su nero** su splash, icona store e header.
9. **Rilascio sicuro.** Build firmate, niente segreti nel binario, SBOM, contatto vulnerabilità (regole §4).

---

## 2.1 Design UI / UX

| Regola | Dettaglio |
| --- | --- |
| **Minimal** | Bottom nav a 3 tab (Palestra, Dieta, Spesa) + Profilo/corpo; niente drawer pieno |
| **Clean** | Superfici piatte, tipografia leggibile, spacing coerente, liste ordinate |
| **Professionale** | Contrasto alto, tono copy sobrio; niente emoji decorative di default |
| **Brand** | Logo G bianca su nero; splash e icona allineate |
| **Motion** | Micro-transizioni corte; rispetta reduced-motion OS |
| **Popup spesa** | Dialog chiaro: “sopra target” / “sotto target”, valori e CTA Chiudi / Vai a target |

Token (da fissare in codice):

- `bg` nero / quasi nero
- `surface` / `surfaceHigh`
- `text` bianco / `textMuted` grigio
- `accent` (un solo colore funzionale, non viola generico — es. bianco/grigio chiaro o verde salute sobrio)
- `danger` / `warning` per alert spesa
- raggio piccolo (4–8), niente pill decorative

---

## 3. Cosa non è (fuori scope v1)

- Social feed, coach live, community
- Wearable sync obbligatorio (Apple Watch / Google Fit) — possibile v1.x
- Piani alimentari AI generativi
- Video esercizi streaming / libreria video proprietaria
- E-commerce spesa / integrazione supermercati
- Diagnosi medica, BMI “clinico”, consigli farmacologici
- Web / PWA come prodotto principale
- Multiutente / condivisione schede cloud

---

## 4. Piattaforme e stack

| Target | Forma | Note |
| --- | --- | --- |
| **Android** | AAB Play Store (+ APK sideload dev) | Touch-first |
| **iOS** | IPA App Store | Touch-first |

**Stack (confermato):** Flutter, persistenza locale (SQLite / Drift o equivalente), state management coerente col team (es. Riverpod).

Cartella app proposta: `gym_app/`.

---

## 5. Visione prodotto (flusso)

```text
Onboarding breve (peso, altezza, target kcal opzionale)
    → Tab Palestra: crea scheda (giorno o nome) → esercizi/serie/reps/peso
    → Progressione: storico peso per esercizio
    → Tab Dieta / corpo: aggiorna misure o target kcal
    → Tab Spesa: aggiungi alimenti → kcal/macro → somma vs target
    → Se fuori fascia → popup alert
```

---

## 6. Funzionalità

### 6.1 Palestra

| Funzione | Dettaglio v1 |
| --- | --- |
| Nuova scheda | Per **giorno della settimana** oppure **nome libero** (es. “Push A”) |
| Esercizi | Nome (catalogo base + custom), ordine nella scheda |
| Serie / ripetizioni | Interi; supporto range reps opzionale (es. 8–12) in v1.1 se troppo |
| Peso | Valore numerico per serie o per esercizio (kg); storico per progressione |
| Sessione | Segnare allenamento svolto (data); salvare carichi usati |
| Progressione | Grafico/lista storica peso (e volume = serie×reps×peso) per esercizio |
| Modifica / elimina | Scheda, esercizio, set; conferma su elimina |

### 6.2 Corpo e calorie (Dieta)

| Funzione | Dettaglio v1 |
| --- | --- |
| Misure | Peso (kg), altezza (cm); opzionale età, sesso, attività (per stima) |
| Target kcal | **Stima sommaria** da formule standard **oppure** inserimento manuale |
| Macro (base) | Opzionale v1: solo kcal obbligatorie; proteine/carb/grassi in v1.1 |
| Disclaimer | Testo breve: stima non medica, non sostituisce professionista |

### 6.3 Spesa / alimenti

| Funzione | Dettaglio v1 |
| --- | --- |
| Aggiungi alimento | Nome, quantità (g / porzione), valori nutrizionali |
| Valori | kcal (obbligatorio); proteine/carb/grassi se noti |
| Catalogo | DB alimenti base seedati + custom utente |
| Lista | Checklist “da comprare” / “preso”; somma nutrizionale della lista |
| Confronto target | Totale lista vs fabbisogno / target giornaliero (o settimanale — default: **giornaliero** riferito alla spesa “piano pasti del giorno”) |
| Alert | Se totale **sopra** soglia alta o **sotto** soglia bassa → **popup** |

**Soglie alert (default, configurabili in Impostazioni):**

- sopra: > 110% del target kcal
- sotto: < 80% del target kcal

Trigger: all’aggiunta/modifica quantità o al completamento check della lista (non a ogni keystroke).

### 6.4 Profilo / impostazioni

- Unità (kg/cm)
- Target kcal e soglie alert
- Tema (default dark brand; light opzionale post-MVP)
- Privacy / disclaimer salute
- Export dati (JSON) post-MVP

---

## 7. Account e dati

v1 **senza account obbligatorio**: tutto locale sul device.

Classificazione: peso, altezza, allenamenti, alimentazione = **dati relativi alla salute** → trattamento con attenzione privacy (regole §5); niente analytics invasivi di default; crash report senza contenuti sensibili.

Post-MVP: account + sync → isolamento UUID, age gate se signup, marketing opt-in (regole §3/§5).

---

## 8. Architettura app (alto livello)

```text
UI Flutter (Android + iOS)
    → Domain: Workout / Exercise / BodyMetrics / Food / ShoppingList
    → Local DB (SQLite)
    → Nutrition calc + alert policy
    → Charts progressione
    → OS: notifiche locali opzionali (v1.1)
```

Identificativi = UUID. Nessun path storage interno esposto come “nome” all’utente.

---

## 9. Brand e logo

| Elemento | Specifica |
| --- | --- |
| Marchio | Gym (nome lavoro; brand store da confermare) |
| Logo | **G** bianca (#FFFFFF) su sfondo nero (#000000) |
| Formato icona | Quadrato; G centrata, sans geometrica bold |
| Asset | `brand/logo.svg`, `brand/logo-gym.png` |
| Uso | App icon, splash, eventuale header compatto |

---

## 10. Rilascio e conformità

Checklist essenziale da regole §4 / §5 / CRA:

- Nessun segreto nell’artefatto
- Build Android/iOS firmate; update solo da store ufficiali
- SBOM della release; versione + commit tracciabili
- Contatto vulnerabilità pubblico
- Disclaimer stima calorica / non consiglio medico
- Errori utente generici; stack solo in debug
- Periodo di supporto dichiarato al go-live UE

---

## 11. Monetizzazione (bozza)

- Free: schede, spesa, target base
- Pro (post-MVP): sync cloud, export, grafici avanzati, catalogo alimenti esteso — da decidere

---

## 12. Roadmap build

### Fase 0 — Fondamenta ✅

- [x] Repo Flutter (Android + iOS) in `gym_app/`
- [x] Shell UI: bottom nav 3 tab + token dark minimale
- [x] Logo G / splash / icone
- [x] DB locale + modello dati + seed esercizi/alimenti

### Fase 1 — Palestra ✅

- [x] CRUD schede (giorno / nome)
- [x] Esercizi, serie, reps, peso
- [x] Storico sessione + progressione base
- [x] Timer **Recupero** (tra serie / tra esercizi) accanto ad Allenati

### Fase 2 — Corpo e calorie ✅

- [x] Form misure + target manuale
- [x] Stima sommaria kcal
- [x] Disclaimer in-app

### Fase 3 — Spesa ✅

- [x] Catalogo alimenti + custom
- [x] Lista spesa + somma nutrizionale
- [x] Popup sopra/sotto target

### Fase 4 — Polish e release ✅ (preparazione)

- [x] Grafici progressione (peso max + volume)
- [x] Checklist store / SBOM / SECURITY (`RELEASE-CHECKLIST.md`, `STORE-LISTING.md`, `gym_app/SECURITY.md`, `scripts/generate_sbom.dart`)
- [ ] Firma e listing Play + App Store (richiede account / certificati dell’autore)

---

## 13. Criteri successo MVP

Su **Android e iOS**, in una sessione:

1. imposta peso/altezza o target kcal manuale  
2. crea una scheda “Push” con 2 esercizi, serie/reps/peso  
3. registra una sessione e vede il peso salvato  
4. aggiunge 3 alimenti in spesa e vede il totale kcal  
5. forza un totale fuori soglia e riceve il **popup** alert  

---

## 14. Decisioni

| Decisione | Scelta |
| --- | --- |
| Stack | **Flutter** |
| Piattaforme v1 | Android + iOS |
| UI | Clean, professionale, minimale, dark brand |
| Logo | G bianca su nero |
| Account v1 | No (solo locale) |
| Calorie | Stima sommaria **o** target manuale |
| Alert spesa | Popup sopra/sotto soglia |

Aperti: nome store definitivo, accent color, periodo target spesa (giorno vs settimana), IAP.
