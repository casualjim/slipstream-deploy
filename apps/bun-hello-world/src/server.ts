import { Hono } from "hono";
import { cors } from "hono/cors";

const app = new Hono();

// CORS middleware
app.use(
  "*",
  cors({
    origin: "*",
    allowMethods: ["GET", "POST", "OPTIONS"],
    allowHeaders: ["Content-Type", "Authorization"],
  })
);

// Hello endpoint
app.get("/hello", (c) => {
  const name = c.req.query("name") || "world";
  return c.json({ message: `Hello, ${name}!` });
});

// Echo endpoint
app.post("/echo", async (c) => {
  try {
    const payload = await c.req.json();
    return c.json({
      timestamp: new Date().toISOString(),
      payload,
    });
  } catch (error) {
    return c.json({ error: "Invalid JSON" }, 400);
  }
});

// Health check endpoint
app.get("/healthz", (c) => {
  return c.json({ status: "ok" });
});

export default app;
