#import <Foundation/Foundation.h>
#import <Capacitor/Capacitor.h>

// Define the plugin using the CAP_PLUGIN Macro, and
// each method the plugin supports using the CAP_PLUGIN_METHOD macro.
CAP_PLUGIN(HealthKitPlugin, "HealthKitPlugin",
           CAP_PLUGIN_METHOD(echo, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(isAvailable, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(requestPermissions, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(writeCalories, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(readCalories, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(writeWeight, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(readWeight, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(writeWater, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(readWater, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(writeMacros, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(readMacros, CAPPluginReturnPromise);
           CAP_PLUGIN_METHOD(readSteps, CAPPluginReturnPromise);
)
