import { readFileSync } from "node:fs";
import { afterEach, describe, expect, it, vi } from "vitest";
import { parseResponse } from "../src/farmadati";
import { PASSWORD, setup, tr001 } from "./helpers";

const HOUR = 60 * 60 * 1000;
const DAY = 24 * HOUR;

afterEach(() => vi.useRealTimers());

describe("parsing Farmadati", () => {
  it("legge una risposta reale TR001", () => {
    const xml = readFileSync(new URL("./fixtures/tr001_034329110.xml", import.meta.url), "utf8");
    const [record] = parseResponse(xml)!;
    expect(record.FDI_0001).toBe("034329110");
    expect(record.FDI_0004).toBe("TACHIPIRINA FLASHTAB*12CPR 125");
    expect(record.FDI_0008).toBe("E");
  });

  it("EMPTY diventa null, un esito KO è un errore", () => {
    const empty = '<s:Envelope xmlns:s="x"><s:Body><ExecuteQueryResponse><ExecuteQueryResult><CodEsito>OK</CodEsito><OutputValue>EMPTY</OutputValue></ExecuteQueryResult></ExecuteQueryResponse></s:Body></s:Envelope>';
    expect(parseResponse(empty)).toBeNull();
    expect(() => parseResponse(empty.replace(">OK<", ">KO<"))).toThrow(/KO/);
  });
});

describe("autenticazione", () => {
  it("senza token o con token non valido risponde 401", async () => {
    const { get, world } = setup();
    expect((await get("/v1/prodotti?q=012745182", null)).status).toBe(401);
    expect((await get("/v1/prodotti?q=012745182", "falso")).status).toBe(401);
    expect(world.chiamateFarmadati).toEqual([]);
  });
});

describe("prodotti", () => {
  it("ricerca per codice: la seconda richiesta non va a Farmadati", async () => {
    const { get, world } = setup();
    world.dati.set("TR001|012745182", [tr001("012745182", "TACHIPIRINA*16CPR 1000MG")]);

    const primo = await get("/v1/prodotti?q=012745182");
    const secondo = await get("/v1/prodotti?q=012745182");

    expect(primo.body.prodotti).toEqual([
      { codice: "012745182", minsan: "012745182", nome: "TACHIPIRINA*16CPR 1000MG", categoria: "D" },
    ]);
    expect(secondo.body).toEqual(primo.body);
    expect(world.chiamateFarmadati).toEqual(["TR001|012745182"]);
  });

  it("maiuscole e minuscole condividono la stessa voce di cache", async () => {
    const { get, world } = setup();
    world.dati.set("TR001|TACHIPIRINA", [tr001("012745182", "TACHIPIRINA*16CPR 1000MG")]);

    await get("/v1/prodotti?q=tachipirina");
    const maiuscolo = await get("/v1/prodotti?q=TACHIPIRINA");

    expect(maiuscolo.body.prodotti).toHaveLength(1);
    expect(world.chiamateFarmadati).toEqual(["TR001|TACHIPIRINA"]);
  });

  it("EAN: TR016 e poi TR001 per ogni codice, tutto in cache", async () => {
    const { get, world } = setup();
    world.dati.set("TR016|8012345678901", [{ FDI_0001: "012745182" }, { FDI_0001: "012745170" }]);
    world.dati.set("TR001|012745182", [tr001("012745182", "TACHIPIRINA*16CPR")]);
    world.dati.set("TR001|012745170", [tr001("012745170", "TACHIPIRINA*8CPR")]);

    const r = await get("/v1/prodotti?q=8012345678901");
    await get("/v1/prodotti?q=8012345678901");
    await get("/v1/prodotti?q=012745170");

    expect(r.body.prodotti.map((p: { nome: string }) => p.nome)).toEqual([
      "TACHIPIRINA*16CPR",
      "TACHIPIRINA*8CPR",
    ]);
    expect(world.chiamateFarmadati).toHaveLength(3);
  });

  it("ricerca per nome: riusa un prefisso completo filtrandolo", async () => {
    const { get, world } = setup();
    world.dati.set("TR001|TACH", [
      tr001("1", "TACHIPIRINA 500"),
      tr001("2", "TACHIFLUDEC"),
      tr001("3", "TACHIPIRINA 1000"),
    ]);

    await get("/v1/prodotti?q=TACH");
    const tachi = await get("/v1/prodotti?q=tachip");

    expect(tachi.body.prodotti.map((p: { codice: string }) => p.codice)).toEqual(["1", "3"]);
    expect(world.chiamateFarmadati).toEqual(["TR001|TACH"]);
  });

  it("un prefisso con 100 risultati (lista troncata) non viene riusato", async () => {
    const { get, world } = setup();
    world.dati.set(
      "TR001|TACH",
      Array.from({ length: 100 }, (_, i) => tr001(String(i), `TACH ${i}`)),
    );

    await get("/v1/prodotti?q=TACH");
    await get("/v1/prodotti?q=TACHI");

    expect(world.chiamateFarmadati).toEqual(["TR001|TACH", "TR001|TACHI"]);
  });

  it("anagrafica scaduta: risponde subito col dato vecchio e aggiorna in background", async () => {
    vi.useFakeTimers({ toFake: ["Date"] });
    vi.setSystemTime(new Date("2026-10-13T09:00:00Z"));
    const { get, world, background } = setup();
    world.dati.set("TR001|012745182", [tr001("012745182", "NOME VECCHIO")]);
    await get("/v1/prodotti?q=012745182");

    world.dati.set("TR001|012745182", [tr001("012745182", "NOME NUOVO")]);
    vi.setSystemTime(new Date(Date.now() + 31 * DAY));
    const scaduto = await get("/v1/prodotti?q=012745182");
    expect(scaduto.body.prodotti[0].nome).toBe("NOME VECCHIO");

    await background();
    const aggiornato = await get("/v1/prodotti?q=012745182");
    expect(aggiornato.body.prodotti[0].nome).toBe("NOME NUOVO");
    expect(world.chiamateFarmadati).toHaveLength(2);
  });
});

