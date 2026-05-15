import Foundation
import Capacitor

@objc(AppIconPlugin)
public class AppIconPlugin: CAPPlugin {
    
    @objc func changeIcon(_ call: CAPPluginCall) {
        print("--- 🔍 [AppIconPlugin] 内部調査開始 ---")
        
        // 1. JSからの受信データ確認
        print("⚡️ 受信データ: \(call.options)")
        guard let iconName = call.getString("iconName") else {
            print("❌ エラー: iconNameが空です")
            call.reject("アイコン名が指定されていません")
            return
        }

        // 2. アプリのパッケージ内にどんなファイルが存在するかリストアップ
        let bundlePath = Bundle.main.bundlePath
        print("📍 Bundleパス: \(bundlePath)")
        
        do {
            let items = try FileManager.default.contentsOfDirectory(atPath: bundlePath)
            // アイコンに関連しそうな名前（AppIcon）を含むファイルを抽出
            let foundIcons = items.filter { $0.contains("AppIcon") }
            
            if foundIcons.isEmpty {
                print("⚠️ 警告: アプリ内に 'AppIcon' という名のファイル/フォルダが一つも見つかりません。ビルド設定に問題があります。")
            } else {
                print("✅ 発見された関連ファイル一覧:")
                foundIcons.forEach { print("  - \($0)") }
            }
        } catch {
            print("❌ フォルダ読み込み失敗: \(error.localizedDescription)")
        }

        print("⚡️ 変更試行中: \(iconName)")

        DispatchQueue.main.async {
            // 3. システムが代替アイコンを許可しているか確認
            let supports = UIApplication.shared.supportsAlternateIcons
            print("📱 システムサポート状態: \(supports)")

            if supports {
                let nameToSet = iconName == "default" ? nil : iconName
                
                UIApplication.shared.setAlternateIconName(nameToSet) { error in
                    if let error = error as NSError? {
                        print("❌ システムエラー検出!")
                        print("   - ドメイン: \(error.domain)")
                        print("   - コード: \(error.code)")
                        print("   - 内容: \(error.localizedDescription)")
                        
                        // ユーザーのBundle ID情報を取得（不整合チェック用）
                        let actualBundleID = Bundle.main.bundleIdentifier ?? "不明"
                        print("🆔 現在のBundle Identifier: \(actualBundleID)")
                        
                        call.reject("アイコン変更失敗: \(error.localizedDescription) (Code: \(error.code))")
                    } else {
                        print("✅ アイコン変更に成功しました: \(iconName)")
                        call.resolve([
                            "status": "success",
                            "icon": iconName
                        ])
                    }
                    print("--- 🔍 調査終了 ---")
                }
            } else {
                print("❌ この端末はアイコン変更を許可していません")
                call.reject("この端末はアイコン変更をサポートしていません")
                print("--- 🔍 調査終了 ---")
            }
        }
    }
}
