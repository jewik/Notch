import SwiftUI

struct SystemLoadGauge: View {
    let title: String
    let value: Double
    let tint: Color
    let pointMultiplier: CGFloat

    private func points(_ value: CGFloat) -> CGFloat {
        value * pointMultiplier
    }

    private var percentageText: String {
        value.formatted(.percent.precision(.fractionLength(0)))
    }

    var body: some View {
        Gauge(value: value, in: 0...1) {
            Text(title)
        } currentValueLabel: {
            Text(percentageText)
                .font(.system(size: points(10), weight: .semibold, design: .rounded))
                .monospacedDigit()
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .tint(tint)
        .frame(width: points(52), height: points(52))
        .accessibilityLabel(title)
        .accessibilityValue(percentageText)
    }
}
