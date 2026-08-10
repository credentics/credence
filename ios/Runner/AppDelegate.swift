import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var backgroundTasks: [Int: UIBackgroundTaskIdentifier] = [:]
  private var nextBackgroundTaskId = 1

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "pass_doc_manager/background_task",
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { [weak self] call, result in
        guard let self = self else {
          result(nil)
          return
        }
        switch call.method {
        case "begin":
          let args = call.arguments as? [String: Any]
          let reason = args?["reason"] as? String ?? "Credence background work"
          result(self.beginBackgroundTask(reason: reason))
        case "end":
          let args = call.arguments as? [String: Any]
          if let id = args?["id"] as? Int {
            self.endBackgroundTask(id: id)
          }
          result(nil)
        case "setScreenAwake":
          let args = call.arguments as? [String: Any]
          let enabled = args?["enabled"] as? Bool ?? false
          UIApplication.shared.isIdleTimerDisabled = enabled
          result(nil)
        default:
          result(FlutterMethodNotImplemented)
        }
      }

      let liveActivityChannel = FlutterMethodChannel(
        name: "pass_doc_manager/live_activity",
        binaryMessenger: controller.binaryMessenger
      )
      liveActivityChannel.setMethodCallHandler { call, result in
        guard #available(iOS 16.1, *) else {
          result(nil)
          return
        }
        let args = call.arguments as? [String: Any] ?? [:]
        switch call.method {
        case "isAvailable":
          result(CredenceLiveActivityController.activitiesEnabled)
        case "start":
          do {
            result(try CredenceLiveActivityController.start(arguments: args))
          } catch {
            result(FlutterError(
              code: "live_activity_start_failed",
              message: error.localizedDescription,
              details: nil
            ))
          }
        case "update":
          Task {
            await CredenceLiveActivityController.update(arguments: args)
            result(nil)
          }
        case "end":
          Task {
            await CredenceLiveActivityController.end(arguments: args)
            result(nil)
          }
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func beginBackgroundTask(reason: String) -> Int? {
    let id = nextBackgroundTaskId
    nextBackgroundTaskId += 1

    var taskIdentifier = UIBackgroundTaskIdentifier.invalid
    taskIdentifier = UIApplication.shared.beginBackgroundTask(withName: reason) { [weak self] in
      self?.endBackgroundTask(id: id)
    }

    if taskIdentifier == UIBackgroundTaskIdentifier.invalid {
      return nil
    }

    backgroundTasks[id] = taskIdentifier
    return id
  }

  private func endBackgroundTask(id: Int) {
    guard let taskIdentifier = backgroundTasks.removeValue(forKey: id) else {
      return
    }
    UIApplication.shared.endBackgroundTask(taskIdentifier)
  }
}
