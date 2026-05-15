//
//  AdMobPlugin.m
//  App
//
//  Created by Maki Shioya on 2026/05/05.
//

#import <Capacitor/Capacitor.h>

CAP_PLUGIN(AdMobPlugin, "AdMobPlugin",
    CAP_PLUGIN_METHOD(initialize, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(showBannerAd, CAPPluginReturnPromise);
    CAP_PLUGIN_METHOD(hideBannerAd, CAPPluginReturnPromise);
)
