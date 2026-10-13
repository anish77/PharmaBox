export interface Entry {
  /** JSON; null = risposta vuota (cache negativa). */
  payload: string | null;
  fetchedAt: number;
}

export interface Store {
  getMany(keys: string[]): Promise<Map<string, Entry>>;
  put(key: string, payload: string | null, fetchedAt: number): Promise<void>;
}

export class D1Store implements Store {
  constructor(private readonly db: D1Database) {}

  async getMany(keys: string[]): Promise<Map<string, Entry>> {
    const found = new Map<string, Entry>();
    if (keys.length === 0) return found;
    const placeholders = keys.map(() => "?").join(",");
    const { results } = await this.db
      .prepare(
        `SELECT key, payload, fetched_at FROM cache WHERE key IN (${placeholders})`,
      )
      .bind(...keys)
      .all<{ key: string; payload: string | null; fetched_at: number }>();
    for (const row of results) {
      found.set(row.key, { payload: row.payload, fetchedAt: row.fetched_at });
    }
    return found;
  }

  async put(key: string, payload: string | null, fetchedAt: number) {
    await this.db
      .prepare(
        "INSERT INTO cache (key, payload, fetched_at) VALUES (?, ?, ?) " +
          "ON CONFLICT(key) DO UPDATE SET payload = excluded.payload, fetched_at = excluded.fetched_at",
      )
      .bind(key, payload, fetchedAt)
      .run();
  }
}

export class MemoryStore implements Store {
  readonly entries = new Map<string, Entry>();

  async getMany(keys: string[]) {
    const found = new Map<string, Entry>();
    for (const key of keys) {
      const entry = this.entries.get(key);
      if (entry) found.set(key, entry);
    }
    return found;
  }

  async put(key: string, payload: string | null, fetchedAt: number) {
    this.entries.set(key, { payload, fetchedAt });
  }
}

export interface Policy {
  ttlMs: number;
  /**
   * Se scaduto: restituisce subito il dato vecchio e lo aggiorna in background.
   * Falso per i dati di sicurezza (lotti invendibili): si aspetta il dato nuovo.
   */
  staleWhileRevalidate: boolean;
}

export interface CacheStats {
  rete: number;
  cache: number;
  scaduti: number;
}

/** Richieste identiche in corso nello stesso isolate condividono la stessa chiamata. */
const inFlight = new Map<string, Promise<string | null>>();

export class CachedLoader {
  readonly stats: CacheStats = { rete: 0, cache: 0, scaduti: 0 };

  constructor(
    private readonly store: Store,
    private readonly waitUntil: (p: Promise<unknown>) => void,
    readonly now: () => number = Date.now,
  ) {}

  async peek(keys: string[]) {
    return this.store.getMany(keys);
  }

  async load(
    key: string,
    policy: Policy,
    fetcher: () => Promise<string | null>,
  ): Promise<string | null> {
    const cached = (await this.store.getMany([key])).get(key);
    if (cached && this.now() - cached.fetchedAt < policy.ttlMs) {
      this.stats.cache++;
      return cached.payload;
    }

    if (cached && policy.staleWhileRevalidate) {
      this.stats.scaduti++;
      this.waitUntil(
        this.refresh(key, fetcher).catch((e) =>
          console.warn(`aggiornamento in background fallito ${key}: ${e}`),
        ),
      );
      return cached.payload;
    }

    try {
      return await this.refresh(key, fetcher);
    } catch (e) {
      if (!cached) throw e;
      // meglio un dato scaduto che nessun dato
      this.stats.scaduti++;
      console.warn(`Farmadati non raggiungibile, uso la cache scaduta ${key}: ${e}`);
      return cached.payload;
    }
  }

  private refresh(key: string, fetcher: () => Promise<string | null>) {
    let pending = inFlight.get(key);
    if (!pending) {
      this.stats.rete++;
      pending = (async () => {
        const payload = await fetcher();
        await this.store.put(key, payload, this.now());
        return payload;
      })().finally(() => inFlight.delete(key));
      inFlight.set(key, pending);
    }
    return pending;
  }
}
