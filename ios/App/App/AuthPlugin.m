#import <Capacitor/Capacitor.h>

CAP_PLUGIN(AuthPlugin, "AuthPlugin",
    CAP_PLUGIN_METHOD(signInWithApple, CAPPluginReturnPromise);
)
