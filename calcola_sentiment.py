"""
Calcola il sentiment (VADER) dei testi delle canzoni.

Input:  CSV con una colonna 'lyrics' (testo) e 'language' (codice lingua)
Output: stesso CSV + colonna 'sentiment_score' (compound score, -1 a +1)

Nota: VADER è affidabile solo su testi in inglese, quindi il dataset
viene filtrato a language == 'en' prima del calcolo.

Dipendenze:
    pip3 install vaderSentiment pandas
"""

import pandas as pd
from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer

INPUT_CSV = "spotify_songs.csv"
OUTPUT_CSV = "dataset_con_sentiment.csv"

df = pd.read_csv(INPUT_CSV)

# Tieni solo i brani in inglese
df = df[df["language"] == "en"].copy()

analyzer = SentimentIntensityAnalyzer()


def calcola_punteggio(testo):
    if pd.isna(testo):
        return None
    return analyzer.polarity_scores(str(testo))["compound"]


df["sentiment_score"] = df["lyrics"].apply(calcola_punteggio)

df.to_csv(OUTPUT_CSV, index=False)

print(f"Fatto! {len(df)} brani in inglese processati.")
