---
"@oportet/passkeys": patch
---

- fix(android): `signalCurrentUserDetails` rejects its promise on any exception. Before, only two exception types were caught, and any other one thrown by the credential provider was left uncaught in the coroutine, which ends the app.
