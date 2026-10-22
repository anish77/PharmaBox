import type { CachedLoader, Policy } from "./cache";
import type { Dataset, FdiRecord, FetchFn } from "./farmadati";

const DAY = 24 * 60 * 60 * 1000;
/** Download e ingest di un'immagine: oltre, meglio nessuna immagine che una richiesta appesa. */
const IMMAGINE_TIMEOUT_MS = 20_000;
const HOUR = 60 * 60 * 1000;

/** Farmadati restituisce al massimo 100 record per pagina. */
export const PAGE_SIZE = 100;

const POLICIES: Record<string, Policy> = {
  codice: { ttlMs: 30 * DAY, staleWhileRevalidate: true },
  nome: { ttlMs: 7 * DAY, staleWhileRevalidate: true },
  ean: { ttlMs: 30 * DAY, staleWhileRevalidate: true },
  immagine: { ttlMs: 90 * DAY, staleWhileRevalidate: true },
  bugiardino: { ttlMs: 30 * DAY, staleWhileRevalidate: true },
  rendibilita: { ttlMs: 7 * DAY, staleWhileRevalidate: true },
  // lotti invendibili: dato di sicurezza, niente dato vecchio se Farmadati risponde
  lotti: { ttlMs: 12 * HOUR, staleWhileRevalidate: false },
};

export interface Prodotto {
  codice: string;
  minsan: string;
  nome: string;
  /** Codice categoria FDI_0008 (l'app lo traduce con CategoriaMapper). */
  categoria: string;
}

/** Un record TR012: stato VF/RI/RD, data stato, motivo (TS031), inizio esaurimento scorte. */
export interface Provvedimento {
  stato: string;
  data: string;
  motivo: string;
  esaurimento: string;
}

/**
 * `lotto` è il primo record, per le versioni dell'app che leggono solo quello;
 * `provvedimenti` li riporta tutti (un codice può averne uno per stato).
 */
export type EsitoVendibilita =
  | { lotto: null; provvedimenti: [] }
  | { lotto: { stato: string; data: string }; provvedimenti: Provvedimento[] }
  | { errore: true };

export interface ServiceDeps {
  loader: CachedLoader;
  /** Chiamata reale a Farmadati (già limitata in concorrenza). */
  query: (dataset: Dataset, filterKey: string, value: string) => Promise<FdiRecord[] | null>;
  fetch: FetchFn;
  /** Verso il Worker di ingest R2 (service binding in produzione). */
  ingestFetch: FetchFn;
  password: string;
  docEndpoint: string;
  r2IngestEndpoint: string;
  r2ApiKey: string;
  bugiardinoBase: string;
  bugiardinoUpload: string;
  /** URL firmato del Worker che inoltra un documento Farmadati senza esporre l'accesskey. */
  signDocUrl: (tipo: string, nome: string) => Promise<string>;
}

export const cacheKey = (dataset: Dataset, filterKey: string, value: string) =>
  `${dataset}|${filterKey}|${value.trim().toUpperCase()}`;

export class FarmadatiService {
  constructor(private readonly deps: ServiceDeps) {}

  private async records(
    dataset: Dataset,
    filterKey: string,
    value: string,
    policy: Policy,
  ): Promise<FdiRecord[] | null> {
    const normalized = value.trim().toUpperCase(); // CONTIENE ignora maiuscole/minuscole
    const payload = await this.deps.loader.load(
      cacheKey(dataset, filterKey, normalized),
      policy,
      async () => {
        const found = await this.deps.query(dataset, filterKey, normalized);
        return found ? JSON.stringify(found) : null;
      },
    );
    return payload ? (JSON.parse(payload) as FdiRecord[]) : null;
  }

