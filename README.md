# @oportet/passkeys

Passkeys for Expo apps on iOS, Android and the web, behind one API.

This is Oportet's fork of [react-native-passkeys](https://github.com/peterferguson/react-native-passkeys) by [Peter Ferguson](https://github.com/peterferguson). He designed and wrote the module. The fork adds capabilities the original does not have yet. See [Acknowledgements](#acknowledgements) and [License](#license).

## What the fork adds

| Addition | Details |
| --- | --- |
| `signalCurrentUserDetails`, which renames a passkey in the credential manager | [Renaming a passkey](#renaming-a-passkey) |
| `androidx.credentials` 1.6.0 on Android, up from 1.3.0-alpha01 | Needs `compileSdkVersion` 35 |

Everything else works as it does in the original, and the rest of this page is its documentation.

## About the module

This is an Expo module to help you create and authenticate with passkeys on iOS, Android & web with the same api. The library aims to stay close to the standard [`navigator.credentials`](https://w3c.github.io/webappsec-credential-management/#framework-credential-management). More specifically, we provide an api for `get` & `create` functions (since these are the functions available cross-platform).

The adaptations we make are simple niceties like providing automatic conversion of base64-url encoded strings to buffer. This is also done to make it easier to pass the values to the native side.

Further niceties include some flag functions that indicate support for certain features.

## Installation

```sh
npx expo install @oportet/passkeys
```

## iOS Setup

#### 1. Host an Apple App Site Association (AASA) file

For Passkeys to work on iOS, you'll need to host an AASA file on your domain. This file is used to verify that your app is allowed to handle the domain you are trying to authenticate with. This must be hosted on a site with a valid SSL certificate.

The file should be hosted at:

```
https://<your_domain>/.well-known/apple-app-site-association
```

Note there is no `.json` extension for this file but the format is json. The contents of the file should look something like this:

```json
{
  "webcredentials": {
    "apps": ["<teamID>.<bundleID>"]
  }
}
```

Replace `<teamID>` with your Apple Team ID and `<bundleID>` with your app's bundle identifier.

#### 2. Add Associated Domains

Add the following to your `app.json`:

```json
{
  "expo": {
    "ios": {
      "associatedDomains": ["webcredentials:<your_domain>"]
    }
  }
}
```

Replace `<your_domain>` with the domain you are hosting the AASA file on. For example, if you are hosting the AASA file on `https://example.com/.well-known/apple-app-site-association`, you would add `example.com` to the `associatedDomains` array.

#### 3. Add minimum deployment target

Add the following to your `app.json`:

```json
{
  "expo": {
    "plugins": [
      [
        "expo-build-properties",
        {
          "ios": {
            "deploymentTarget": "15.0"
          }
        }
      ]
    ]
  }
}
```

#### 4. Prebuild and run your app

```sh
npx expo prebuild -p ios
npx expo run:ios # or build in the cloud with EAS
```

## Android Setup

#### 1. Host an `assetlinks.json` File

For Passkeys to work on Android, you'll need to host an `assetlinks.json` file on your domain. This file is used to verify that your app is allowed to handle the domain you are trying to authenticate with. This must be hosted on a site with a valid SSL certificate.

The file should be hosted at:

```
https://<your_domain>/.well-known/assetlinks.json
```

and should look something like this (you can generate this file using the [Android Asset Links Assistant](https://developers.google.com/digital-asset-links/tools/generator)):

```json
[
  {
    "relation": [
      "delegate_permission/common.handle_all_urls",
      "delegate_permission/common.get_login_creds"
    ],
    "target": {
      "namespace": "android_app",
      "package_name": "<package_name>",
      "sha256_cert_fingerprints": ["<sha256_cert_fingerprint>"]
    }
  }
]
```

Replace `<package_name>` with your app's package name and `<sha256_cert_fingerprint>` with your app's SHA256 certificate fingerprint.

The `get_login_creds` relation is required for passkey flows via Android's Credential Manager — without it, calls will fail silently or return "no matching credentials". `handle_all_urls` alone is only enough for App Links. See [Credential Manager prerequisites](https://developer.android.com/identity/credential-manager/prerequisites).

> **Note on DAL caching:** Android caches `assetlinks.json` for up to 24 hours. After updating, reinstall the app on your device/emulator to force a fresh fetch.

#### 2. Modify Expo Build Properties

Next, you'll need to modify the `compileSdkVersion` in your `app.json` to be at least 34.

```json
{
  "expo": {
    "plugins": [
      [
        "expo-build-properties",
        {
          "android": {
            "compileSdkVersion": 34
          }
        }
      ]
    ]
  }
}
```

#### 3. Prebuild and run your app

```sh
npx expo prebuild -p android
npx expo run:android # or build in the cloud with EAS
```

## Renaming a passkey

A credential manager keeps showing the name a passkey was created with. When the account's name changes, `signalCurrentUserDetails` sends the new one.

```ts
import { signalCurrentUserDetails } from "@oportet/passkeys";

const sent = await signalCurrentUserDetails({
  rpId: "example.com",
  userId, // base64url, the user handle the passkey was created with
  name: "new-name",
  displayName: "New Name",
});
```

It renames every passkey that shares the `rpId` and `userId`, so give each passkey its own user id if they need different names.

| Platform | Support |
| --- | --- |
| iOS | 26 and up. Only `name` is applied. |
| Android | 15 and up, with Google Play services. Needs `compileSdkVersion` 35. |
| Web | Browsers with the WebAuthn Signal API. |

The promise resolves to `false` when the platform has no Signal API, and nothing is sent. Android allows 10 signals in 120 seconds.

The two signals that delete passkeys, `signalUnknownCredential` and `signalAllAcceptedCredentials`, are left out on purpose. On iOS 26 they have been seen deleting a passkey that belongs to another account.

## Acknowledgements

react-native-passkeys is the work of [Peter Ferguson](https://github.com/peterferguson) and its contributors. The API, the native modules for iOS and Android and the web implementation all come from there. If this package is useful to you, the original is the one to star.

## License

MIT, the same license as the original. See [LICENSE](LICENSE).

- The original work is copyright Peter Ferguson.
- The changes made in this fork are copyright Oportet, released under the same MIT terms.

Both notices are in `LICENSE`, which ships with the package. [CHANGELOG.md](CHANGELOG.md) lists what the fork changed, starting from `react-native-passkeys` 0.4.2.
