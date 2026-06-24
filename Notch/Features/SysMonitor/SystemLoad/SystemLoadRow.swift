import SwiftUI

struct SystemLoadRow: View {


    let snapshot: SystemLoadSnapshot
    let pointMultiplier: CGFloat

    private func points(_ value: CGFloat) -> CGFloat {
        value * pointMultiplier
    }


    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            SystemLoadGauge(
                title: "MEM",
                value: snapshot.memoryLoad,
                pointMultiplier: pointMultiplier
            )

            Spacer(minLength: points(8))

            SystemLoadGauge(
                title: "CPU",
                value: snapshot.cpuLoad,
                pointMultiplier: pointMultiplier
            )

            Spacer(minLength: points(8))

            SystemLoadGauge(
                title: "DISK",
                value: snapshot.diskLoad,
                pointMultiplier: pointMultiplier
            )

            Spacer(minLength: points(8))

            SystemLoadGauge(
                title: "BAT",
                value: snapshot.batteryCharge,
                pointMultiplier: pointMultiplier
            )
        }
        .padding(.horizontal, points(24))
        .padding(.bottom, points(24))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }
}
