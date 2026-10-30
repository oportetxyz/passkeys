import AuthenticationServices
import ExpoModulesCore
import Foundation

protocol PasskeyResultHandler {
    func onSuccess(_ data: PublicKeyCredentialJSON)
    func onFailure(_ error: Error)
}

class PasskeyDelegate: NSObject, ASAuthorizationControllerDelegate,
    ASAuthorizationControllerPresentationContextProviding
{
    private let handler: PasskeyResultHandler

    init(handler: PasskeyResultHandler) {
        self.handler = handler
    }

    // Perform the authorization request for a given ASAuthorizationController instance
    @available(iOS 15.0, *)
    func performAuthForController(controller: ASAuthorizationController) {
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    @available(iOS 13.0, *)
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return foregroundSceneWindow()
            ?? UIApplication.shared.keyWindow
            ?? UIApplication.shared.windows.first
            ?? ASPresentationAnchor()
    }

    // Under the scene life cycle the sheet needs a window from the scene on screen, since a
    // window made with no scene never shows. Apps without scenes get nil here and keep the
    // application-wide lookups. Written out because the expo helper for this needs SDK 58.
    @available(iOS 13.0, *)
    private func foregroundSceneWindow() -> UIWindow? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let scene =
            scenes.first { $0.activationState == .foregroundActive }
            ?? scenes.first { $0.activationState == .foregroundInactive }

        return scene?.windows.first { $0.isKeyWindow }
    }

    @available(iOS 13.0, *)
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        handler.onFailure(error)
    }

    @available(iOS 15.0, *)
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {

        switch authorization.credential {
        case let credential as ASAuthorizationPlatformPublicKeyCredentialRegistration:
            if credential.rawAttestationObject == nil {
                handler.onFailure((ASAuthorizationError(ASAuthorizationError.Code.failed)))
            }

            var largeBlob: AuthenticationExtensionsLargeBlobOutputsJSON?
            if #available(iOS 17.0, *) {
                largeBlob = AuthenticationExtensionsLargeBlobOutputsJSON(
                    supported: Field.init(wrappedValue: credential.largeBlob?.isSupported)
                )
            }

            var prf: AuthenticationExtensionsPRFOutputsJSON?
            if #available(iOS 18.0, *) {
                prf = credential.prf.flatMap { it in
                    AuthenticationExtensionsPRFOutputsJSON(
                        enabled: Field.init(wrappedValue: it.isSupported),
                        results: Field.init(
                            wrappedValue: it.first.map { first in
                                AuthenticationExtensionsPRFValuesJSON(
                                    first: Field.init(wrappedValue: first.serialize()),
                                    second: Field.init(wrappedValue: it.second.serialize()))
                            }
                        )
                    )
                }
            }

            let clientExtensionResults = AuthenticationExtensionsClientOutputsJSON(
                largeBlob: Field.init(wrappedValue: largeBlob),
                prf: Field.init(wrappedValue: prf)
            )

            let response = AuthenticatorAttestationResponseJSON(
                clientDataJSON: Field.init(
                    wrappedValue: credential.rawClientDataJSON.toBase64URLEncodedString()),
                publicKey: Field.init(
                    wrappedValue: getPublicKey(from: credential.rawAttestationObject!)?
                        .toBase64URLEncodedString()),
                attestationObject: Field.init(
                    wrappedValue: credential.rawAttestationObject!.toBase64URLEncodedString())
            )

            let registrationResult = RegistrationResponseJSON(
                id: Field.init(wrappedValue: credential.credentialID.toBase64URLEncodedString()),
                rawId: Field.init(wrappedValue: credential.credentialID.toBase64URLEncodedString()),
                response: Field.init(wrappedValue: response),
                authenticatorAttachment: Field.init(wrappedValue: .platform),
                clientExtensionResults: Field.init(wrappedValue: clientExtensionResults)
            )

            handler.onSuccess(Either(registrationResult))

        case let credential as ASAuthorizationSecurityKeyPublicKeyCredentialRegistration:
            if credential.rawAttestationObject == nil {
                handler.onFailure((ASAuthorizationError(ASAuthorizationError.Code.failed)))
            }

            let response = AuthenticatorAttestationResponseJSON(
                clientDataJSON: Field.init(
                    wrappedValue: credential.rawClientDataJSON.toBase64URLEncodedString()),
                publicKey: Field.init(
                    wrappedValue: getPublicKey(from: credential.rawAttestationObject!)?
                        .toBase64URLEncodedString()),
                attestationObject: Field.init(
                    wrappedValue: credential.rawAttestationObject!.toBase64URLEncodedString())
            )

            let registrationResult = RegistrationResponseJSON(
                id: Field.init(wrappedValue: credential.credentialID.toBase64URLEncodedString()),
                rawId: Field.init(wrappedValue: credential.credentialID.toBase64URLEncodedString()),
                response: Field.init(wrappedValue: response),
                authenticatorAttachment: Field.init(wrappedValue: .crossPlatform)
            )

            handler.onSuccess(Either(registrationResult))

        case let credential as ASAuthorizationPlatformPublicKeyCredentialAssertion:
            var largeBlob: AuthenticationExtensionsLargeBlobOutputsJSON? =
                AuthenticationExtensionsLargeBlobOutputsJSON()
            if #available(iOS 17.0, *), let result = credential.largeBlob?.result {
                switch result {
                case .read(data: let blobData):
                    largeBlob?.blob = blobData?.toBase64URLEncodedString()
                case .write(success: let successfullyWritten):
                    largeBlob?.written = successfullyWritten
                @unknown default: break
                }
            }

            var prf: AuthenticationExtensionsPRFOutputsJSON?
            if #available(iOS 18.0, *) {
                prf = credential.prf.map {
                    AuthenticationExtensionsPRFOutputsJSON(
                        results: Field.init(
                            wrappedValue: AuthenticationExtensionsPRFValuesJSON(
                                first: Field.init(wrappedValue: $0.first.serialize()),
                                second: Field.init(wrappedValue: $0.second.serialize())
                            )
                        )
                    )
                }
            }

            let clientExtensionResults = AuthenticationExtensionsClientOutputsJSON(
                largeBlob: Field.init(wrappedValue: largeBlob),
                prf: Field.init(wrappedValue: prf)
            )

            let response = AuthenticatorAssertionResponseJSON(
                authenticatorData: Field.init(
                    wrappedValue: credential.rawAuthenticatorData.toBase64URLEncodedString()),
                clientDataJSON: Field.init(
                    wrappedValue: credential.rawClientDataJSON.toBase64URLEncodedString()),
                signature: Field.init(
                    wrappedValue: credential.signature!.toBase64URLEncodedString()),
                userHandle: Field.init(wrappedValue: credential.userID!.toBase64URLEncodedString())
            )

            let assertionResult = AuthenticationResponseJSON(
                id: Field.init(wrappedValue: credential.credentialID.toBase64URLEncodedString()),
                rawId: Field.init(wrappedValue: credential.credentialID.toBase64URLEncodedString()),
                response: Field.init(wrappedValue: response),
                clientExtensionResults: Field.init(wrappedValue: clientExtensionResults)
            )

            handler.onSuccess(Either(assertionResult))

        case let credential as ASAuthorizationSecurityKeyPublicKeyCredentialAssertion:
            let response = AuthenticatorAssertionResponseJSON(
                authenticatorData: Field.init(
                    wrappedValue: credential.rawAuthenticatorData.toBase64URLEncodedString()),
                clientDataJSON: Field.init(
                    wrappedValue: credential.rawClientDataJSON.toBase64URLEncodedString()),
                signature: Field.init(
                    wrappedValue: credential.signature!.toBase64URLEncodedString()),
                userHandle: Field.init(wrappedValue: credential.userID!.toBase64URLEncodedString())
            )

            let assertionResult = AuthenticationResponseJSON(
                id: Field.init(wrappedValue: credential.credentialID.toBase64URLEncodedString()),
                rawId: Field.init(wrappedValue: credential.credentialID.toBase64URLEncodedString()),
                response: Field.init(wrappedValue: response)
            )

            handler.onSuccess(Either(assertionResult))
        default:
            handler.onFailure((ASAuthorizationError(ASAuthorizationError.Code.failed)))
        }
    }
}