describe("vendibilità", () => {
  it("più codici in una richiesta, risposte vuote in cache", async () => {
    const { get, world } = setup();
    world.dati.set("TR012|034329110", [{ FDI_T292: "VF", FDI_T293: "2020-01-01" }]);

    const r = await get("/v1/vendibilita?codici=034329110,012745182,012745182");
    await get("/v1/vendibilita?codici=012745182,034329110");

    expect(r.body.esiti).toEqual({
      "034329110": { lotto: { stato: "VF", data: "2020-01-01" } },
      "012745182": { lotto: null },
    });
    expect(world.chiamateFarmadati.sort()).toEqual(["TR012|012745182", "TR012|034329110"]);
  });

  it("scade dopo 12 ore e si aspetta il dato nuovo (niente dato vecchio)", async () => {
    vi.useFakeTimers({ toFake: ["Date"] });
    vi.setSystemTime(new Date("2026-10-13T09:00:00Z"));
    const { get, world } = setup();
    await get("/v1/vendibilita?codici=012745182");

    world.dati.set("TR012|012745182", [{ FDI_T292: "RI", FDI_T293: "2026-10-13" }]);
    vi.setSystemTime(new Date(Date.now() + 13 * HOUR));
    const r = await get("/v1/vendibilita?codici=012745182");

    expect(r.body.esiti["012745182"]).toEqual({ lotto: { stato: "RI", data: "2026-10-13" } });
    expect(world.chiamateFarmadati).toHaveLength(2);
  });

  it("se Farmadati è giù usa il dato scaduto, senza cache segnala l'errore", async () => {
    vi.useFakeTimers({ toFake: ["Date"] });
    vi.setSystemTime(new Date("2026-10-13T09:00:00Z"));
    const { get, world } = setup();
    world.dati.set("TR012|012745182", [{ FDI_T292: "VF", FDI_T293: "2020-01-01" }]);
    await get("/v1/vendibilita?codici=012745182");

    vi.setSystemTime(new Date(Date.now() + 13 * HOUR));
    world.farmadatiGiu = true;
    const r = await get("/v1/vendibilita?codici=012745182,099999999");

    expect(r.body.esiti["012745182"]).toEqual({ lotto: { stato: "VF", data: "2020-01-01" } });
    expect(r.body.esiti["099999999"]).toEqual({ errore: true });
  });

  it("al massimo 6 chiamate contemporanee a Farmadati", async () => {
    const { get, world } = setup();
    world.ritardoMs = 20;
    const codici = Array.from({ length: 30 }, (_, i) => String(100000000 + i));

    await get(`/v1/vendibilita?codici=${codici.join(",")}`);

    expect(world.chiamateFarmadati).toHaveLength(30);
    expect(world.maxAttive).toBeLessThanOrEqual(6);
  });

  it("richieste contemporanee per lo stesso codice: una sola chiamata", async () => {
    const { get, world } = setup();
    world.ritardoMs = 20;

    await Promise.all(Array.from({ length: 10 }, () => get("/v1/vendibilita?codici=012745182")));

    expect(world.chiamateFarmadati).toEqual(["TR012|012745182"]);
  });

  it("rifiuta più di 50 codici", async () => {
    const { get } = setup();
    const codici = Array.from({ length: 51 }, (_, i) => String(i)).join(",");
    expect((await get(`/v1/vendibilita?codici=${codici}`)).status).toBe(400);
  });
});

