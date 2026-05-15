import UIKit
import Capacitor


class ViewController: CAPBridgeViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("⚡️ --------------------------------------------------")
        print("⚡️ しおやミュージック 司令塔が起動しました！")
        
        if let bridge = self.bridge {
            // 将棋エンジンなどの不要なプラグイン登録は削除し、共通の認証系だけを残します
            
            bridge.registerPluginInstance(AuthPlugin())
            print("⚡️ AuthPlugin を登録しました")
            
            bridge.registerPluginInstance(GoogleAuthPlugin())
            print("⚡️ GoogleAuthPlugin を登録しました")
            
            bridge.registerPluginInstance(AdMobPlugin())
            print("⚡️ AdMobPlugin を登録しました")

            bridge.registerPluginInstance(AppIconPlugin())
            print("⚡️ AppIconPlugin を登録しました")
        }
        
        // --- 画面表示の最適化スクリプト（ノッチ対策・ズーム禁止） ---
        let selectionNoneScript = """
            // 1. テキスト選択とメニューを禁止
            var style = document.createElement('style');
            style.innerHTML = '* { -webkit-user-select: none !important; -webkit-touch-callout: none !important; } input, textarea { -webkit-user-select: text !important; }';
            document.head.appendChild(style);

            // 2. ピンチズーム禁止 ＆ ノッチ対策（viewport-fit=cover）
            var meta = document.createElement('meta');
            meta.name = 'viewport';
            meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover';
            document.getElementsByTagName('head')[0].appendChild(meta);

            // 3. ジェスチャーによるズーム防止
            document.addEventListener('gesturestart', function (e) {
                e.preventDefault();
            });
        """
                
        let userScript = WKUserScript(
            source: selectionNoneScript,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
                
        self.webView?.configuration.userContentController.addUserScript(userScript)
        print("⚡️ システムスクリプトを注入しました")
        
        print("⚡️ --------------------------------------------------")
    }
}
