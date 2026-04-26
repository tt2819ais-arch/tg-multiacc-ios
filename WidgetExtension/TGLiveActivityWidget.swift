import WidgetKit
import SwiftUI
import ActivityKit

/// Live Activity surface visible on:
/// • Lock screen (full island) — wide pill with developer handle + counters.
/// • Dynamic Island (compact / minimal / expanded) — accent badge.
/// • Notched iPhones (e.g. iPhone 11) — TDLib-style pill near the status bar.
@available(iOS 16.1, *)
struct TGLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TGActivityAttributes.self) { context in
            // Lock-screen + iPhone-without-island banner.
            TGLockScreenLiveActivityView(state: context.state)
                .activityBackgroundTint(Color.black)
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
                            .foregroundColor(.cyan)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    HStack(spacing: 6) {
                        Image(systemName: "person.2.fill")
                            .foregroundColor(.cyan)
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
                Image(systemName: "paperplane.fill").foregroundColor(.cyan)
            } compactTrailing: {
                Text(context.state.label)
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
            } minimal: {
                Image(systemName: "paperplane.fill").foregroundColor(.cyan)
            }
            .keylineTint(.cyan)
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
                    .fill(LinearGradient(colors: [Color.cyan, Color.blue],
                                          startPoint: .topLeading,
                                          endPoint: .bottomTrailing))
                Image(systemName: "paperplane.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 22, weight: .black))
            }
            .frame(width: 46, height: 46)

            VStack(alignment: .leading, spacing: 3) {
                Text("TG MULTIACC")
                    .font(.system(size: 11, weight: .heavy, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))
                Text(state.label)
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                HStack(spacing: 6) {
                    Image(systemName: "person.2.fill").foregroundColor(.cyan)
                    Text("\(state.ready)/\(state.totalAccounts)")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
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
