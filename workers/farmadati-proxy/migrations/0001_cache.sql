-- Cache condivisa delle risposte Farmadati.
-- key: "<dataset>|<campo filtro>|<valore in maiuscolo>" oppure "r2|<codice>"
-- payload: JSON; NULL = risposta vuota (cache negativa)
CREATE TABLE IF NOT EXISTS cache (
  key TEXT PRIMARY KEY,
  payload TEXT,
  fetched_at INTEGER NOT NULL -- epoch ms
);
