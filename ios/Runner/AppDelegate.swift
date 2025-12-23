import Flutter
import UIKit
import GoogleMaps // ✅ Added this line

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // ✅ Added your Google Maps API key initialization here
    GMSServices.provideAPIKey("DbYZO9XiU3YZJl1eJLshFvJa7c4c5viJ")

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
