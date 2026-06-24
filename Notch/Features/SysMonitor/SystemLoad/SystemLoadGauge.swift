import SwiftUI

struct SystemLoadGauge: View {
    let title: String
    let value: Double
    let pointMultiplier: CGFloat
    @State private var isHovering = false

    private func points(_ value: CGFloat) -> CGFloat {
        value * pointMultiplier
    }

    private var clampedValue: Double {
        min(max(value, 0), 1)
    }

    private var percentageText: String {
        clampedValue.formatted(.percent.precision(.fractionLength(0)))
    }

    private var iconName: String {
        switch title {
        case "MEM":
            "memorychip"
        case "CPU":
            "cpu"
        case "DISK":
            "internaldrive"
        case "BAT":
            "battery.100percent"
        default:
            "gauge"
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    Color.gray.opacity(0.35),
                    style: StrokeStyle(lineWidth: points(5), lineCap: .round)
                )

            Circle()
                .trim(from: 0, to: clampedValue)
                .stroke(
                    Color.green,
                    style: StrokeStyle(lineWidth: points(5), lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            ZStack {
                VStack(spacing: points(1)) {
                    Image(systemName: iconName)
                        .font(.system(size: points(11), weight: .semibold))

                    Text(title)
                        .font(.system(size: points(10), weight: .semibold, design: .rounded))
                }
                    .opacity(isHovering ? 0 : 1)
                    .blur(radius: isHovering ? points(4) : 0)

                Text(percentageText)
                    .font(.system(size: points(13), weight: .semibold, design: .rounded))
                    .opacity(isHovering ? 1 : 0)
                    .blur(radius: isHovering ? 0 : points(4))
                    .monospacedDigit()
            }
        }
        .frame(width: points(52), height: points(52))
        .contentShape(Circle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.18)) {
                isHovering = hovering
            }
        }
        .accessibilityLabel(title)
        .accessibilityValue(percentageText)
    }
}
