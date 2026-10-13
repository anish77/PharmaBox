import { createRemoteJWKSet, jwtVerify } from "jose";

const firebaseKeys = createRemoteJWKSet(
  new URL(
    "https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com",
  ),
);

/** Verifica un ID token Firebase Auth e restituisce l'uid dell'utente. */
export async function verifyFirebaseToken(token: string, projectId: string): Promise<string> {
  const { payload } = await jwtVerify(token, firebaseKeys, {
    issuer: `https://securetoken.google.com/${projectId}`,
    audience: projectId,
    algorithms: ["RS256"],
  });
  if (!payload.sub) throw new Error("token senza utente");
  return payload.sub;
}

const encoder = new TextEncoder();

async function hmacKey(secret: string) {
  return crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign", "verify"],
  );
}

const toBase64Url = (bytes: ArrayBuffer) =>
  btoa(String.fromCharCode(...new Uint8Array(bytes)))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");

const fromBase64Url = (s: string) =>
  Uint8Array.from(atob(s.replace(/-/g, "+").replace(/_/g, "/")), (c) => c.charCodeAt(0));

/** Firma (tipo, nome, scadenza) per il link /v1/doc usato dalla WebView. */
export async function signDoc(secret: string, tipo: string, nome: string, exp: number) {
  const sig = await crypto.subtle.sign(
    "HMAC",
    await hmacKey(secret),
    encoder.encode(`${tipo}|${nome}|${exp}`),
  );
  return toBase64Url(sig);
}

export async function verifyDoc(
  secret: string,
  tipo: string,
  nome: string,
  exp: number,
  sig: string,
  now = Date.now(),
): Promise<boolean> {
  if (!Number.isFinite(exp) || exp < now) return false;
  try {
    return await crypto.subtle.verify(
      "HMAC",
      await hmacKey(secret),
      fromBase64Url(sig),
      encoder.encode(`${tipo}|${nome}|${exp}`),
    );
  } catch {
    return false;
  }
}
