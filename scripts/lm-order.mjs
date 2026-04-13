export const handler = async (event) => {

  // check internal API for legit call
  if (event.headers['x-api-key'] !== process.env.INTERNAL_API_KEY) {
    return {
      statusCode: 403,
      body: JSON.stringify({ error: 'Forbidden: Invalid API Key' }),
    };
  }

  // get order information
  const body = event.body ? JSON.parse(event.body) : {};
  const { recipient, items } = body;
  console.log(body);
  console.log(recipient, items);

  try {
    // Get Printful API key
    const apiKey = process.env.PRINTFUL_API_KEY;

    // Create order
    const response = await fetch("https://api.printful.com/orders", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${apiKey}`,
        "Content-Type": "application/json",
        "X-PF-Store-Id": process.env.printful_store_id
      },
      body: JSON.stringify({recipient, items})
    });

    const data = await response.json();
    console.log("Printful order response:", data);

    return {
      statusCode: 200,
      body: JSON.stringify({ message: "Order attempted", data })
    };
  } catch (err) {
    return {
      statusCode: 500,
      body: JSON.stringify({ error: err.message })
    };
  }
};