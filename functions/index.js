import * as functions from "firebase-functions";
import fetch from "node-fetch";

const functions = require("firebase-functions");
const stripe = require("stripe")(functions.config().stripe.secret); // chiave segreta salvata in config
const PAYPAL_API_BASE = "https://api-m.sandbox.paypal.com"; // usa .paypal.com per produzione

exports.createCardPayment = functions.https.onRequest(async (req, res) => {
    try {
        const { amount, currency, card } = req.body;
        if (!amount || !card) {
            return res.status(400).send({ success: false, message: "Dati mancanti" });
        }

        const paymentIntent = await stripe.paymentIntents.create({
            amount: Math.round(parseFloat(amount) * 100), // in centesimi
            currency,
            payment_method_data: {
                type: "card",
                card: {
                    number: card.number,
                    exp_month: card.expiration.split("/")[0],
                    exp_year: "20" + card.expiration.split("/")[1],
                    cvc: card.cvv,
                },
            },
            confirm: true,
        });

        res.status(200).send({ success: true, paymentId: paymentIntent.id });
    } catch (error) {
        console.error("Errore pagamento:", error);
        res.status(500).send({ success: false, message: error.message });
    }
});

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
