import SwiftUI

struct SystemLoadRow: View {
    let snapshot: SystemLoadSnapshot
    let pointMultiplier: CGFloat

    private func points(_ value: CGFloat) -> CGFloat {
        value * pointMultiplier
    }

    private var horizontalPadding: CGFloat {
        points(12)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            SystemLoadGauge(
                title: "RAM",
                value: snapshot.memoryLoad,
                tint: .blue,
                pointMultiplier: pointMultiplier
            )

            Spacer(minLength: points(8))

            SystemLoadGauge(
                title: "CPU",
                value: snapshot.cpuLoad,
                tint: .green,
                pointMultiplier: pointMultiplier
            )

            Spacer(minLength: points(8))

            SystemLoadGauge(
                title: "Disk",
                value: snapshot.diskLoad,
                tint: .orange,
                pointMultiplier: pointMultiplier
            )

            Spacer(minLength: points(8))

            SystemLoadGauge(
                title: "Batt",
                value: snapshot.batteryCharge,
                tint: .yellow,
                pointMultiplier: pointMultiplier
            )
        }
        .padding(.horizontal, horizontalPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}
