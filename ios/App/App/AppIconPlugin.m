#import <Foundation/Foundation.h>
#import <Capacitor/Capacitor.h>

// JavaScript側にプラグインを認識させるための定義
CAP_PLUGIN(AppIconPlugin, "AppIconPlugin",
           CAP_PLUGIN_METHOD(changeIcon, CAPPluginReturnPromise);
)
