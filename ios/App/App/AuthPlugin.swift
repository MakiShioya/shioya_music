import Foundation
import Capacitor
import AuthenticationServices
import CryptoKit

@objc(AuthPlugin)
public class AuthPlugin: CAPPlugin, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    
    // JSからの呼び出しを一時的に保存しておく変数
    private var currentCall: CAPPluginCall?
    private var currentNonce: String?
    
    @objc func signInWithApple(_ call: CAPPluginCall) {
        self.currentCall = call
        
        // 1. Firebase用の暗号（ノンス）を生成
        let nonce = randomNonceString()
        self.currentNonce = nonce
        
        // 2. Appleの認証リクエストを作成
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
        
        // 3. 認証画面（Face ID等のシステムUI）を呼び出す
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        
        DispatchQueue.main.async {
            authorizationController.performRequests()
        }
    }
    
    // 画面のどこにポップアップを出すかを指定する必須メソッド
    public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.bridge?.viewController?.view.window ?? ASPresentationAnchor()
    }
    
    // 認証が成功したときに呼ばれるメソッド
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            currentCall?.reject("認証情報の取得に失敗しました")
            return
        }
        
        guard let nonce = currentNonce else {
            currentCall?.reject("暗号（Nonce）が見つかりません")
            return
        }
        
        // Firebaseに渡すための身分証明書（IDトークン）を取得
        guard let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            currentCall?.reject("トークンの取得に失敗しました")
            return
        }
        
        // JS側に証明書と暗号を返す
        currentCall?.resolve([
            "status": "success",
            "idToken": idTokenString,
            "rawNonce": nonce
        ])
    }
    
    // 認証が失敗・キャンセルされたときに呼ばれるメソッド
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        currentCall?.reject("ログインがキャンセルされたか、エラーが発生しました")
    }
    
    // --- 以下、Firebase用の暗号（Nonce）を生成するための補助関数 ---
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("暗号の生成に失敗しました")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        let nonce = randomBytes.map { byte in
            charset[Int(byte) % charset.count]
        }
        return String(nonce)
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        return hashString
    }
}
