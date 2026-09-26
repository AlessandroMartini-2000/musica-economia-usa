-- =============================================================
-- ANALISI 3 (robustezza): SENTIMENT DEI TESTI (NLP)
-- ~15.400 brani con testo, sentiment calcolato con VADER
-- (vedi python/calcola_sentiment.py) solo su brani in lingua inglese.
--
-- Questa è la dimensione più vicina a quella usata nella letteratura
-- accademica di riferimento, che analizza il sentiment dei testi
-- (non le audio features) dei brani più consumati.
--
-- Soglia numero_brani >= 50 per escludere gli anni con campione
-- troppo piccolo (il dataset copre in modo scarso gli anni '60).
--
-- LIMITE NOTO: questo dataset proviene da playlist Spotify curate
-- OGGI per genere/decade, non da un campione storico reale di cosa
-- si ascoltava nell'anno di uscita -> stesso tipo di survivorship
-- bias scoperto con la colonna "popularity" (vedi README).
-- =============================================================

WITH sentiment_annuale AS (
    SELECT
        LEFT(track_album_release_date, 4) AS anno,
        ROUND(AVG(sentiment_score)::numeric, 3) AS sentiment_medio,
        COUNT(*) AS numero_brani
    FROM sentiment_testi
    WHERE sentiment_score IS NOT NULL
    GROUP BY LEFT(track_album_release_date, 4)
),
sentiment_filtrato AS (
    SELECT * FROM sentiment_annuale WHERE numero_brani >= 50
),
disoccupazione_annuale AS (
    SELECT EXTRACT(YEAR FROM date)::text AS anno,
           ROUND(AVG(unrate)::numeric, 2) AS disoccupazione_media
    FROM unemployment GROUP BY EXTRACT(YEAR FROM date)
),
fiducia_annuale AS (
    SELECT EXTRACT(YEAR FROM date)::text AS anno,
           ROUND(AVG(umcsent)::numeric, 2) AS fiducia_media
    FROM consumer_sentiment GROUP BY EXTRACT(YEAR FROM date)
),
inflazione_annuale AS (
    SELECT EXTRACT(YEAR FROM date)::text AS anno,
           ROUND(AVG(cpiaucsl)::numeric, 2) AS inflazione_media
    FROM inflation GROUP BY EXTRACT(YEAR FROM date)
),
dataset_completo AS (
    SELECT
        s.anno, s.sentiment_medio,
        d.disoccupazione_media, f.fiducia_media, i.inflazione_media
    FROM sentiment_filtrato s
    LEFT JOIN disoccupazione_annuale d ON s.anno = d.anno
    LEFT JOIN fiducia_annuale f ON s.anno = f.anno
    LEFT JOIN inflazione_annuale i ON s.anno = i.anno
    WHERE d.disoccupazione_media IS NOT NULL
),
dataset_con_variazioni AS (
    SELECT
        anno,
        sentiment_medio - LAG(sentiment_medio) OVER (ORDER BY anno) AS var_sentiment,
        disoccupazione_media - LAG(disoccupazione_media) OVER (ORDER BY anno) AS var_disoccupazione,
        fiducia_media - LAG(fiducia_media) OVER (ORDER BY anno) AS var_fiducia,
        (inflazione_media - LAG(inflazione_media) OVER (ORDER BY anno))
            / LAG(inflazione_media) OVER (ORDER BY anno) * 100 AS var_inflazione
    FROM dataset_completo
)
SELECT
    CORR(var_disoccupazione, var_sentiment) AS corr_disoccupazione,
    CORR(var_fiducia, var_sentiment) AS corr_fiducia,
    CORR(var_inflazione, var_sentiment) AS corr_inflazione
FROM dataset_con_variazioni;

-- Risultato ottenuto: -0.08 | +0.07 | ~0.00
