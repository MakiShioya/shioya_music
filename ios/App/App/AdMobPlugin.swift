//
//  AdMobPlugin.swift
//  App
//
//  Created by Maki Shioya on 2026/05/05.
//

import Foundation
import Capacitor
import GoogleMobileAds
import AppTrackingTransparency

@objc(AdMobPlugin)
public class AdMobPlugin: CAPPlugin {
    // バナー広告を保持するための変数
    private var bannerView: BannerView?

    // 1. 初期化処理（トラッキング許可のダイアログを含む）
    @objc func initialize(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            if #available(iOS 14, *) {
                ATTrackingManager.requestTrackingAuthorization { status in
                    MobileAds.shared.start(completionHandler: nil)
                    call.resolve(["status": "initialized"])
                }
            } else {
                MobileAds.shared.start(completionHandler: nil)
                call.resolve(["status": "initialized"])
            }
        }
    }

    // 2. バナー広告を表示する
    @objc func showBannerAd(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            guard let rootVC = self.bridge?.viewController else {
                call.reject("画面が取得できません")
                return
            }

            // すでにバナーが表示されている場合は何もしない（重複防止）
            if self.bannerView != nil {
                call.resolve(["status": "already showing"])
                return
            }

            print("⏳ バナー広告をロード中...")
 
            let adUnitID = "ca-app-pub-4686002256203931/7457426027"

            // バナーの作成（標準的な 320x50 サイズ）
            let banner = BannerView(adSize: AdSizeBanner)
            banner.adUnitID = adUnitID
            banner.rootViewController = rootVC
            // AutoLayoutを利用するためfalseに設定
            banner.translatesAutoresizingMaskIntoConstraints = false

            // Web画面（WebView）の上にバナーを追加
            rootVC.view.addSubview(banner)

            // 画面の「一番下」かつ「中央」に固定する設定
            NSLayoutConstraint.activate([
                banner.bottomAnchor.constraint(equalTo: rootVC.view.safeAreaLayoutGuide.bottomAnchor),
                banner.centerXAnchor.constraint(equalTo: rootVC.view.centerXAnchor)
            ])

            // 広告の読み込み（将棋の時と同じく Request() を使用）
            let request = Request()
            banner.load(request)

            self.bannerView = banner
            print("✅ バナー広告を表示しました")
            call.resolve(["status": "banner showing"])
        }
    }

    // 3. （オプション）バナー広告を隠す機能
    @objc func hideBannerAd(_ call: CAPPluginCall) {
        DispatchQueue.main.async {
            self.bannerView?.removeFromSuperview()
            self.bannerView = nil
            call.resolve(["status": "banner hidden"])
        }
    }
}
