import { XMLParser } from "fast-xml-parser";

export type Dataset = "TR001" | "TR012" | "TR015" | "TR016" | "TDZ" | "TDF" | "TD1";

/** Un record Farmadati: campo FDI_xxxx -> valore (sempre stringa, zeri iniziali inclusi). */
export type FdiRecord = Record<string, string>;

export interface FarmadatiConfig {
  endpoint: string;
  username: string;
  password: string;
}

export type FetchFn = (input: string, init?: RequestInit) => Promise<Response>;

const parser = new XMLParser({
  ignoreAttributes: true,
  removeNSPrefix: true,
  parseTagValue: false, // "012745182" deve restare una stringa
  trimValues: true,
  htmlEntities: true,
});

const xmlEscape = (s: string) =>
  s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");

export function buildEnvelope(
  cfg: FarmadatiConfig,
  dataset: Dataset,
  filterKey: string,
  value: string,
): string {
  return `<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:web="http://webservices.farmadati.it" xmlns:arr="http://schemas.microsoft.com/2003/10/Serialization/Arrays" xmlns:fdiw="http://schemas.datacontract.org/2004/07/FDIWebServices">
  <soapenv:Header/>
  <soapenv:Body>
    <web:ExecuteQuery>
      <web:Username>${xmlEscape(cfg.username)}</web:Username>
      <web:Password>${xmlEscape(cfg.password)}</web:Password>
      <web:CodiceSetDati>${dataset}</web:CodiceSetDati>
      <web:CampiDaEstrarre><arr:string>ALL</arr:string></web:CampiDaEstrarre>
      <web:Filtri>
        <fdiw:Filter>
          <fdiw:Key>${filterKey}</fdiw:Key>
          <fdiw:Operator>CONTIENE</fdiw:Operator>
          <fdiw:Value>${xmlEscape(value)}</fdiw:Value>
        </fdiw:Filter>
      </web:Filtri>
      <web:PageN>1</web:PageN>
      <web:PagingN>100</web:PagingN>
    </web:ExecuteQuery>
  </soapenv:Body>
</soapenv:Envelope>`;
}

/** Esegue ExecuteQuery. Restituisce null se Farmadati risponde "EMPTY". */
export async function executeQuery(
  cfg: FarmadatiConfig,
  dataset: Dataset,
  filterKey: string,
  value: string,
  fetchFn: FetchFn = fetch,
): Promise<FdiRecord[] | null> {
  const resp = await fetchFn(cfg.endpoint, {
    method: "POST",
    headers: {
      "Content-Type": "text/xml; charset=utf-8",
      Accept: "application/xml",
      SOAPAction:
        "http://webservices.farmadati.it/FarmadatiItaliaWebServicesM1/ExecuteQuery",
    },
    body: buildEnvelope(cfg, dataset, filterKey, value),
    signal: AbortSignal.timeout(15_000),
  });
  if (!resp.ok) throw new Error(`Farmadati HTTP ${resp.status}`);
  return parseResponse(await resp.text());
}

export function parseResponse(soap: string): FdiRecord[] | null {
  const result = parser.parse(soap)?.Envelope?.Body?.ExecuteQueryResponse
    ?.ExecuteQueryResult;
  if (!result) throw new Error("Risposta Farmadati non riconosciuta");
  if (result.CodEsito !== "OK") {
    throw new Error(`Farmadati: ${result.CodEsito} ${result.DescEsito ?? ""}`);
  }

  const output = String(result.OutputValue ?? "").trim();
  if (!output || output === "EMPTY") return null;

  const products = findProducts(parser.parse(output));
  return products.length > 0 ? products : null;
}

function findProducts(node: unknown): FdiRecord[] {
  if (node === null || typeof node !== "object") return [];
  for (const [key, child] of Object.entries(node)) {
    if (key === "Product") {
      return (Array.isArray(child) ? child : [child]).map(toRecord);
    }
    const found = findProducts(child);
    if (found.length > 0) return found;
  }
  return [];
}

function toRecord(product: unknown): FdiRecord {
  const record: FdiRecord = {};
  if (product && typeof product === "object") {
    for (const [key, value] of Object.entries(product)) {
      record[key] = typeof value === "string" ? value : String(value ?? "");
    }
  }
  return record;
}
