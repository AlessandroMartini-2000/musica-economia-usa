-- =============================================================
-- CREAZIONE TABELLE
-- Progetto: Musica e Ciclo Economico USA (1948-2020)
-- =============================================================

-- ---------------------------------------------------------
-- 1. Catalogo Spotify completo (1921-2020, ~586k brani)
-- Fonte: Kaggle - "Spotify Dataset 1921-2020, 160k+/600k+ Tracks" (Yamac Eren Ay)
-- ---------------------------------------------------------
CREATE TABLE tracks (
    id TEXT PRIMARY KEY,
    name TEXT,
    popularity INTEGER,
    duration_ms INTEGER,
    explicit BOOLEAN,
    artists TEXT,
    id_artists TEXT,
    release_date TEXT,          -- formato non uniforme (solo anno o data completa) -> trattato come testo
    danceability REAL,
    energy REAL,
    key INTEGER,
    loudness REAL,
    mode INTEGER,
    speechiness REAL,
    acousticness REAL,
    instrumentalness REAL,
    liveness REAL,
    valence REAL,
    tempo REAL,
    time_signature INTEGER
);

-- ---------------------------------------------------------
-- 2. Serie macroeconomiche mensili (FRED)
-- ---------------------------------------------------------
CREATE TABLE unemployment (
    date DATE,
    unrate REAL
);

CREATE TABLE consumer_sentiment (
    date DATE,
    umcsent REAL
);

CREATE TABLE inflation (
    date DATE,
    cpiaucsl REAL
);

-- ---------------------------------------------------------
-- 3. Billboard Hot 100 - classifiche settimanali storiche (dal 1958)
-- Fonte: Kaggle - "Billboard Hot 100 Weekly Charts with Audio"
-- ---------------------------------------------------------
CREATE TABLE hot100_settimanale (
    idx REAL,
    url TEXT,
    week_id TEXT,                 -- formato M/D/AAAA
    week_position REAL,
    song TEXT,
    performer TEXT,
    song_id TEXT,
    instance REAL,
    previous_week_position REAL,
    peak_position REAL,
    weeks_on_chart REAL
);

CREATE TABLE hot100_audio_features (
    idx REAL,
    song_id TEXT,
    performer TEXT,
    song TEXT,
    spotify_genre TEXT,
    spotify_track_id TEXT,
    spotify_track_preview_url TEXT,
    spotify_track_duration_ms REAL,
    spotify_track_explicit BOOLEAN,
    spotify_track_album TEXT,
    danceability REAL,
    energy REAL,
    key REAL,
    loudness REAL,
    mode REAL,
    speechiness REAL,
    acousticness REAL,
    instrumentalness REAL,
    liveness REAL,
    valence REAL,
    tempo REAL,
    time_signature REAL,
    spotify_track_popularity REAL
);

-- ---------------------------------------------------------
-- 4. Dataset con testi + sentiment NLP (~15k brani)
-- Fonte: Kaggle - "Audio features and lyrics of Spotify songs" (imuhammad)
-- La colonna sentiment_score viene aggiunta dallo script python/calcola_sentiment.py
-- ---------------------------------------------------------
CREATE TABLE sentiment_testi (
    track_id TEXT,
    track_name TEXT,
    track_artist TEXT,
    lyrics TEXT,
    track_popularity REAL,
    track_album_id TEXT,
    track_album_name TEXT,
    track_album_release_date TEXT,   -- formato YYYY-MM-DD
    playlist_name TEXT,
    playlist_id TEXT,
    playlist_genre TEXT,
    playlist_subgenre TEXT,
    danceability REAL,
    energy REAL,
    key REAL,
    loudness REAL,
    mode REAL,
    speechiness REAL,
    acousticness REAL,
    instrumentalness REAL,
    liveness REAL,
    valence REAL,
    tempo REAL,
    duration_ms REAL,
    language TEXT,
    sentiment_score REAL              -- VADER compound score, da -1 a +1
);
