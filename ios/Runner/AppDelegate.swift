import UIKit
import Flutter
import AudioToolbox
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var audioPlayer: AVAudioPlayer?

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

      let navChannel = FlutterMethodChannel(name: "com.taqarrab.quran/app_navigation", binaryMessenger: controller)
      navChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
        if call.method == "getInitialNavigation" {
          result(nil)
        } else if call.method == "setSystemGestureExclusion" {
          result(true)
        } else {
          result(FlutterMethodNotImplemented)
        }
      }

      let remindersChannel = FlutterMethodChannel(name: "com.taqarrab.quran/native_reminders", binaryMessenger: controller)
      remindersChannel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
        guard let self = self else {
          result(false)
          return
        }
        if call.method == "previewSound" {
          let soundKey = (call.arguments as? [String: Any])?["soundKey"] as? String ?? "fazakkir"
          self.playPreviewSound(soundKey: soundKey)
          result(true)
        } else if call.method == "stopSound" {
          self.stopPreviewSound()
          result(true)
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func playPreviewSound(soundKey: String) {
    stopPreviewSound()
    guard soundKey != "silent" && soundKey != "system_default" else { return }

    let filename: String
    switch soundKey {
    case "fazakkir": filename = "fazakkir"
    case "azkar_1": filename = "azkar_1"
    case "azkar_2": filename = "azkar_2"
    case "adhan": filename = "adhan_ios"
    case "cannon": filename = "cannon"
    default: filename = soundKey
    }

    guard let url = Bundle.main.url(forResource: filename, withExtension: "wav") else {
      print("⚠️ [AppDelegate] Sound file not found: \(filename).wav")
      return
    }

    do {
      try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
      try AVAudioSession.sharedInstance().setActive(true)
      audioPlayer = try AVAudioPlayer(contentsOf: url)
      audioPlayer?.prepareToPlay()
      audioPlayer?.play()
    } catch {
      print("⚠️ [AppDelegate] Error playing preview sound: \(error)")
    }
  }

  private func stopPreviewSound() {
    audioPlayer?.stop()
    audioPlayer = nil
  }
}
