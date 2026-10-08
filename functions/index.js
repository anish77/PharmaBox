import fetch from "node-fetch";
import * as functions from "firebase-functions";

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
    .runWith({ secrets: ["PAYPAL_CLIENT_ID", "PAYPAL_SECRET_KEY"] })
    .https.onRequest((req, res) => {
        const paypalOk = !!process.env.PAYPAL_CLIENT_ID;
        const paypalSecretOk = !!process.env.PAYPAL_SECRET_KEY;

        if (paypalOk && paypalSecretOk) {
            res.status(200).send("✅ Secrets caricati correttamente");
        } else {
            res
                .status(500)
                .send(
                    `❌ Mancano segreti: ${!paypalOk || !paypalSecretOk ? "PAYPAL" : ""
                    }`
                );
        }
    });
