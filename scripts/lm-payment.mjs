import { LambdaClient, InvokeCommand } from "@aws-sdk/client-lambda";
import Stripe from "stripe";
const lambda = new LambdaClient({ region: "us-east-2" });
const stripe = new Stripe(process.env.STRIPE_SECRET_KEY, { apiVersion: "2023-08-16" });

export const handler = async (event) => {
  // Cors pre-flight
  const headers = {
    "Access-Control-Allow-Origin": "https://ushirtsa.com",
    "Access-Control-Allow-Headers": "Content-Type",
    "Access-Control-Allow-Methods": "POST, OPTIONS"
  };
  const method = event.requestContext?.http?.method || event.httpMethod; 
  if (method === "OPTIONS") {
    return { statusCode: 204, headers };
  }
  // Parse input (from frontend)
  const body = typeof event.body === "string"
    ? JSON.parse(event.body)
    : event.body;
  console.log("Incoming body:", body); // for debug
  const { action, paymentIntentId, recipient, items } = body;

  // Check first if payment is attempted
  if (action === "create-payment-intent") {
    const paymentIntent = await stripe.paymentIntents.create({
      amount: 2026,
      currency: "usd",
      automatic_payment_methods: { enabled: true }
    });

    return {
      statusCode: 200,
      headers,
      body: JSON.stringify({ clientSecret: paymentIntent.client_secret })
    };
  }

  // Place order if payment succeeded
  if (action === "confirm-order") {
    const paymentIntent = await stripe.paymentIntents.retrieve(paymentIntentId);

    if (paymentIntent.status === "succeeded") {
      const payload = { recipient, items };
      const command = new InvokeCommand({
        FunctionName: "order-handler", 
        Payload: Buffer.from(
          JSON.stringify({
            body: JSON.stringify(payload),  
            headers: { "x-api-key": process.env.INTERNAL_API_KEY },
          })
        ),
      });

      const result = await lambda.send(command);
      const orderResult = JSON.parse(Buffer.from(result.Payload).toString());

      return {
        statusCode: 200,
        headers,
        body: JSON.stringify({
          message: "Order placed!",
          orderResult,
        }),
      };
    }
    
    // for future error checking
    return {
      statusCode: 400,
      headers,
      body: JSON.stringify({ message: "Payment failed" }),
    };
  }
};