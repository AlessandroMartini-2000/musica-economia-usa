-- =============================================================
-- DATASET PER LA REGRESSIONE MENSILE (vedi python/regressione_mensile.py)
--
-- Aggrega Billboard Hot 100 a livello MENSILE (non annuale) e lo
-- unisce alla disoccupazione mensile FRED, replicando la stessa
-- granularità usata come test di robustezza nel paper accademico
-- di riferimento (de Lucio & Palomeque, 2022 - vedi README).
--
-- Include una colonna "trend" (numero progressivo per mese), da
-- usare come regressore nel modello Python per isolare l'effetto
-- del semplice passare del tempo dall'effetto della disoccupazione.
--
-- Periodo: dal 1967 (inizio dati mensili ad alta frequenza),
-- replicando il periodo usato nel paper di riferimento.
--
-- Eseguire con psql per esportare direttamente in CSV:
--   \copy (... query sotto ...) TO 'hot100_mensile.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');
-- =============================================================

WITH hot100_mensile AS (
    SELECT
        SPLIT_PART(h.week_id, '/', 3) || '-' || LPAD(SPLIT_PART(h.week_id, '/', 1), 2, '0') AS anno_mese,
        ROUND(AVG(a.valence)::numeric, 3) AS valence_media,
        ROUND(AVG(a.danceability)::numeric, 3) AS danceability_media,
        ROUND(AVG(a.acousticness)::numeric, 3) AS acousticness_media,
        COUNT(*) AS numero_apparizioni
    FROM hot100_settimanale h
    JOIN hot100_audio_features a ON h.song_id = a.song_id
    GROUP BY SPLIT_PART(h.week_id, '/', 3) || '-' || LPAD(SPLIT_PART(h.week_id, '/', 1), 2, '0')
),
disoccupazione_mensile AS (
    SELECT
        TO_CHAR(date, 'YYYY-MM') AS anno_mese,
        ROUND(unrate::numeric, 2) AS disoccupazione
    FROM unemployment
)
SELECT
    h.anno_mese,
    ROW_NUMBER() OVER (ORDER BY h.anno_mese) AS trend,
    h.valence_media,
    h.danceability_media,
    h.acousticness_media,
    h.numero_apparizioni,
    d.disoccupazione
FROM hot100_mensile h
JOIN disoccupazione_mensile d ON h.anno_mese = d.anno_mese
WHERE h.anno_mese >= '1967-01'
ORDER BY h.anno_mese;
