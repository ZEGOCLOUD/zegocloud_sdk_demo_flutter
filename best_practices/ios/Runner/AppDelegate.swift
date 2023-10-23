import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // Add this code.
    ZegoBeautyPlugin.register(with: registrar(forPlugin: "ZegoBeautyPlugin")!)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
