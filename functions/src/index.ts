import type { Request, Response } from "express";
import { onRequest } from "firebase-functions/v2/https";
import {
    defineSecret,
    defineString,
} from "firebase-functions/params";
import * as logger from "firebase-functions/logger";

/* ------------------------------------------------------------------ */
/*  Shared configuration                                               */
/* ------------------------------------------------------------------ */
const defaultRegion = "europe-west1";

/* ------------------------------------------------------------------ */
/*  PayPal configuration                                               */
/* ------------------------------------------------------------------ */
const paypalClientId = defineSecret("PAYPAL_CLIENT_ID");
const paypalSecret = defineSecret("PAYPAL_SECRET_KEY");
const paypalMode = defineString("PAYPAL_MODE", { default: "sandbox" });
const paypalReturnUrl = defineString("PAYPAL_RETURN_URL", {
    default: "https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/paypalReturn",
});
const paypalCancelUrl = defineString("PAYPAL_CANCEL_URL", {
    default: "https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/paypalCancel",
});
const paypalSuccessRedirect = defineString("PAYPAL_SUCCESS_REDIRECT", {
    default: "pharmabox://payment/paypal",
});
const paypalCancelRedirect = defineString("PAYPAL_CANCEL_REDIRECT", {
    default: "pharmabox://payment/paypal",
});

/* ------------------------------------------------------------------ */
/*  Utility helpers                                                    */
/* ------------------------------------------------------------------ */
const withCors = (res: Response) => {
    res.set("Access-Control-Allow-Origin", "*");
    res.set(
        "Access-Control-Allow-Headers",
        "Content-Type, Authorization, X-Requested-With",
    );
    res.set("Access-Control-Allow-Methods", "GET,POST,OPTIONS");
};

const parseBody = <T>(req: Request): T => {
    if (typeof req.body === "string") {
        try {
            return JSON.parse(req.body) as T;
        } catch (error) {
            logger.warn("Failed to parse JSON body", error);
            return {} as T;
        }
    }
    return (req.body ?? {}) as T;
};

const baseUrlFor = (mode: string) =>
    mode.toLowerCase() === "live"
        ? "https://api-m.paypal.com"
        : "https://api-m.sandbox.paypal.com";

const buildRedirectUrl = (
    base: string | undefined,
    params: Record<string, string | undefined>,
) => {
    const trimmed = (base ?? "").trim();
    if (!trimmed) return "";

    try {
        const url = new URL(trimmed);
        Object.entries(params).forEach(([key, value]) => {
            if (value !== undefined) url.searchParams.set(key, value);
        });
        return url.toString();
    } catch {
        const hasQuery = trimmed.includes("?");
        const separator = hasQuery ? "&" : "?";
        const filteredEntries = Object.entries(params).filter(
            (entry): entry is [string, string] => entry[1] !== undefined,
        );
        const query = new URLSearchParams(filteredEntries);
        return `${trimmed}${separator}${query.toString()}`;
    }
};

const renderResultPage = (title: string, message: string, redirectUrl: string) => {
    const refreshSeconds = redirectUrl ? 3 : 0;
    return `<!doctype html>
<html lang="it">
  <head>
    <meta charset="utf-8" />
    <title>${title}</title>
    ${redirectUrl ? `<meta http-equiv="refresh" content="${refreshSeconds};url=${redirectUrl}" />` : ""}
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <style>
      body {
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
        background-color: #f5f7fa;
        color: #2b2d66;
        display: flex;
        align-items: center;
        justify-content: center;
        padding: 24px;
        min-height: 100vh;
      }
      .card {
        background: #ffffff;
        border-radius: 16px;
        padding: 32px;
        max-width: 420px;
        box-shadow: 0 16px 48px rgba(45, 57, 91, 0.12);
        text-align: center;
      }
      h1 { font-size: 22px; margin-bottom: 16px; }
      p { font-size: 16px; line-height: 1.5; margin-bottom: 24px; }
      a {
        display: inline-block;
        margin-top: 8px;
        color: #5d5fef;
        text-decoration: none;
        font-weight: 600;
      }
      a:hover { text-decoration: underline; }
    </style>
  </head>
  <body>
    <div class="card">
      <h1>${title}</h1>
      <p>${message}</p>
      ${redirectUrl
            ? `<a href="${redirectUrl}">Torna all'app</a>`
            : '<a href="https://pharmabox.app">Visita PharmaBox</a>'
        }
    </div>
  </body>
