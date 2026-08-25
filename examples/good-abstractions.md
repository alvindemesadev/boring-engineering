# Good Abstractions

Abstractions that are justified by real, proven need. These patterns are worth the indirection.

---

## 1. Shared Validation Used in Multiple Places

**Situation:** Email validation logic appears in the registration handler, the profile update handler, and the invite handler.

**Good:**
```js
// lib/validators.js
export function isValidEmail(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}
```

One function, three consumers, one place to fix a bug or update the rule.

---

## 2. Database Query Helper for a Repeated Pattern

**Situation:** Every route manually opens a connection, runs a query, and closes the connection.

**Good:**
```js
// lib/db.js
export async function query(sql, params) {
  const client = await pool.connect();
  try {
    const result = await client.query(sql, params);
    return result.rows;
  } finally {
    client.release();
  }
}
```

The abstraction has one clear responsibility. All callers benefit from the same fix if connection handling needs to change.

---

## 3. Error Response Helper Used Across All Route Handlers

**Situation:** Every route handler formats error responses differently, causing inconsistent API behavior.

**Good:**
```js
// lib/respond.js
export function errorResponse(res, status, message) {
  return res.status(status).json({ error: message });
}
```

Small, named, single-purpose. The duplication it removes is meaningful because the format must stay consistent.

---

## 4. Config Loader for Environment Variables

**Situation:** Multiple modules each read `process.env` directly with no validation.

**Good:**
```js
// config.js
export const config = {
  port: parseInt(process.env.PORT ?? '3000', 10),
  dbUrl: requireEnv('DATABASE_URL'),
  jwtSecret: requireEnv('JWT_SECRET'),
};

function requireEnv(key) {
  const value = process.env[key];
  if (!value) throw new Error(`Missing required environment variable: ${key}`);
  return value;
}
```

Centralizes validation, fails fast on misconfiguration, and gives all consumers a typed, consistent interface.

---

## What These Have in Common

- Each abstraction has exactly **one clear job**
- Each is consumed in **multiple real places**, not one
- Each **removes a genuine maintenance burden** — one fix applies everywhere it matters
- None of them require a `type`, `mode`, or `strategy` flag to branch behavior
- None were created speculatively — they exist because the duplication already existed
