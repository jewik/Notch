import SwiftUI

struct BluetoothNotificationView: View {
    let systemName: String
    let deviceName: String
    let message: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.blue)
                .frame(width: 36, height: 36)
                .background(.blue.opacity(0.16), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(deviceName)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .lineLimit(1)

                Text(message)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .frame(width: 270, height: 58)
    }
}

#Preview {
    BluetoothNotificationView(
        systemName: "computermouse",
        deviceName: "MX Master 3",
        message: "Battery 72%"
    )
    .background(.black)
}
