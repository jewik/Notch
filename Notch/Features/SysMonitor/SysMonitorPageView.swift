import SwiftUI

struct SysMonitorPageView: View {
    let pointMultiplier: CGFloat
    @StateObject private var systemLoad = SystemLoadMonitor()

    var body: some View {
        SystemLoadRow(snapshot: systemLoad.snapshot, pointMultiplier: pointMultiplier)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}
