import SwiftUI

struct SysMonitorPageView: View {
    let pointMultiplier: CGFloat
    let openRoute: (PanelRoute) -> Void
    @StateObject private var systemLoad = SystemLoadMonitor()

    private func points(_ value: CGFloat) -> CGFloat {
        value * pointMultiplier
    }

    private var rowWidth: CGFloat {
        points(PanelSizePreset.sysMonitor.width)
    }

    private var serviceRowHeight: CGFloat {
        points(35)
    }

    private var systemRowHeight: CGFloat {
        points(65)
    }

    var body: some View {
        VStack(spacing: 0) {
            ServiceButtonRow(
                pointMultiplier: pointMultiplier,
                openRoute: openRoute
            )
                .frame(width: rowWidth, height: serviceRowHeight, alignment: .leading)

            SystemLoadRow(snapshot: systemLoad.snapshot, pointMultiplier: pointMultiplier)
                .frame(width: rowWidth, height: systemRowHeight, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

private struct ServiceButtonRow: View {
    let pointMultiplier: CGFloat
    let openRoute: (PanelRoute) -> Void

    private func points(_ value: CGFloat) -> CGFloat {
        value * pointMultiplier
    }

    var body: some View {
        HStack(spacing: 0) {
            Button {
                openRoute(.clipboard)
            } label: {
                Image(systemName: "doc.on.clipboard")
                    .font(.system(size: points(15), weight: .semibold))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white.opacity(0.86))
            .frame(width: points(35))
            .frame(maxHeight: .infinity)
            .accessibilityLabel("Clipboard")

            Spacer(minLength: 0)
        }
    }
}
