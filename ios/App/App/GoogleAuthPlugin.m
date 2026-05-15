//
//  GoogleAuthPlugin.m
//  App
//
//  Created by Maki Shioya on 2026/03/26.
//

#import <Capacitor/Capacitor.h>

CAP_PLUGIN(GoogleAuthPlugin, "GoogleAuthPlugin",
    CAP_PLUGIN_METHOD(signIn, CAPPluginReturnPromise);
)
