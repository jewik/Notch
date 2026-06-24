import SwiftUI

struct HomePageView: View {
    let pointMultiplier: CGFloat

    private func points(_ value: CGFloat) -> CGFloat {
        value * pointMultiplier
    }

    var body: some View {
        HStack {
            Text("Hello!")
                .font(.system(size: points(18), weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))

            Spacer(minLength: 0)
        }
        .padding(.horizontal, points(18))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
