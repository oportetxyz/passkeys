---
"@oportet/passkeys": patch
---

- fix(ios): the passkey sheet anchors on the key window of the foreground scene, for apps on the scene life cycle that iOS 27 requires. When there is no such window it falls back to the application key window and then the first window, so apps without scenes behave as before.
