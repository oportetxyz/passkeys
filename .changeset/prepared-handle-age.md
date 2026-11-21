---
"@oportet/passkeys": patch
---

On Android, a `get` no longer opens from a prepared sign-in sheet older than half the request's timeout, so it never hands Google an expired one.
