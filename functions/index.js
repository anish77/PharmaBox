import * as functions from "firebase-functions";
import fetch from "node-fetch";

const PAYPAL_API_BASE = "https://api-m.sandbox.paypal.com"; // usa .paypal.com per produzione

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
                    "Authorization": `Basic ${auth}`,
                },
                body: JSON.stringify({
                    intent: "CAPTURE",
                    purchase_units: [
                        {
                            amount: {
                                currency_code: "EUR",
                                value: "1.00",
                            },
                            description: "Abbonamento annuale PharmaBox",
                        },
                    ],
                }),
            });

            const data = await response.json();
            res.json(data);
        } catch (error) {
            res.status(500).json({ error: error.message });
        }
    });

export const capturePaypalOrder = functions
    .runWith({ secrets: ["PAYPAL_CLIENT_ID", "PAYPAL_SECRET_KEY"] })
    .https.onRequest(async (req, res) => {
        try {
            const { orderId } = req.query;
            const auth = Buffer.from(
                `${process.env.PAYPAL_CLIENT_ID}:${process.env.PAYPAL_SECRET_KEY}`
            ).toString("base64");

            const response = await fetch(`${PAYPAL_API_BASE}/v2/checkout/orders/${orderId}/capture`, {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    "Authorization": `Basic ${auth}`,
                },
            });

            const data = await response.json();
            res.json(data);
        } catch (error) {
            res.status(500).json({ error: error.message });
        }
    });
const functions = require("firebase-functions");

exports.testRunWith = functions
    .runWith({ secrets: ["PAYPAL_CLIENT_ID"] })
    .https.onRequest((req, res) => {
        const ok = !!process.env.PAYPAL_CLIENT_ID;
        res.status(ok ? 200 : 500).send(ok ? "runWith funziona ✅" : "❌ secret mancante");
    });
