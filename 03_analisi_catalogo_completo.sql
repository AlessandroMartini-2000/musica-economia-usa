-- =============================================================
-- ANALISI 1: CATALOGO COMPLETO (lato "offerta")
-- ~586.000 brani pubblicati su Spotify, 1921-2020
--
-- Mood Index = valence + danceability - acousticness
-- Soglia numero_brani >= 3500 per escludere gli anni con campione
-- troppo piccolo per una media affidabile (anni '20-'40).
--
-- Le correlazioni sono calcolate sulle VARIAZIONI anno su anno
-- (non sui livelli assoluti) per evitare la correlazione spuria
-- dovuta al trend strutturale crescente di valence/danceability
-- e decrescente di acousticness nel tempo.
--
-- L'inflazione è trasformata in variazione PERCENTUALE (vero tasso
-- di inflazione), non in differenza assoluta dell'indice CPI, che
-- altrimenti cresce quasi sempre solo perché la base è più alta.
-- =============================================================

WITH musica_annuale AS (
    SELECT
        LEFT(release_date, 4) AS anno,
        ROUND(AVG(valence)::numeric, 3) AS valence_media,
        ROUND(AVG(danceability)::numeric, 3) AS danceability_media,
        ROUND(AVG(acousticness)::numeric, 3) AS acousticness_media,
        COUNT(*) AS numero_brani
    FROM tracks
    GROUP BY LEFT(release_date, 4)
),
musica_filtrata AS (
    SELECT * FROM musica_annuale WHERE numero_brani >= 3500
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
        m.anno, m.valence_media, m.danceability_media, m.acousticness_media,
        d.disoccupazione_media, f.fiducia_media, i.inflazione_media
    FROM musica_filtrata m
    LEFT JOIN disoccupazione_annuale d ON m.anno = d.anno
    LEFT JOIN fiducia_annuale f ON m.anno = f.anno
    LEFT JOIN inflazione_annuale i ON m.anno = i.anno
    WHERE d.disoccupazione_media IS NOT NULL
),
dataset_con_variazioni AS (
    SELECT
        anno,
        (valence_media + danceability_media - acousticness_media)
            - LAG(valence_media + danceability_media - acousticness_media) OVER (ORDER BY anno) AS var_mood,
        disoccupazione_media - LAG(disoccupazione_media) OVER (ORDER BY anno) AS var_disoccupazione,
        fiducia_media - LAG(fiducia_media) OVER (ORDER BY anno) AS var_fiducia,
        (inflazione_media - LAG(inflazione_media) OVER (ORDER BY anno))
            / LAG(inflazione_media) OVER (ORDER BY anno) * 100 AS var_inflazione
    FROM dataset_completo
)

-- (A) Dataset pronto per l'export verso Tableau (livelli, non variazioni)
-- SELECT * FROM dataset_completo ORDER BY anno;

-- (B) Correlazioni finali (decommentare l'una o l'altra query)
SELECT
    CORR(var_disoccupazione, var_mood) AS corr_disoccupazione,
    CORR(var_fiducia, var_mood) AS corr_fiducia,
    CORR(var_inflazione, var_mood) AS corr_inflazione
FROM dataset_con_variazioni;

-- Risultato ottenuto: -0.13 | -0.11 | +0.05
