import ActivityKit
import Foundation

@available(iOS 16.1, *)
final class CredenceLiveActivityController {
  private static var activity: Activity<CredenceBackupActivityAttributes>?

  static var activitiesEnabled: Bool {
    ActivityAuthorizationInfo().areActivitiesEnabled
  }

  static func start(arguments: [String: Any]) throws -> String? {
    guard activitiesEnabled else {
      return nil
    }

    let state = contentState(from: arguments)
    if let existing = activity {
      Task {
        await updateActivity(existing, state: state)
      }
      return existing.id
    }

    let attributes = CredenceBackupActivityAttributes(
      startedAtIso: ISO8601DateFormatter().string(from: Date())
    )

    let requested: Activity<CredenceBackupActivityAttributes>
    if #available(iOS 16.2, *) {
      requested = try Activity.request(
        attributes: attributes,
        content: ActivityContent(state: state, staleDate: nil),
        pushType: nil
      )
    } else {
      requested = try Activity.request(
        attributes: attributes,
        contentState: state,
        pushType: nil
      )
    }

    activity = requested
    return requested.id
  }

  static func update(arguments: [String: Any]) async {
    guard let existing = activity else {
      return
    }
    await updateActivity(existing, state: contentState(from: arguments))
  }

  static func end(arguments: [String: Any]) async {
    guard let existing = activity else {
      return
    }

    let state = contentState(from: arguments)
    let dismissal = ActivityUIDismissalPolicy.after(
      Date().addingTimeInterval(state.status == "failure" ? 14 : 8)
    )

    if #available(iOS 16.2, *) {
      await existing.end(
        ActivityContent(state: state, staleDate: nil),
        dismissalPolicy: dismissal
      )
    } else {
      await existing.end(using: state, dismissalPolicy: dismissal)
    }
    activity = nil
  }

  private static func updateActivity(
    _ activity: Activity<CredenceBackupActivityAttributes>,
    state: CredenceBackupActivityAttributes.ContentState
  ) async {
    if #available(iOS 16.2, *) {
      await activity.update(ActivityContent(state: state, staleDate: nil))
    } else {
      await activity.update(using: state)
    }
  }

  private static func contentState(
    from arguments: [String: Any]
  ) -> CredenceBackupActivityAttributes.ContentState {
    CredenceBackupActivityAttributes.ContentState(
      operation: string(arguments["operation"], fallback: "Sync"),
      provider: string(arguments["provider"], fallback: "Credence"),
      message: string(arguments["message"], fallback: "Working"),
      detail: string(arguments["detail"], fallback: ""),
      progress: progress(arguments["progress"]),
      status: string(arguments["status"], fallback: "running")
    )
  }

  private static func string(_ value: Any?, fallback: String) -> String {
    let raw = (value as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let raw, !raw.isEmpty else {
      return fallback
    }
    return raw
  }

  private static func progress(_ value: Any?) -> Double {
    let raw: Double
    if let doubleValue = value as? Double {
      raw = doubleValue
    } else if let numberValue = value as? NSNumber {
      raw = numberValue.doubleValue
    } else {
      raw = 0
    }
    return min(max(raw, 0), 1)
  }
}
