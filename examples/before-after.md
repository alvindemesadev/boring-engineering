# Before & After

Real refactoring examples showing overengineered code simplified to its correct form.

---

## 1. User Fetch Endpoint

### Before

```js
// UserRepository.js
class UserRepository extends BaseRepository {
  constructor(dbProvider) {
    super(dbProvider);
  }
  async findById(id) {
    return this.db.query('SELECT * FROM users WHERE id = $1', [id]);
  }
}

// UserService.js
class UserService {
  constructor(userRepository) {
    this.userRepository = userRepository;
  }
  async getUser(id) {
    return this.userRepository.findById(id);
  }
}

// UserController.js
class UserController {
  constructor(userService) {
    this.userService = userService;
  }
  async handleGetUser(req, res) {
    const user = await this.userService.getUser(req.params.id);
    res.json(user);
  }
}
```

Three classes, two levels of indirection, one query.

### After

```js
// users.routes.js
router.get('/users/:id', async (req, res) => {
  const [user] = await db.query('SELECT * FROM users WHERE id = $1', [req.params.id]);
  if (!user) return res.status(404).json({ error: 'User not found' });
  res.json(user);
});
```

Same behavior. No unnecessary layers. Easy to read, easy to change.

---

## 2. Email Sending

### Before

```js
class EmailProviderFactory {
  static create(type) {
    if (type === 'smtp') return new SmtpEmailProvider();
    if (type === 'sendgrid') return new SendGridEmailProvider();
    throw new Error('Unknown provider');
  }
}

class AbstractEmailProvider {
  async send(to, subject, body) {
    throw new Error('Not implemented');
  }
}

class SmtpEmailProvider extends AbstractEmailProvider {
  async send(to, subject, body) { /* ... */ }
}

// Usage
const provider = EmailProviderFactory.create(process.env.EMAIL_PROVIDER);
await provider.send(user.email, 'Welcome', welcomeBody);
```

### After

```js
// lib/email.js
export async function sendEmail(to, subject, body) {
  await transporter.sendMail({ from: config.emailFrom, to, subject, text: body });
}

// Usage
await sendEmail(user.email, 'Welcome', welcomeBody);
```

The project uses one email provider. The factory and abstract class exist for a flexibility that was never needed.

---

## 3. Form Validation

### Before

```js
class ValidationRule {
  validate(value) { throw new Error('Not implemented'); }
}

class RequiredRule extends ValidationRule {
  validate(value) { return value != null && value !== ''; }
}

class MinLengthRule extends ValidationRule {
  constructor(min) { super(); this.min = min; }
  validate(value) { return value.length >= this.min; }
}

class Validator {
  constructor(rules) { this.rules = rules; }
  validate(value) { return this.rules.every(r => r.validate(value)); }
}

// Usage
const validator = new Validator([new RequiredRule(), new MinLengthRule(8)]);
const isValid = validator.validate(password);
```

### After

```js
function isValidPassword(password) {
  return password != null && password.length >= 8;
}

const isValid = isValidPassword(password);
```

One function. Zero indirection. The class hierarchy added no value.

---

## Pattern

In each case the "before" code:
- Introduced abstractions before they were needed
- Added indirection that served no current consumer
- Made the code harder to read and trace without making it more capable

The "after" code:
- Does exactly what is required
- Is readable at a glance
- Is trivial to modify when requirements change
