import SwiftUI

struct HomePageView: View {
    let pointMultiplier: CGFloat
    @StateObject private var systemLoad = SystemLoadMonitor()

    private func points(_ value: CGFloat) -> CGFloat {
        value * pointMultiplier
    }

    private var rowWidth: CGFloat {
        points(PanelSizePreset.home.width)
    }

    private var serviceRowHeight: CGFloat {
        points(35)
    }

    private var systemRowHeight: CGFloat {
        points(65)
    }

    var body: some View {
        VStack(spacing: 0) {
            ServiceButtonRow()
                .frame(width: rowWidth, height: serviceRowHeight, alignment: .leading)

            SystemLoadRow(snapshot: systemLoad.snapshot, pointMultiplier: pointMultiplier)
                .frame(width: rowWidth, height: systemRowHeight, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

private struct ServiceButtonRow: View {
    var body: some View {
        HStack(spacing: 0) {
            Color.clear
        }
    }
}
