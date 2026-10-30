---
"@oportet/passkeys": patch
---

- feat(ios): `get` asks only for passkeys on the device and in iCloud Keychain, so the sheet goes straight to Face ID. It also offers security keys when `get(request, { securityKey: true })` is passed or an `allowCredentials` entry lists a `usb`, `nfc` or `ble` transport.
- feat(ios): registration responses report `authenticatorAttachment` as `platform` or `cross-platform`.
- feat(android): `prepareGet(request)` warms the sheet with `prepareGetCredential` on Android 14 and up. The next `get` with the same request opens from it, and any other request falls back to `getCredential`. It resolves `false` on older Android, iOS and the web.
