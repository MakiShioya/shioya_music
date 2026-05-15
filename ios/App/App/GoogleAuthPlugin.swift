//
//  GoogleAuthPlugin.swift
//  App
//
//  Created by Maki Shioya on 2026/03/26.
//

import Foundation
import Capacitor
import GoogleSignIn

@objc(GoogleAuthPlugin)
public class GoogleAuthPlugin: CAPPlugin {
    
    @objc func signIn(_ call: CAPPluginCall) {
        // ▼▼▼ 追加：JSからSwiftが呼ばれた証拠を出力 ▼▼▼
        print("🟢 [Native] GoogleAuthPlugin signIn が呼ばれました！")
        
        DispatchQueue.main.async {
            guard let viewController = self.bridge?.viewController else {
                print("🔴 [Native] エラー: 画面(viewController)が取得できません")
                call.reject("画面が取得できません")
                return
            }
            
            print("🟢 [Native] Google SDK の signIn を呼び出します...")
            
            GIDSignIn.sharedInstance.signIn(withPresenting: viewController) { result, error in
                if let error = error {
                    // ▼▼▼ 追加：Google SDK が返した本当のエラーを出力 ▼▼▼
                    print("🔴 [Native] Google SDK エラー発生: \(error.localizedDescription)")
                    call.reject(error.localizedDescription)
                    return
                }
                
                guard let user = result?.user,
                      let idToken = user.idToken?.tokenString else {
                    print("🔴 [Native] エラー: ユーザー情報またはidTokenが空です")
                    call.reject("ユーザー情報の取得に失敗しました")
                    return
                }
                
                print("🟢 [Native] Googleログイン大成功！トークンをJSへ返します")
                call.resolve([
                    "idToken": idToken,
                    "accessToken": user.accessToken.tokenString
                ])
            }
        }
    }
}
