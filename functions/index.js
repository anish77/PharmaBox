import fetch from "node-fetch";
import * as functions from "firebase-functions";
import Stripe from "stripe";

// === STRIPE ===
import * as functions from "firebase-functions";
import Stripe from "stripe";

export const createStripePaymentIntent = functions
    .runWith({
        secrets: ["STRIPE_SECRET_KEY_TEST", "STRIPE_SECRET_KEY"],
    })
    .https.onRequest(async (req, res) => {
        try {
            const { amount, currency, mode = "test" } = req.body;

            if (!amount || !currency) {
                return res
                    .status(400)
                    .json({ success: false, message: "Dati mancanti: amount o currency" });
            }

            // ✅ Usa la chiave corretta in base all’ambiente
            const secretKey =
                mode === "live"
                    ? process.env.STRIPE_SECRET_KEY
                    : process.env.STRIPE_SECRET_KEY_TEST;

            if (!secretKey) {
                return res.status(500).json({
                    success: false,
                    message: `Chiave Stripe non trovata per ambiente ${mode}`,
                });
            }

            const stripe = new Stripe(secretKey, {
                apiVersion: "2025-01-27.acacia", // o l'ultima disponibile
            });

            const paymentIntent = await stripe.paymentIntents.create({
                amount: Math.round(parseFloat(amount)),
                currency,
                automatic_payment_methods: { enabled: true },
            });

            functions.logger.info("✅ PaymentIntent creato", {
                id: paymentIntent.id,
                clientSecret: paymentIntent.client_secret,
                amount,
                mode,
            });

            // 🔹 Risposta completa per il client
            return res.status(200).json({
                success: true,
                paymentIntentId: paymentIntent.id,
                clientSecret: paymentIntent.client_secret,
                mode,
            });
        } catch (error) {
            functions.logger.error("❌ Errore creazione PaymentIntent", error);
            return res.status(500).json({
                success: false,
                message: error.message || "Errore Stripe",
            });
        }
    });

logger.i("🔧 Stripe.publishableKey: ${Stripe.publishableKey}");
logger.i("🆔 PaymentIntent ID: ${paymentIntent['id']}");
logger.i("🧩 Client Secret: ${paymentIntent['client_secret']}");

// === PAYPAL ===
const PAYPAL_API_BASE = "https://api-m.paypal.com"; // Usa .paypal.com per produzione

export const createPaypalOrder = functions
    .runWith({ secrets: ["PAYPAL_CLIENT_ID", "PAYPAL_SECRET_KEY"] })
    .https.onRequest(async (req, res) => {
        try {
            const auth = Buffer.from(
                `${process.env.PAYPAL_CLIENT_ID}:${process.env.PAYPAL_SECRET_KEY}`
            ).toString("base64");

            const response = await fetch(`${PAYPAL_API_BASE}/v2/checkout/orders`, {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    Authorization: `Basic ${auth}`,
                },
                body: JSON.stringify({
                    intent: "CAPTURE",
                    purchase_units: [
                        {
                            amount: {
                                currency_code: "EUR",
                                value: req.body.amount || "1.00",
                            },
                            description: "Abbonamento annuale PharmaBox",
                        },
                    ],
                    application_context: {
                        return_url:
                            "https://europe-west1-pharmabox-1c149.cloudfunctions.net/paypalReturn",
                        cancel_url:
                            "https://europe-west1-pharmabox-1c149.cloudfunctions.net/paypalCancel",
                    },
                }),
            });

            const data = await response.json();
            return res.json(data);
        } catch (error) {
            console.error("Errore PayPal:", error);
            return res.status(500).json({ error: error.message });
        }
    });

export const capturePaypalOrder = functions
    .runWith({ secrets: ["PAYPAL_CLIENT_ID", "PAYPAL_SECRET_KEY"] })
    .https.onRequest(async (req, res) => {
        try {
            const { orderId } = req.query;
            if (!orderId) {
                return res.status(400).json({ error: "orderId mancante" });
            }

            const auth = Buffer.from(
                `${process.env.PAYPAL_CLIENT_ID}:${process.env.PAYPAL_SECRET_KEY}`
            ).toString("base64");

            const response = await fetch(
                `${PAYPAL_API_BASE}/v2/checkout/orders/${orderId}/capture`,
                {
                    method: "POST",
                    headers: {
                        "Content-Type": "application/json",
                        Authorization: `Basic ${auth}`,
                    },
                }
            );

            const data = await response.json();
            return res.json(data);
        } catch (error) {
            console.error("Errore cattura PayPal:", error);
            return res.status(500).json({ error: error.message });
        }
    });

// === TEST SECRETS ===
export const testRunWith = functions
    .runWith({ secrets: ["PAYPAL_CLIENT_ID", "STRIPE_SECRET_KEY"] })
    .https.onRequest((req, res) => {
        const paypalOk = !!process.env.PAYPAL_CLIENT_ID;
        const stripeOk = !!process.env.STRIPE_SECRET_KEY;

        if (paypalOk && stripeOk) {
            res.status(200).send("✅ Secrets caricati correttamente");
        } else {
            res
                .status(500)
                .send(
                    `❌ Mancano segreti: ${!paypalOk ? "PAYPAL" : ""} ${!stripeOk ? "STRIPE" : ""
                    }`
                );
        }
    });
