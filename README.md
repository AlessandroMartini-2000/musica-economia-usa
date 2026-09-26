# Musica e Ciclo Economico USA (1948-2020)

Esiste un legame tra l'umore della musica pubblicata/ascoltata e l'andamento dell'economia? Questo progetto testa la domanda con tre fonti dati indipendenti, un confronto diretto con la letteratura accademica sul tema, e una narrazione onesta di ciò che i dati mostrano e non mostrano.

**Dashboard interattiva:** [Musica e Ciclo Economico USA (Tableau Public)](https://public.tableau.com/app/profile/alessandro.martini1058/viz/MusicaeCicloEconomicoUSA1948-2020/Dashboard1)

---

## Obiettivo

Verificare se esistono pattern ricorrenti tra il "mood" della musica e tre indicatori macroeconomici USA (disoccupazione, fiducia dei consumatori, inflazione), usando tre diverse fonti musicali indipendenti per capire quanto il risultato dipenda dalla fonte scelta, non solo dal metodo statistico.

## Dataset utilizzati

| Dataset | Contenuto | Periodo | Fonte |
|---|---|---|---|
| Catalogo Spotify completo | ~586.000 brani, audio features | 1921-2020 | Kaggle (Yamac Eren Ay) |
| Billboard Hot 100 | Classifiche settimanali storiche + audio features | 1958-2021 | Kaggle |
| Spotify + testi | ~18.000 brani con testo, filtrati a ~15.400 in inglese | Multi-decade (playlist curate) | Kaggle (imuhammad) |
| Disoccupazione, fiducia consumatori, inflazione | Serie mensili USA | 1948-2020 | FRED (Federal Reserve) |

## Metodologia

**Pipeline:** PostgreSQL per l'aggregazione e il join dei dati (window function, CTE, correlazioni), Python per il sentiment analysis dei testi (VADER) e per la regressione OLS con correzione per autocorrelazione (statsmodels), Tableau Public per la visualizzazione finale.

**Indicatore musicale (fonte audio):** `Mood Index = valence + danceability - acousticness`

**Indicatore musicale (fonte testi):** compound score di VADER sui testi in inglese (-1 = molto negativo, +1 = molto positivo)

Le correlazioni sono calcolate sulle **variazioni anno su anno**, non sui livelli assoluti — per il motivo spiegato sotto.

## Risultati

| Fonte musicale | Disoccupazione | Fiducia consumatori | Inflazione |
|---|---|---|---|
| Catalogo completo (audio) | -0.13 | -0.11 | +0.05 |
| Billboard Hot 100 (audio, consumo storico) | -0.19 | -0.04 | +0.05 |
| Sentiment testi (NLP) | -0.08 | +0.07 | ~0.00 |

**Nessuna correlazione supera 0.19 in valore assoluto**, in nessuna delle tre fonti indipendenti. Il segnale non è solo debole: cambia segno tra un metodo e l'altro per fiducia e inflazione, un pattern tipico di rumore statistico piuttosto che di un effetto reale a livello annuale.

**Approfondimento a più alta frequenza:** replicando su base *mensile* (invece che annuale) la tecnica di regressione con trend esplicito usata come test di robustezza nel paper accademico di riferimento (vedi sotto), e correggendo per l'autocorrelazione seriale con errori standard HAC (Newey-West), emerge un effetto della disoccupazione sul Mood Index nella direzione prevista dalla letteratura, ma statisticamente debole: coefficiente 0.013, p = 0.048, R² = 0.16 (N = 653 mesi). Uno dei risultati più solidi del progetto proprio perché costruito con la tecnica più rigorosa a disposizione — e resta comunque un effetto borderline, non una conferma forte.

## Confronto con la letteratura accademica

Il riferimento principale è **de Lucio & Palomeque (2022)**, *"Music preferences as an instrument of emotional self-regulation along the business cycle"*, Journal of Cultural Economics ([DOI: 10.1007/s10824-022-09454-7](https://doi.org/10.1007/s10824-022-09454-7)). Gli autori trovano che quando la disoccupazione aumenta, il pubblico consuma musica più positiva (un meccanismo di auto-regolazione emotiva, coerente con il cosiddetto "lipstick effect"), usando una classificazione via NLP dei testi della Billboard Hot 100 dal 1958 al 2019.

Due differenze spiegano perché questo progetto non replica lo stesso segnale forte:

1. **Frequenza dei dati.** Il risultato principale del paper si basa su dati **settimanali** (2.765 osservazioni), non annuali. Gli stessi autori, ripetendo l'analisi su base annuale (62 osservazioni, lo stesso ordine di grandezza usato qui), riportano un effetto nella stessa direzione ma con **significatività più bassa** — un pattern coerente con quanto trovato in questo progetto.
2. **Tecnica di rimozione del trend.** Il paper usa una regressione sui livelli con un trend temporale esplicito come regressore; questo progetto usa principalmente le differenze anno su anno. Sono entrambi modi legittimi di isolare l'effetto ciclico da un trend strutturale, ma su un campione annuale piccolo possono produrre risultati di forza diversa — le differenze tendono ad amplificare il rumore rispetto al segnale.

## Errori metodologici scoperti e corretti durante il progetto

Il valore di questo progetto sta anche nei tre problemi metodologici individuati e corretti nel percorso, non solo nel risultato finale:

1. **Correlazione spuria da trend condiviso.** Calcolando la correlazione sui *livelli* assoluti (non sulle variazioni), l'inflazione mostrava una correlazione di 0.83 con il Mood Index — quasi interamente dovuta al fatto che entrambe le serie crescono nel tempo per ragioni indipendenti (evoluzione della produzione musicale, inflazione strutturale), non a un vero legame economico. Corretto passando alle variazioni anno su anno.
2. **Trasformazione errata dell'indice di inflazione.** Anche dopo la correzione precedente, la differenza *assoluta* dell'indice CPI resta artificiosamente correlata con qualsiasi altra serie crescente, perché la base dell'indice cresce nel tempo. Corretto usando la vera variazione *percentuale* (il tasso di inflazione), non la differenza assoluta dell'indice.
3. **Autocorrelazione seriale nella regressione mensile.** La prima stima OLS (senza correzione) mostrava un Durbin-Watson di 0.117 — segno di residui fortemente autocorrelati, che rende i p-value calcolati in modo standard artificiosamente bassi. Corretto con errori standard robusti HAC (Newey-West, 12 lag).

## Limiti noti

- **Survivorship bias sulla `popularity` di Spotify**: la colonna `popularity` riflette gli ascolti *attuali*, non quelli storici — filtrare per popularity elevata isola i "classici senza tempo" sopravvissuti fino ad oggi, non ciò che si ascoltava realmente in una data epoca. Per questo è stato usato il dato Billboard (classifiche storiche reali) invece che questo filtro.
- **Dataset con testi non storicamente rappresentativo**: proviene da playlist Spotify curate oggi per genere/decade, quindi soffre dello stesso tipo di bias del punto precedente, in forma più attenuata.
- **Campione annuale ridotto** (60-70 osservazioni): limita il potere statistico per rilevare effetti deboli, un vincolo esplicitamente confermato anche nel paper di riferimento a parità di frequenza dei dati.

## Struttura del repository

```
├── README.md
├── sql/
│   ├── 01_creazione_tabelle.sql
│   ├── 02_import_dati.sql                    (richiede psql, usa \copy)
│   ├── 03_analisi_catalogo_completo.sql
│   ├── 04_analisi_billboard.sql
│   ├── 05_analisi_sentiment_testi.sql
│   └── 06_dataset_regressione_mensile.sql
└── python/
    ├── calcola_sentiment.py                  (VADER sentiment analysis)
    └── regressione_mensile.py                (OLS con trend e correzione HAC)
```

## Strumenti utilizzati

PostgreSQL 18 · pgAdmin / psql · Python (pandas, vaderSentiment, statsmodels) · Tableau Public

## Fonti dati

- Spotify Dataset 1921-2020 — Kaggle (Yamac Eren Ay)
- Billboard Hot 100 Weekly Charts with Audio — Kaggle
- Audio features and lyrics of Spotify songs — Kaggle (imuhammad)
- FRED (Federal Reserve Economic Data) — serie UNRATE, UMCSENT, CPIAUCSL
