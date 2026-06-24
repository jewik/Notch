import SwiftUI

struct SystemLoadRow: View {
    let snapshot: SystemLoadSnapshot
    let pointMultiplier: CGFloat

    private func points(_ value: CGFloat) -> CGFloat {
        value * pointMultiplier
    }

    private var horizontalPadding: CGFloat {
        points(10)
    }

    private var gaugeSpacing: CGFloat {
        points(18)
    }

    var body: some View {
        HStack(alignment: .center, spacing: gaugeSpacing) {
            SystemLoadGauge(
                title: "RAM",
                value: snapshot.memoryLoad,
                tint: .blue,
                pointMultiplier: pointMultiplier
            )

            SystemLoadGauge(
                title: "CPU",
                value: snapshot.cpuLoad,
                tint: .green,
                pointMultiplier: pointMultiplier
            )
        }
        .padding(.leading, horizontalPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}