  async prodotti(q: string): Promise<Prodotto[]> {
    const query = q.trim();
    if (query.length < 3) return [];

    if (/^\d{10,}$/.test(query)) {
      // EAN -> codici ministeriali (TR016) -> anagrafica di ciascuno (TR001)
      const ean = (await this.records("TR016", "FDI_0002", query, POLICIES.ean)) ?? [];
      const codici = [...new Set(ean.map((r) => r.FDI_0001).filter(Boolean))];
      const dettagli = await Promise.all(
        codici.map(async (c) => (await this.records("TR001", "FDI_0001", c, POLICIES.codice))?.[0]),
      );
      return dettagli.filter((r): r is FdiRecord => !!r).map(toProdotto);
    }

    if (/^\d+$/.test(query)) {
      const found = await this.records("TR001", "FDI_0001", query, POLICIES.codice);
      return (found ?? []).map(toProdotto);
    }

    const daPrefisso = await this.cercaDaPrefisso(query);
    if (daPrefisso) return daPrefisso.map(toProdotto);
    const found = await this.records("TR001", "FDI_0004", query, POLICIES.nome);
    return (found ?? []).map(toProdotto);
  }

  /**
   * Se una ricerca più corta che è prefisso di questa è in cache con meno di
   * PAGE_SIZE risultati, la sua lista è completa: ogni nome che contiene
   * "TACHI" contiene anche "TACH". Basta filtrarla, senza chiamare Farmadati.
   */
  private async cercaDaPrefisso(query: string): Promise<FdiRecord[] | null> {
    const upper = query.toUpperCase();
    const prefissi: string[] = [];
    for (let len = upper.length - 1; len >= 3; len--) prefissi.push(upper.slice(0, len));
    if (prefissi.length === 0) return null;

    const keys = prefissi.map((p) => cacheKey("TR001", "FDI_0004", p));
    const cached = await this.deps.loader.peek(keys);
    for (const key of keys) {
      // dal prefisso più lungo: meno record da filtrare
      const entry = cached.get(key);
      if (!entry || this.deps.loader.now() - entry.fetchedAt >= POLICIES.nome.ttlMs) continue;
      if (entry.payload === null) return [];
      const records = JSON.parse(entry.payload) as FdiRecord[];
      if (records.length >= PAGE_SIZE) continue; // lista troncata: non affidabile
      this.deps.loader.stats.cache++;
      return records.filter((r) => (r.FDI_0004 ?? "").toUpperCase().includes(upper));
    }
    return null;
  }

  async vendibilita(codici: string[]): Promise<Record<string, EsitoVendibilita>> {
    const unici = [...new Set(codici.map((c) => c.trim()).filter(Boolean))];
    const esiti = await Promise.all(
      unici.map(async (codice): Promise<[string, EsitoVendibilita]> => {
        try {
          // il filtro Farmadati è CONTIENE: si tengono solo i record del codice esatto
          const lotti = (
            (await this.records("TR012", "FDI_T291", codice, POLICIES.lotti)) ?? []
          ).filter((r) => !r.FDI_T291 || r.FDI_T291 === codice);
          if (lotti.length === 0) return [codice, { lotto: null, provvedimenti: [] }];
          return [
            codice,
            {
              lotto: { stato: lotti[0].FDI_T292 ?? "", data: lotti[0].FDI_T293 ?? "" },
              provvedimenti: lotti.map((r) => ({
                stato: r.FDI_T292 ?? "",
                data: r.FDI_T293 ?? "",
                motivo: r.FDI_T294 ?? "",
                esaurimento: r.FDI_T298 ?? "",
              })),
            },
          ];
        } catch (e) {
          console.warn(`vendibilita ${codice}: ${e}`);
          return [codice, { errore: true }];
        }
      }),
    );
    return Object.fromEntries(esiti);
  }

  async rendibilita(codice: string): Promise<{ trovato: boolean; codice: string | null }> {
    const found = await this.records("TR015", "FDI_0001", codice, POLICIES.rendibilita);
    if (!found) return { trovato: false, codice: null };
    return { trovato: true, codice: found[0].FDI_0460 || null };
  }