</html>`;
};

const getAccessToken = async (baseUrl: string, clientId: string, secret: string) => {
    const auth = Buffer.from(`${clientId}:${secret}`, "utf8").toString("base64");
    const response = await fetch(`${baseUrl}/v1/oauth2/token`, {
        method: "POST",
        headers: {
            Authorization: `Basic ${auth}`,
            "Content-Type": "application/x-www-form-urlencoded",
        },
        body: "grant_type=client_credentials",
    });

    if (!response.ok) {
        const detail = await response.text();
        logger.error("PayPal token error", detail);
        throw new Error("PAYPAL_TOKEN_FAILED");
    }

    const data = (await response.json()) as { access_token: string };
    return data.access_token;
};

const captureOrder = async (baseUrl: string, orderId: string, accessToken: string) => {
    const response = await fetch(`${baseUrl}/v2/checkout/orders/${orderId}/capture`, {
        method: "POST",
        headers: {
            Authorization: `Bearer ${accessToken}`,
            "Content-Type": "application/json",
        },
    });

    const body = await response.json().catch(() => ({}));
    return { ok: response.ok, body };
};

/* ------------------------------------------------------------------ */
/*  PayPal Functions                                                  */
/* ------------------------------------------------------------------ */
export const createPaypalOrder = onRequest(
    {
        region: defaultRegion,
        secrets: [paypalClientId, paypalSecret],
    },
    async (req, res) => {
        withCors(res);

        if (req.method === "OPTIONS") {
            res.status(204).send("");
            return;
        }
        if (req.method !== "POST") {
            res.status(405).json({ error: "method-not-allowed" });
            return;
        }

        const body = parseBody<{
            amount?: string | number;
            currency?: string;
            returnUrl?: string;
            cancelUrl?: string;
            redirect?: string;
            cancelRedirect?: string;
            description?: string;
        }>(req);

        const amountValue =
            typeof body.amount === "number"
                ? body.amount.toFixed(2)
                : (body.amount ?? "").toString().trim();
        if (!amountValue) {
            res.status(400).json({ error: "missing-amount" });
            return;
        }

        const currency =
            (body.currency ?? "EUR").toString().trim().toUpperCase() || "EUR";
        const successRedirect =
            (body.redirect ?? "").toString().trim() ||
            paypalSuccessRedirect.value();
        const cancelRedirect =
            (body.cancelRedirect ?? "").toString().trim() ||
            paypalCancelRedirect.value();

        const returnUrl = (
            body.returnUrl ??
            buildRedirectUrl(paypalReturnUrl.value(), { redirect: successRedirect })
        ).toString();

        const cancelUrl = (
            body.cancelUrl ??
            buildRedirectUrl(paypalCancelUrl.value(), { redirect: cancelRedirect })
        ).toString();

        try {
            const baseUrl = baseUrlFor(paypalMode.value());
            const accessToken = await getAccessToken(
                baseUrl,
                paypalClientId.value(),
                paypalSecret.value(),
            );

            const orderPayload = {
                intent: "CAPTURE",
                purchase_units: [
                    {
                        amount: {
                            currency_code: currency,
                            value: amountValue,
                        },
                        description: body.description,
                    },
                ],
                application_context: {
                    return_url: returnUrl,
                    cancel_url: cancelUrl,
                    user_action: "PAY_NOW",
                },
            };

            const response = await fetch(`${baseUrl}/v2/checkout/orders`, {
                method: "POST",
                headers: {
                    Authorization: `Bearer ${accessToken}`,
                    "Content-Type": "application/json",
                },
                body: JSON.stringify(orderPayload),
            });

            const orderBody = (await response.json()) as {
                id?: string;
                links?: Array<{ rel?: string; href?: string }>;
            };

            if (!response.ok) {
                logger.error("PayPal create order failed", orderBody);
                res.status(502).json({ error: "paypal-create-failed", details: orderBody });
                return;
            }

            const approvalUrl = (orderBody.links ?? []).find(
                (link) => link.rel === "approve",
            )?.href;
            if (!approvalUrl) {
                logger.error("Missing approval URL", orderBody);
                res.status(502).json({ error: "approval-link-missing", details: orderBody });
                return;
            }

            res.status(200).json({
                orderId: orderBody.id,
                approvalUrl,
                returnUrl,
                cancelUrl,
            });
        } catch (error) {
            logger.error("createPaypalOrder error", error);
            res.status(500).json({
                error: "internal",
                message: "Unable to create PayPal order right now.",
            });
        }
    },
);

export const capturePaypalOrder = onRequest(
    {
        region: defaultRegion,
        secrets: [paypalClientId, paypalSecret],
    },
    async (req, res) => {
        withCors(res);

        if (req.method === "OPTIONS") {
            res.status(204).send("");
            return;
        }
        if (req.method !== "POST") {
            res.status(405).json({ error: "method-not-allowed" });
            return;
        }

        const body = parseBody<{ orderId?: string }>(req);
        const orderId = body.orderId?.toString().trim();
        if (!orderId) {
            res.status(400).json({ error: "missing-order-id" });
            return;
        }

        try {
            const baseUrl = baseUrlFor(paypalMode.value());
            const accessToken = await getAccessToken(
                baseUrl,
                paypalClientId.value(),
                paypalSecret.value(),
            );

            const capture = await captureOrder(baseUrl, orderId, accessToken);
            if (!capture.ok) {
                logger.error("PayPal capture failed", capture.body);
                res.status(502).json({ error: "paypal-capture-failed", details: capture.body });
                return;
            }

            res.status(200).json(capture.body);
        } catch (error) {
            logger.error("capturePaypalOrder error", error);
            res.status(500).json({
                error: "internal",
                message: "Unable to capture PayPal order right now.",
            });
        }
    },
);

export const paypalReturn = onRequest(
    {
        region: defaultRegion,
        secrets: [paypalClientId, paypalSecret],
    },
    async (req, res) => {
        withCors(res);

        if (req.method === "OPTIONS") {
            res.status(204).send("");
            return;
        }
        if (req.method !== "GET") {
            res.status(405).send("Method not allowed");
            return;
        }

        const orderId = req.query.token?.toString();
        if (!orderId) {
            res
                .status(400)
                .send(
                    renderResultPage(
                        "Pagamento PayPal",
                        "Token mancante nella risposta di PayPal.",
                        "",
                    ),
                );
            return;
        }

        const redirectTarget =
            (req.query.redirect as string | undefined)?.trim() ||
            paypalSuccessRedirect.value();

        try {
            const baseUrl = baseUrlFor(paypalMode.value());
            const accessToken = await getAccessToken(
                baseUrl,
                paypalClientId.value(),
                paypalSecret.value(),
            );

            const capture = await captureOrder(baseUrl, orderId, accessToken);
            if (!capture.ok) {
                logger.error("PayPal redirect capture failed", capture.body);
                res
                    .status(502)
                    .send(
                        renderResultPage(
                            "Pagamento PayPal",
                            "Non siamo riusciti a confermare il pagamento.",
                            buildRedirectUrl(redirectTarget, { status: "error", orderId }),
                        ),
                    );
                return;
            }

            res
                .status(200)
                .send(
                    renderResultPage(
                        "Pagamento completato",
                        "Grazie! Il pagamento è stato confermato con successo.",
                        buildRedirectUrl(redirectTarget, { status: "success", orderId }),
                    ),
                );
        } catch (error) {
            logger.error("paypalReturn error", error);
            res
                .status(500)
                .send(
                    renderResultPage(
                        "Pagamento PayPal",
                        "Si è verificato un problema inatteso.",
                        buildRedirectUrl(redirectTarget, { status: "error", orderId }),
                    ),
                );
        }
    },
);

export const paypalCancel = onRequest(
    {
        region: defaultRegion,
    },
    (req, res) => {
        withCors(res);
        if (req.method === "OPTIONS") {
            res.status(204).send("");
            return;
        }
        if (req.method !== "GET") {
            res.status(405).send("Method not allowed");
            return;
        }

        const redirectTarget =
            (req.query.redirect as string | undefined)?.trim() ||
            paypalCancelRedirect.value();

        res
            .status(200)
            .send(
                renderResultPage(
                    "Pagamento annullato",
                    "Hai annullato il pagamento. Puoi riprovare in qualsiasi momento.",
                    buildRedirectUrl(redirectTarget, { status: "cancelled" }),
                ),
            );
    },
);

/* ------------------------------------------------------------------ */
/*  Diagnostics                                                        */
/* ------------------------------------------------------------------ */
export const checkSecrets = onRequest(
    {
        region: defaultRegion,
        secrets: [
            paypalClientId,
            paypalSecret,
        ],
    },
    (_req, res) => {
        withCors(res);
        const okPaypalId = !!process.env.PAYPAL_CLIENT_ID;
        const okPaypalSecret = !!process.env.PAYPAL_SECRET_KEY;
        if (okPaypalId && okPaypalSecret) {
            res.status(200).send("✅ Secrets OK");
            return;
        }

        res.status(500).send("❌ Secrets missing");
    },
);