describe("rendibilità e immagine", () => {
  it("rendibilità: codice FDI_0460, assente se Farmadati non ha dati", async () => {
    const { get, world } = setup();
    world.dati.set("TR015|012745182", [{ FDI_0460: "J" }]);

    expect((await get("/v1/rendibilita?codice=012745182")).body).toEqual({ trovato: true, codice: "J" });
    expect((await get("/v1/rendibilita?codice=099999999")).body).toEqual({ trovato: false, codice: null });
  });

  it("immagine: un solo ingest su R2, poi URL dalla cache", async () => {
    const { get, world } = setup();
    world.dati.set("TDZ|012745182", [{ FDI_T218: "012745182", FDI_T438: "img 1.jpg" }]);

    const primo = await get("/v1/immagine?codice=012745182");
    const secondo = await get("/v1/immagine?codice=012745182");

    expect(primo.body).toEqual({ url: "https://cdn.test/012745182.jpg" });
    expect(secondo.body).toEqual(primo.body);
    expect(world.chiamateFarmadati).toEqual(["TDZ|012745182"]);
    expect(world.altreChiamate.filter((c) => c.includes("r2.test"))).toHaveLength(1);
  });

  it("immagine assente in TDZ: url null, anche questo in cache", async () => {
    const { get, world } = setup();
    expect((await get("/v1/immagine?codice=012745182")).body).toEqual({ url: null });
    expect((await get("/v1/immagine?codice=012745182")).body).toEqual({ url: null });
    expect(world.chiamateFarmadati).toEqual(["TDZ|012745182"]);
  });
});

describe("bugiardino", () => {
  it("se è già su doublecore non chiama Farmadati", async () => {
    const { get, world } = setup();
    world.doublecore.add("http://doublecore.test/pdf_html/012745182.html");

    const r = await get("/v1/bugiardino?codice=012745182&tipo=F");

    expect(r.body).toEqual({ url: "http://doublecore.test/pdf_html/012745182.html" });
    expect(world.chiamateFarmadati).toEqual([]);
  });

  it("altrimenti lo carica su doublecore e restituisce quella copia", async () => {
    const { get, world } = setup();
    world.dati.set("TDF|012745182", [{ FDI_T218: "012745182", FDI_T227: "doc123.htm" }]);

    const r = await get("/v1/bugiardino?codice=012745182&tipo=F");

    expect(r.body).toEqual({ url: "http://doublecore.test/pdf_html/012745182.html" });
    expect(world.chiamateFarmadati).toEqual(["TDF|012745182"]);
  });

  it("se l'upload fallisce restituisce un link firmato, senza accesskey", async () => {
    const { get, world } = setup();
    world.uploadOk = false;
    world.dati.set("TD1|900000001", [{ FDI_T218: "900000001", FDI_T477: "para.htm" }]);

    const r = await get("/v1/bugiardino?codice=900000001&tipo=P");
    const link = new URL(r.body.url);

    expect(link.pathname).toBe("/v1/doc");
    expect(r.text).not.toContain(PASSWORD);

    const doc = await get(`${link.pathname}${link.search}`, null);
    expect(doc.status).toBe(200);
    expect(doc.text).toContain("bugiardino");
    const richiesta = world.altreChiamate.find((c) => c.includes("doc.farmadati.test"))!;
    expect(richiesta).toContain("tipodoc=1");
    expect(richiesta).toContain("nomefile=para.htm");

    link.searchParams.set("nome", "altro.htm");
    expect((await get(`${link.pathname}${link.search}`, null)).status).toBe(403);
  });

  it("il link firmato scade dopo un'ora", async () => {
    vi.useFakeTimers({ toFake: ["Date"] });
    vi.setSystemTime(new Date("2026-10-13T09:00:00Z"));
    const { get, world } = setup();
    world.uploadOk = false;
    world.dati.set("TDF|012745182", [{ FDI_T218: "012745182", FDI_T227: "doc.htm" }]);
    const link = new URL((await get("/v1/bugiardino?codice=012745182&tipo=F")).body.url);

    vi.setSystemTime(new Date(Date.now() + 2 * HOUR));
    expect((await get(`${link.pathname}${link.search}`, null)).status).toBe(403);
  });
});

it("nessuna risposta contiene la password Farmadati", async () => {
  const { get, world } = setup();
  world.dati.set("TR001|012745182", [tr001("012745182", "X")]);
  for (const path of [
    "/v1/prodotti?q=012745182",
    "/v1/vendibilita?codici=012745182",
    "/v1/rendibilita?codice=012745182",
    "/v1/immagine?codice=012745182",
  ]) {
    expect((await get(path)).text).not.toContain(PASSWORD);
  }
});
