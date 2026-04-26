import WidgetKit
import SwiftUI
import ActivityKit

/// Live Activity surface visible on:
/// • Lock screen / banner under the notch on notched iPhones — wide
///   monochrome pill with the developer handle.
/// • Dynamic Island (compact / minimal / expanded) — accent badge.
///
/// Colors stay close to system grays per the user's "no neon" guidance.
@available(iOS 16.1, *)
struct TGLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TGActivityAttributes.self) { context in
            TGLockScreenLiveActivityView(state: context.state)
                .activityBackgroundTint(Color.black.opacity(0.8))
                .activitySystemActionForegroundColor(Color.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label {
                        Text(context.state.label)
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                    } icon: {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(Color.white.opacity(0.9))
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    HStack(spacing: 6) {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(Color.white.opacity(0.7))
                        Text("\(context.state.ready)/\(context.state.totalAccounts)")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    if !context.state.lastAction.isEmpty {
                        Text(context.state.lastAction)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(2)
                    } else {
                        Text("TG MULTIACC")
                            .font(.system(size: 12, weight: .heavy, design: .monospaced))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            } compactLeading: {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(Color.white.opacity(0.9))
            } compactTrailing: {
                Text(context.state.label)
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
            } minimal: {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(Color.white.opacity(0.9))
            }
            .keylineTint(Color.white.opacity(0.55))
        }
    }
}

@available(iOS 16.1, *)
struct TGLockScreenLiveActivityView: View {
    let state: TGActivityAttributes.ContentState

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                    )
                Image(systemName: "paperplane.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 22, weight: .bold))
            }
            .frame(width: 46, height: 46)

            VStack(alignment: .leading, spacing: 3) {
                Text("TG MULTIACC")
                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    .foregroundColor(.white.opacity(0.55))
                Text(state.label)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                if state.totalAccounts > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "person.2.fill").foregroundColor(.white.opacity(0.7))
                        Text("\(state.ready)/\(state.totalAccounts)")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                }
                if !state.lastAction.isEmpty {
                    Text(state.lastAction)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                }
            }
        }
        .padding(14)
    }
}
