import SwiftUI

struct LogsView: View {
    @EnvironmentObject var settings: SettingsStore
    @EnvironmentObject var logger: AppLogger

    @State private var search: String = ""
    @State private var levelFilter: LogLevel? = nil
    @State private var shareURL: URL?
    @State private var pinToBottom: Bool = true

    var l: L10n { settings.l10n }

    var filtered: [LogEntry] {
        var arr = logger.entries
        if let lvl = levelFilter { arr = arr.filter { $0.level == lvl } }
        if !search.isEmpty {
            let s = search.lowercased()
            arr = arr.filter {
                $0.message.lowercased().contains(s) ||
                $0.category.lowercased().contains(s) ||
                ($0.detail?.lowercased().contains(s) ?? false)
            }
        }
        return arr
    }

    var body: some View {
        ZStack {
            settings.theme.background.ignoresSafeArea()
            VStack(spacing: 0) {
                filterBar
                if logger.entries.isEmpty {
                    EmptyStateView(icon: "doc.text", title: l.t("logs.empty"), action: nil)
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 6) {
                                ForEach(filtered) { entry in
                                    LogRow(entry: entry).id(entry.id)
                                }
                            }
                            .padding(12)
                        }
                        .onChange(of: filtered.count) { _ in
                            if pinToBottom, let last = filtered.last {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    proxy.scrollTo(last.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(l.t("logs.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        if let url = logger.makeShareableSnapshot() { shareURL = url }
                    } label: { Label(l.t("logs.export"), systemImage: "square.and.arrow.up") }

                    Button(role: .destructive) {
                        logger.clear()
                    } label: { Label(l.t("logs.clear"), systemImage: "trash") }

                    Toggle("Pin to bottom", isOn: $pinToBottom)
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(settings.theme.accent)
                }
            }
        }
        .sheet(item: Binding(
            get: { shareURL.map { ShareURLItem(url: $0) } },
            set: { _ in shareURL = nil }
        )) { item in
            ShareSheet(items: [item.url])
        }
    }

    private var filterBar: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundStyle(AppTheme.textTertiary)
                TextField(l.t("logs.search"), text: $search)
                    .textFieldStyle(.plain)
                    .foregroundStyle(AppTheme.textPrimary)
                    .font(AppTheme.body(14))
                if !search.isEmpty {
                    Button { search = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(AppTheme.textTertiary)
                    }.buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 9)
            .background(RoundedRectangle(cornerRadius: 10).fill(AppTheme.surfaceElevated))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    levelChip(nil, label: l.t("logs.filter.all"))
                    ForEach(LogLevel.allCases) { lvl in
                        levelChip(lvl, label: lvl.label)
                    }
                }
            }
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(AppTheme.surface)
    }

    @ViewBuilder
    private func levelChip(_ lvl: LogLevel?, label: String) -> some View {
        let selected = levelFilter == lvl
        Button {
            levelFilter = lvl
        } label: {
            Text(label)
                .font(AppTheme.mono(11))
                .padding(.horizontal, 10).padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 8)
                    .fill(selected ? (lvl?.color ?? settings.theme.accent).opacity(0.25)
                                    : AppTheme.surfaceElevated))
                .overlay(RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(selected ? (lvl?.color ?? settings.theme.accent) : AppTheme.separator,
                                  lineWidth: 1))
                .foregroundStyle(selected ? (lvl?.color ?? settings.theme.accent) : AppTheme.textSecondary)
        }
    }
}

private struct LogRow: View {
    let entry: LogEntry
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Text(entry.level.label)
                    .font(AppTheme.mono(10))
                    .padding(.horizontal, 5).padding(.vertical, 2)
                    .background(RoundedRectangle(cornerRadius: 4).fill(entry.level.color.opacity(0.18)))
                    .foregroundStyle(entry.level.color)
                Text(entry.timeString)
                    .font(AppTheme.mono(10))
                    .foregroundStyle(AppTheme.textTertiary)
                Text(entry.category)
                    .font(AppTheme.mono(10))
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
                if entry.detail != nil {
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(AppTheme.textTertiary)
                }
            }
            Text(entry.message)
                .font(AppTheme.body(13))
                .foregroundStyle(AppTheme.textPrimary)
                .multilineTextAlignment(.leading)
            if expanded, let d = entry.detail {
                Text(d)
                    .font(AppTheme.mono(11))
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 6).fill(AppTheme.surface))
            }
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 8).fill(AppTheme.surface))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(AppTheme.separator, lineWidth: 1))
        .onTapGesture {
            if entry.detail != nil {
                withAnimation { expanded.toggle() }
            }
        }
    }
}

private struct ShareURLItem: Identifiable {
    let url: URL
    var id: URL { url }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
