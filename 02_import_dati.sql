-- =============================================================
-- IMPORT DEI CSV
-- ATTENZIONE: questo file usa \copy, un meta-comando di psql.
-- Va eseguito con psql (es. `psql -U postgres -d musica_economia -f 02_import_dati.sql`),
-- non funziona in client grafici generici come pgAdmin Query Tool.
--
-- Sostituire i percorsi dei file con quelli reali sul proprio sistema.
-- =============================================================

-- 1. Catalogo completo (nessun valore mancante problematico riscontrato)
\copy tracks FROM 'tracks.csv' DELIMITER ',' CSV HEADER;

-- 2. Serie FRED (mensili, nessun problema di formato)
\copy unemployment FROM 'UNRATE.csv' DELIMITER ',' CSV HEADER;
\copy consumer_sentiment FROM 'UMCSENT.csv' DELIMITER ',' CSV HEADER;
\copy inflation FROM 'CPIAUCSL.csv' DELIMITER ',' CSV HEADER;

-- 3. Billboard Hot 100
-- NOTA: il dataset contiene valori mancanti come stringa vuota tra virgolette ("")
-- nelle colonne numeriche (es. previous_week_position per un brano alla prima
-- settimana in classifica). FORCE_NULL dice a Postgres di trattarli come NULL
-- invece di tentare una conversione a REAL che fallirebbe.
\copy hot100_settimanale FROM 'Hot Stuff.csv' WITH (
    FORMAT csv, HEADER true, DELIMITER ',',
    FORCE_NULL(idx, week_position, instance, previous_week_position, peak_position, weeks_on_chart)
);

\copy hot100_audio_features FROM 'Hot 100 Audio Features.csv' WITH (
    FORMAT csv, HEADER true, DELIMITER ',',
    FORCE_NULL(idx, spotify_track_duration_ms, danceability, energy, key, loudness, mode,
               speechiness, acousticness, instrumentalness, liveness, valence, tempo,
               time_signature, spotify_track_popularity)
);

-- 4. Dataset con sentiment (output dello script python/calcola_sentiment.py)
\copy sentiment_testi FROM 'dataset_con_sentiment.csv' WITH (
    FORMAT csv, HEADER true, DELIMITER ',',
    FORCE_NULL(track_popularity, danceability, energy, key, loudness, mode, speechiness,
               acousticness, instrumentalness, liveness, valence, tempo, duration_ms, sentiment_score)
);
