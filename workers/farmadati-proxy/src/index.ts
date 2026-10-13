import { CachedLoader, D1Store, type Store } from "./cache";
import { executeQuery, type Dataset, type FetchFn } from "./farmadati";
import { signDoc, verifyDoc, verifyFirebaseToken } from "./security";
import { FarmadatiService } from "./service";

export interface Env {
  DB: D1Database;
  FIREBASE_PROJECT_ID: string;
  FARMADATI_ENDPOINT: string;
  FARMADATI_DOC_ENDPOINT: string;
  FARMADATI_USERNAME: string;
  FARMADATI_PASSWORD: string;
  R2_INGEST_ENDPOINT: string;
  R2_API_KEY: string;
  BUGIARDINO_BASE: string;
  BUGIARDINO_UPLOAD: string;
  DOC_SIGNING_KEY: string;
}

/** Richieste contemporanee massime verso Farmadati per isolate. */
const MAX_FARMADATI_CONCORRENTI = 6;
const MAX_CODICI_VENDIBILITA = 50;
const DOC_LINK_VALIDITA_MS = 60 * 60 * 1000;

class Semaforo {
  private attivi = 0;
  private readonly coda: (() => void)[] = [];
  constructor(private readonly max: number) {}

  async run<T>(fn: () => Promise<T>): Promise<T> {
    if (this.attivi >= this.max) await new Promise<void>((r) => this.coda.push(r));
    this.attivi++;
    try {
      return await fn();
    } finally {
      this.attivi--;
      this.coda.shift()?.();
    }
  }
}

const semaforo = new Semaforo(MAX_FARMADATI_CONCORRENTI);

class HttpError extends Error {
  constructor(readonly status: number, message: string) {
    super(message);
  }
}

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json; charset=utf-8" },
  });

export interface Overrides {
  store?: Store;
  fetch?: FetchFn;
  verifyToken?: (token: string) => Promise<string>;
}

export function createHandler(overrides: Overrides = {}) {
  return async (request: Request, env: Env, ctx: ExecutionContext): Promise<Response> => {
    const url = new URL(request.url);
    // sempre chiamato senza "this": il fetch globale invocato come metodo di
    // un altro oggetto (this.deps.fetch) lancia "Illegal invocation"
    const fetchFn: FetchFn = (input, init) => (overrides.fetch ?? fetch)(input, init);
    try {
      if (request.method !== "GET") throw new HttpError(405, "metodo non consentito");
      if (url.pathname === "/v1/doc") return await inoltraDocumento(url, env, fetchFn);

      const header = request.headers.get("authorization") ?? "";
      const token = header.startsWith("Bearer ") ? header.slice(7) : "";
      if (!token) throw new HttpError(401, "token mancante");
      try {
        await (overrides.verifyToken ?? ((t) => verifyFirebaseToken(t, env.FIREBASE_PROJECT_ID)))(token);
      } catch {
        throw new HttpError(401, "token non valido");
      }

      const loader = new CachedLoader(overrides.store ?? new D1Store(env.DB), (p) => ctx.waitUntil(p));
      const service = new FarmadatiService({
        loader,
        query: (dataset: Dataset, filterKey: string, value: string) =>
          semaforo.run(() =>
            executeQuery(
              {
                endpoint: env.FARMADATI_ENDPOINT,
                username: env.FARMADATI_USERNAME,
                password: env.FARMADATI_PASSWORD,
              },
              dataset,
              filterKey,
              value,
              fetchFn,
            ),
          ),
        fetch: fetchFn,
        password: env.FARMADATI_PASSWORD,
        docEndpoint: env.FARMADATI_DOC_ENDPOINT,
        r2IngestEndpoint: env.R2_INGEST_ENDPOINT,
        r2ApiKey: env.R2_API_KEY,
        bugiardinoBase: env.BUGIARDINO_BASE,
        bugiardinoUpload: env.BUGIARDINO_UPLOAD,
        signDocUrl: async (tipo, nome) => {
          const exp = Date.now() + DOC_LINK_VALIDITA_MS;
          const sig = await signDoc(env.DOC_SIGNING_KEY, tipo, nome, exp);
          const params = new URLSearchParams({ tipo, nome, exp: String(exp), sig });
          return `${url.origin}/v1/doc?${params}`;
        },
      });

      const param = (name: string) => (url.searchParams.get(name) ?? "").trim();
      const richiesto = (name: string) => {
        const value = param(name);
        if (!value) throw new HttpError(400, `parametro mancante: ${name}`);
        return value;
      };

      let body: unknown;
      switch (url.pathname) {
        case "/v1/prodotti":
          body = { prodotti: await service.prodotti(richiesto("q")) };
          break;
        case "/v1/vendibilita": {
          const codici = richiesto("codici").split(",");
          if (codici.length > MAX_CODICI_VENDIBILITA) {
            throw new HttpError(400, `massimo ${MAX_CODICI_VENDIBILITA} codici`);
          }
          body = { esiti: await service.vendibilita(codici) };
          break;
        }
        case "/v1/rendibilita":
          body = await service.rendibilita(richiesto("codice"));
          break;
        case "/v1/immagine":
          // un ingest fallito diventa 502 (non null): l'app non lo mette in cache
          body = { url: await service.immagine(richiesto("codice")) };
          break;
        case "/v1/bugiardino":
          body = { url: await service.bugiardino(richiesto("codice"), param("tipo") || null) };
          break;
        default:
          throw new HttpError(404, "non trovato");
      }
      console.log(`${url.pathname} farmadati=${JSON.stringify(loader.stats)}`);
      return json(body);
    } catch (e) {
      if (e instanceof HttpError) return json({ errore: e.message }, e.status);
      console.error(`${url.pathname}: ${e}`);
      return json({ errore: "Farmadati non disponibile" }, 502);
    }
  };
}

/** Inoltra un documento Farmadati (bugiardino) senza esporre l'accesskey all'app. */
async function inoltraDocumento(url: URL, env: Env, fetchFn: FetchFn): Promise<Response> {
  const tipo = url.searchParams.get("tipo") ?? "";
  const nome = url.searchParams.get("nome") ?? "";
  const exp = Number(url.searchParams.get("exp"));
  const sig = url.searchParams.get("sig") ?? "";
  if (!(await verifyDoc(env.DOC_SIGNING_KEY, tipo, nome, exp, sig))) {
    throw new HttpError(403, "link non valido o scaduto");
  }
  const params = new URLSearchParams({ accesskey: env.FARMADATI_PASSWORD, tipodoc: tipo, nomefile: nome });
  const resp = await fetchFn(`${env.FARMADATI_DOC_ENDPOINT}?${params}`);
  return new Response(resp.body, {
    status: resp.status,
    headers: {
      "content-type": resp.headers.get("content-type") ?? "application/octet-stream",
      "cache-control": "private, max-age=3600",
    },
  });
}

export default { fetch: createHandler() } satisfies ExportedHandler<Env>;
