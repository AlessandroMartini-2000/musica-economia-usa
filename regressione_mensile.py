"""
Regressione OLS mensile: Mood Index (Billboard) ~ disoccupazione + trend.

Replica, con dati mensili, la tecnica usata come test di robustezza nel
paper di riferimento (de Lucio & Palomeque, 2022): una regressione sui
livelli con un trend temporale esplicito come regressore, invece della
differenza anno su anno usata nelle analisi SQL principali di questo
progetto (vedi sql/03, 04, 05).

Gli errori standard sono corretti con il metodo HAC (Newey-West), che
tiene conto dell'autocorrelazione seriale nei residui — un problema
reale qui: la prima stima (senza questa correzione) mostrava un
Durbin-Watson di 0.117, indice di forte autocorrelazione, che rende i
p-value della regressione OLS "semplice" artificiosamente ottimisti.

Input:  sql/06_dataset_regressione_mensile.sql -> hot100_mensile.csv
Dipendenze:
    pip3 install pandas statsmodels
"""

import pandas as pd
import statsmodels.api as sm

df = pd.read_csv("hot100_mensile.csv")

# Mood Index: stessa formula usata nelle analisi annuali
df["mood_index"] = df["valence_media"] + df["danceability_media"] - df["acousticness_media"]

X = df[["disoccupazione", "trend"]]
X = sm.add_constant(X)
y = df["mood_index"]

# HAC (Newey-West) con 12 lag: corregge gli errori standard per
# l'autocorrelazione seriale tipica di dati mensili persistenti.
modello = sm.OLS(y, X).fit(cov_type="HAC", cov_kwds={"maxlags": 12})

print(modello.summary())

# Risultato ottenuto:
# disoccupazione: coef = 0.0127, std err = 0.006, p = 0.048, R² = 0.159
# Effetto nella direzione prevista dalla letteratura, ma statisticamente
# debole/borderline rispetto ai risultati weekly del paper di riferimento.
