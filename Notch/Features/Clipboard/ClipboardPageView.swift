import SwiftUI

struct ClipboardPageView: View {
    let pointMultiplier: CGFloat

    var body: some View {
        Color.clear
            .frame(
                width: PanelSizePreset.clipboard.width * pointMultiplier,
                height: PanelSizePreset.clipboard.height * pointMultiplier
            )
    }
}
