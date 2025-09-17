function corsHeaders() {
  return {
    "access-control-allow-origin": "*",
    "access-control-allow-headers": "content-type, x-api-key",
    "access-control-allow-methods": "GET, POST, OPTIONS",
  };
}

function json(body, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "content-type": "application/json",
      ...corsHeaders(),
    },
  });
}

function text(body, status = 200) {
  return new Response(body, { status, headers: { ...corsHeaders() } });
}

function error(message, status = 400) {
  return json({ ok: false, error: message }, status);
}

async function sha1hex(arrayBuffer) {
  const digest = await crypto.subtle.digest("SHA-1", arrayBuffer);
  const bytes = new Uint8Array(digest);
  return [...bytes].map((b) => b.toString(16).padStart(2, "0")).join("");
}

async function handleOptions(request) {
  return new Response(null, { status: 204, headers: { ...corsHeaders() } });
}

async function ingest(request, env) {
  // Autenticazione molto semplice, opzionale
  const clientKey = request.headers.get("x-api-key");
  if (env.API_KEY && env.API_KEY !== "" && clientKey !== env.API_KEY) {
    return error("Unauthorized", 401);
  }

  let payload;
  try {
    payload = await request.json();
  } catch {
    return error("Invalid JSON body", 400);
  }

  const ean = String(payload.ean || "").trim();
  const imageUrl = String(payload.imageUrl || "").trim();
  if (!ean || !imageUrl) return error("Missing ean or imageUrl", 400);

  // Scarica l'immagine sorgente (Farmadati o altra)
  const upstream = await fetch(imageUrl, {
    headers: { "User-Agent": "PharmaBox/1.0" },
    cf: { cacheTtl: 0 },
  });
  if (!upstream.ok) return error(`Upstream fetch failed ${upstream.status}`, 502);

  const contentType = upstream.headers.get("content-type") || "image/jpeg";
  const buf = await upstream.arrayBuffer();
  const hash = await sha1hex(buf); // per dedup/versioning

  // Chiave deterministica con version hash per cache-busting
  const key = `products/${ean}/${hash}/original.jpg`;

  // Se esiste già, non riscrivere
  const head = await env.PROD_IMAGES.head(key);
  if (!head) {
    await env.PROD_IMAGES.put(key, buf, {
      httpMetadata: {
        contentType,
        cacheControl: "public, max-age=31536000, immutable",
      },
    });
  }

  const base = env.CDN_BASE_URL?.replace(/\/$/, "") || "";
  const origUrl = base ? `${base}/${key}` : key;
  return json({ ok: true, ean, hash, origUrl, existed: !!head });
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (request.method === "OPTIONS") return handleOptions(request);
    if (url.pathname === "/health") return text("ok", 200);
    if (url.pathname === "/exists" && request.method === "GET") {
      const ean = String(url.searchParams.get("ean") || "").trim();
      if (!ean) return error("Missing ean", 400);
      const list = await env.PROD_IMAGES.list({ prefix: `products/${ean}/`, limit: 1 });
      if (!list || !list.objects || list.objects.length === 0) {
        return json({ ok: true, exists: false });
      }
      const key = list.objects[0].key;
      const base = env.CDN_BASE_URL?.replace(/\/$/, "") || "";
      const origUrl = base ? `${base}/${key}` : key;
      return json({ ok: true, exists: true, key, origUrl });
    }
    if (url.pathname === "/ingest" && request.method === "POST") return ingest(request, env);
    return text("Not Found", 404);
  },
};