  async immagine(codice: string): Promise<string | null> {
    // l'URL CDN su R2 non cambia: in cache si evitano sia TDZ sia un nuovo ingest
    return this.deps.loader.load(`r2|${codice.trim()}`, POLICIES.immagine, async () => {
      const found = await this.records("TDZ", "FDI_T218", codice, POLICIES.immagine);
      const file = found?.[0]?.FDI_T438;
      if (!found || !file) return null;

      const imageUrl =
        `${this.deps.docEndpoint}?accesskey=${this.deps.password}` +
        `&tipodoc=Z&nomefile=${encodeURIComponent(file)}`;
      // Se il file non c'è Farmadati risponde 200 con una pagina HTML, che
      // l'ingest salverebbe come immagine: senza un'immagine vera, nessuna immagine.
      const sorgente = await this.deps.fetch(imageUrl, {
        signal: AbortSignal.timeout(IMMAGINE_TIMEOUT_MS),
      });
      await sorgente.body?.cancel();
      if (!sorgente.ok || !sorgente.headers.get("content-type")?.startsWith("image/")) {
        return null;
      }

      const resp = await this.deps.ingestFetch(this.deps.r2IngestEndpoint, {
        method: "POST",
        headers: { "content-type": "application/json", "x-api-key": this.deps.r2ApiKey },
        body: JSON.stringify({ ean: found[0].FDI_T218 || codice, imageUrl }),
        signal: AbortSignal.timeout(IMMAGINE_TIMEOUT_MS),
      });
      const data = resp.ok ? await resp.json<{ ok?: boolean; origUrl?: string }>() : null;
      // se l'ingest fallisce non salviamo nulla: si riproverà
      if (!data?.ok || !data.origUrl) throw new Error(`ingest R2 fallito (${resp.status})`);
      return data.origUrl;
    });
  }

  async bugiardino(codice: string, tipo: string | null): Promise<string | null> {
    const minsan = codice.trim();
    if (!minsan) return null;
    const copiaDoublecore = `${this.deps.bugiardinoBase}/${minsan}.html`;
    if (await this.exists(copiaDoublecore)) return copiaDoublecore;

    const isFarmaco = tipo === "F";
    const found = await this.records(
      isFarmaco ? "TDF" : "TD1",
      "FDI_T218",
      minsan,
      POLICIES.bugiardino,
    );
    const raw = (found?.[0]?.[isFarmaco ? "FDI_T227" : "FDI_T477"] ?? "").trim();
    if (!raw) return null;

    const percorso = jsonPath(raw);
    const tipoDoc = isFarmaco ? "F" : "1";
    const sorgente =
      percorso ??
      `${this.deps.docEndpoint}?accesskey=${this.deps.password}&tipodoc=${tipoDoc}&nomefile=${raw}`;
    if (percorso && new URL(percorso, copiaDoublecore).host === new URL(copiaDoublecore).host) {
      return percorso;
    }

    if ((await this.uploadDoublecore(sorgente, minsan)) && (await this.exists(copiaDoublecore))) {
      return copiaDoublecore;
    }
    // l'URL Farmadati contiene l'accesskey: all'app va solo un link firmato del Worker
    return percorso ?? this.deps.signDocUrl(tipoDoc, raw);
  }

  private async exists(url: string): Promise<boolean> {
    try {
      const resp = await this.deps.fetch(url, { method: "HEAD", signal: AbortSignal.timeout(5000) });
      return resp.ok;
    } catch {
      return false;
    }
  }

  private async uploadDoublecore(url: string, minsan: string): Promise<boolean> {
    try {
      const resp = await this.deps.fetch(this.deps.bugiardinoUpload, {
        method: "POST",
        body: new URLSearchParams({ url, savefileas: minsan }),
        signal: AbortSignal.timeout(20_000),
      });
      if (!resp.ok) return false;
      const data = await resp.json<{ status?: string }>();
      const status = (data.status ?? "").toLowerCase();
      return status === "saved" || status === "already_exists";
    } catch (e) {
      console.warn(`upload bugiardino ${minsan}: ${e}`);
      return false;
    }
  }
}

function toProdotto(r: FdiRecord): Prodotto {
  const codice = r.FDI_0001 ?? "";
  return {
    codice,
    minsan: r.FDI_0002 || codice,
    nome: r.FDI_0004 ?? "",
    categoria: r.FDI_0008 ?? "",
  };
}

function jsonPath(raw: string): string | null {
  if (!raw.startsWith("{")) return null;
  try {
    const path = (JSON.parse(raw) as { path?: unknown }).path;
    return typeof path === "string" && path ? path : null;
  } catch {
    return null;
  }
}
