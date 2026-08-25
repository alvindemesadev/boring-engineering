# Bad Abstractions

Patterns that introduce unnecessary complexity. Avoid these unless a genuine requirement justifies them.

---

## 1. Premature Abstraction for One Use Case

**Situation:** User needs one API client.

**Bad:**
```
BaseApiClient
AbstractApiProvider
ApiClientFactory
ApiClientRegistry
```

Four classes to do what one direct implementation handles. None of the extra classes have a second consumer.

**Good:**
```js
// api-client.js
export async function fetchUser(id) {
  const res = await fetch(`/api/users/${id}`);
  return res.json();
}
```

---

## 2. Generic Infrastructure for a Single Feature

**Situation:** One background job needs to run on a schedule.

**Bad:**
```
JobScheduler
JobRegistry
JobExecutorFactory
BaseJob (abstract)
ScheduledJob (extends BaseJob)
EmailReminderJob (extends ScheduledJob)
```

**Good:**
```js
// jobs/send-reminders.js
export async function sendReminders() {
  const users = await getActiveUsers();
  for (const user of users) {
    await sendEmail(user.email, reminderTemplate(user));
  }
}
```

---

## 3. Configuration Options With One Value

**Situation:** A function always sends JSON.

**Bad:**
```js
function request(url, options = {}) {
  const format = options.format ?? 'json';
  const encoding = options.encoding ?? 'utf-8';
  const retryStrategy = options.retryStrategy ?? 'exponential';
  // ...
}
```

**Good:**
```js
async function request(url, body) {
  return fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
}
```

---

## 4. Abstraction That Requires a Type Flag

When an abstraction needs a `type`, `mode`, or `strategy` parameter to branch into different behavior, it is usually two separate things pretending to be one.

**Bad:**
```js
function formatLabel(entity, type) {
  if (type === 'user') return `${entity.firstName} ${entity.lastName}`;
  if (type === 'product') return `${entity.name} (${entity.sku})`;
}
```

**Good:**
```js
function formatUserName(user) {
  return `${user.firstName} ${user.lastName}`;
}

function formatProductLabel(product) {
  return `${product.name} (${product.sku})`;
}
```

---

## 5. Deep Folder Hierarchy for a Small Feature

**Bad:**
```
src/
  features/
    user/
      domain/
        models/
          UserEntity.js
        services/
          UserDomainService.js
      application/
        use-cases/
          GetUserUseCase.js
      infrastructure/
        repositories/
          UserRepository.js
```

For a feature that returns a user by ID.

**Good:**
```
src/
  users/
    users.routes.js
    users.service.js
    users.db.js
```
