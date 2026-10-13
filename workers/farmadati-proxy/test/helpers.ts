import { MemoryStore } from "../src/cache";
import type { FdiRecord } from "../src/farmadati";
import { createHandler, type Env } from "../src/index";

export const PASSWORD = "segreto-farmadati";

export const env = {
  FIREBASE_PROJECT_ID: "test",
  FARMADATI_ENDPOINT: "http://farmadati.test/ws",
  FARMADATI_DOC_ENDPOINT: "https://doc.farmadati.test/GetDoc.aspx",
  FARMADATI_USERNAME: "utente",
  FARMADATI_PASSWORD: PASSWORD,
  R2_INGEST_ENDPOINT: "https://r2.test/ingest",
  R2_API_KEY: "chiave-r2",
  BUGIARDINO_BASE: "http://doublecore.test/pdf_html",
  BUGIARDINO_UPLOAD: "http://doublecore.test/uploader.php",
  DOC_SIGNING_KEY: "chiave-firma",
} as unknown as Env;

export function soap(records: FdiRecord[] | null): string {
  const inner = records
    ? '<?xml version="1.0" encoding="UTF-8"?>\r\n<TableResult>' +
      records
        .map(
          (r) =>
            "<Product>" +
            Object.entries(r)
              .map(([k, v]) => `<${k}>${v}</${k}>`)
              .join("") +
            "</Product>",
        )
        .join("") +
      "</TableResult>"
    : "EMPTY";
  const escaped = inner.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
  return (
    '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/"><s:Body>' +
    '<ExecuteQueryResponse xmlns="http://webservices.farmadati.it">' +
    '<ExecuteQueryResult xmlns:a="http://schemas.datacontract.org/2004/07/FDIWebServices">' +
    `<a:CodEsito>OK</a:CodEsito><a:OutputValue>${escaped}</a:OutputValue>` +
    "</ExecuteQueryResult></ExecuteQueryResponse></s:Body></s:Envelope>"
  );
}

/** Mondo finto: Farmadati SOAP, GetDoc, doublecore, ingest R2. */
export class FakeWorld {
  /** "DATASET|VALORE" -> record (assente = EMPTY) */
  readonly dati = new Map<string, FdiRecord[]>();
  readonly chiamateFarmadati: string[] = [];
  readonly altreChiamate: string[] = [];
  readonly doublecore = new Set<string>();
  uploadOk = true;
  farmadatiGiu = false;
  attive = 0;
  maxAttive = 0;
  ritardoMs = 0;

  readonly fetch = async (input: string, init?: RequestInit): Promise<Response> => {
    const url = String(input);
    if (url === env.FARMADATI_ENDPOINT) {
      const body = String(init?.body);
      const dataset = /<web:CodiceSetDati>(.*?)</.exec(body)![1];
      const valore = /<fdiw:Value>(.*?)</.exec(body)![1];
      const key = `${dataset}|${valore}`;
      this.chiamateFarmadati.push(key);
      this.attive++;
      this.maxAttive = Math.max(this.maxAttive, this.attive);
      try {
        await new Promise((r) => setTimeout(r, this.ritardoMs));
        if (this.farmadatiGiu) throw new Error("connessione rifiutata");
        return new Response(soap(this.dati.get(key) ?? null));
      } finally {
        this.attive--;
      }
    }

    this.altreChiamate.push(`${init?.method ?? "GET"} ${url}`);
    if (url.startsWith(env.BUGIARDINO_BASE)) {
      return new Response(null, { status: this.doublecore.has(url) ? 200 : 404 });
    }
    if (url === env.BUGIARDINO_UPLOAD) {
      const form = init?.body as URLSearchParams;
      if (!this.uploadOk) return Response.json({ status: "error" });
      this.doublecore.add(`${env.BUGIARDINO_BASE}/${form.get("savefileas")}.html`);
      return Response.json({ status: "saved" });
    }
    if (url === env.R2_INGEST_ENDPOINT) {
      const { ean } = JSON.parse(String(init?.body));
      return Response.json({ ok: true, origUrl: `https://cdn.test/${ean}.jpg` });
    }
    if (url.startsWith(env.FARMADATI_DOC_ENDPOINT)) {
      return new Response("<html>bugiardino</html>", { headers: { "content-type": "text/html" } });
    }
    return new Response(null, { status: 404 });
  };
}

export function setup() {
  const world = new FakeWorld();
  const store = new MemoryStore();
  const pending: Promise<unknown>[] = [];
  const handler = createHandler({
    store,
    // come il fetch globale del runtime Workers: invocato come metodo di un
    // altro oggetto lancia "Illegal invocation"
    fetch: function (this: unknown, input: string, init?: RequestInit) {
      if (this !== undefined && this !== globalThis) {
        throw new TypeError("Illegal invocation: function called with incorrect `this` reference");
      }
      return world.fetch(input, init);
    },
    verifyToken: async (t) => {
      if (t !== "token-valido") throw new Error("no");
      return "uid-1";
    },
  });
  const ctx = {
    waitUntil: (p: Promise<unknown>) => pending.push(p),
    passThroughOnException: () => {},
  } as unknown as ExecutionContext;

  async function get(path: string, token: string | null = "token-valido") {
    const headers: Record<string, string> = token ? { authorization: `Bearer ${token}` } : {};
    const resp = await handler(new Request(`https://proxy.test${path}`, { headers }), env, ctx);
    const text = await resp.text();
    return { status: resp.status, text, body: text.startsWith("{") ? JSON.parse(text) : null };
  }

  /** Attende gli aggiornamenti in background (ctx.waitUntil). */
  async function background() {
    await Promise.all(pending.splice(0));
  }

  return { world, store, get, background, handler, ctx };
}

export const tr001 = (codice: string, nome: string, categoria = "D"): FdiRecord => ({
  FDI_0001: codice,
  FDI_0004: nome,
  FDI_0008: categoria,
});
