import UIKit
import Capacitor
import WidgetKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        migrateUserDefaultsToAppGroups()
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        // Called when the app was launched with a url. Feel free to add additional processing here,
        // but if you want the App API to support tracking app url opens, make sure to keep this call
        return ApplicationDelegateProxy.shared.application(app, open: url, options: options)
    }

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        // Called when the app was launched with an activity, including Universal Links.
        // Feel free to add additional processing here, but if you want the App API to support
        // tracking app url opens, make sure to keep this call
        return ApplicationDelegateProxy.shared.application(application, continue: userActivity, restorationHandler: restorationHandler)
    }

}

// Workaround: cant access UserDefaults set by capacitor from an extension - only by using group
  func migrateUserDefaultsToAppGroups() {
          
          // User Defaults - Old
          let userDefaults = UserDefaults.standard
          
          // App Groups Default - New
          let groupDefaults = UserDefaults(suiteName: "group.com.kaloriq.shared")
          
          if let groupDefaults = groupDefaults {
              
                     // 🔹 Einmalige Migration
                     for key in userDefaults.dictionaryRepresentation().keys {
                         if key == "CapacitorStorage.widgetData" {
                             groupDefaults.set(userDefaults.dictionaryRepresentation()[key], forKey: "widgetData")
                         }
                     }
                     groupDefaults.synchronize()
                     WidgetCenter.shared.reloadAllTimelines()
                     print("Successfully migrated defaults")
                     
                     // 🔹 Timer für regelmäßigen Sync alle 10 Sekunden
                     Timer.scheduledTimer(withTimeInterval: 7.0, repeats: true) { _ in
                         for key in userDefaults.dictionaryRepresentation().keys {
                             if key == "CapacitorStorage.widgetData" {
                                 groupDefaults.set(userDefaults.dictionaryRepresentation()[key], forKey: "widgetData")
                             }
                         }
                         groupDefaults.synchronize()
                         WidgetCenter.shared.reloadAllTimelines()
                         print("Successfully migrated defaults in timer")
                     }

          } else {
              print("Unable to create NSUserDefaults with given app group")
          }
          
      }
