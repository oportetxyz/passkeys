// Import the native module. On web, it will be resolved to ReactNativePasskeys.web.ts
// and on native platforms to ReactNativePasskeys.ts
import ReactNativePasskeysModule from "./ReactNativePasskeysModule";

import type {
	AuthenticationExtensionsLargeBlobInputs,
	AuthenticationExtensionsPRFInputs,
	AuthenticationResponseJSON,
	PublicKeyCredentialCreationOptionsJSON,
	PublicKeyCredentialRequestOptionsJSON,
	CreationResponse,
	GetOptions,
	SignalCurrentUserDetailsOptions,
} from "./ReactNativePasskeys.types";

export function isSupported(): boolean {
	return ReactNativePasskeysModule.isSupported();
}

export function isAutoFillAvalilable(): boolean {
	return ReactNativePasskeysModule.isAutoFillAvalilable();
}

export async function create(
	request: Omit<PublicKeyCredentialCreationOptionsJSON, "extensions"> & {
		// Platform support:
		// - iOS: largeBlob (iOS 17+), prf (iOS 18+)
		// - Android: prf
		// - Web: largeBlob, prf
		extensions?: {
			largeBlob?: AuthenticationExtensionsLargeBlobInputs;
			prf?: AuthenticationExtensionsPRFInputs;
			// Request credProps on registration to learn discoverability.
			credProps?: boolean;
		};
	} & Pick<CredentialCreationOptions, "signal">,
): Promise<CreationResponse | null> {
	return await ReactNativePasskeysModule.create(request);
}

type GetRequest = Omit<PublicKeyCredentialRequestOptionsJSON, "extensions"> & {
	// Platform support:
	// - iOS: largeBlob (iOS 17+), prf (iOS 18+)
	// - Android: prf
	// - Web: largeBlob, prf
	extensions?: {
		largeBlob?: AuthenticationExtensionsLargeBlobInputs;
		prf?: AuthenticationExtensionsPRFInputs;
	};
};

/**
 * Signs in with a passkey.
 *
 * On iOS the sheet offers only passkeys on the device and in iCloud Keychain, unless
 * `options.securityKey` is true or an `allowCredentials` entry lists a security-key transport
 * (`usb`, `nfc` or `ble`). Asking for both makes iOS open a chooser instead of going straight to
 * Face ID. Android and the web offer security keys from their own sheet and ignore the option.
 */
export async function get(
	request: GetRequest,
	options?: GetOptions,
): Promise<AuthenticationResponseJSON | null> {
	return await ReactNativePasskeysModule.get(request, options ?? null);
}

/**
 * Prepares a `get` before the user asks for it, so the sheet opens sooner.
 *
 * Platform support:
 * - Android: 14+ (prepareGetCredential). The next `get` with a request identical to this one opens
 *   from the prepared state; any other request, or a second `get`, starts from scratch.
 * - iOS, Web: no-op
 *
 * @returns `true` when a prepared `get` is waiting
 */
export async function prepareGet(request: GetRequest): Promise<boolean> {
	return await ReactNativePasskeysModule.prepareGet(request);
}

/**
 * Tells the credential manager the current name of a user, so the passkeys it lists for them stop
 * showing the name they were created with. Every passkey sharing the `rpId` and `userId` is renamed.
 *
 * Platform support:
 * - iOS: 26+
 * - Android: 15+ with Google Play services
 * - Web: browsers that implement the WebAuthn Signal API
 *
 * @returns `false` where the platform has no Signal API, in which case nothing was sent
 */
export async function signalCurrentUserDetails(
	options: SignalCurrentUserDetailsOptions,
): Promise<boolean> {
	return await ReactNativePasskeysModule.signalCurrentUserDetails(options);
}
