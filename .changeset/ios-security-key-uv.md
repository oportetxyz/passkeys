---
"@oportet/passkeys": patch
---

fix(ios): a security key sign-in now honours the request's `userVerification`, as a passkey sign-in and both registrations already did, instead of falling back to the iOS default.
