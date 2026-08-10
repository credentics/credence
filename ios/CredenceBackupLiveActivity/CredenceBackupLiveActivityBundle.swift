import ActivityKit
import SwiftUI
import WidgetKit

@main
struct CredenceBackupLiveActivityBundle: WidgetBundle {
  var body: some Widget {
    CredenceBackupLiveActivityWidget()
  }
}

struct CredenceBackupLiveActivityWidget: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: CredenceBackupActivityAttributes.self) { context in
      CredenceBackupLockScreenView(state: context.state)
        .activityBackgroundTint(CredenceLiveActivityColors.surface)
        .activitySystemActionForegroundColor(CredenceLiveActivityColors.primary)
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          CredenceLiveActivityGlyph(state: context.state, size: 34)
        }
        DynamicIslandExpandedRegion(.center) {
          VStack(alignment: .leading, spacing: 2) {
            Text(activityTitle(context.state))
              .font(.system(size: 14, weight: .semibold, design: .rounded))
              .lineLimit(1)
            Text(providerLine(context.state))
              .font(.system(size: 11, weight: .medium, design: .rounded))
              .foregroundStyle(.secondary)
              .lineLimit(1)
          }
        }
        DynamicIslandExpandedRegion(.trailing) {
          VStack(alignment: .trailing, spacing: 2) {
            Text(percentText(context.state.progress))
              .font(.system(size: 15, weight: .bold, design: .rounded))
              .foregroundStyle(statusColor(context.state))
              .monospacedDigit()
            Image(systemName: iconName(context.state))
              .font(.system(size: 10, weight: .semibold))
              .foregroundStyle(.secondary)
          }
        }
        DynamicIslandExpandedRegion(.bottom) {
          VStack(alignment: .leading, spacing: 5) {
            CredenceLiveActivityProgressBar(state: context.state)
            Text(shortDetail(context.state))
              .font(.system(size: 11, weight: .medium, design: .rounded))
              .foregroundStyle(.secondary)
              .lineLimit(1)
          }
          .padding(.top, 1)
        }
      } compactLeading: {
        Image(systemName: iconName(context.state))
          .font(.system(size: 12, weight: .semibold))
          .foregroundStyle(statusColor(context.state))
      } compactTrailing: {
        Text(percentText(context.state.progress))
          .font(.system(size: 11, weight: .bold, design: .rounded))
          .foregroundStyle(statusColor(context.state))
          .monospacedDigit()
      } minimal: {
        ZStack {
          Circle()
            .stroke(statusColor(context.state).opacity(0.25), lineWidth: 3)
          Circle()
            .trim(from: 0, to: max(0.04, context.state.progress))
            .stroke(
              statusColor(context.state),
              style: StrokeStyle(lineWidth: 3, lineCap: .round)
            )
            .rotationEffect(.degrees(-90))
          Image(systemName: iconName(context.state))
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(statusColor(context.state))
        }
      }
      .keylineTint(statusColor(context.state))
    }
  }
}

private struct CredenceBackupLockScreenView: View {
  let state: CredenceBackupActivityAttributes.ContentState

  var body: some View {
    HStack(spacing: 12) {
      CredenceLiveActivityGlyph(state: state, size: 42)

      VStack(alignment: .leading, spacing: 4) {
        Text(activityTitle(state))
          .font(.system(size: 16, weight: .bold, design: .rounded))
          .foregroundStyle(CredenceLiveActivityColors.text)
          .lineLimit(1)

        Text(shortDetail(state))
          .font(.system(size: 12, weight: .medium, design: .rounded))
          .foregroundStyle(.secondary)
          .lineLimit(1)

        CredenceLiveActivityProgressBar(state: state)
          .padding(.top, 2)
      }

      Spacer(minLength: 8)

      VStack(alignment: .trailing, spacing: 4) {
        Text(state.provider)
          .font(.system(size: 11, weight: .semibold, design: .rounded))
          .foregroundStyle(.secondary)
          .lineLimit(1)
        Text(percentText(state.progress))
          .font(.system(size: 17, weight: .bold, design: .rounded))
          .foregroundStyle(statusColor(state))
          .monospacedDigit()
      }
    }
    .padding(14)
  }
}

private struct CredenceLiveActivityGlyph: View {
  let state: CredenceBackupActivityAttributes.ContentState
  let size: CGFloat

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
        .fill(statusColor(state).opacity(0.14))
      Image(systemName: iconName(state))
        .font(.system(size: size * 0.40, weight: .semibold))
        .foregroundStyle(statusColor(state))
    }
    .frame(width: size, height: size)
  }
}

private struct CredenceLiveActivityProgressBar: View {
  let state: CredenceBackupActivityAttributes.ContentState

  var body: some View {
    GeometryReader { geometry in
      ZStack(alignment: .leading) {
        Capsule()
          .fill(statusColor(state).opacity(0.14))
        Capsule()
          .fill(statusColor(state))
          .frame(width: max(8, geometry.size.width * state.progress))
      }
    }
    .frame(height: 6)
  }
}

private enum CredenceLiveActivityColors {
  static let primary = Color(red: 0.08, green: 0.43, blue: 0.23)
  static let warning = Color(red: 0.76, green: 0.43, blue: 0.06)
  static let danger = Color(red: 0.74, green: 0.16, blue: 0.18)
  static let surface = Color(red: 0.98, green: 0.97, blue: 0.95)
  static let text = Color(red: 0.14, green: 0.13, blue: 0.12)
}

private func activityTitle(
  _ state: CredenceBackupActivityAttributes.ContentState
) -> String {
  switch state.status {
  case "success":
    return "\(state.operation) complete"
  case "failure":
    return "\(state.operation) failed"
  default:
    if state.operation.lowercased().contains("sync") {
      return "Syncing backup"
    }
    if state.operation.lowercased().contains("restore") {
      return "Restoring vault"
    }
    return "Creating backup"
  }
}

private func providerLine(
  _ state: CredenceBackupActivityAttributes.ContentState
) -> String {
  state.provider.isEmpty ? "Credence" : state.provider
}

private func shortDetail(
  _ state: CredenceBackupActivityAttributes.ContentState
) -> String {
  let detail = state.detail.trimmingCharacters(in: .whitespacesAndNewlines)
  if !detail.isEmpty {
    return detail
  }
  let message = state.message.trimmingCharacters(in: .whitespacesAndNewlines)
  if !message.isEmpty {
    return message
  }
  return "Keeping the vault mirror up to date"
}

private func percentText(_ progress: Double) -> String {
  "\(Int((min(max(progress, 0), 1) * 100).rounded()))%"
}

private func statusColor(
  _ state: CredenceBackupActivityAttributes.ContentState
) -> Color {
  switch state.status {
  case "success":
    return CredenceLiveActivityColors.primary
  case "failure":
    return CredenceLiveActivityColors.danger
  default:
    return state.operation.lowercased().contains("restore")
      ? CredenceLiveActivityColors.warning
      : CredenceLiveActivityColors.primary
  }
}

private func iconName(
  _ state: CredenceBackupActivityAttributes.ContentState
) -> String {
  switch state.status {
  case "success":
    return "checkmark.icloud.fill"
  case "failure":
    return "exclamationmark.icloud.fill"
  default:
    if state.operation.lowercased().contains("restore") {
      return "icloud.and.arrow.down.fill"
    }
    if state.operation.lowercased().contains("backup") ||
      state.operation.lowercased().contains("sync") {
      return "arrow.triangle.2.circlepath.icloud.fill"
    }
    return "icloud.fill"
  }
}
