---
"@oportet/passkeys": patch
---

Add `cancel()`: drops a passkey ceremony iOS started but never answered, freeing the single native slot that otherwise rejects every `get` and `create` with "There is already a pending passkey request" until the app restarts. Android and web keep no such slot and return `false`.
