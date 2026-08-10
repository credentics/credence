import ActivityKit
import Foundation

@available(iOS 16.1, *)
struct CredenceBackupActivityAttributes: ActivityAttributes {
  public struct ContentState: Codable, Hashable {
    var operation: String
    var provider: String
    var message: String
    var detail: String
    var progress: Double
    var status: String
  }

  var startedAtIso: String
}
