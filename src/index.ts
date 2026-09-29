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

export async function get(
	request: Omit<PublicKeyCredentialRequestOptionsJSON, "extensions"> & {
		// Platform support:
		// - iOS: largeBlob (iOS 17+), prf (iOS 18+)
		// - Android: prf
		// - Web: largeBlob, prf
		extensions?: {
			largeBlob?: AuthenticationExtensionsLargeBlobInputs;
			prf?: AuthenticationExtensionsPRFInputs;
		};
	},
): Promise<AuthenticationResponseJSON | null> {
	return await ReactNativePasskeysModule.get(request);
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
