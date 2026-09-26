-- =============================================================
-- ANALISI 2 (robustezza): BILLBOARD HOT 100 (lato "consumo")
-- Classifiche settimanali storiche reali, 1958-2021, con audio
-- features Spotify collegate. A differenza del catalogo completo,
-- ogni apparizione settimanale è una riga: un brano rimasto più
-- settimane in classifica pesa di più nella media annuale,
-- riflettendo meglio l'esposizione reale del pubblico.
--
-- Soglia numero_apparizioni >= 5000 per escludere gli anni parziali
-- (1958, anno di lancio della classifica, e l'ultimo anno coperto
-- dal dataset, entrambi con meno di 52 settimane piene).
-- =============================================================

WITH hot100_completo AS (
    SELECT
        h.song_id,
        SPLIT_PART(h.week_id, '/', 3) AS anno,
        a.valence, a.danceability, a.acousticness
    FROM hot100_settimanale h
    JOIN hot100_audio_features a ON h.song_id = a.song_id
),
hot100_annuale AS (
    SELECT anno,
        ROUND(AVG(valence)::numeric, 3) AS valence_media,
        ROUND(AVG(danceability)::numeric, 3) AS danceability_media,
        ROUND(AVG(acousticness)::numeric, 3) AS acousticness_media,
        COUNT(*) AS numero_apparizioni
    FROM hot100_completo GROUP BY anno
),
hot100_filtrato AS (
    SELECT * FROM hot100_annuale WHERE numero_apparizioni >= 5000
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
        h.anno, h.valence_media, h.danceability_media, h.acousticness_media,
        d.disoccupazione_media, f.fiducia_media, i.inflazione_media
    FROM hot100_filtrato h
    LEFT JOIN disoccupazione_annuale d ON h.anno = d.anno
    LEFT JOIN fiducia_annuale f ON h.anno = f.anno
    LEFT JOIN inflazione_annuale i ON h.anno = i.anno
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
SELECT
    CORR(var_disoccupazione, var_mood) AS corr_disoccupazione,
    CORR(var_fiducia, var_mood) AS corr_fiducia,
    CORR(var_inflazione, var_mood) AS corr_inflazione
FROM dataset_con_variazioni;

-- Risultato ottenuto: -0.19 | -0.04 | +0.05
