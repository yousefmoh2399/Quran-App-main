import UIKit
import Flutter
import AudioToolbox

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterBinaryMessenger {
      let vibrationChannel = FlutterMethodChannel(name: "com.taqarrab.quran/vibration", binaryMessenger: controller)
      vibrationChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
        if call.method == "vibrate" || call.method == "vibratePattern" {
          AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
          let generator = UIImpactFeedbackGenerator(style: .heavy)
          generator.prepare()
          generator.impactOccurred()
          result(true)
        } else if call.method == "cancel" {
          result(true)
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
