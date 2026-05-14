import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let controller = window?.rootViewController as? FlutterViewController {
      let timeZoneChannel = FlutterMethodChannel(
        name: "dawatime/timezone",
        binaryMessenger: controller.binaryMessenger
      )

      timeZoneChannel.setMethodCallHandler { call, result in
        if call.method == "getLocalTimeZone" {
          result(TimeZone.current.identifier)
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
